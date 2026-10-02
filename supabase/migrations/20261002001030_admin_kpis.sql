-- 1030 admin_kpis(): the Section 13 success metrics that admin_metrics() does
-- not cover (admin/BACKEND_NEEDS.md item 2). Admin only, read only.
--
-- Definitions (all percentages 0-100 with one decimal, null when the
-- denominator is 0 or the input is not configured):
--   request_to_acceptance_pct  requests created in the last 30 days that were awarded
--   seller_response_rate_pct   (seller, request) pairs notified as new_lead in the last 30 days
--                              that the seller quoted
--   free_to_paid_pct           sellers with a store-paid entitlement (any store but 'manual',
--                              ever paid) / all sellers
--   retention                  rolling Dn retention: of the users who signed up in the 30 days
--                              ending n days ago, the share active on or after day n. Activity =
--                              posting a request, sending a chat message, quoting, opening a lead,
--                              or the app refreshing its push token. Buyers by profiles.created_at,
--                              sellers by sellers.created_at; review accounts excluded.
--   revenue_30d_minor          estimated from kpi_product_prices_minor (admin setting,
--                              {"seller_pro_monthly": 49900, ...}) x store entitlements with a
--                              billing event in the last 30 days; null while the price map is empty
--   revenue_per_seller_minor   revenue_30d_minor / sellers (not hidden)
--   refunds_30d                entitlements refunded in the last 30 days
--   outreach_sent_today        'sent' outreach events since 00:00 UTC (the cap day)
--   outreach_daily_capacity    sum of active inboxes' warm-up caps, bounded by outreach_global_daily_cap
--   outreach_queue             leads still in the automated pipeline (sourced / contacted,
--                              sequence none / active, < 3 touches, not a seller)
--   outreach_reply_rate_pct    contacted leads that replied (replied, not_now or negative reply)
--   outreach_signup_rate_pct   contacted leads that became sellers
set search_path = public, extensions;

insert into public.app_settings (key, value, is_public, description) values
  ('kpi_product_prices_minor', '{}', false,
   'Gross price per product id in minor units for the admin revenue KPI estimate, e.g. {"seller_pro_monthly": 49900}')
on conflict (key) do nothing;

create or replace function private.kpi_pct(p_num numeric, p_den numeric)
returns numeric
language sql
immutable
set search_path = ''
as $$
  select case when coalesce(p_den, 0) = 0 then null else round(100.0 * coalesce(p_num, 0) / p_den, 1) end
$$;

create or replace function public.admin_kpis()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := now();
  v_since timestamptz := now() - interval '30 days';
  v_prices jsonb := coalesce(private.setting('kpi_product_prices_minor'), '{}'::jsonb);
  v_sellers bigint;
  v_revenue bigint;
  v_retention jsonb := '{}'::jsonb;
  v_n int;
  v_role text;
  v_pct numeric;
  v_contacted bigint;
begin
  perform private.require_admin();

  select count(*) into v_sellers from public.sellers where not hidden;

  -- retention ----------------------------------------------------------------------------------
  for v_role, v_n in select r, n from unnest(array['buyer','seller']) r cross join unnest(array[1, 7, 30]) n loop
    with cohort as (
      select p.id, p.created_at from public.profiles p
       where v_role = 'buyer' and p.status <> 'deleted' and not p.is_review_account
         and p.created_at >= v_now - make_interval(days => v_n + 30)
         and p.created_at < v_now - make_interval(days => v_n)
      union all
      select s.id, s.created_at from public.sellers s join public.profiles p on p.id = s.id
       where v_role = 'seller' and p.status <> 'deleted' and not p.is_review_account
         and s.created_at >= v_now - make_interval(days => v_n + 30)
         and s.created_at < v_now - make_interval(days => v_n)
    )
    select private.kpi_pct(count(*) filter (where
             exists (select 1 from public.requests r where r.buyer_id = c.id and r.created_at >= c.created_at + make_interval(days => v_n))
          or exists (select 1 from public.messages m where m.sender_id = c.id and m.created_at >= c.created_at + make_interval(days => v_n))
          or exists (select 1 from public.quotes q where q.seller_id = c.id and q.created_at >= c.created_at + make_interval(days => v_n))
          or exists (select 1 from public.lead_states ls where ls.seller_id = c.id and ls.seen_at >= c.created_at + make_interval(days => v_n))
          or exists (select 1 from public.device_tokens d where d.user_id = c.id and d.updated_at >= c.created_at + make_interval(days => v_n))),
           count(*))
      into v_pct from cohort c;
    v_retention := v_retention || jsonb_build_object(v_role || '_d' || v_n, v_pct);
  end loop;

  -- revenue estimate -----------------------------------------------------------------------------
  if jsonb_typeof(v_prices) = 'object' and v_prices <> '{}'::jsonb then
    select coalesce(sum(case when jsonb_typeof(v_prices -> e.product_id) = 'number'
                             then (v_prices ->> e.product_id)::bigint else 0 end), 0)
      into v_revenue
      from public.entitlements e
     where e.store <> 'manual'
       and e.status in ('active','grace','on_hold','paused','cancelled','expired')
       and coalesce(e.last_event_at, e.created_at) >= v_since;
  end if;

  select count(*) into v_contacted from public.outreach_leads where contacted_at is not null;

  return jsonb_build_object(
    'request_to_acceptance_pct', (
      select private.kpi_pct(count(*) filter (where r.status = 'awarded' or r.accepted_quote_id is not null), count(*))
        from public.requests r where r.created_at >= v_since and not r.hidden),
    'seller_response_rate_pct', (
      with notified as (
        select distinct n.user_id as seller_id, (n.payload ->> 'request_id')::uuid as request_id
          from public.notifications n
         where n.type = 'new_lead' and n.created_at >= v_since
           and n.payload ->> 'request_id' ~* '^[0-9a-f-]{36}$')
      select private.kpi_pct(count(*) filter (where exists (
               select 1 from public.quotes q where q.seller_id = x.seller_id and q.request_id = x.request_id)), count(*))
        from notified x),
    'free_to_paid_pct', private.kpi_pct(
      (select count(distinct e.seller_id) from public.entitlements e
        where e.store <> 'manual' and e.status in ('active','grace','on_hold','paused','cancelled','expired','refunded')),
      (select count(*) from public.sellers)),
    'retention', v_retention,
    'revenue_30d_minor', v_revenue,
    'revenue_per_seller_minor', case when v_revenue is null or v_sellers = 0 then null else v_revenue / v_sellers end,
    'refunds_30d', (select count(*) from public.entitlements e
                     where e.status = 'refunded' and coalesce(e.last_event_at, e.updated_at) >= v_since),
    'outreach_sent_today', (select count(*) from public.outreach_events e
                             where e.event_type = 'sent' and e.created_at >= date_trunc('day', v_now)),
    'outreach_daily_capacity', least(
      private.setting_int('outreach_global_daily_cap', 50),
      (select coalesce(sum(private.outreach_inbox_daily_cap(i.id, v_now)), 0)::int
         from public.outreach_inboxes i where i.active)),
    'outreach_queue', (select count(*) from public.outreach_leads l
                        where l.stage in ('sourced','contacted') and l.sequence_status in ('none','active')
                          and l.touches_sent < 3 and l.seller_id is null),
    'outreach_reply_rate_pct', private.kpi_pct(
      (select count(*) from public.outreach_leads l where l.contacted_at is not null and exists (
         select 1 from public.outreach_events e
          where e.lead_id = l.id and e.event_type in ('replied','not_now','negative_reply'))),
      v_contacted),
    'outreach_signup_rate_pct', private.kpi_pct(
      (select count(*) from public.outreach_leads l where l.contacted_at is not null and l.seller_id is not null),
      v_contacted),
    'outreach_active_campaigns', (select count(*) from public.outreach_campaigns c
                                   where c.status = 'active' and c.activated_by is not null),
    'outreach_business_address_ready', private.outreach_business_address_ready(),
    'computed_at', v_now);
end $$;

revoke all on function private.kpi_pct(numeric, numeric) from public, anon;
grant execute on function private.kpi_pct(numeric, numeric) to authenticated, service_role;
revoke execute on function public.admin_kpis() from public, anon;
grant execute on function public.admin_kpis() to authenticated, service_role;
