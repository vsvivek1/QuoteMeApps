-- Admin gating, monetization switch, seller onboarding, reports/auto-hide,
-- reviews, orders, blocking and account deletion.
begin;
\ir _helpers.psql
select plan(33);

select tests.create_user('at-admin', 'Admin', '{buyer,admin}') as admin \gset
select tests.create_user('at-buyer', 'Asha Buyer') as buyer \gset
select tests.create_user('at-newseller', 'New Seller') as newseller \gset
select tests.create_user('at-r1') as r1 \gset
select tests.create_user('at-r2') as r2 \gset
select tests.create_user('at-r3') as r3 \gset

-- admin gating ---------------------------------------------------------------------------------
select tests.authenticate_as(:'buyer');
select throws_ok($$ select public.admin_set_setting('quote_cap', '12') $$, 'PT403', 'admin_only', 'non-admins cannot call admin RPCs');
select throws_ok($$ select public.admin_metrics() $$, 'PT403', 'admin_only', 'non-admins cannot read metrics');
select tests.authenticate_as(:'admin');
select is((public.admin_set_setting('quote_cap', '12')).value, '12'::jsonb, 'admin changes the quote cap');
select throws_ok($$ select public.admin_set_setting('quote_cap', '"lots"') $$, 'PT400', 'invalid_setting_value', 'setting values are validated');
-- stale token: claim without admin (role revoked in DB or never granted) is not enough, and vice versa
select set_config('request.jwt.claims', json_build_object('sub', :'admin', 'role', 'authenticated', 'roles', json_build_array('buyer'))::text, true);
select throws_ok($$ select public.admin_metrics() $$, 'PT403', 'admin_only', 'admin RPCs need the roles claim from the token hook');
select set_config('request.jwt.claims', json_build_object('sub', :'buyer', 'role', 'authenticated', 'roles', json_build_array('buyer','admin'))::text, true);
select throws_ok($$ select public.admin_metrics() $$, 'PT403', 'admin_only', 'a forged claim without the DB role is rejected');

-- onboarding while launch-free; then the monetization switch ------------------------------------------
reset role;
update public.app_settings set value = 'null' where key = 'early_partner_free_until';
select tests.authenticate_as(:'newseller');
select is((public.become_seller('New Seller Electronics')).early_partner, true, 'sellers joining before monetization are early partners');
select is((select roles from public.profiles where id = :'newseller'), array['buyer','seller'], 'seller role added');
select is(public.set_active_mode('seller'), 'seller', 'mode switch to seller');
select is((public.upsert_seller_profile(p_area_type => 'radius', p_lat => 12.0, p_lng => 77.0, p_radius_km => 15,
            p_category_ids => array[tests.cat('t-fridge')])).radius_km, 15.0, 'onboarding sets the service area');
select throws_ok(format($$ select public.upsert_seller_profile(p_category_ids => array[%s]) $$, tests.cat('t-forbidden')),
  'PT422', 'invalid_or_blocked_category', 'sellers cannot pick blocked categories');
select throws_ok($$ select public.submit_verification('gstin', '27AAPFU0939F1ZW') $$, 'PT422', 'invalid_gstin', 'GSTIN checksum validated');
select is((public.submit_verification('gstin', '27AAPFU0939F1ZV')).status, 'pending', 'valid GSTIN queued for review');

select tests.authenticate_as(:'admin');
select public.admin_set_setting('monetization_enabled', 'true');
reset role;
select ok((select free_until between now() + interval '5 months' and now() + interval '7 months' from public.sellers where id = :'newseller'),
  'turning monetization on stamps free_until (default +6 months) on early partners');
select ok((select (value #>> '{}')::timestamptz > now() from public.app_settings where key = 'early_partner_free_until'),
  'early_partner_free_until setting is fixed');
select tests.authenticate_as(:'newseller');
select is(public.get_my_entitlement() ->> 'next_quote_billing_source', 'early_partner', 'entitlement summary for the app');

select tests.authenticate_as(:'admin');
select is((public.admin_review_document((select id from public.seller_documents where seller_id = :'newseller'), true)).status,
  'approved', 'admin approves the document');
reset role;
select is((select verification_status from public.sellers where id = :'newseller'), 'verified', 'seller becomes verified');

-- reports and auto-hide after 3 -------------------------------------------------------------------------
select tests.make_request(:'buyer', 't-repair', '990001', 'both', true, 'Suspicious request') as bad_req \gset
select tests.authenticate_as(:'r1');
select public.report_content('request', :'bad_req', 'spam');
select tests.authenticate_as(:'r2');
select public.report_content('request', :'bad_req', 'spam');
reset role;
select is((select hidden from public.requests where id = :'bad_req'), false, 'two reports do not hide yet');
select tests.authenticate_as(:'r3');
select public.report_content('request', :'bad_req', 'fraud');
reset role;
select is((select hidden from public.requests where id = :'bad_req'), true, 'third distinct report auto-hides the content');
select tests.authenticate_as(:'admin');
select is(public.admin_resolve_report((select id from public.reports where target_id = :'bad_req' limit 1), 'restore'), 3,
  'admin resolves all reports on the target');
reset role;
select is((select hidden from public.requests where id = :'bad_req'), false, 'restored content is visible again');

-- orders and reviews ----------------------------------------------------------------------------------------
select tests.make_request(:'buyer', 't-fridge', '990001', 'both', true, 'Order flow') as oreq \gset
select tests.authenticate_as(:'newseller');
select id as oquote from tests.quote(:'oreq') \gset
select tests.authenticate_as(:'buyer');
select id as order_id from public.accept_quote(:'oquote') \gset
select throws_ok(format($$ select public.submit_review(%L, 5) $$, :'order_id'), 'PT409', 'order_not_completed',
  'reviews only from completed orders');
select throws_ok(format($$ select public.update_order_status(%L, 'dispatched') $$, :'order_id'), 'PT409', 'invalid_status_transition',
  'buyers cannot mark dispatch');
select tests.authenticate_as(:'newseller');
select is((public.update_order_status(:'order_id', 'delivered')).status, 'delivered', 'seller marks delivered');
select tests.authenticate_as(:'buyer');
select is((public.update_order_status(:'order_id', 'completed')).status, 'completed', 'buyer confirms completion');
select is((select (get_order_contacts(:'order_id') -> 'seller' ->> 'business_name')), 'New Seller Electronics',
  'contacts unlocked for order parties');
select is((public.submit_review(:'order_id', 4, array['on_time'], 'Good')).stars, 4, 'buyer reviews the seller');
reset role;
select is((select rating_avg || '/' || rating_count from public.sellers where id = :'newseller'), '4.00/1', 'seller rating aggregates updated');
select tests.authenticate_as(:'newseller');
select is((public.seller_reply_review((select id from public.reviews where order_id = :'order_id'), 'Thank you!')).seller_reply,
  'Thank you!', 'seller replies publicly');
select throws_ok(format($$ select public.seller_reply_review((select id from public.reviews where order_id = %L), 'Again') $$, :'order_id'),
  'PT409', 'already_replied', 'only one reply');

-- account deletion ----------------------------------------------------------------------------------------------
select tests.make_request(:'buyer', 't-repair', '990001', 'both', true, 'Open at deletion') as open_req \gset
select tests.authenticate_as(:'buyer');
select public.delete_my_account();
reset role;
select is((select status || '|' || coalesce(name, '-') || '|' || coalesce(phone, '-') from public.profiles where id = :'buyer'),
  'deleted|-|-', 'profile anonymized');
select is((select status from public.requests where id = :'open_req'), 'cancelled', 'open requests cancelled; orders kept');

select tests.clear_auth();
select * from finish();
rollback;
