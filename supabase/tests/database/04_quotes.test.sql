-- submit_quote rules (cap, priority window, licence, area, entitlements) and
-- the effects of accept_quote / withdraw / revise / counter / decline.
begin;
\ir _helpers.psql
select plan(43);

select tests.create_user('q-buyer') as buyer \gset
select tests.make_request(:'buyer') as req \gset

-- 11 sellers in range; quote cap is 10 ---------------------------------------------------------------
select count(tests.make_seller('q-seller-' || i)) as n_sellers from generate_series(1, 11) i \gset

select set_config('tests.req', :'req', true) \gset
do $$
declare i int;
begin
  for i in 1..10 loop
    perform tests.authenticate_as(md5('pgtap:q-seller-' || i)::uuid);
    perform tests.quote(current_setting('tests.req')::uuid, 100000 + i * 100);
  end loop;
end $$;
reset role;

select is((select quote_count from public.requests where id = :'req'), 10, '10 quotes accepted, quote_count = 10');
select tests.authenticate_as(md5('pgtap:q-seller-11')::uuid);
select throws_ok(format($$ select tests.quote(%L) $$, :'req'), 'PT409', 'quote_cap_reached', '11th quote is rejected (cap 10)');
select tests.authenticate_as(md5('pgtap:q-seller-1')::uuid);
select throws_ok(format($$ select tests.quote(%L) $$, :'req'), 'PT409', 'already_quoted', 'a seller cannot quote twice');

-- withdraw frees a slot for the 11th seller
select lives_ok(format($$ select public.withdraw_quote((select id from public.quotes where request_id = %L and seller_id = %L)) $$,
  :'req', md5('pgtap:q-seller-1')::uuid), 'seller withdraws');
reset role;
select is((select quote_count from public.requests where id = :'req'), 9, 'withdraw decrements quote_count');
select tests.authenticate_as(md5('pgtap:q-seller-11')::uuid);
select lives_ok(format($$ select tests.quote(%L) $$, :'req'), 'freed slot can be used by another seller');

-- quote content: totals computed server side (intra-state GST) -------------------------------------------
select is((select tax_breakdown->>'mode' from public.quotes where request_id = :'req' and seller_id = md5('pgtap:q-seller-11')::uuid),
  'intra', 'same-state seller gets CGST+SGST');
select is((select total_minor from public.quotes where request_id = :'req' and seller_id = md5('pgtap:q-seller-11')::uuid),
  118000::bigint, 'total = 100000 + 18% GST');
select is((select count(*)::int from public.quote_line_items li join public.quotes q on q.id = li.quote_id
            where q.request_id = :'req' and q.seller_id = md5('pgtap:q-seller-11')::uuid), 1, 'line items stored');

-- accept_quote effects -----------------------------------------------------------------------------
reset role;
select id as win_quote from public.quotes where request_id = :'req' and seller_id = md5('pgtap:q-seller-2')::uuid \gset
select tests.authenticate_as(md5('pgtap:q-seller-2')::uuid);
select throws_ok(format($$ select public.accept_quote(%L) $$, :'win_quote'), 'PT404', 'quote_not_found', 'a seller cannot accept');
select tests.authenticate_as(:'buyer');
select id as order_id from public.accept_quote(:'win_quote') \gset
reset role;
select is((select status from public.quotes where id = :'win_quote'), 'accepted', 'accepted quote is accepted');
select is((select count(*)::int from public.quotes where request_id = :'req' and id <> :'win_quote'
            and status = 'declined' and decline_reason = 'another_quote_accepted'), 9, 'all other active quotes declined');
select is((select status from public.quotes where request_id = :'req' and seller_id = md5('pgtap:q-seller-1')::uuid),
  'withdrawn', 'withdrawn quote untouched');
select is((select status from public.requests where id = :'req'), 'awarded', 'request is closed (awarded)');
select is((select accepted_quote_id from public.requests where id = :'req'), :'win_quote'::uuid, 'accepted_quote_id set');
select is((select count(*)::int from public.orders where id = :'order_id' and quote_id = :'win_quote'
            and seller_id = md5('pgtap:q-seller-2')::uuid and status = 'accepted'), 1, 'order created for the winner');
select is((select count(*)::int from public.order_events where order_id = :'order_id' and status = 'accepted'), 1, 'order_event recorded');
select is((select quotes_won from public.sellers where id = md5('pgtap:q-seller-2')::uuid), 1, 'winner quotes_won incremented');
select is((select count(*)::int from public.notifications where user_id = md5('pgtap:q-seller-2')::uuid and type = 'quote_accepted'),
  1, 'winner notified');
select is((select count(*)::int from public.notifications where type = 'quote_not_selected'
            and payload->>'request_id' = :'req'), 9, 'other sellers politely notified');
select is((select count(*)::int from public.messages m join public.chats c on c.id = m.chat_id
            where c.request_id = :'req' and m.type = 'system' and m.body = 'quote_accepted'), 1, 'system message in the winner chat');
select tests.authenticate_as(md5('pgtap:q-seller-11')::uuid);
select throws_ok(format($$ select tests.quote(%L) $$, :'req'), 'PT409', 'request_not_open', 'no more quotes after the request is awarded');
select tests.authenticate_as(:'buyer');
select throws_ok(format($$ select public.accept_quote(%L) $$, :'win_quote'), 'PT409', 'request_not_open', 'cannot accept twice');

-- priority window: unverified sellers wait, verified go first ---------------------------------------------
reset role;
select tests.make_request(:'buyer', 't-fridge', '990001', 'both', false, 'Fresh request') as fresh \gset
select tests.make_seller('q-verified', p_verified => true) as verified \gset
select tests.authenticate_as(md5('pgtap:q-seller-3')::uuid);
select throws_ok(format($$ select tests.quote(%L) $$, :'fresh'), 'PT403', 'priority_window', 'unverified seller blocked during priority window');
select tests.authenticate_as(:'verified');
select lives_ok(format($$ select tests.quote(%L) $$, :'fresh'), 'verified seller can quote during the window');

-- service area / category / licence / blocked ---------------------------------------------------------------
reset role;
select tests.make_seller('q-far', p_lat => 13.5, p_lng => 77.0, p_radius => 10) as far_seller \gset
select tests.make_seller('q-other-cat', p_cats => '{t-repair}') as other_cat \gset
select tests.make_request(:'buyer', 't-licensed', '990001', 'both', true, 'Licensed job') as lic_req \gset
select tests.make_seller('q-licensed', p_cats => '{t-licensed}') as lic_seller \gset
select tests.authenticate_as(:'far_seller');
select throws_ok(format($$ select tests.quote(%L) $$, :'fresh'), 'PT403', null, 'seller outside the radius cannot quote');
select tests.authenticate_as(:'other_cat');
select throws_ok(format($$ select tests.quote(%L) $$, :'fresh'), 'PT403', null, 'seller without the category cannot quote');
select tests.authenticate_as(:'lic_seller');
select throws_ok(format($$ select public.submit_quote(%L, tests.line()) $$, :'lic_req'), 'PT403', 'licence_required',
  'restricted category needs an approved licence');
reset role;
insert into public.seller_licences (seller_id, licence_type, number, category_ids, expires_at, status)
values (:'lic_seller', 't_licence', 'L-1', array[tests.cat('t-restricted-root')], now() + interval '1 year', 'approved');
select tests.authenticate_as(:'lic_seller');
select lives_ok(format($$ select public.submit_quote(%L, tests.line()) $$, :'lic_req'), 'licensed seller can quote');

-- entitlements once monetization is on --------------------------------------------------------------------------
reset role;
update public.app_settings set value = 'true' where key = 'monetization_enabled';
update public.app_settings set value = '1' where key = 'free_quotes_per_month';
select tests.make_request(:'buyer', 't-repair', '990001', 'both', true, 'Paid lead 1') as paid1 \gset
select tests.make_request(:'buyer', 't-repair', '990001', 'both', true, 'Paid lead 2') as paid2 \gset
select tests.make_request(:'buyer', 't-repair', '990001', 'both', true, 'Paid lead 3') as paid3 \gset
select tests.authenticate_as(md5('pgtap:q-seller-5')::uuid);
select is((public.submit_quote(:'paid1', tests.line())).billing_source, 'free_tier', 'first quote uses the free tier');
select throws_ok(format($$ select public.submit_quote(%L, tests.line()) $$, :'paid2'), 'PT402', 'quota_exhausted',
  'no free quotes or credits left');
reset role;
insert into public.entitlements (seller_id, store, provider, product_id, tier, status, credits_balance)
values (md5('pgtap:q-seller-5')::uuid, 'manual', 'admin', 'credits_1', 'credits', 'active', 1);
select tests.authenticate_as(md5('pgtap:q-seller-5')::uuid);
select is((public.submit_quote(:'paid2', tests.line())).billing_source, 'credit', 'a credit is spent');
reset role;
select is((select credits_balance from public.entitlements where seller_id = md5('pgtap:q-seller-5')::uuid), 0, 'credit balance decremented');
update public.sellers set early_partner = true, free_until = now() + interval '1 month' where id = md5('pgtap:q-seller-5')::uuid;
select tests.authenticate_as(md5('pgtap:q-seller-5')::uuid);
select is((public.submit_quote(:'paid3', tests.line())).billing_source, 'early_partner', 'early partners stay free until free_until');

-- revise, counter-offer, decline, shortlist --------------------------------------------------------------------
reset role;
select id as rq from public.quotes where request_id = :'fresh' and seller_id = :'verified' \gset
select tests.authenticate_as(:'buyer');
select is((public.shortlist(:'rq')).status, 'shortlisted', 'buyer shortlists');
select is((public.counter_offer(:'rq', 90000, 'Can you do 900?')).counter_target_minor, 90000::bigint, 'buyer sends a counter-offer');
select tests.authenticate_as(:'verified');
select is((public.revise_quote(:'rq', tests.line(80000))).total_minor, 94400::bigint, 'seller revises the price');
reset role;
select is((select count(*)::int from public.quote_revisions where quote_id = :'rq'), 1, 'revision snapshot stored');

-- US sales tax in ppm (migration 1050): 8.875 % is exact; older apps still send basis points
update public.app_settings set value = '"US"' where key = 'country';
select tests.authenticate_as(:'verified');
select is((public.revise_quote(:'rq', tests.line(80000), p_sales_tax_rate_ppm => 88750)).total_minor, 87100::bigint,
  'US revise at 8.875 % (88750 ppm): 80000 + 7100');
select is((select tax_breakdown from public.quotes where id = :'rq'),
  '{"kind":"sales_tax","rate_ppm":88750,"rate_bp":888,"amount":7100}'::jsonb, 'breakdown stores rate_ppm');
select is((public.revise_quote(:'rq', tests.line(80000), p_sales_tax_rate_bp => 825)).total_minor, 86600::bigint,
  'older app: p_sales_tax_rate_bp 825 still works');
select is((select (tax_breakdown->>'rate_ppm')::int from public.quotes where id = :'rq'), 82500, 'bp is stored as ppm (bp * 100)');
reset role;
update public.app_settings set value = '"IN"' where key = 'country';
select tests.authenticate_as(:'buyer');
select is((public.decline_quote(:'rq', 'Too far')).status, 'declined', 'buyer declines with a reason');

reset role;
select * from finish();
rollback;
