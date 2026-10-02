-- Nightly SEO export (migration 1100, Section 21.9): data gates from
-- app_settings, small-town merge, no single-quote leakage, seller directory
-- opt-in, seo_pages status, guide review queue and access rules.
begin;
\ir _helpers.psql
select plan(50);

select tests.create_user('seo-admin', 'SEO Admin', '{buyer,admin}') as admin \gset
select tests.create_user('seo-user', 'Plain User') as usr \gset
select tests.create_user('seo-buyer', 'Buyer Person') as buyer \gset
select tests.create_user('seo-review-buyer', 'Review Buyer') as rbuyer \gset
update public.profiles set is_review_account = true where id = :'rbuyer';

-- Places far away from every seed / demo city. Seotown (small) is ~11 km from
-- Seobigcity and merges into it; Seothin is ~220 km away.
insert into public.cities (name, ascii_name, slug, state, state_code, population, centroid) values
  ('Seobigcity', 'Seobigcity', 'seobigcity', 'Seostate', 'SS', 900000, st_setsrid(st_makepoint(80.0, 20.0), 4326)::geography),
  ('Seotown', 'Seotown', 'seotown', 'Seostate', 'SS', 20000, st_setsrid(st_makepoint(80.0, 20.1), 4326)::geography),
  ('Seothin', 'Seothin', 'seothin', 'Seostate', 'SS', 600000, st_setsrid(st_makepoint(80.0, 22.0), 4326)::geography);

select tests.make_seller('seo-s1', 'radius', 20.0, 80.0, 20, '{}', '{t-fridge,t-repair,t-licensed}') as s1 \gset
select tests.make_seller('seo-s2', 'radius', 20.0, 80.01, 20, '{}', '{t-fridge,t-repair}') as s2 \gset
select tests.make_seller('seo-s3', 'radius', 20.05, 80.0, 20, '{}', '{t-fridge,t-repair}') as s3 \gset
select tests.make_seller('seo-s4', 'radius', 22.0, 80.0, 20, '{}', '{t-fridge}') as s4 \gset
select tests.make_seller('seo-review', 'radius', 20.0, 80.0, 20, '{}', '{t-fridge}') as srev \gset
update public.profiles set is_review_account = true where id = :'srev';
update public.sellers set description = 'Secret shop text', city = 'Seobigcity' where id = :'s1';
insert into public.seller_contacts (seller_id, business_phone) values (:'s1', '+919999911111')
  on conflict (seller_id) do update set business_phone = excluded.business_phone;

-- One request + one quote, inserted directly (as postgres) with full control
-- over date, price and model.
create function tests.seo_q(p_seller uuid, p_buyer uuid, p_cat text, p_lat float8, p_lng float8,
                            p_subtotal bigint, p_days_ago int, p_model text default null)
returns uuid language plpgsql as $$
declare v_req uuid; v_q uuid; v_at timestamptz := now() - make_interval(days => p_days_ago);
begin
  insert into public.requests (buyer_id, category_id, title, currency, location, audience, quote_window_ends_at, created_at)
  values (p_buyer, tests.cat(p_cat), 'Secret request title zq', 'INR',
          st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography, 'both', v_at + interval '2 days', v_at)
  returning id into v_req;
  insert into public.quotes (request_id, seller_id, subtotal_minor, tax_minor, delivery_minor, total_minor, currency,
                             offered_brand_model, delivery_date, response_mins, created_at)
  values (v_req, p_seller, p_subtotal, 0, 5000, p_subtotal + 5000, 'INR', p_model, (v_at + interval '3 days')::date, 60, v_at)
  returning id into v_q;
  return v_q;
end $$;

-- A: Seobigcity x t-fridge: 10 quotes from 3 sellers (2 of them from Seotown).
--    Five recent (10-14 days ago, 1100.00) and five older (35-39 days ago, 1000.00).
select tests.seo_q(:'s1', :'buyer', 't-fridge', 20.0, 80.0, 110000, 10, 'Model X 300L');
select tests.seo_q(:'s2', :'buyer', 't-fridge', 20.0, 80.0, 110000, 11, 'model x  300l');
select tests.seo_q(:'s3', :'buyer', 't-fridge', 20.0, 80.0, 110000, 12, 'Model X 300L');
select tests.seo_q(:'s1', :'buyer', 't-fridge', 20.1, 80.0, 110000, 13, 'Solo Model');
select tests.seo_q(:'s2', :'buyer', 't-fridge', 20.0, 80.0, 110000, 14);
select tests.seo_q(:'s3', :'buyer', 't-fridge', 20.0, 80.0, 100000, 35, 'Model X 300L');
select tests.seo_q(:'s1', :'buyer', 't-fridge', 20.1, 80.0, 100000, 36, 'Solo Model');
select tests.seo_q(:'s2', :'buyer', 't-fridge', 20.0, 80.0, 100000, 37);
select tests.seo_q(:'s3', :'buyer', 't-fridge', 20.0, 80.0, 100000, 38);
select tests.seo_q(:'s1', :'buyer', 't-fridge', 20.0, 80.0, 100000, 39, 'Solo Model');
-- excluded: review-account seller, review-account buyer, withdrawn, hidden, older than the window
select tests.seo_q(:'srev', :'buyer', 't-fridge', 20.0, 80.0, 900000, 5);
select tests.seo_q(:'s2', :'rbuyer', 't-fridge', 20.0, 80.0, 900000, 5);
select tests.seo_q(:'s3', :'buyer', 't-fridge', 20.0, 80.0, 900000, 5) as wq \gset
update public.quotes set status = 'withdrawn' where id = :'wq';
select tests.seo_q(:'s1', :'buyer', 't-fridge', 20.0, 80.0, 900000, 5) as hq \gset
update public.quotes set hidden = true where id = :'hq';
select tests.seo_q(:'s1', :'buyer', 't-fridge', 20.0, 80.0, 900000, 120);
-- B: Seobigcity x t-repair: 9 quotes from 3 sellers (one short of the threshold)
select tests.seo_q(s, :'buyer', 't-repair', 20.0, 80.0, 50000 + i * 1000, i)
  from (select i, (array[:'s1', :'s2', :'s3']::uuid[])[1 + i % 3] s from generate_series(1, 9) i) x;
-- C: Seothin x t-fridge: a single quote
select tests.seo_q(:'s4', :'buyer', 't-fridge', 22.0, 80.0, 777777, 3, 'Lonely Model 9');
-- D: restricted category with plenty of data
select tests.seo_q(s, :'buyer', 't-licensed', 20.0, 80.0, 300000, i)
  from (select i, (array[:'s1', :'s2', :'s3']::uuid[])[1 + i % 3] s from generate_series(1, 12) i) x;

-- seller directory opt-in (seller RPC)
select tests.authenticate_as(:'s1');
select is((public.set_seller_directory_opt_in(true)).seo_directory_opt_in, true, 'a seller opts in to the directory');
select tests.authenticate_as(:'usr');
select throws_ok($$ select public.set_seller_directory_opt_in(true) $$, 'PT403', 'not_a_seller',
  'only sellers can opt in');
select is((select seo_directory_opt_in from public.sellers where id = :'s2'), false, 'directory opt-in is off by default');

-- access ----------------------------------------------------------------------------------------------
select throws_ok($$ select public.seo_export('x', true) $$, '42501', null, 'users cannot run the export');
select tests.authenticate_as(:'admin');
select throws_ok($$ select public.seo_export('x', true) $$, '42501', null, 'the export is service-role only (Edge Function)');
reset role;
select tests.clear_auth();

-- run --------------------------------------------------------------------------------------------------
create temp table run1 as select public.seo_export('pgtap') as r;
create temp table d1 as select r -> 'data' as d from run1;
create temp table pg1 as
  select p from d1, jsonb_array_elements(d -> 'pages') p where p ->> 'city' in ('seobigcity','seothin','seotown');

select is((select d ->> 'country' from d1), 'india', 'country from app_settings');
select is((select d -> 'thresholds' from d1), '{"min_quotes":10,"min_sellers":3,"window_days":90,"stale_days":90}'::jsonb,
  'default thresholds exported');
select is((select p ->> 'quotes_window' from pg1 where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-fridge'),
  '10', 'merged town quotes count for the larger area; excluded quotes do not');
select is((select p ->> 'sellers_window' from pg1 where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-fridge'),
  '3', 'distinct sellers counted');
select is((select p -> 'price' from pg1 where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-fridge'),
  '{"median":1050,"p25":1000,"p75":1100}'::jsonb, 'median and quartiles in major units (India: tax inclusive, no delivery)');
select is((select p -> 'top_models' from pg1 where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-fridge'),
  '[{"name":"Model X 300L","quotes":4}]'::jsonb, 'most-quoted models only when several sellers quoted them');
select is((select p ->> 'trend_pct_vs_last_month' from pg1 where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-fridge'),
  '10.0', 'trend vs last month from the two monthly medians');
select is((select (p ->> 'median_delivery_days') || '/' || (p ->> 'median_response_hours') from pg1
            where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-fridge'), '3/1.0', 'delivery and response medians');
select is((select (p ->> 'local_sellers')::int from pg1 where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-fridge'),
  3, 'local sellers counted (review-account store excluded)');
select is((select p ->> 'last_quote_at' from pg1 where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-fridge'),
  to_char(date_trunc('day', now() - interval '10 days') at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
  'last quote date is truncated to the day');
select is((select count(*)::int from pg1 where p ->> 'city' = 'seotown'), 0, 'merged town has no page of its own');
select is((select c ->> 'merge_into' from d1, jsonb_array_elements(d -> 'cities') c where c ->> 'slug' = 'seotown'),
  'seobigcity', 'merged town listed with merge_into (canonical = area page)');
select is((select count(*)::int from pg1 where p ->> 'category' = 't-licensed'), 0, 'restricted category gets no page');
select ok((select c ->> 'policy' = 'restricted' from d1, jsonb_array_elements(d -> 'categories') c where c ->> 'slug' = 't-licensed'),
  'restricted category still listed with its policy');

-- below the gates: counts only, never a price or model
select is((select p - 'period' - 'last_quote_at' - 'local_sellers' from pg1 where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-repair'),
  '{"city":"seobigcity","category":"t-repair","quotes_window":9,"sellers_window":3}'::jsonb,
  '9 quotes: counts only (no price, models, delivery, response or trend)');
select is((select p - 'period' - 'last_quote_at' - 'local_sellers' from pg1 where p ->> 'city' = 'seothin'),
  '{"city":"seothin","category":"t-fridge","quotes_window":1,"sellers_window":1}'::jsonb,
  'a single quote exposes counts only');
select ok((select position('7777' in d::text) = 0 and position('7780' in d::text) = 0
             and position('Lonely Model' in d::text) = 0 from d1),
  'the single quote''s price and model appear nowhere in the export');
select ok((select position(:'buyer' in d::text) = 0 and position('Secret request' in d::text) = 0
             and position('+919999911111' in d::text) = 0 from d1),
  'no buyer ids, request text or seller contact details in the export');

-- seller directory
select is((select count(*)::int from d1, jsonb_array_elements(d -> 'sellers') s where s ->> 'name' like 'Shop seo-%'),
  1, 'only opted-in sellers are in the directory');
select is((select (s ->> 'city') || '|' || (s -> 'categories')::text from d1, jsonb_array_elements(d -> 'sellers') s
            where s ->> 'name' = 'Shop seo-s1'), 'seobigcity|["t-fridge", "t-repair"]',
  'directory entry: area city and allowed categories only');

-- seo_pages
select is((select status from public.seo_pages where path = '/quotes/seobigcity/t-fridge'), 'indexable', 'seo_pages: indexable');
select is((select status from public.seo_pages where path = '/quotes/seobigcity/t-repair'), 'waiting_for_data',
  'seo_pages: below threshold waits for data');
select is((select merged_city_ids from public.seo_pages where path = '/quotes/seobigcity/t-fridge'),
  array[(select id from public.cities where slug = 'seotown')], 'seo_pages records the merged towns');
select ok((select indexable_since is not null and refreshed_at = now() from public.seo_pages where path = '/quotes/seobigcity/t-fridge'),
  'seo_pages: last update and indexable since');
select is((select pages_total >= 3 and triggered_by = 'pgtap' from public.seo_export_runs where id = (select (r ->> 'run_id')::bigint from run1)),
  true, 'export run recorded');

-- thresholds come from app_settings (admin-editable, validated) ---------------------------------------
select tests.authenticate_as(:'admin');
select throws_ok($$ select public.admin_set_setting('seo_thresholds', '{"min_quotes":1,"min_sellers":3,"window_days":90,"stale_days":90}') $$,
  'PT400', 'invalid_setting_value', 'thresholds below the anonymity floor are rejected');
select throws_ok($$ select public.admin_set_setting('seo_thresholds', '{"min_quotes":10}') $$,
  'PT400', 'invalid_setting_value', 'all four thresholds are required');
select lives_ok($$ select public.admin_set_setting('seo_thresholds', '{"min_quotes":11,"min_sellers":3,"window_days":90,"stale_days":7}') $$,
  'admin edits the thresholds');
reset role;
select tests.clear_auth();
create temp table d2 as select public.seo_export('pgtap') -> 'data' as d;
select is((select p ->> 'price' from d2, jsonb_array_elements(d -> 'pages') p where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-fridge'),
  null, 'raised min_quotes hides the price');
select is((select status || ':' || array_to_string(reasons, ',') from public.seo_pages where path = '/quotes/seobigcity/t-fridge'),
  'waiting_for_data:below threshold (10 quotes / 3 sellers; need 11 / 3),stale (no quotes in 7 days)',
  'seo_pages reflect the new thresholds and staleness');
select tests.authenticate_as(:'admin');
select lives_ok($$ select public.admin_set_setting('seo_thresholds', '{"min_quotes":10,"min_sellers":3,"window_days":90,"stale_days":7}') $$,
  'admin restores min_quotes');
reset role;
select tests.clear_auth();
select public.seo_export('pgtap');
select is((select status from public.seo_pages where path = '/quotes/seobigcity/t-fridge'), 'noindex',
  'enough data but no quote within stale_days: noindex');

-- manual noindex is kept across exports
select tests.authenticate_as(:'admin');
select lives_ok($$ select public.admin_set_setting('seo_thresholds', '{"min_quotes":10,"min_sellers":3,"window_days":90,"stale_days":90}') $$, 'reset');
select lives_ok($$ select public.admin_set_seo_page_noindex((select id from public.cities where slug = 'seobigcity'), tests.cat('t-fridge'), true) $$,
  'admin forces a page to noindex');
reset role;
select tests.clear_auth();
create temp table d3 as select public.seo_export('pgtap') -> 'data' as d;
select is((select status from public.seo_pages where path = '/quotes/seobigcity/t-fridge'), 'noindex', 'manual noindex survives the export');
select is((select p ->> 'manual_noindex' from d3, jsonb_array_elements(d -> 'pages') p where p ->> 'city' = 'seobigcity' and p ->> 'category' = 't-fridge'),
  'true', 'manual noindex is exported for the site');

-- visibility of seo tables
select tests.authenticate_as(:'usr');
select is((select count(*)::int from public.seo_pages), 0, 'normal users see no seo_pages');
select tests.authenticate_anon();
select throws_ok($$ select count(*) from public.seo_pages $$, '42501', null, 'anon has no access to seo_pages');
select tests.authenticate_as(:'admin');
select ok((select count(*) from public.seo_pages) >= 3, 'admins read seo_pages');

-- guides: review queue, weekly AI cap, export only approved / published ---------------------------------
select public.admin_set_setting('seo_ai_guides_weekly_cap', '1');
create temp table g as
  select * from public.admin_upsert_seo_guide(null, 'fridge-size-family', 'Fridge size for a family of four',
          tests.cat('t-fridge'), '# Guide' || chr(10) || 'Text', (select id from public.cities where slug = 'seobigcity'),
          'How big a fridge you need', true);
select throws_ok($$ select public.admin_upsert_seo_guide(null, 'second-ai-guide', 'Another AI guide', tests.cat('t-fridge'), 'x', null, null, true) $$,
  'PT429', 'ai_guide_weekly_cap', 'weekly cap on new AI-assisted guides');
select lives_ok($$ select public.admin_upsert_seo_guide(null, 'human-guide', 'A human-written guide', tests.cat('t-fridge'), 'x') $$,
  'human-written guides are not capped');
select throws_ok(format($$ select public.admin_review_seo_guide(%L, 'publish') $$, (select id from g)),
  'PT409', 'guide_not_approved', 'a draft cannot be published without approval');
select is((public.admin_review_seo_guide((select id from g), 'approve')).reviewer_id, :'admin'::uuid,
  'approval records the reviewer (and date)');
reset role;
select tests.clear_auth();
create temp table d4 as select public.seo_export('pgtap', true) -> 'data' as d;
select is((select string_agg((x ->> 'slug') || ':' || (x ->> 'status') || ':' || (x ->> 'city'), ',') from d4, jsonb_array_elements(d -> 'guides') x
            where x ->> 'slug' in ('fridge-size-family','human-guide')),
  'fridge-size-family:approved:seobigcity', 'drafts are not exported; approved guides are');
select tests.authenticate_as(:'usr');
select throws_ok(format($$ select public.admin_review_seo_guide(%L, 'publish') $$, (select id from g)),
  'PT403', 'admin_only', 'only admins review guides');

reset role;
select tests.clear_auth();
select * from finish();
rollback;
