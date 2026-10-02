-- 0740 Admin RPCs. Every function calls private.require_admin(), which checks
-- the 'admin' entry of the roles claim (custom access token hook) AND the
-- profile row, so a revoked admin is locked out immediately.
set search_path = public, extensions;

create or replace function public.admin_review_document(
  p_document_id uuid, p_approve boolean, p_reason text default null, p_verify_seller boolean default true)
returns public.seller_documents
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_doc public.seller_documents;
begin
  update public.seller_documents
     set status = case when p_approve then 'approved' else 'rejected' end,
         rejection_reason = case when p_approve then null else p_reason end,
         reviewed_by = v_admin, reviewed_at = now()
   where id = p_document_id
  returning * into v_doc;
  if v_doc.id is null then perform private.raise_error('document_not_found', 404); end if;
  if p_approve and p_verify_seller then
    update public.sellers set verification_status = 'verified', verified_at = now() where id = v_doc.seller_id;
    perform private.notify(v_doc.seller_id, 'seller_verified', jsonb_build_object('route', '/seller/profile'));
  elsif not p_approve then
    update public.sellers set verification_status = 'rejected'
     where id = v_doc.seller_id and verification_status = 'pending'
       and not exists (select 1 from public.seller_documents d
                        where d.seller_id = v_doc.seller_id and d.status = 'pending');
    perform private.notify(v_doc.seller_id, 'verification_rejected',
      jsonb_build_object('reason', p_reason, 'route', '/seller/verification'));
  end if;
  return v_doc;
end $$;

create or replace function public.admin_set_seller_verification(
  p_seller_id uuid, p_status text, p_reason text default null)
returns public.sellers
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_seller public.sellers;
begin
  if p_status not in ('unverified','pending','verified','rejected') then
    perform private.raise_error('invalid_status', 400);
  end if;
  update public.sellers
     set verification_status = p_status,
         verified_at = case when p_status = 'verified' then now() else null end
   where id = p_seller_id returning * into v_seller;
  if v_seller.id is null then perform private.raise_error('seller_not_found', 404); end if;
  return v_seller;
end $$;

create or replace function public.admin_review_licence(p_licence_id uuid, p_approve boolean, p_reason text default null)
returns public.seller_licences
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_lic public.seller_licences;
begin
  update public.seller_licences
     set status = case when p_approve then 'approved' else 'rejected' end,
         rejection_reason = case when p_approve then null else p_reason end,
         reviewed_by = v_admin, reviewed_at = now()
   where id = p_licence_id returning * into v_lic;
  if v_lic.id is null then perform private.raise_error('licence_not_found', 404); end if;
  perform private.notify(v_lic.seller_id, case when p_approve then 'licence_approved' else 'licence_rejected' end,
    jsonb_build_object('licence_id', v_lic.id, 'reason', p_reason, 'route', '/seller/verification'));
  return v_lic;
end $$;

-- p_action: 'dismiss' (keep visible), 'hide' (keep hidden / hide), 'restore' (unhide + dismiss)
create or replace function public.admin_resolve_report(p_report_id uuid, p_action text, p_note text default null)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_rep public.reports;
  v_n int;
begin
  if p_action not in ('dismiss','hide','restore') then
    perform private.raise_error('invalid_action', 400);
  end if;
  select * into v_rep from public.reports where id = p_report_id;
  if not found then perform private.raise_error('report_not_found', 404); end if;
  perform private.set_target_hidden(v_rep.target_type, v_rep.target_id, p_action = 'hide');
  -- resolve every open report on the same target
  update public.reports
     set status = case when p_action = 'hide' then 'actioned' else 'dismissed' end,
         resolved_by = v_admin, resolved_at = now(), resolution_note = p_note
   where target_type = v_rep.target_type and target_id = v_rep.target_id and status = 'open';
  get diagnostics v_n = row_count;
  return v_n;
end $$;

-- Suspend (with optional end), ban, or reactivate a user.
create or replace function public.admin_set_user_status(
  p_user_id uuid, p_status text, p_until timestamptz default null, p_reason text default null)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_profile public.profiles;
begin
  if p_status not in ('active','suspended','banned') then
    perform private.raise_error('invalid_status', 400);
  end if;
  if p_user_id = v_admin then perform private.raise_error('cannot_change_own_status', 400); end if;
  update public.profiles
     set status = p_status,
         suspended_until = case when p_status = 'suspended' then p_until end,
         status_reason = p_reason
   where id = p_user_id returning * into v_profile;
  if v_profile.id is null then perform private.raise_error('user_not_found', 404); end if;
  update public.sellers set hidden = (p_status <> 'active') where id = p_user_id;
  if p_status = 'banned' then
    update public.requests set status = 'cancelled', closed_at = now() where buyer_id = p_user_id and status = 'open';
    update public.quotes set status = 'withdrawn' where seller_id = p_user_id and status in ('sent','revised','shortlisted');
  end if;
  return v_profile;
end $$;

create or replace function public.admin_set_role(p_user_id uuid, p_role text, p_grant boolean)
returns text[]
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_roles text[];
begin
  if p_role not in ('buyer','seller','admin') then perform private.raise_error('invalid_role', 400); end if;
  update public.profiles
     set roles = case when p_grant then (select array_agg(distinct r) from unnest(roles || array[p_role]) r)
                      else array_remove(roles, p_role) end
   where id = p_user_id returning roles into v_roles;
  return v_roles;
end $$;

create or replace function public.admin_set_category_policy(
  p_category_id bigint, p_policy text, p_required_licence_type text default null,
  p_disclaimer jsonb default null, p_policy_reason jsonb default null)
returns public.categories
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_cat public.categories;
begin
  if p_policy not in ('allowed','restricted','blocked') then perform private.raise_error('invalid_policy', 400); end if;
  if p_policy = 'restricted' and coalesce(p_required_licence_type, '') = '' then
    perform private.raise_error('licence_type_required', 400);
  end if;
  update public.categories
     set policy = p_policy,
         required_licence_type = case when p_policy = 'restricted' then p_required_licence_type else required_licence_type end,
         disclaimer = coalesce(p_disclaimer, disclaimer),
         policy_reason = coalesce(p_policy_reason, policy_reason)
   where id = p_category_id returning * into v_cat;
  if v_cat.id is null then perform private.raise_error('category_not_found', 404); end if;
  return v_cat;
end $$;

-- Category / field-schema editor. p_id null = create.
create or replace function public.admin_upsert_category(
  p_id bigint, p_slug text, p_names jsonb, p_parent_id bigint default null,
  p_field_schema jsonb default null, p_keywords text[] default null, p_icon text default null,
  p_sort int default null, p_active boolean default null)
returns public.categories
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_cat public.categories;
begin
  if p_id is null then
    insert into public.categories (slug, names, parent_id, field_schema, keywords, icon, sort, active)
    values (p_slug, p_names, p_parent_id, p_field_schema, coalesce(p_keywords, '{}'), p_icon,
            coalesce(p_sort, 0), coalesce(p_active, true))
    returning * into v_cat;
  else
    update public.categories set
      slug = coalesce(p_slug, slug), names = coalesce(p_names, names),
      parent_id = coalesce(p_parent_id, parent_id), field_schema = coalesce(p_field_schema, field_schema),
      keywords = coalesce(p_keywords, keywords), icon = coalesce(p_icon, icon),
      sort = coalesce(p_sort, sort), active = coalesce(p_active, active)
    where id = p_id returning * into v_cat;
  end if;
  return v_cat;
end $$;

create or replace function public.admin_upsert_keyword(
  p_keyword text, p_action text, p_category_id bigint default null, p_lang text default 'en',
  p_reason jsonb default null, p_active boolean default true)
returns public.category_keywords
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_kw public.category_keywords;
begin
  insert into public.category_keywords (keyword, lang, action, category_id, reason, active)
  values (lower(trim(p_keyword)), p_lang, p_action, p_category_id, p_reason, p_active)
  on conflict (keyword, lang, action) do update
    set category_id = excluded.category_id, reason = excluded.reason, active = excluded.active
  returning * into v_kw;
  return v_kw;
end $$;

-- Settings (monetization switch, quote cap, priority window, early partner date …).
create or replace function public.admin_set_setting(p_key text, p_value jsonb)
returns public.app_settings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_row public.app_settings;
  v_was_on boolean := private.setting_bool('monetization_enabled', false);
  v_until timestamptz;
begin
  if not exists (select 1 from public.app_settings where key = p_key) then
    perform private.raise_error('unknown_setting', 404, p_key);
  end if;
  if p_key in ('quote_cap','priority_window_minutes','free_quotes_per_month','max_requests_per_buyer_per_day',
               'max_quotes_per_seller_per_hour','auto_hide_report_threshold','match_push_cap',
               'outreach_global_daily_cap','outreach_per_domain_daily_cap')
     and (jsonb_typeof(p_value) <> 'number' or (p_value #>> '{}')::numeric < 0) then
    perform private.raise_error('invalid_setting_value', 400, p_key);
  end if;
  if p_key = 'quote_cap' and (p_value #>> '{}')::int not between 1 and 50 then
    perform private.raise_error('invalid_setting_value', 400, p_key);
  end if;
  if p_key in ('monetization_enabled','outreach_enabled') and jsonb_typeof(p_value) <> 'boolean' then
    perform private.raise_error('invalid_setting_value', 400, p_key);
  end if;
  if p_key = 'early_partner_free_until' and jsonb_typeof(p_value) not in ('string','null') then
    perform private.raise_error('invalid_setting_value', 400, p_key);
  end if;

  update public.app_settings set value = p_value where key = p_key returning * into v_row;

  -- First time monetization flips on: fix the early-partner end date
  -- (default 6 months later) and stamp it on every early partner.
  if p_key = 'monetization_enabled' and (p_value #>> '{}')::boolean and not v_was_on then
    v_until := coalesce(private.setting_ts('early_partner_free_until'), now() + interval '6 months');
    update public.app_settings set value = to_jsonb(v_until) where key = 'early_partner_free_until';
    update public.sellers set free_until = v_until where early_partner and free_until is null;
  end if;
  if p_key = 'early_partner_free_until' and jsonb_typeof(p_value) = 'string' then
    update public.sellers set free_until = (p_value #>> '{}')::timestamptz where early_partner;
  end if;
  return v_row;
end $$;

create or replace function public.admin_get_settings()
returns setof public.app_settings
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return query select * from public.app_settings order by key;
end $$;

-- Manual plan grant (support / partner deals).
create or replace function public.admin_grant_entitlement(
  p_seller_id uuid, p_tier text, p_credits int default 0, p_expires_at timestamptz default null,
  p_note text default null)
returns public.entitlements
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_ent public.entitlements;
begin
  if p_tier not in ('pro','credits') then perform private.raise_error('invalid_tier', 400); end if;
  insert into public.entitlements (seller_id, store, provider, product_id, tier, status, credits_balance,
                                   expires_at, raw)
  values (p_seller_id, 'manual', 'admin', 'admin_grant_' || p_tier, p_tier, 'active',
          greatest(coalesce(p_credits, 0), 0), p_expires_at,
          jsonb_build_object('granted_by', v_admin, 'note', p_note))
  returning * into v_ent;
  return v_ent;
end $$;

create or replace function public.admin_metrics()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return jsonb_build_object(
    'users', (select count(*) from public.profiles where status <> 'deleted'),
    'sellers', (select count(*) from public.sellers where not hidden),
    'verified_sellers', (select count(*) from public.sellers where verification_status = 'verified'),
    'pending_verifications', (select count(*) from public.seller_documents where status = 'pending'),
    'pending_licences', (select count(*) from public.seller_licences where status = 'pending'),
    'open_reports', (select count(*) from public.reports where status = 'open'),
    'open_requests', (select count(*) from public.requests where status = 'open'),
    'requests_7d', (select count(*) from public.requests where created_at > now() - interval '7 days'),
    'quotes_7d', (select count(*) from public.quotes where created_at > now() - interval '7 days'),
    'orders_7d', (select count(*) from public.orders where created_at > now() - interval '7 days'),
    'requests_with_3_quotes_pct', (select round(100.0 * count(*) filter (where quote_count >= 3) / greatest(count(*), 1), 1)
                                     from public.requests where created_at > now() - interval '30 days'),
    'median_first_quote_mins', (select percentile_cont(0.5) within group (order by m)
                                  from (select min(q.response_mins) m from public.quotes q
                                         where q.created_at > now() - interval '30 days' group by q.request_id) x));
end $$;
