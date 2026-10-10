-- One-time seller onboarding fee: off by default, its own switch (works with
-- monetization off, in both countries), early partners exempt, a paid
-- entitlement clears it.
begin;
\ir _helpers.psql
select plan(12);

select tests.make_seller('of-seller') as seller \gset
select tests.make_seller('of-partner') as partner \gset
update public.sellers set early_partner = true, free_until = null where id = :'partner';
update public.app_settings set value = '"US"' where key = 'country';
update public.app_settings set value = '"USD"' where key = 'currency';
update public.app_settings set value = 'true' where key = 'monetization_enabled';
update public.app_settings set value = '2900' where key = 'onboarding_fee_minor';

select is(private.onboarding_fee_due(:'seller'), false, 'fee is off by default');
select is(private.quote_entitlement(:'seller', false), 'free_tier', 'quoting works while the fee is off');

update public.app_settings set value = 'true' where key = 'onboarding_fee_enabled';
select is(private.onboarding_fee_due(:'seller'), true, 'fee is due once switched on (US, monetization on)');
select throws_ok(format($$ select private.quote_entitlement(%L, false) $$, :'seller'),
  'PT402', 'onboarding_fee_required', 'an unpaid seller cannot quote');
select is(private.quote_entitlement(:'partner', false), 'early_partner', 'early partners skip the fee');

select tests.authenticate_as(:'seller');
select is(public.get_my_onboarding_fee() ->> 'amount_minor', '2900', 'app sees the $29 amount');
reset role;

select public.apply_entitlement(:'seller', 'web', 'stripe', 'seller_onboarding', 'onboarding', 'active', 'stripe:pi_test');
select is(private.onboarding_fee_due(:'seller'), false, 'paid seller no longer owes the fee');
select is(private.quote_entitlement(:'seller', false), 'free_tier', 'paid seller quotes on the free tier');

select public.apply_entitlement(:'seller', 'web', 'stripe', 'seller_onboarding', 'onboarding', 'refunded', 'stripe:pi_test');
select is(private.onboarding_fee_due(:'seller'), true, 'a refunded fee is due again');

update public.app_settings set value = 'false' where key = 'monetization_enabled';
select is(private.onboarding_fee_due(:'seller'), true, 'the fee is due even while monetization is off');
select throws_ok(format($$ select private.quote_entitlement(%L, false) $$, :'seller'),
  'PT402', 'onboarding_fee_required', 'launch-free quoting still needs the fee');

update public.app_settings set value = '"IN"' where key = 'country';
select public.apply_entitlement(:'seller', 'play', 'google_play', 'seller_onboarding', 'onboarding', 'active', 'play:token_test');
select is(private.quote_entitlement(:'seller', false), 'launch_free', 'India seller who paid on Play quotes free');

select * from finish();
rollback;
