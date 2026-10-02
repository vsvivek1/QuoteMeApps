-- get_lead_feed: PostGIS radius, postal-code lists, nationwide, filters,
-- priority window, caps, blocks and keyset pagination.
begin;
\ir _helpers.psql
select plan(22);

select tests.create_user('lf-buyer') as buyer \gset
-- A = 990001 (centre), B = 990002 (~5.6 km north), C = 990003 (~111 km north)
select tests.make_request(:'buyer', 't-fridge', '990001', 'both', true, 'Fridge at A') as req_a \gset
select tests.make_request(:'buyer', 't-fridge', '990002', 'both', true, 'Fridge at B') as req_b \gset
select tests.make_request(:'buyer', 't-fridge', '990003', 'both', true, 'Fridge at C') as req_c \gset
select tests.make_request(:'buyer', 't-fridge', '990003', 'local', true, 'Local only at C') as req_c_local \gset
select tests.make_request(:'buyer', 't-repair', '990001', 'both', true, 'Repair at A') as req_repair \gset
update public.requests set created_at = now() - interval '5 minutes' where id = :'req_a';
update public.requests set created_at = now() - interval '4 minutes' where id = :'req_b';
update public.requests set created_at = now() - interval '3 minutes' where id = :'req_c';
update public.requests set created_at = now() - interval '2 minutes' where id = :'req_c_local';

select tests.make_seller('lf-radius10', 'radius', 12.0, 77.0, 10, '{}', '{t-fridge}') as r10 \gset
select tests.make_seller('lf-radius3', 'radius', 12.0, 77.0, 3, '{}', '{t-fridge}') as r3 \gset
select tests.make_seller('lf-codes', 'codes', 12.0, 77.0, null, '{990003}', '{t-fridge}') as codes \gset
select tests.make_seller('lf-national', 'nationwide', 20.0, 77.0, null, '{}', '{t-root}') as national \gset
select tests.make_seller('lf-repair', 'radius', 12.0, 77.0, 50, '{}', '{t-repair}') as repair \gset

-- radius ------------------------------------------------------------------------------------------
select tests.authenticate_as(:'r10');
select set_eq(format($$ select request_id from public.get_lead_feed('{}', null, 50) $$),
  array[:'req_b', :'req_a']::uuid[], '10 km radius seller sees A and B, not C');
select cmp_ok((select distance_m from public.get_lead_feed('{}', null, 50) where request_id = :'req_b'), '>', 5000::float8,
  'distance is returned (B ~5.6 km)');
select cmp_ok((select distance_m from public.get_lead_feed('{}', null, 50) where request_id = :'req_b'), '<', 6000::float8,
  'distance is accurate (PostGIS geography)');
select is((select request_id from public.get_lead_feed('{}', null, 50) limit 1), :'req_b'::uuid, 'newest first');
select set_eq(format($$ select request_id from public.get_lead_feed('{"max_distance_km": 2}', null, 50) $$),
  array[:'req_a']::uuid[], 'max_distance_km filter narrows the radius');

select tests.authenticate_as(:'r3');
select set_eq(format($$ select request_id from public.get_lead_feed('{}', null, 50) $$),
  array[:'req_a']::uuid[], '3 km radius seller sees only A');

-- postal codes ---------------------------------------------------------------------------------------
select tests.authenticate_as(:'codes');
select set_eq(format($$ select request_id from public.get_lead_feed('{}', null, 50) $$),
  array[:'req_c', :'req_c_local']::uuid[], 'code-list seller sees requests in its codes (incl. local-only)');

-- nationwide --------------------------------------------------------------------------------------------
select tests.authenticate_as(:'national');
select set_eq(format($$ select request_id from public.get_lead_feed('{}', null, 50) $$),
  array[:'req_a', :'req_b', :'req_c', :'req_repair']::uuid[], 'nationwide seller sees non-local requests in its categories (parent covers children)');
select set_eq(format($$ select request_id from public.get_lead_feed(jsonb_build_object('category_ids', jsonb_build_array(%s)), null, 50) $$, tests.cat('t-repair')),
  array[:'req_repair']::uuid[], 'category filter');

-- category ---------------------------------------------------------------------------------------------------
select tests.authenticate_as(:'repair');
select set_eq(format($$ select request_id from public.get_lead_feed('{}', null, 50) $$),
  array[:'req_repair']::uuid[], 'seller only sees their categories');

-- keyset pagination ---------------------------------------------------------------------------------------------
select tests.authenticate_as(:'national');
select request_id as p1_id, created_at as p1_ts from public.get_lead_feed('{}', null, 2) offset 1 limit 1 \gset
select set_eq(format($$ select request_id from public.get_lead_feed('{}', jsonb_build_object('created_at', %L, 'id', %L), 10) $$, :'p1_ts', :'p1_id'),
  array[:'req_a', :'req_b']::uuid[], 'cursor returns the next page');
select is((select count(*)::int from public.get_lead_feed('{}', null, 2)), 2, 'limit respected');

-- safe columns: hidden budget -------------------------------------------------------------------------------------
reset role;
update public.requests set budget_min_minor = 100000, budget_max_minor = 200000, budget_visible = false where id = :'req_a';
select tests.authenticate_as(:'r10');
select is((select budget_max_minor from public.get_lead_feed('{}', null, 50) where request_id = :'req_a'), null::bigint,
  'hidden budget is not returned');

-- dismiss ------------------------------------------------------------------------------------------------------------
select public.dismiss_lead(:'req_a');
select set_eq(format($$ select request_id from public.get_lead_feed('{}', null, 50) $$), array[:'req_b']::uuid[], 'dismissed lead hidden');
select set_eq(format($$ select request_id from public.get_lead_feed('{"include_dismissed": true}', null, 50) $$),
  array[:'req_a', :'req_b']::uuid[], 'include_dismissed brings it back');

-- priority window ------------------------------------------------------------------------------------------------------
reset role;
update public.requests set priority_until = now() + interval '10 minutes' where id = :'req_b';
select tests.authenticate_as(:'r10');
select is((select count(*)::int from public.get_lead_feed('{}', null, 50) where request_id = :'req_b'), 0,
  'unverified seller does not see requests inside the priority window');
reset role;
update public.sellers set verification_status = 'verified' where id = :'r10';
select tests.authenticate_as(:'r10');
select is((select count(*)::int from public.get_lead_feed('{}', null, 50) where request_id = :'req_b'), 1,
  'verified seller sees them immediately');

-- quote cap and blocks ----------------------------------------------------------------------------------------------------
reset role;
update public.requests set quote_count = max_quotes where id = :'req_b';
select tests.authenticate_as(:'r10');
select is((select count(*)::int from public.get_lead_feed('{}', null, 50) where request_id = :'req_b'), 0, 'requests at the cap are hidden');
reset role;
insert into public.blocks (blocker_id, blocked_id) values (:'buyer', :'national');
select tests.authenticate_as(:'national');
select is((select count(*)::int from public.get_lead_feed('{}', null, 50)), 0, 'buyer who blocked the seller is excluded');

-- closed / non-seller / restricted -----------------------------------------------------------------------------------------
reset role;
update public.requests set status = 'cancelled' where id = :'req_c';
select tests.authenticate_as(:'codes');
select set_eq(format($$ select request_id from public.get_lead_feed('{}', null, 50) $$), array[:'req_c_local']::uuid[], 'closed requests drop out');
select tests.authenticate_as(:'buyer');
select throws_ok($$ select * from public.get_lead_feed('{}', null, 10) $$, 'PT403', 'not_a_seller', 'buyers cannot call the lead feed');
reset role;
select tests.make_request(:'buyer', 't-licensed', '990001', 'both', true, 'Licensed lead') as lic \gset
select tests.make_seller('lf-unlicensed', 'radius', 12.0, 77.0, 10, '{}', '{t-licensed}') as unlic \gset
select tests.authenticate_as(:'unlic');
select is((select count(*)::int from public.get_lead_feed('{}', null, 50)), 0, 'restricted leads hidden without a valid licence');

reset role;
select * from finish();
rollback;
