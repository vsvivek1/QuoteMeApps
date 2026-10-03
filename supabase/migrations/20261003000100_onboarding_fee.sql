-- One-time seller onboarding fee (I Want USA, paid by Stripe Checkout).
-- Off by default and only enforced while monetization_enabled is also on, in
-- a project whose country is US. Founding (early) partners never pay it.
-- The amount lives in app_settings (USD cents) and create-checkout charges
-- exactly that, so the price is changed in one place by an admin.

alter table public.entitlements drop constraint if exists entitlements_tier_check;
alter table public.entitlements add constraint entitlements_tier_check
  check (tier in ('pro','credits','onboarding'));

insert into public.app_settings (key, value, is_public, description) values
  ('onboarding_fee_enabled', 'false', true,
   'One-time seller onboarding fee (US only). Enforced only while monetization_enabled is on; early partners are exempt'),
  ('onboarding_fee_minor', '2900', true, 'Onboarding fee in minor units of the project currency (2900 = $29.00)')
on conflict (key) do nothing;

create or replace function private.onboarding_fee_due(p_seller_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.setting_bool('monetization_enabled', false)
     and private.setting_bool('onboarding_fee_enabled', false)
     and private.setting_text('country', 'IN') = 'US'
     and not exists (select 1 from public.sellers s
                      where s.id = p_seller_id and s.early_partner
                        and (s.free_until is null or s.free_until > now()))
     and not exists (select 1 from public.entitlements e
                      where e.seller_id = p_seller_id and e.tier = 'onboarding' and e.status = 'active')
$$;

-- Same as before plus the onboarding check right after the early-partner exemption.
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
  if private.onboarding_fee_due(p_seller_id) then
    perform private.raise_error('onboarding_fee_required', 402, 'Pay the one-time onboarding fee to start quoting');
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

-- Whether a seller still owes the fee, and how much. Service role (create-checkout)
-- passes the seller id; the app calls get_my_onboarding_fee() for itself.
create or replace function public.onboarding_fee_status(p_seller_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'due', private.onboarding_fee_due(p_seller_id),
    'paid', exists (select 1 from public.entitlements e
                     where e.seller_id = p_seller_id and e.tier = 'onboarding' and e.status = 'active'),
    'amount_minor', private.setting_int('onboarding_fee_minor', 2900),
    'currency', private.setting_text('currency', 'USD'))
  where exists (select 1 from public.sellers where id = p_seller_id)
$$;

create or replace function public.get_my_onboarding_fee()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$ select public.onboarding_fee_status(auth.uid()) $$;

revoke all on function public.onboarding_fee_status(uuid) from public, anon, authenticated;
grant execute on function public.onboarding_fee_status(uuid) to service_role;
revoke all on function public.get_my_onboarding_fee() from public, anon;
grant execute on function public.get_my_onboarding_fee() to authenticated, service_role;
