-- create_request: validation, postal-code location, blocked categories and
-- keywords, duplicate detection, daily rate limit, privacy of exact location.
begin;
\ir _helpers.psql
select plan(19);

select tests.create_user('cr-buyer') as buyer \gset
select tests.make_seller('cr-seller', 'radius', 12.0, 77.0, 10, '{}', '{t-fridge}', true) as seller \gset

select tests.authenticate_as(:'buyer');
select * from public.create_request(
  p_category_id => tests.cat('t-fridge'), p_title => 'Double door fridge', p_fields => '{"door_type":"double"}',
  p_location_code => '990002', p_quote_window_hours => 24) \gset cr_
select isnt(:'cr_request_id'::uuid, null::uuid, 'request created from a postal code only');
select is(:'cr_matched_sellers'::int, 1, 'matched seller count returned ("We''ve notified N sellers")');
reset role;
select is((select location_code || '|' || city || '|' || state from public.requests where id = :'cr_request_id'),
  '990002|Testpur|Teststate', 'location resolved from postal_codes');
select ok((select st_dwithin(location, (select centroid from public.postal_codes where code = '990002'), 1)
             from public.requests where id = :'cr_request_id'), 'point = postal code centroid');
select ok((select priority_until between now() + interval '14 minutes' and now() + interval '16 minutes'
             from public.requests where id = :'cr_request_id'), 'priority_until = now + 15 min');
select ok((select quote_window_ends_at between now() + interval '23 hours' and now() + interval '25 hours'
             from public.requests where id = :'cr_request_id'), 'quote window = 24 h');
select is((select max_quotes from public.requests where id = :'cr_request_id'), 10, 'quote cap from app_settings');
select is((select buyer_phone from public.request_private where request_id = :'cr_request_id'),
  (select phone from public.profiles where id = :'buyer'), 'buyer phone stored privately');

-- GPS pin: coarse point public, exact point private
select tests.authenticate_as(:'buyer');
select request_id as gps_req from public.create_request(
  p_category_id => tests.cat('t-repair'), p_title => 'Repair at my pin', p_lat => 12.0123456, p_lng => 77.0123456,
  p_full_address => 'Flat 4, Secret Apartments') \gset
reset role;
select is((select round(st_y(location::geometry)::numeric, 7) from public.requests where id = :'gps_req'), 12.0120000,
  'public location is rounded (~110 m)');
select is((select round(st_y(exact_location::geometry)::numeric, 7) from public.request_private where request_id = :'gps_req'),
  12.0123456, 'exact pin kept in request_private');
select is((select location_code from public.requests where id = :'gps_req'), '990001', 'nearest postal code attached to a GPS pin');

-- validation -----------------------------------------------------------------------------------------------
select tests.authenticate_as(:'buyer');
select throws_ok(format($$ select * from public.create_request(p_category_id => %s, p_title => 'Banned thing', p_location_code => '990001') $$,
  tests.cat('t-forbidden')), 'PT422', 'category_blocked', 'blocked category cannot be requested');
select throws_ok(format($$ select * from public.create_request(p_category_id => %s, p_title => 'Need zzforbiddenthing fast', p_location_code => '990001') $$,
  tests.cat('t-repair')), 'PT422', 'blocked_content', 'keyword classifier catches blocked items in allowed categories');
select throws_ok(format($$ select * from public.create_request(p_category_id => %s, p_title => 'Fridge no door type', p_location_code => '990001') $$,
  tests.cat('t-fridge')), 'PT400', 'missing_required_field', 'required structured fields enforced');
select throws_ok(format($$ select * from public.create_request(p_category_id => %s, p_title => 'Unknown code', p_location_code => '990999') $$,
  tests.cat('t-repair')), 'PT422', 'unknown_postal_code', 'unknown postal code rejected');
select throws_ok(format($$ select * from public.create_request(p_category_id => %s, p_title => 'Parent category', p_location_code => '990001') $$,
  tests.cat('t-root')), 'PT400', 'category_not_leaf', 'must pick a leaf category');

-- duplicate within 24 h ------------------------------------------------------------------------------------------
select throws_ok(format($$ select * from public.create_request(p_category_id => %s, p_title => '  double DOOR   fridge ',
    p_fields => '{"door_type":"double"}', p_location_code => '990001') $$, tests.cat('t-fridge')),
  'PT409', 'duplicate_request', 'same buyer, category and text within 24 h is a duplicate');

-- daily limit (10 per rolling 24 h) ------------------------------------------------------------------------------------
reset role;
insert into public.requests (buyer_id, category_id, title, currency, audience, quote_window_ends_at, created_at)
select :'buyer', tests.cat('t-repair'), 'Filler ' || i, 'INR', 'online', now() + interval '1 day', now() - interval '1 hour'
  from generate_series(1, 8) i;
select tests.authenticate_as(:'buyer');
select throws_ok(format($$ select * from public.create_request(p_category_id => %s, p_title => 'Eleventh request', p_location_code => '990001') $$,
  tests.cat('t-repair')), 'PT429', 'rate_limited', '11th request in 24 h is rate limited');

-- classifier suggestion ------------------------------------------------------------------------------------------------
select is((select slug from public.classify_request_text('I need a testfridgeword please') limit 1), 't-fridge',
  'classify_request_text suggests a category from keywords');

reset role;
select * from finish();
rollback;
