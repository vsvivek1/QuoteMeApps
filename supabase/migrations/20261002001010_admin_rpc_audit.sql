-- 1010 Every admin_* RPC that changes data now writes one admin_audit_log row
-- (private.audit) in the same transaction as the change. Bodies are the 0740
-- versions plus the audit insert (and the outreach_business_address
-- validation in admin_set_setting). Signatures, results and grants are
-- unchanged (create or replace keeps the ACL).
--
-- Read-only admin RPCs (admin_get_settings, admin_metrics, admin_kpis,
-- admin_seller_coverage) change nothing and are not logged.
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
  perform private.audit('admin_review_document', 'document', v_doc.id::text,
    jsonb_build_object('approve', p_approve, 'reason', p_reason, 'verify_seller', p_verify_seller,
                       'seller_id', v_doc.seller_id, 'doc_type', v_doc.doc_type, 'status', v_doc.status));
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
  v_old text;
begin
  if p_status not in ('unverified','pending','verified','rejected') then
    perform private.raise_error('invalid_status', 400);
  end if;
  select verification_status into v_old from public.sellers where id = p_seller_id;
  update public.sellers
     set verification_status = p_status,
         verified_at = case when p_status = 'verified' then now() else null end
   where id = p_seller_id returning * into v_seller;
  if v_seller.id is null then perform private.raise_error('seller_not_found', 404); end if;
  perform private.audit('admin_set_seller_verification', 'seller', v_seller.id::text,
    jsonb_build_object('from', v_old, 'to', p_status, 'reason', p_reason));
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
  perform private.audit('admin_review_licence', 'licence', v_lic.id::text,
    jsonb_build_object('approve', p_approve, 'reason', p_reason, 'seller_id', v_lic.seller_id,
                       'licence_type', v_lic.licence_type));
  return v_lic;
end $$;

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
  update public.reports
     set status = case when p_action = 'hide' then 'actioned' else 'dismissed' end,
         resolved_by = v_admin, resolved_at = now(), resolution_note = p_note
   where target_type = v_rep.target_type and target_id = v_rep.target_id and status = 'open';
  get diagnostics v_n = row_count;
  perform private.audit('admin_resolve_report', 'report', v_rep.id::text,
    jsonb_build_object('action', p_action, 'note', p_note, 'content_type', v_rep.target_type,
                       'content_id', v_rep.target_id, 'reports_resolved', v_n));
  return v_n;
end $$;

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
  v_old text;
begin
  if p_status not in ('active','suspended','banned') then
    perform private.raise_error('invalid_status', 400);
  end if;
  if p_user_id = v_admin then perform private.raise_error('cannot_change_own_status', 400); end if;
  select status into v_old from public.profiles where id = p_user_id;
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
  perform private.audit('admin_set_user_status', 'user', v_profile.id::text,
    jsonb_build_object('from', v_old, 'to', p_status, 'until', p_until, 'reason', p_reason));
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
  v_old text[];
  v_roles text[];
begin
  if p_role not in ('buyer','seller','admin') then perform private.raise_error('invalid_role', 400); end if;
  select roles into v_old from public.profiles where id = p_user_id;
  update public.profiles
     set roles = case when p_grant then (select array_agg(distinct r) from unnest(roles || array[p_role]) r)
                      else array_remove(roles, p_role) end
   where id = p_user_id returning roles into v_roles;
  if v_roles is not null then
    perform private.audit('admin_set_role', 'user', p_user_id::text,
      jsonb_build_object('role', p_role, 'grant', p_grant, 'from', to_jsonb(v_old), 'to', to_jsonb(v_roles)));
  end if;
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
  v_old text;
begin
  if p_policy not in ('allowed','restricted','blocked') then perform private.raise_error('invalid_policy', 400); end if;
  if p_policy = 'restricted' and coalesce(p_required_licence_type, '') = '' then
    perform private.raise_error('licence_type_required', 400);
  end if;
  select policy into v_old from public.categories where id = p_category_id;
  update public.categories
     set policy = p_policy,
         required_licence_type = case when p_policy = 'restricted' then p_required_licence_type else required_licence_type end,
         disclaimer = coalesce(p_disclaimer, disclaimer),
         policy_reason = coalesce(p_policy_reason, policy_reason)
   where id = p_category_id returning * into v_cat;
  if v_cat.id is null then perform private.raise_error('category_not_found', 404); end if;
  perform private.audit('admin_set_category_policy', 'category', v_cat.id::text,
    jsonb_build_object('slug', v_cat.slug, 'from', v_old, 'to', p_policy,
                       'required_licence_type', v_cat.required_licence_type));
  return v_cat;
end $$;

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
  if v_cat.id is not null then
    perform private.audit('admin_upsert_category', 'category', v_cat.id::text,
      jsonb_strip_nulls(jsonb_build_object('created', p_id is null, 'slug', v_cat.slug, 'names', p_names,
                                           'parent_id', p_parent_id, 'field_schema_changed', p_field_schema is not null,
                                           'keywords', to_jsonb(p_keywords), 'active', p_active, 'sort', p_sort)));
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
  perform private.audit('admin_upsert_keyword', 'keyword', v_kw.keyword,
    jsonb_build_object('action', p_action, 'lang', p_lang, 'category_id', p_category_id, 'active', p_active));
  return v_kw;
end $$;

-- Settings (monetization switch, quote cap, priority window, early partner date,
-- outreach flags and the outreach business address).
create or replace function public.admin_set_setting(p_key text, p_value jsonb)
returns public.app_settings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_row public.app_settings;
  v_old jsonb;
  v_was_on boolean := private.setting_bool('monetization_enabled', false);
  v_until timestamptz;
begin
  select value into v_old from public.app_settings where key = p_key;
  if not found then
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
  -- CAN-SPAM postal address used in every outreach email. A string (an empty
  -- or {{...}} placeholder value is accepted but keeps every send blocked).
  if p_key = 'outreach_business_address'
     and (jsonb_typeof(p_value) <> 'string' or length(p_value #>> '{}') > 300) then
    perform private.raise_error('invalid_setting_value', 400, p_key);
  end if;
  if p_key = 'kpi_product_prices_minor' and jsonb_typeof(p_value) <> 'object' then
    perform private.raise_error('invalid_setting_value', 400, p_key);
  end if;

  update public.app_settings set value = p_value where key = p_key returning * into v_row;

  if p_key = 'monetization_enabled' and (p_value #>> '{}')::boolean and not v_was_on then
    v_until := coalesce(private.setting_ts('early_partner_free_until'), now() + interval '6 months');
    update public.app_settings set value = to_jsonb(v_until) where key = 'early_partner_free_until';
    update public.sellers set free_until = v_until where early_partner and free_until is null;
  end if;
  if p_key = 'early_partner_free_until' and jsonb_typeof(p_value) = 'string' then
    update public.sellers set free_until = (p_value #>> '{}')::timestamptz where early_partner;
  end if;
  perform private.audit('admin_set_setting', 'setting', p_key,
    jsonb_build_object('from', v_old, 'to', p_value));
  return v_row;
end $$;

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
  perform private.audit('admin_grant_entitlement', 'entitlement', v_ent.id::text,
    jsonb_build_object('seller_id', p_seller_id, 'tier', p_tier, 'credits', p_credits,
                       'expires_at', p_expires_at, 'note', p_note));
  return v_ent;
end $$;
