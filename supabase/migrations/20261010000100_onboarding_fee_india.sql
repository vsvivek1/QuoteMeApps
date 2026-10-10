-- Seller onboarding fee for both countries, paid through Google Play Billing in
-- the Android apps (Play policy) and Stripe Checkout on the USA web dashboard.
-- The fee now has its own switch: onboarding_fee_enabled alone decides whether
-- it is due, independent of monetization_enabled, so India can charge the fee
-- while quoting otherwise stays free. Early partners never pay it.

update public.app_settings
   set description = 'One-time seller onboarding fee (Play Billing in the apps, Stripe on the USA web). Independent of monetization_enabled; early partners are exempt'
 where key = 'onboarding_fee_enabled';

-- India price: Rs 2,499 (about $29). The Play Console product price is what the
-- buyer is charged; this value only labels the button when the store has no price.
update public.app_settings set value = '249900'
 where key = 'onboarding_fee_minor' and value = '2900'
   and private.setting_text('country', 'IN') = 'IN';

create or replace function private.onboarding_fee_due(p_seller_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.setting_bool('onboarding_fee_enabled', false)
     and not exists (select 1 from public.sellers s
                      where s.id = p_seller_id and s.early_partner
                        and (s.free_until is null or s.free_until > now()))
     and not exists (select 1 from public.entitlements e
                      where e.seller_id = p_seller_id and e.tier = 'onboarding' and e.status = 'active')
$$;

-- Same as before, but the fee is checked before the launch-free shortcut.
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
  if private.onboarding_fee_due(p_seller_id) then
    perform private.raise_error('onboarding_fee_required', 402, 'Pay the one-time onboarding fee to start quoting');
  end if;
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
