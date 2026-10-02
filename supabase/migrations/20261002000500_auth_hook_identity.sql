-- 0500 Auth integration: profile creation, custom access token hook (roles
-- claim), identity helper functions used by RLS policies and RPCs.
set search_path = public, extensions;

-- Create a profile for each new auth user ---------------------------------------
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, name, phone, email, photo_url, language)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    nullif(new.phone, ''),
    nullif(new.email, ''),
    coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture'),
    coalesce(new.raw_user_meta_data->>'language', 'en'))
  on conflict (id) do nothing;
  return new;
end $$;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- Keep phone/email in sync when they change in auth (e.g. phone linked later).
create or replace function private.handle_user_contact_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles
     set phone = coalesce(nullif(new.phone, ''), phone),
         email = coalesce(nullif(new.email, ''), email)
   where id = new.id and status <> 'deleted';
  return new;
end $$;

create or replace trigger on_auth_user_contact_changed
  after update of phone, email on auth.users
  for each row
  when (old.phone is distinct from new.phone or old.email is distinct from new.email)
  execute function private.handle_user_contact_change();

-- Custom Access Token Hook ----------------------------------------------------------
-- Adds: roles (text[]), active_mode, account_status, seller_verified.
-- Configure in config.toml [auth.hook.custom_access_token] and in the dashboard
-- (Auth > Hooks) for hosted projects.
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  v_claims jsonb := coalesce(event->'claims', '{}'::jsonb);
  v_profile record;
  v_verified boolean;
begin
  select p.roles, p.active_mode, p.status
    into v_profile
    from public.profiles p
   where p.id = (event->>'user_id')::uuid;

  if found then
    select (s.verification_status = 'verified') into v_verified
      from public.sellers s where s.id = (event->>'user_id')::uuid;
    v_claims := v_claims
      || jsonb_build_object(
        'roles', to_jsonb(case when v_profile.status in ('banned','deleted')
                               then array[]::text[] else v_profile.roles end),
        'active_mode', v_profile.active_mode,
        'account_status', v_profile.status,
        'seller_verified', coalesce(v_verified, false));
  else
    v_claims := v_claims || jsonb_build_object(
      'roles', jsonb_build_array('buyer'), 'active_mode', 'buyer',
      'account_status', 'active', 'seller_verified', false);
  end if;

  return jsonb_set(event, '{claims}', v_claims);
end $$;

grant usage on schema public to supabase_auth_admin;
grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
revoke execute on function public.custom_access_token_hook(jsonb) from authenticated, anon, public;
grant select on public.profiles, public.sellers to supabase_auth_admin;

create policy "auth admin reads profiles for token hook" on public.profiles
  as permissive for select to supabase_auth_admin using (true);
create policy "auth admin reads sellers for token hook" on public.sellers
  as permissive for select to supabase_auth_admin using (true);

-- Identity helpers ----------------------------------------------------------------------
-- Admin = roles claim in the JWT contains 'admin' AND the profile still has it
-- (so a revoked admin loses access immediately, not at token expiry).
create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((auth.jwt() -> 'roles') ? 'admin', false)
     and exists (select 1 from public.profiles
                  where id = auth.uid() and 'admin' = any(roles) and status = 'active')
$$;

-- Active (not suspended / banned / deleted) user check.
create or replace function private.is_active_user(p_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
     where id = p_uid
       and (status = 'active'
            or (status = 'suspended' and suspended_until is not null and suspended_until < now())))
$$;

create or replace function private.is_blocked_between(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.blocks
                  where (blocker_id = p_a and blocked_id = p_b)
                     or (blocker_id = p_b and blocked_id = p_a))
$$;

-- Requires an authenticated, active caller; returns auth.uid().
create or replace function private.require_user()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then
    perform private.raise_error('not_authenticated', 401);
  end if;
  if not private.is_active_user(v_uid) then
    perform private.raise_error('account_not_active', 403);
  end if;
  return v_uid;
end $$;

create or replace function private.require_admin()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null or not private.is_admin() then
    perform private.raise_error('admin_only', 403);
  end if;
  return v_uid;
end $$;

-- Helper used by RLS: is the caller a party to this chat?
create or replace function private.is_chat_member(p_chat_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.chats c
                  where c.id = p_chat_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid()))
$$;

create or replace function private.is_request_buyer(p_request_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.requests r where r.id = p_request_id and r.buyer_id = auth.uid())
$$;

-- The seller whose quote was accepted on this request (after acceptance only).
create or replace function private.is_accepted_seller(p_request_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.requests r
      join public.quotes q on q.id = r.accepted_quote_id
     where r.id = p_request_id and q.status = 'accepted' and q.seller_id = auth.uid())
$$;

create or replace function private.can_view_quote(p_quote_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.quotes q join public.requests r on r.id = q.request_id
     where q.id = p_quote_id and (q.seller_id = auth.uid() or r.buyer_id = auth.uid()))
$$;

create or replace function private.has_order_with_seller(p_seller_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.orders o
                  where o.seller_id = p_seller_id and o.buyer_id = auth.uid()
                    and o.status <> 'cancelled')
$$;

create or replace function private.is_order_party(p_order_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.orders o
                  where o.id = p_order_id and (o.buyer_id = auth.uid() or o.seller_id = auth.uid()))
$$;

revoke all on all functions in schema private from public;
grant execute on all functions in schema private to authenticated, service_role;
grant execute on function private.is_admin(), private.is_chat_member(uuid),
  private.is_request_buyer(uuid) to anon;
