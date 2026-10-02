-- 0700 Shared RPC helpers, profile, mode switch, seller onboarding,
-- verification, entitlements.
set search_path = public, extensions;

-- Notifications helper ------------------------------------------------------------------------
-- Writes an inbox row. push_status 'none' when the user disabled push.
create or replace function private.notify(
  p_user_id uuid, p_type text, p_payload jsonb,
  p_digest_key text default null, p_push_after timestamptz default now())
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_push boolean;
begin
  select coalesce((notification_prefs->>'push')::boolean, true) and status = 'active'
    into v_push from public.profiles where id = p_user_id;
  insert into public.notifications (user_id, type, payload, digest_key, push_after, push_status)
  values (p_user_id, p_type, coalesce(p_payload, '{}'::jsonb), p_digest_key,
          coalesce(p_push_after, now()),
          case when coalesce(v_push, false) then 'queued' else 'none' end)
  returning id into v_id;
  return v_id;
end $$;

-- Category helpers ------------------------------------------------------------------------------
-- Effective policy = most restrictive of the category and its parent.
create or replace function private.category_policy(p_category_id bigint,
  out policy text, out required_licence_type text, out parent_id bigint,
  out active boolean, out is_leaf boolean, out disclaimer jsonb, out policy_reason jsonb)
language sql
stable
security definer
set search_path = ''
as $$
  select
    case
      when 'blocked' in (c.policy, coalesce(p.policy, 'allowed')) then 'blocked'
      when 'restricted' in (c.policy, coalesce(p.policy, 'allowed')) then 'restricted'
      else 'allowed' end,
    coalesce(c.required_licence_type, p.required_licence_type),
    c.parent_id,
    c.active and coalesce(p.active, true),
    not exists (select 1 from public.categories ch where ch.parent_id = c.id and ch.active),
    coalesce(c.disclaimer, p.disclaimer),
    coalesce(c.policy_reason, p.policy_reason)
  from public.categories c
  left join public.categories p on p.id = c.parent_id
  where c.id = p_category_id
$$;

-- Does the seller hold a valid licence for this (restricted) category?
create or replace function private.seller_has_licence(p_seller_id uuid, p_category_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.seller_licences l
      join public.categories c on c.id = p_category_id
      left join public.categories p on p.id = c.parent_id
     where l.seller_id = p_seller_id
       and l.status = 'approved'
       and (l.expires_at is null or l.expires_at > now())
       and l.licence_type = coalesce(c.required_licence_type, p.required_licence_type)
       and (cardinality(l.category_ids) = 0
            or c.id = any(l.category_ids)
            or c.parent_id = any(l.category_ids)))
$$;

-- All leaf category ids a seller may receive leads for: the seller's
-- categories (a parent selection covers its children), minus blocked ones,
-- minus restricted ones without a valid licence.
create or replace function private.seller_category_ids(p_seller_id uuid)
returns bigint[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(distinct c.id), '{}')
    from public.categories c
    left join public.categories p on p.id = c.parent_id
   where c.active and coalesce(p.active, true)
     and (c.id in (select category_id from public.seller_categories where seller_id = p_seller_id)
          or c.parent_id in (select category_id from public.seller_categories where seller_id = p_seller_id))
     and c.policy <> 'blocked' and coalesce(p.policy, 'allowed') <> 'blocked'
     and (('restricted' not in (c.policy, coalesce(p.policy, 'allowed')))
          or private.seller_has_licence(p_seller_id, c.id))
$$;

-- Verified sellers and active subscribers get the priority window.
create or replace function private.seller_has_priority(p_seller_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.sellers where id = p_seller_id and verification_status = 'verified')
      or exists (select 1 from public.entitlements e
                  where e.seller_id = p_seller_id and e.tier = 'pro'
                    and e.status in ('active','grace')
                    and (e.expires_at is null or e.expires_at > now()))
$$;

-- Postal code normalization per country (IN: 6 digits, US: 5 digits).
create or replace function public.normalize_postal_code(p_code text)
returns text
language plpgsql
stable
set search_path = ''
as $$
declare
  v_country text := private.setting_text('country', 'IN');
  v_code text := regexp_replace(coalesce(p_code, ''), '\s', '', 'g');
begin
  if v_code = '' then return null; end if;
  if v_country = 'US' then
    v_code := left(v_code, 5);
    if v_code !~ '^[0-9]{5}$' then return null; end if;
  else
    if v_code !~ '^[1-9][0-9]{5}$' then return null; end if;
  end if;
  return v_code;
end $$;

-- GSTIN: 15 chars, state code, PAN, entity, 'Z', check digit (mod-36 checksum).
create or replace function public.is_valid_gstin(p_gstin text)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v text := upper(coalesce(p_gstin, ''));
  chars constant text := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  v_sum int := 0;
  v_prod int;
  i int;
begin
  if v !~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$' then
    return false;
  end if;
  for i in 1..14 loop
    v_prod := (strpos(chars, substr(v, i, 1)) - 1) * (case when i % 2 = 1 then 1 else 2 end);
    v_sum := v_sum + (v_prod / 36) + (v_prod % 36);
  end loop;
  return substr(chars, ((36 - (v_sum % 36)) % 36) + 1, 1) = substr(v, 15, 1);
end $$;

create or replace function public.is_valid_ein(p_ein text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(p_ein, '') ~ '^[0-9]{2}-?[0-9]{7}$'
     and left(regexp_replace(p_ein, '-', ''), 2) not in ('00','07','08','09','17','18','19','28','29','49','69','70','78','79','89','96','97')
$$;

-- Settings for clients ------------------------------------------------------------------------------
create or replace function public.get_app_settings()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_object_agg(key, value), '{}'::jsonb)
    from public.app_settings where is_public
$$;

-- Profiles ---------------------------------------------------------------------------------------------
create or replace function public.set_active_mode(p_mode text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare v_uid uuid := private.require_user();
begin
  if p_mode not in ('buyer','seller') then
    perform private.raise_error('invalid_mode', 400);
  end if;
  if p_mode = 'seller' and not exists (select 1 from public.sellers where id = v_uid) then
    perform private.raise_error('not_a_seller', 403, 'Call become_seller first');
  end if;
  update public.profiles set active_mode = p_mode where id = v_uid;
  return p_mode; -- client should refresh the session to get the new claim
end $$;

-- Public display info for other users (no phone/email). Name is shortened
-- ("Priya S.") for buyers; sellers show their business name.
create or replace function public.get_profiles_public(p_ids uuid[])
returns table (id uuid, display_name text, photo_url text, is_seller boolean,
               business_name text, seller_verified boolean, rating_avg numeric, rating_count int)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id,
         case when p.status = 'deleted' then 'Deleted user'
              else nullif(trim(split_part(coalesce(p.name, ''), ' ', 1) ||
                   coalesce(' ' || nullif(left(split_part(coalesce(p.name, ''), ' ', 2), 1), '') || '.', '')), '')
         end,
         case when p.status = 'deleted' then null else p.photo_url end,
         s.id is not null,
         s.business_name,
         coalesce(s.verification_status = 'verified', false),
         s.rating_avg, s.rating_count
    from public.profiles p
    left join public.sellers s on s.id = p.id and not s.hidden
   where p.id = any(p_ids) and auth.uid() is not null
   limit 200
$$;

create or replace function public.register_device_token(
  p_token text, p_platform text, p_app_version text default null, p_locale text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_uid uuid := private.require_user();
begin
  insert into public.device_tokens (user_id, fcm_token, platform, app_version, locale)
  values (v_uid, p_token, p_platform, p_app_version, p_locale)
  on conflict (fcm_token) do update
    set user_id = excluded.user_id, platform = excluded.platform,
        app_version = excluded.app_version, locale = excluded.locale, updated_at = now();
end $$;

create or replace function public.block_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_uid uuid := private.require_user();
begin
  if p_user_id = v_uid then perform private.raise_error('cannot_block_self', 400); end if;
  insert into public.blocks (blocker_id, blocked_id) values (v_uid, p_user_id)
  on conflict do nothing;
end $$;

create or replace function public.unblock_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_uid uuid := private.require_user();
begin
  delete from public.blocks where blocker_id = v_uid and blocked_id = p_user_id;
end $$;

-- Seller onboarding -------------------------------------------------------------------------------------
-- Creates or updates the caller's seller profile. NULL arguments keep the
-- current value. p_category_ids replaces the category set when given.
create or replace function public.upsert_seller_profile(
  p_business_name text default null,
  p_description text default null,
  p_years_in_business int default null,
  p_brands text[] default null,
  p_area_type text default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_radius_km numeric default null,
  p_service_codes text[] default null,
  p_category_ids bigint[] default null,
  p_logo_url text default null,
  p_photos text[] default null,
  p_city text default null,
  p_state text default null,
  p_timezone text default null,
  p_notify_mode text default null,
  p_quiet_hours_start time default null,
  p_quiet_hours_end time default null,
  p_business_phone text default null,
  p_business_email text default null,
  p_website text default null,
  p_address_line text default null,
  p_postal_code text default null,
  p_signup_token text default null)
returns public.sellers
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_uid uuid := private.require_user();
  v_seller public.sellers;
  v_is_new boolean;
  v_center geography;
  v_pc public.postal_codes;
  v_codes text[];
  v_bad bigint;
  v_profile public.profiles;
begin
  select * into v_seller from public.sellers where id = v_uid for update;
  v_is_new := not found;
  select * into v_profile from public.profiles where id = v_uid;

  if v_is_new and coalesce(trim(p_business_name), '') = '' then
    perform private.raise_error('business_name_required', 400);
  end if;
  if p_area_type is not null and p_area_type not in ('radius','codes','nationwide') then
    perform private.raise_error('invalid_area_type', 400);
  end if;

  -- shop location: explicit pin, else postal code centroid
  if p_lat is not null and p_lng is not null then
    v_center := st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography;
  end if;
  if p_postal_code is not null then
    select * into v_pc from public.postal_codes where code = public.normalize_postal_code(p_postal_code);
    if v_center is null and v_pc.code is not null then
      v_center := v_pc.centroid;
    end if;
  end if;

  if p_service_codes is not null then
    select coalesce(array_agg(distinct n) filter (where n is not null), '{}')
      into v_codes
      from (select public.normalize_postal_code(c) n from unnest(p_service_codes) c) x;
    if cardinality(v_codes) > 500 then
      perform private.raise_error('too_many_service_codes', 400);
    end if;
  end if;

  if v_is_new then
    insert into public.sellers (
      id, business_name, description, years_in_business, brands, area_type, center, radius_km,
      service_codes, logo_url, photos, city, state, timezone, notify_mode,
      quiet_hours_start, quiet_hours_end, early_partner, free_until, slug)
    values (
      v_uid, trim(p_business_name), p_description, p_years_in_business, coalesce(p_brands, '{}'),
      coalesce(p_area_type, case when v_center is not null and p_radius_km is not null then 'radius' else 'nationwide' end),
      v_center, p_radius_km, coalesce(v_codes, '{}'), p_logo_url, coalesce(p_photos, '{}'),
      coalesce(p_city, v_pc.city), coalesce(p_state, v_pc.state), p_timezone,
      coalesce(p_notify_mode, 'instant'), coalesce(p_quiet_hours_start, '22:00'),
      coalesce(p_quiet_hours_end, '07:00'),
      not private.setting_bool('monetization_enabled', false),
      case when not private.setting_bool('monetization_enabled', false)
           then private.setting_ts('early_partner_free_until') end,
      lower(regexp_replace(trim(p_business_name), '[^a-zA-Z0-9]+', '-', 'g')) || '-' || left(v_uid::text, 6))
    returning * into v_seller;

    update public.profiles
       set roles = (select array_agg(distinct r) from unnest(roles || array['seller']) r),
           active_mode = 'seller'
     where id = v_uid;

    insert into public.seller_contacts (seller_id, business_phone)
    values (v_uid, coalesce(p_business_phone, v_profile.phone))
    on conflict do nothing;

    -- Attribute outreach lead (Section 21.5) by signup token, phone or email.
    if to_regclass('public.outreach_leads') is not null then
      execute $q$
        update public.outreach_leads
           set seller_id = $1, stage = 'live_seller', sequence_status =
               case when sequence_status = 'active' then 'stopped' else sequence_status end
         where seller_id is null
           and ((signup_token is not null and signup_token = $2)
                or (phone is not null and phone = $3)
                or (email is not null and lower(email) = lower($4)))$q$
      using v_uid, p_signup_token, coalesce(p_business_phone, v_profile.phone),
            coalesce(p_business_email, v_profile.email);
    end if;
  else
    update public.sellers set
      business_name = coalesce(nullif(trim(p_business_name), ''), business_name),
      description = coalesce(p_description, description),
      years_in_business = coalesce(p_years_in_business, years_in_business),
      brands = coalesce(p_brands, brands),
      area_type = coalesce(p_area_type, area_type),
      center = coalesce(v_center, center),
      radius_km = coalesce(p_radius_km, radius_km),
      service_codes = coalesce(v_codes, service_codes),
      logo_url = coalesce(p_logo_url, logo_url),
      photos = coalesce(p_photos, photos),
      city = coalesce(p_city, v_pc.city, city),
      state = coalesce(p_state, v_pc.state, state),
      timezone = coalesce(p_timezone, timezone),
      notify_mode = coalesce(p_notify_mode, notify_mode),
      quiet_hours_start = coalesce(p_quiet_hours_start, quiet_hours_start),
      quiet_hours_end = coalesce(p_quiet_hours_end, quiet_hours_end)
    where id = v_uid
    returning * into v_seller;
  end if;

  if p_business_phone is not null or p_business_email is not null or p_website is not null
     or p_address_line is not null or p_postal_code is not null then
    insert into public.seller_contacts (seller_id, business_phone, business_email, website, address_line, postal_code)
    values (v_uid, p_business_phone, p_business_email, p_website, p_address_line, public.normalize_postal_code(p_postal_code))
    on conflict (seller_id) do update set
      business_phone = coalesce(excluded.business_phone, seller_contacts.business_phone),
      business_email = coalesce(excluded.business_email, seller_contacts.business_email),
      website = coalesce(excluded.website, seller_contacts.website),
      address_line = coalesce(excluded.address_line, seller_contacts.address_line),
      postal_code = coalesce(excluded.postal_code, seller_contacts.postal_code);
  end if;

  if p_category_ids is not null then
    select x into v_bad from unnest(p_category_ids) x
     where not exists (select 1 from public.categories c where c.id = x and c.active)
        or (select policy from private.category_policy(x)) = 'blocked'
     limit 1;
    if v_bad is not null then
      perform private.raise_error('invalid_or_blocked_category', 422, v_bad::text);
    end if;
    if cardinality(p_category_ids) > 30 then
      perform private.raise_error('too_many_categories', 400);
    end if;
    delete from public.seller_categories where seller_id = v_uid and category_id <> all(p_category_ids);
    insert into public.seller_categories (seller_id, category_id)
    select v_uid, x from unnest(p_category_ids) x on conflict do nothing;
  end if;

  return v_seller;
exception
  when check_violation then
    perform private.raise_error('invalid_seller_profile', 400, sqlerrm);
    return null;
end $$;

-- Minimal "I'm a business" step; the onboarding wizard then calls
-- upsert_seller_profile with categories and service area.
create or replace function public.become_seller(p_business_name text, p_signup_token text default null)
returns public.sellers
language sql
security definer
set search_path = public, extensions, pg_temp
as $$
  select * from public.upsert_seller_profile(p_business_name => p_business_name, p_signup_token => p_signup_token)
$$;

create or replace function public.get_my_seller_profile()
returns jsonb
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select to_jsonb(s) - 'center'
         || jsonb_build_object(
              'center_lat', st_y(s.center::geometry), 'center_lng', st_x(s.center::geometry),
              'contacts', (select to_jsonb(c) from public.seller_contacts c where c.seller_id = s.id),
              'category_ids', (select coalesce(jsonb_agg(category_id), '[]') from public.seller_categories where seller_id = s.id),
              'lead_category_ids', to_jsonb(private.seller_category_ids(s.id)))
    from public.sellers s where s.id = auth.uid()
$$;

-- Verification ------------------------------------------------------------------------------------------
create or replace function public.submit_verification(
  p_doc_type text, p_doc_number text default null, p_file_path text default null)
returns public.seller_documents
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_doc public.seller_documents;
  v_number text := upper(regexp_replace(coalesce(p_doc_number, ''), '\s', '', 'g'));
begin
  if not exists (select 1 from public.sellers where id = v_uid) then
    perform private.raise_error('not_a_seller', 403);
  end if;
  if p_doc_type = 'gstin' and not public.is_valid_gstin(v_number) then
    perform private.raise_error('invalid_gstin', 422);
  end if;
  if p_doc_type = 'ein' and not public.is_valid_ein(v_number) then
    perform private.raise_error('invalid_ein', 422);
  end if;
  if p_doc_type = 'udyam' and v_number !~ '^UDYAM-[A-Z]{2}-[0-9]{2}-[0-9]{7}$' then
    perform private.raise_error('invalid_udyam', 422);
  end if;
  if p_file_path is not null and p_file_path not like v_uid::text || '/%' then
    perform private.raise_error('invalid_file_path', 400, 'verification-docs path must start with {seller_id}/');
  end if;
  insert into public.seller_documents (seller_id, doc_type, doc_number, file_path)
  values (v_uid, p_doc_type, nullif(v_number, ''), p_file_path)
  returning * into v_doc;
  update public.sellers set verification_status = 'pending'
   where id = v_uid and verification_status in ('unverified','rejected');
  return v_doc;
end $$;

create or replace function public.submit_licence(
  p_licence_type text, p_number text, p_issuer text default null, p_state text default null,
  p_category_ids bigint[] default '{}', p_expires_at timestamptz default null, p_file_path text default null)
returns public.seller_licences
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_lic public.seller_licences;
begin
  if not exists (select 1 from public.sellers where id = v_uid) then
    perform private.raise_error('not_a_seller', 403);
  end if;
  if coalesce(trim(p_number), '') = '' or coalesce(trim(p_licence_type), '') = '' then
    perform private.raise_error('licence_details_required', 400);
  end if;
  if p_expires_at is not null and p_expires_at <= now() then
    perform private.raise_error('licence_expired', 422);
  end if;
  if p_file_path is not null and p_file_path not like v_uid::text || '/%' then
    perform private.raise_error('invalid_file_path', 400);
  end if;
  insert into public.seller_licences (seller_id, licence_type, number, issuer, state, category_ids, expires_at, file_path)
  values (v_uid, trim(p_licence_type), trim(p_number), p_issuer, p_state, coalesce(p_category_ids, '{}'), p_expires_at, p_file_path)
  returning * into v_lic;
  return v_lic;
end $$;

-- Entitlements (Section 7) ----------------------------------------------------------------------------------
-- Decides how a new quote is paid for; with p_consume it also spends a credit.
-- Raises quota_exhausted (402) when nothing covers the quote.
create or replace function private.quote_entitlement(p_seller_id uuid, p_consume boolean)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_seller public.sellers;
  v_used int;
  v_ent_id uuid;
begin
  if not private.setting_bool('monetization_enabled', false) then
    return 'launch_free';
  end if;
  select * into v_seller from public.sellers where id = p_seller_id;
  if v_seller.early_partner and (v_seller.free_until is null or v_seller.free_until > now()) then
    return 'early_partner';
  end if;
  if exists (select 1 from public.entitlements e
              where e.seller_id = p_seller_id and e.tier = 'pro' and e.status in ('active','grace')
                and (e.expires_at is null or e.expires_at > now())) then
    return 'subscription';
  end if;
  select count(*) into v_used from public.quotes q
   where q.seller_id = p_seller_id and q.billing_source = 'free_tier'
     and q.created_at >= date_trunc('month', now());
  if v_used < private.setting_int('free_quotes_per_month', 10) then
    return 'free_tier';
  end if;
  select e.id into v_ent_id from public.entitlements e
   where e.seller_id = p_seller_id and e.tier = 'credits' and e.status = 'active'
     and e.credits_balance > 0 and (e.expires_at is null or e.expires_at > now())
   order by e.expires_at nulls last, e.created_at
   limit 1 for update;
  if v_ent_id is not null then
    if p_consume then
      update public.entitlements set credits_balance = credits_balance - 1 where id = v_ent_id;
    end if;
    return 'credit';
  end if;
  perform private.raise_error('quota_exhausted', 402, 'No free quotes, subscription or credits left');
  return null;
end $$;

create or replace function public.get_my_entitlement()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_seller public.sellers;
  v_sub public.entitlements;
  v_credits int;
  v_used int;
  v_next text;
begin
  select * into v_seller from public.sellers where id = v_uid;
  if not found then
    return jsonb_build_object('is_seller', false);
  end if;
  select * into v_sub from public.entitlements e
   where e.seller_id = v_uid and e.tier = 'pro' and e.status in ('active','grace','on_hold','paused')
   order by e.updated_at desc limit 1;
  select coalesce(sum(credits_balance), 0) into v_credits from public.entitlements
   where seller_id = v_uid and tier = 'credits' and status = 'active'
     and (expires_at is null or expires_at > now());
  select count(*) into v_used from public.quotes q
   where q.seller_id = v_uid and q.billing_source = 'free_tier' and q.created_at >= date_trunc('month', now());
  begin
    v_next := private.quote_entitlement(v_uid, false);
  exception when others then
    v_next := null;
  end;
  return jsonb_build_object(
    'is_seller', true,
    'monetization_enabled', private.setting_bool('monetization_enabled', false),
    'early_partner', v_seller.early_partner,
    'free_until', coalesce(v_seller.free_until, private.setting_ts('early_partner_free_until')),
    'subscription', case when v_sub.id is null then null else jsonb_build_object(
        'store', v_sub.store, 'product_id', v_sub.product_id, 'status', v_sub.status,
        'renews_at', v_sub.renews_at, 'expires_at', v_sub.expires_at) end,
    'payment_issue', coalesce(v_sub.status in ('grace','on_hold'), false),
    'free_quotes_per_month', private.setting_int('free_quotes_per_month', 10),
    'free_quotes_used', v_used,
    'credits_balance', v_credits,
    'has_priority', private.seller_has_priority(v_uid),
    'can_quote', v_next is not null,
    'next_quote_billing_source', v_next);
end $$;
