-- 0750 Functions for Edge Functions (service_role only) and scheduled jobs.
set search_path = public, extensions;

-- Reverse match for match-request (same rules as the lead feed).
create or replace function public.match_sellers_for_request(p_request_id uuid, p_limit int default 200)
returns table (seller_id uuid, verified boolean, has_priority boolean, notify_mode text,
               quiet_hours_start time, quiet_hours_end time, timezone text, language text,
               rating_avg numeric, avg_response_mins int, distance_m double precision,
               fcm_tokens text[])
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select m.*, (select coalesce(array_agg(d.fcm_token), '{}') from public.device_tokens d where d.user_id = m.seller_id)
    from private.match_sellers(p_request_id, least(greatest(p_limit, 0), 1000)) m
$$;

-- Atomically claims due notifications for push sending (skip locked, so
-- concurrent send-push invocations never double-send).
create or replace function public.claim_due_notifications(p_limit int default 500)
returns table (id uuid, user_id uuid, type text, payload jsonb, digest_key text, created_at timestamptz,
               language text, notification_prefs jsonb, timezone text, fcm_tokens text[])
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  return query
  with due as (
    select n.id from public.notifications n
     where n.push_status = 'queued' and n.push_after <= now()
     order by n.push_after
     limit least(greatest(p_limit, 1), 2000)
     for update skip locked
  ), upd as (
    update public.notifications n set push_status = 'sending'
      from due where n.id = due.id
    returning n.*
  )
  select u.id, u.user_id, u.type, u.payload, u.digest_key, u.created_at,
         p.language, p.notification_prefs,
         coalesce(p.timezone, private.setting_text('default_timezone', 'UTC')),
         (select coalesce(array_agg(d.fcm_token), '{}') from public.device_tokens d where d.user_id = u.user_id)
    from upd u join public.profiles p on p.id = u.user_id;
end $$;

-- p_status: 'sent' | 'failed' | 'skipped' | 'queued' (re-queue, e.g. quiet hours, with p_push_after)
create or replace function public.mark_notifications_pushed(
  p_ids uuid[], p_status text, p_push_after timestamptz default null)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare v_n int;
begin
  update public.notifications
     set push_status = p_status,
         sent_at = case when p_status = 'sent' then now() else sent_at end,
         push_after = coalesce(p_push_after, push_after)
   where id = any(p_ids);
  get diagnostics v_n = row_count;
  return v_n;
end $$;

create or replace function public.delete_device_tokens(p_tokens text[])
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare v_n int;
begin
  delete from public.device_tokens where fcm_token = any(p_tokens);
  get diagnostics v_n = row_count;
  return v_n;
end $$;

-- Webhook idempotency: returns true the first time an event is seen.
create or replace function public.record_billing_event(
  p_provider text, p_event_id text, p_event_type text, p_seller_id uuid, p_payload jsonb)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare v_id bigint;
begin
  insert into public.billing_events (provider, event_id, event_type, seller_id, payload)
  values (p_provider, p_event_id, p_event_type, p_seller_id, p_payload)
  on conflict (provider, event_id) do nothing
  returning id into v_id;
  return v_id is not null;
end $$;

-- Single entry point for every store/provider: upserts the seller's
-- entitlement by (store, original_transaction_id); credit packs add credits.
create or replace function public.apply_entitlement(
  p_seller_id uuid, p_store text, p_provider text, p_product_id text, p_tier text, p_status text,
  p_original_transaction_id text, p_credits_delta int default 0, p_renews_at timestamptz default null,
  p_expires_at timestamptz default null, p_external_customer_id text default null, p_raw jsonb default null)
returns public.entitlements
language plpgsql
security definer
set search_path = ''
as $$
declare v_ent public.entitlements;
begin
  if not exists (select 1 from public.sellers where id = p_seller_id) then
    perform private.raise_error('seller_not_found', 404);
  end if;
  insert into public.entitlements (seller_id, store, provider, product_id, tier, status, credits_balance,
                                   renews_at, expires_at, original_transaction_id, external_customer_id,
                                   last_event_at, raw)
  values (p_seller_id, p_store, p_provider, p_product_id, p_tier, p_status, greatest(coalesce(p_credits_delta, 0), 0),
          p_renews_at, p_expires_at, p_original_transaction_id, p_external_customer_id, now(), p_raw)
  on conflict (store, original_transaction_id) where original_transaction_id is not null do update set
    status = excluded.status,
    product_id = excluded.product_id,
    credits_balance = greatest(public.entitlements.credits_balance + coalesce(p_credits_delta, 0), 0),
    renews_at = coalesce(excluded.renews_at, public.entitlements.renews_at),
    expires_at = coalesce(excluded.expires_at, public.entitlements.expires_at),
    external_customer_id = coalesce(excluded.external_customer_id, public.entitlements.external_customer_id),
    last_event_at = now(),
    raw = coalesce(excluded.raw, public.entitlements.raw)
  returning * into v_ent;
  return v_ent;
end $$;

-- Scheduled jobs ------------------------------------------------------------------------------
-- Expire requests and quotes; remind buyers 2h before the quote window ends.
create or replace function private.expire_stale()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_req int; v_q int; v_rem int := 0;
  r record;
begin
  with x as (
    update public.requests set status = 'expired', closed_at = now()
     where status = 'open'
       and quote_window_ends_at + make_interval(days => private.setting_int('request_expire_days_after_window', 14)) < now()
    returning id)
  select count(*) into v_req from x;

  update public.quotes q set status = 'expired'
   where q.status in ('sent','revised','shortlisted')
     and (q.valid_until < current_date
          or exists (select 1 from public.requests r where r.id = q.request_id and r.status = 'expired'));
  get diagnostics v_q = row_count;

  for r in update public.requests rq set window_reminder_sent_at = now()
            where rq.status = 'open' and rq.window_reminder_sent_at is null
              and rq.quote_window_ends_at between now() and now() + interval '2 hours'
              and exists (select 1 from public.quotes q where q.request_id = rq.id and q.status in ('sent','revised'))
            returning rq.id, rq.buyer_id, rq.title loop
    perform private.notify(r.buyer_id, 'quote_window_ending',
      jsonb_build_object('request_id', r.id, 'title', r.title, 'route', '/r/' || r.id));
    v_rem := v_rem + 1;
  end loop;

  -- quotes expiring tomorrow: tell the seller
  perform private.notify(q.seller_id, 'quote_expiring',
           jsonb_build_object('quote_id', q.id, 'request_id', q.request_id, 'route', '/seller/quotes/' || q.id),
           'quote_expiring:' || q.seller_id)
     from public.quotes q
    where q.status in ('sent','revised','shortlisted') and q.valid_until = current_date + 1
      and not exists (select 1 from public.notifications n
                       where n.user_id = q.seller_id and n.type = 'quote_expiring'
                         and n.payload->>'quote_id' = q.id::text);

  delete from public.rate_limits where window_start < now() - interval '2 days';
  return jsonb_build_object('expired_requests', v_req, 'expired_quotes', v_q, 'window_reminders', v_rem);
end $$;

-- Licence expiry: mark expired, warn N days before.
create or replace function private.check_licence_expiry()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_exp int := 0; v_warn int := 0; l record;
begin
  for l in update public.seller_licences set status = 'expired'
            where status = 'approved' and expires_at is not null and expires_at <= now()
            returning id, seller_id, licence_type loop
    perform private.notify(l.seller_id, 'licence_expired',
      jsonb_build_object('licence_id', l.id, 'licence_type', l.licence_type, 'route', '/seller/verification'));
    v_exp := v_exp + 1;
  end loop;
  for l in update public.seller_licences set expiry_warned_at = now()
            where status = 'approved' and expiry_warned_at is null and expires_at is not null
              and expires_at <= now() + make_interval(days => private.setting_int('licence_expiry_warn_days', 30))
            returning id, seller_id, licence_type, expires_at loop
    perform private.notify(l.seller_id, 'licence_expiring',
      jsonb_build_object('licence_id', l.id, 'licence_type', l.licence_type, 'expires_at', l.expires_at,
                         'route', '/seller/verification'));
    v_warn := v_warn + 1;
  end loop;
  return jsonb_build_object('expired', v_exp, 'warned', v_warn);
end $$;

-- Grants: everything in public is service_role only unless granted below
-- to authenticated / anon.
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on all functions in schema public to service_role;

grant execute on function
  public.money_round_half_up(numeric, numeric),
  public.gst_line_tax(numeric, bigint, int, boolean),
  public.us_sales_tax(bigint, int),
  public.compute_quote_totals(text, jsonb, bigint, int, boolean),
  public.normalize_postal_code(text),
  public.is_valid_gstin(text),
  public.is_valid_ein(text),
  public.get_app_settings(),
  public.classify_request_text(text, int)
  to anon, authenticated;

grant execute on function
  public.set_active_mode(text),
  public.get_profiles_public(uuid[]),
  public.register_device_token(text, text, text, text),
  public.block_user(uuid),
  public.unblock_user(uuid),
  public.upsert_seller_profile(text, text, int, text[], text, double precision, double precision, numeric,
    text[], bigint[], text, text[], text, text, text, text, time, time, text, text, text, text, text, text),
  public.become_seller(text, text),
  public.get_my_seller_profile(),
  public.submit_verification(text, text, text),
  public.submit_licence(text, text, text, text, bigint[], timestamptz, text),
  public.get_my_entitlement(),
  public.create_request(bigint, text, text, jsonb, bigint, bigint, boolean, date, double precision,
    double precision, text, text, text, int, text, text, text, uuid),
  public.close_request(uuid, text, text),
  public.get_request_for_seller(uuid),
  public.get_lead_feed(jsonb, jsonb, int),
  public.dismiss_lead(uuid, boolean),
  public.mark_leads_seen(uuid[]),
  public.submit_quote(uuid, jsonb, bigint, int, text, date, text, int, text, text[], jsonb),
  public.revise_quote(uuid, jsonb, bigint, int, text, date, text, int, text, text[], jsonb),
  public.withdraw_quote(uuid),
  public.accept_quote(uuid),
  public.decline_quote(uuid, text),
  public.counter_offer(uuid, bigint, text),
  public.shortlist(uuid, boolean),
  public.get_my_quotes(text, jsonb, int),
  public.get_or_create_chat(uuid, uuid),
  public.open_chat(uuid, uuid),
  public.mark_read(uuid, timestamptz),
  public.mark_notifications_read(uuid[]),
  public.record_payment(uuid, text, bigint),
  public.update_order_status(uuid, text, text, timestamptz),
  public.get_order_contacts(uuid),
  public.submit_review(uuid, int, text[], text, text[]),
  public.seller_reply_review(uuid, text),
  public.report_content(text, uuid, text, text),
  public.delete_my_account(),
  -- admin (each checks the admin claim itself)
  public.admin_review_document(uuid, boolean, text, boolean),
  public.admin_set_seller_verification(uuid, text, text),
  public.admin_review_licence(uuid, boolean, text),
  public.admin_resolve_report(uuid, text, text),
  public.admin_set_user_status(uuid, text, timestamptz, text),
  public.admin_set_role(uuid, text, boolean),
  public.admin_set_category_policy(bigint, text, text, jsonb, jsonb),
  public.admin_upsert_category(bigint, text, jsonb, bigint, jsonb, text[], text, int, boolean),
  public.admin_upsert_keyword(text, text, bigint, text, jsonb, boolean),
  public.admin_set_setting(text, jsonb),
  public.admin_get_settings(),
  public.admin_grant_entitlement(uuid, text, int, timestamptz, text),
  public.admin_metrics()
  to authenticated;

-- The access token hook is for supabase_auth_admin only.
revoke execute on function public.custom_access_token_hook(jsonb) from authenticated, anon, public, service_role;
grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
