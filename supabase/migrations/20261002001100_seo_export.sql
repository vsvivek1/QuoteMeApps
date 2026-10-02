-- 1100 Nightly SEO data export (brief Section 21.9): settings, seller
-- directory opt-in, seo_pages / seo_export_runs / seo_guides, the export
-- function used by the `seo-export` Edge Function and the admin RPCs for the
-- guide review queue.
--
-- Data shape: exactly what web/app_site/src/lib/seo.ts reads (SeoData), plus
-- `guides` (approved / published buying guides) and `sellers` (directory
-- entries for sellers who opted in). Every figure is an aggregate:
--   * prices, delivery and response times are medians / quartiles over at
--     least the threshold number of quotes from the threshold number of
--     sellers, rounded (never one seller's quote);
--   * most-quoted models only when at least `min_sellers` different sellers
--     quoted them;
--   * no buyer identifiers, no request text, no seller's own quote.
set search_path = public, extensions;

-- Settings ---------------------------------------------------------------------------------------
insert into public.app_settings (key, value, is_public, description) values
  ('seo_thresholds', '{"min_quotes":10,"min_sellers":3,"window_days":90,"stale_days":90}', false,
   'SEO price-page gates (Section 21.9): a city x category page is indexable with at least min_quotes quotes from min_sellers sellers in the last window_days days and a quote within stale_days'),
  ('seo_ai_guides_weekly_cap', '10', false,
   'Max new AI-assisted buying guides per rolling 7 days (Section 21.9)'),
  ('seo_merge', '{"max_population":50000,"radius_km":25,"assign_radius_km":40}', false,
   'SEO area merge: towns below max_population within radius_km of a larger city share its page (canonical); quotes are assigned to the nearest city within assign_radius_km'),
  ('seo_category_meta', '{"kitchen-remodel":{"kind":"service"},"interior-design":{"kind":"service"},"modular-kitchens":{"kind":"service"},"interiors":{"kind":"service"},"vehicle-servicing":{"kind":"service"},"printing":{"kind":"service"}}', false,
   'SEO category kind/unit overrides {slug:{kind:product|service,unit?}}; children of home-services default to service "per job", children of events to service, categories with a required quantity field to "per item"')
on conflict (key) do nothing;

-- Validation for the new keys (separate trigger so it composes with
-- private.validate_app_setting from 1040 and later migrations).
create or replace function private.validate_seo_setting(p_key text, p_value jsonb)
returns void
language plpgsql
immutable
set search_path = ''
as $$
declare
  k text;
  v jsonb;
  ranges constant jsonb := '{"min_quotes":[3,1000],"min_sellers":[2,100],"window_days":[7,365],"stale_days":[7,365]}';
begin
  if p_key = 'seo_thresholds' then
    if jsonb_typeof(p_value) <> 'object'
       or (select count(*) from jsonb_object_keys(p_value)) <> 4 then
      perform private.raise_error('invalid_setting_value', 400, p_key);
    end if;
    for k, v in select * from jsonb_each(p_value) loop
      if not ranges ? k or jsonb_typeof(v) <> 'number' or (v #>> '{}')::numeric <> trunc((v #>> '{}')::numeric)
         or (v #>> '{}')::numeric not between (ranges -> k ->> 0)::numeric and (ranges -> k ->> 1)::numeric then
        perform private.raise_error('invalid_setting_value', 400, p_key || '.' || k);
      end if;
    end loop;
  elsif p_key = 'seo_ai_guides_weekly_cap' then
    if jsonb_typeof(p_value) <> 'number' or (p_value #>> '{}')::numeric <> trunc((p_value #>> '{}')::numeric)
       or (p_value #>> '{}')::numeric not between 0 and 100 then
      perform private.raise_error('invalid_setting_value', 400, p_key);
    end if;
  elsif p_key = 'seo_merge' then
    if jsonb_typeof(p_value) <> 'object'
       or jsonb_typeof(p_value -> 'max_population') <> 'number'
       or jsonb_typeof(p_value -> 'radius_km') <> 'number'
       or jsonb_typeof(p_value -> 'assign_radius_km') <> 'number'
       or (p_value ->> 'max_population')::numeric not between 0 and 10000000
       or (p_value ->> 'radius_km')::numeric not between 0 and 100
       or (p_value ->> 'assign_radius_km')::numeric not between 1 and 200 then
      perform private.raise_error('invalid_setting_value', 400, p_key);
    end if;
  elsif p_key = 'seo_category_meta' then
    if jsonb_typeof(p_value) <> 'object' then
      perform private.raise_error('invalid_setting_value', 400, p_key);
    end if;
    for k, v in select * from jsonb_each(p_value) loop
      if jsonb_typeof(v) <> 'object' or coalesce(v ->> 'kind', '') not in ('product','service')
         or (v ? 'unit' and (jsonb_typeof(v -> 'unit') <> 'string' or length(v ->> 'unit') > 30)) then
        perform private.raise_error('invalid_setting_value', 400, p_key || '.' || k);
      end if;
    end loop;
  end if;
end $$;

create or replace function private.app_settings_validate_seo()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  perform private.validate_seo_setting(new.key, new.value);
  return new;
end $$;

create trigger app_settings_validate_seo before insert or update of value on public.app_settings
  for each row execute function private.app_settings_validate_seo();

-- Seller directory opt-in -------------------------------------------------------------------------
-- Off by default. Only opted-in sellers get a public directory entry (name,
-- city, categories, rating, response time; never contact details or quotes).
alter table public.sellers
  add column if not exists seo_directory_opt_in boolean not null default false,
  add column if not exists seo_directory_opt_in_at timestamptz;

create or replace function public.set_seller_directory_opt_in(p_opt_in boolean)
returns public.sellers
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_seller public.sellers;
begin
  if p_opt_in is null then perform private.raise_error('invalid_opt_in', 400); end if;
  update public.sellers
     set seo_directory_opt_in = p_opt_in,
         seo_directory_opt_in_at = case when p_opt_in then now() else null end
   where id = v_uid
  returning * into v_seller;
  if v_seller.id is null then perform private.raise_error('not_a_seller', 403); end if;
  return v_seller;
end $$;

-- Tables -------------------------------------------------------------------------------------------
-- One row per city (area) x allowed category with at least one quote in the
-- last year; refreshed by every export. Admin-readable.
create table public.seo_pages (
  city_id bigint not null references public.cities(id) on delete cascade,
  category_id bigint not null references public.categories(id) on delete cascade,
  city_slug text not null,
  category_slug text not null,
  path text not null,
  status text not null default 'waiting_for_data' check (status in ('indexable','noindex','waiting_for_data')),
  reasons text[] not null default '{}',
  quotes_window int not null default 0,
  sellers_window int not null default 0,
  local_sellers int not null default 0,
  merged_city_ids bigint[] not null default '{}',
  last_quote_at timestamptz,
  manual_noindex boolean not null default false,
  first_seen_at timestamptz not null default now(),
  indexable_since timestamptz,
  refreshed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (city_id, category_id)
);
create index seo_pages_status_idx on public.seo_pages (status, refreshed_at desc);

create table public.seo_export_runs (
  id bigint generated by default as identity primary key,
  triggered_by text not null default 'cron',
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  country text,
  pages_total int,
  indexable int,
  noindex int,
  waiting_for_data int,
  guides int,
  sellers int,
  storage_path text,
  upload_ok boolean,
  deploy_hook text check (deploy_hook in ('triggered','dry_run','failed','skipped')),
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Buying guides (and later trend articles): written or AI-drafted, always
-- reviewed by a person before going live. Exported when approved (noindex)
-- or published (indexable).
create table public.seo_guides (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and length(slug) <= 100),
  title text not null check (length(trim(title)) between 5 and 140),
  description text check (description is null or length(description) <= 300),
  city_id bigint references public.cities(id) on delete set null,
  category_id bigint not null references public.categories(id) on delete restrict,
  body_md text not null check (length(body_md) between 1 and 50000),
  status text not null default 'draft' check (status in ('draft','approved','published')),
  ai_assisted boolean not null default false,
  author_id uuid references public.profiles(id) on delete set null,
  reviewer_id uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (status = 'draft' or (reviewer_id is not null and reviewed_at is not null)),
  check (status <> 'published' or published_at is not null)
);
create index seo_guides_status_idx on public.seo_guides (status, updated_at desc);
create index seo_guides_ai_created_idx on public.seo_guides (created_at) where ai_assisted;

do $$
declare t text;
begin
  foreach t in array array['seo_pages','seo_export_runs','seo_guides'] loop
    perform private.add_updated_at_trigger(('public.' || t)::regclass);
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from public, anon, authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
    execute format('grant all on public.%I to service_role', t);
    execute format('create policy %I on public.%I for select to authenticated using (private.is_admin())',
                   t || '_admin_read', t);
  end loop;
end $$;
grant usage, select on sequence public.seo_export_runs_id_seq to service_role;

-- Helpers ------------------------------------------------------------------------------------------
create or replace function private.seo_slugify(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(trim(both '-' from regexp_replace(lower(coalesce(p_text, '')), '[^a-z0-9]+', '-', 'g')), '')
$$;

-- Stable, unique, URL-safe slug per city (name, then -<state code>, then -<id>).
create or replace function private.seo_city_slugs()
returns table (city_id bigint, slug text)
language sql
stable
security definer
set search_path = ''
as $$
  with base as (
    select c.id,
           coalesce(private.seo_slugify(c.slug), private.seo_slugify(coalesce(c.ascii_name, c.name)), 'city') as b,
           private.seo_slugify(coalesce(c.state_code, c.state)) as st
      from public.cities c
  ), lvl1 as (
    select id, b, st, count(*) over (partition by b) as n from base
  ), lvl2 as (
    select id, case when n = 1 then b else b || coalesce('-' || st, '') end as s from lvl1
  )
  select id, case when count(*) over (partition by s) = 1 then s else s || '-' || id end from lvl2
$$;

-- "Nice" rounding of a major-unit amount so a published figure never equals
-- one seller's exact quote: <100 -> 1, <1k -> 5, <10k -> 10, <100k -> 100, else 1000.
create or replace function private.seo_round_price(p_major numeric)
returns bigint
language sql
immutable
set search_path = ''
as $$
  select case
    when p_major is null then null
    when p_major < 100 then round(p_major)
    when p_major < 1000 then round(p_major / 5) * 5
    when p_major < 10000 then round(p_major / 10) * 10
    when p_major < 100000 then round(p_major / 100) * 100
    else round(p_major / 1000) * 1000 end::bigint
$$;

create or replace function private.seo_thresholds()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select '{"min_quotes":10,"min_sellers":3,"window_days":90,"stale_days":90}'::jsonb
         || coalesce((select value from public.app_settings where key = 'seo_thresholds'
                       and jsonb_typeof(value) = 'object'), '{}'::jsonb)
$$;

-- The export ------------------------------------------------------------------------------------------
-- Service role only (seo-export Edge Function). Computes every page, writes
-- seo_pages and a seo_export_runs row (unless p_dry_run) and returns
--   {"run_id": n | null, "country": "usa"|"india", "data": SeoData}
-- p_now is for tests; production calls use now().
create or replace function public.seo_export(
  p_triggered_by text default 'cron', p_dry_run boolean default false, p_now timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  t jsonb := private.seo_thresholds();
  v_min_q int := (t ->> 'min_quotes')::int;
  v_min_s int := (t ->> 'min_sellers')::int;
  v_window int := (t ->> 'window_days')::int;
  v_stale int := (t ->> 'stale_days')::int;
  v_merge jsonb := coalesce(private.setting('seo_merge'), '{}'::jsonb);
  v_max_pop bigint := coalesce((v_merge ->> 'max_population')::bigint, 50000);
  v_merge_m float8 := coalesce((v_merge ->> 'radius_km')::float8, 25) * 1000;
  v_assign_m float8 := coalesce((v_merge ->> 'assign_radius_km')::float8, 40) * 1000;
  v_meta jsonb := coalesce(private.setting('seo_category_meta'), '{}'::jsonb);
  v_cc text := private.setting_text('country', 'IN');
  v_country text := case when upper(v_cc) in ('US','USA') then 'usa' else 'india' end;
  v_currency text := private.setting_text('currency', case when v_country = 'usa' then 'USD' else 'INR' end);
  v_from timestamptz := p_now - make_interval(days => v_window);
  v_lookback timestamptz := p_now - interval '365 days';
  v_run bigint;
  v_pages jsonb;
  v_cities jsonb;
  v_categories jsonb;
  v_guides jsonb;
  v_sellers jsonb;
  v_data jsonb;
  v_tmp text;
begin
  -- temp tables of an earlier call in the same transaction (tests)
  for v_tmp in select unnest(array['_q','_area','_slug','_qa','_p','_stats','_status']) loop
    if to_regclass('pg_temp.' || v_tmp) is not null then execute format('drop table pg_temp.%I', v_tmp); end if;
  end loop;
  -- 1. Quotes that count: real (not hidden / withdrawn), this project's
  --    currency, allowed + active category, no review / demo-store accounts,
  --    no banned or deleted seller. Price per unit: USA pre-tax subtotal,
  --    India tax-inclusive (total - delivery), divided by the request quantity.
  create temp table _q on commit drop as
  select q.id, q.seller_id, q.created_at, r.category_id,
         coalesce(near.id, byname.id) as city_id,
         ((case when v_country = 'usa' then q.subtotal_minor else q.total_minor - q.delivery_minor end)::numeric
           / case when r.fields ->> 'quantity' ~ '^[0-9]+(\.[0-9]+)?$'
                  then greatest((r.fields ->> 'quantity')::numeric, 1) else 1 end) / 100.0 as price_major,
         q.response_mins,
         case when q.delivery_date is not null and q.delivery_date - q.created_at::date between 0 and 365
              then q.delivery_date - q.created_at::date end as delivery_days,
         nullif(regexp_replace(lower(trim(q.offered_brand_model)), '\s+', ' ', 'g'), '') as model_key,
         nullif(trim(q.offered_brand_model), '') as model_raw
    from public.quotes q
    join public.requests r on r.id = q.request_id
    join public.categories cat on cat.id = r.category_id and cat.policy = 'allowed' and cat.active
    join public.sellers s on s.id = q.seller_id and not s.hidden
    join public.profiles sp on sp.id = q.seller_id and sp.status not in ('banned','deleted') and not sp.is_review_account
    join public.profiles bp on bp.id = r.buyer_id and not bp.is_review_account
    left join lateral (
      select c.id from public.cities c
       where r.location is not null and c.centroid is not null
         and st_dwithin(c.centroid, r.location, v_assign_m)
       order by c.centroid <-> r.location limit 1) near on true
    left join lateral (
      select c.id from public.cities c
       where r.location is null and r.city is not null and lower(c.name) = lower(r.city)
         and (r.state is null or c.state is null or lower(c.state) = lower(r.state))
       order by c.population desc nulls last limit 1) byname on true
   where q.status <> 'withdrawn' and not q.hidden and not r.hidden
     and q.currency = v_currency
     and q.created_at >= v_lookback and q.created_at < p_now;
  delete from _q where city_id is null;

  -- 2. Small-town merge: a town below max_population shares the page of the
  --    nearest city of at least max_population within radius_km.
  create temp table _area on commit drop as
  select c.id as city_id, coalesce(m.id, c.id) as area_id
    from public.cities c
    left join lateral (
      select b.id from public.cities b
       where c.population is not null and c.population < v_max_pop and v_merge_m > 0
         and b.id <> c.id and b.population >= v_max_pop and b.centroid is not null and c.centroid is not null
         and st_dwithin(b.centroid, c.centroid, v_merge_m)
       order by b.centroid <-> c.centroid limit 1) m on true
   where c.id in (select distinct city_id from _q);

  create temp table _slug on commit drop as select * from private.seo_city_slugs();

  create temp table _qa on commit drop as
  select q.*, a.area_id, q.created_at >= v_from as in_window
    from _q q join _area a on a.city_id = q.city_id;

  -- 3. One row per area x category.
  create temp table _p on commit drop as
  with agg as (
    select area_id, category_id,
           count(*) filter (where in_window)::int as quotes_window,
           count(distinct seller_id) filter (where in_window)::int as sellers_window,
           max(created_at) as last_quote,
           array_agg(distinct city_id) filter (where city_id <> area_id) as merged
      from _qa group by area_id, category_id
  )
  select a.*,
         (a.quotes_window >= v_min_q and a.sellers_window >= v_min_s) as gates_met,
         date_trunc('day', a.last_quote) as last_quote_day,
         ls.n as local_sellers
    from agg a
    join public.cities c on c.id = a.area_id
    left join lateral (
      select count(distinct s.id)::int as n
        from public.sellers s
        join public.seller_categories sc on sc.seller_id = s.id and sc.category_id = a.category_id
        join public.profiles p on p.id = s.id and p.status = 'active' and not p.is_review_account
       where not s.hidden and c.centroid is not null
         and ((s.area_type = 'radius' and s.center is not null
               and st_dwithin(s.center, c.centroid, greatest(s.radius_km * 1000, 25000)::float8))
              or (s.area_type = 'codes' and exists (
                    select 1 from public.postal_codes pc
                     where pc.code = any(s.service_codes) and pc.centroid is not null
                       and st_dwithin(pc.centroid, c.centroid, 25000))))) ls on true;

  -- 4. Stats (only for rows that pass the data gates).
  create temp table _stats on commit drop as
  select p.area_id, p.category_id,
         st.p25, st.p50, st.p75, st.resp_h, st.deliv_d, tr.pct as trend_pct, tm.models
    from _p p
    cross join lateral (
      select percentile_cont(0.25) within group (order by price_major) as p25,
             percentile_cont(0.5) within group (order by price_major) as p50,
             percentile_cont(0.75) within group (order by price_major) as p75,
             case when count(response_mins) >= 3
                  then round((percentile_cont(0.5) within group (order by response_mins) / 60.0)::numeric, 1) end as resp_h,
             case when count(delivery_days) >= 3
                  then round(percentile_cont(0.5) within group (order by delivery_days)::numeric) end as deliv_d
        from _qa x where x.area_id = p.area_id and x.category_id = p.category_id and x.in_window) st
    left join lateral (
      select round(((cur.m - prev.m) / prev.m * 100)::numeric, 1) as pct
        from (select percentile_cont(0.5) within group (order by price_major) m, count(*) n, count(distinct seller_id) s
                from _qa x where x.area_id = p.area_id and x.category_id = p.category_id
                 and x.created_at >= p_now - interval '30 days') cur,
             (select percentile_cont(0.5) within group (order by price_major) m, count(*) n, count(distinct seller_id) s
                from _qa x where x.area_id = p.area_id and x.category_id = p.category_id
                 and x.created_at >= p_now - interval '60 days' and x.created_at < p_now - interval '30 days') prev
       where cur.n >= 5 and prev.n >= 5 and cur.s >= 2 and prev.s >= 2 and prev.m > 0) tr on true
    left join lateral (
      select jsonb_agg(jsonb_build_object('name', name, 'quotes', n) order by n desc, name) as models
        from (select mode() within group (order by model_raw) as name, count(*)::int as n
                from _qa x where x.area_id = p.area_id and x.category_id = p.category_id and x.in_window
                 and x.model_key is not null
               group by x.model_key
              having count(distinct x.seller_id) >= v_min_s
               order by count(*) desc, x.model_key limit 5) mm) tm on true
   where p.gates_met;

  -- 5. Page rows for the site (rows with no quote in the window are left out:
  --    the site would skip them anyway).
  select coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
           'city', sl.slug,
           'category', cat.slug,
           'quotes_window', p.quotes_window,
           'sellers_window', p.sellers_window,
           'local_sellers', p.local_sellers,
           'last_quote_at', to_char(p.last_quote_day at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
           'period', jsonb_build_object('from', to_char(v_from at time zone 'UTC', 'YYYY-MM-DD'),
                                        'to', to_char(p_now at time zone 'UTC', 'YYYY-MM-DD')),
           'price', case when st.p50 is not null and private.seo_round_price(st.p25::numeric) > 0
                         then jsonb_build_object('median', private.seo_round_price(st.p50::numeric),
                                                 'p25', private.seo_round_price(st.p25::numeric),
                                                 'p75', greatest(private.seo_round_price(st.p75::numeric),
                                                                 private.seo_round_price(st.p25::numeric))) end,
           'median_response_hours', st.resp_h,
           'median_delivery_days', st.deliv_d,
           'trend_pct_vs_last_month', st.trend_pct,
           'top_models', st.models,
           'manual_noindex', case when sp.manual_noindex then true end))
         order by sl.slug, cat.slug), '[]'::jsonb)
    into v_pages
    from _p p
    join _slug sl on sl.city_id = p.area_id
    join public.categories cat on cat.id = p.category_id
    left join _stats st on st.area_id = p.area_id and st.category_id = p.category_id
    left join public.seo_pages sp on sp.city_id = p.area_id and sp.category_id = p.category_id
   where p.quotes_window > 0;

  -- 6. Cities: every area with a page, plus the towns merged into it.
  select coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
           'slug', sl.slug, 'name', c.name, 'state', coalesce(c.state, ''), 'population', c.population,
           'merge_into', case when a.area_id is not null and a.area_id <> c.id then asl.slug end))
         order by c.population desc nulls last, sl.slug), '[]'::jsonb)
    into v_cities
    from public.cities c
    join _slug sl on sl.city_id = c.id
    left join _area a on a.city_id = c.id
    left join _slug asl on asl.city_id = a.area_id
   where c.id in (select area_id from _p where quotes_window > 0)
      or (a.area_id <> c.id and a.area_id in (select area_id from _p where quotes_window > 0));

  -- 7. Categories: every active leaf category with its policy (the site only
  --    builds pages for "allowed").
  select coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
           'slug', c.slug,
           'name', c.names ->> 'en',
           'group', coalesce(par.names ->> 'en', c.names ->> 'en'),
           'kind', coalesce(v_meta -> c.slug ->> 'kind',
                            case when par.slug in ('home-services','events') then 'service' else 'product' end),
           'policy', c.policy,
           -- prices are per unit of the request quantity (step 1): label bulk
           -- categories, where the quantity field is required
           'unit', coalesce(v_meta -> c.slug ->> 'unit',
                            case when jsonb_typeof(c.field_schema -> 'fields') = 'array' and exists (
                                        select 1 from jsonb_array_elements(c.field_schema -> 'fields') f
                                         where f ->> 'key' = 'quantity' and f ->> 'required' = 'true') then 'per item'
                                 when v_meta -> c.slug is null and par.slug = 'home-services' then 'per job' end)))
         order by coalesce(par.sort, c.sort), par.id nulls first, c.sort, c.slug), '[]'::jsonb)
    into v_categories
    from public.categories c
    left join public.categories par on par.id = c.parent_id
   where c.active and private.seo_slugify(c.slug) = c.slug
     and not exists (select 1 from public.categories ch where ch.parent_id = c.id and ch.active);

  -- 8. Guides: approved (noindex) and published (indexable) only.
  select coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
           'slug', g.slug, 'title', g.title, 'description', g.description,
           'city', gsl.slug, 'city_name', gc.name, 'category', cat.slug,
           'status', g.status, 'ai_assisted', g.ai_assisted, 'body_md', g.body_md,
           'reviewed_at', to_char(g.reviewed_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
           'published_at', to_char(g.published_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
           'updated_at', to_char(g.updated_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')))
         order by g.published_at desc nulls last, g.slug), '[]'::jsonb)
    into v_guides
    from public.seo_guides g
    join public.categories cat on cat.id = g.category_id and cat.policy <> 'blocked'
    left join public.cities gc0 on gc0.id = g.city_id
    left join lateral (
      select b.id from public.cities b
       where gc0.population is not null and gc0.population < v_max_pop and v_merge_m > 0
         and b.id <> gc0.id and b.population >= v_max_pop and b.centroid is not null and gc0.centroid is not null
         and st_dwithin(b.centroid, gc0.centroid, v_merge_m)
       order by b.centroid <-> gc0.centroid limit 1) gm on true
    left join public.cities gc on gc.id = coalesce(gm.id, gc0.id)
    left join _slug gsl on gsl.city_id = gc.id
   where g.status in ('approved','published');

  -- 9. Seller directory: opted-in sellers only. No contact details, no quotes.
  select coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
           'slug', coalesce(private.seo_slugify(s.slug), private.seo_slugify(s.business_name || '-' || left(s.id::text, 6))),
           'name', s.business_name,
           'description', left(s.description, 500),
           'city', ssl.slug,
           'city_name', sc.name,
           'categories', (select coalesce(jsonb_agg(c.slug order by c.slug), '[]'::jsonb)
                            from public.seller_categories x join public.categories c on c.id = x.category_id
                           where x.seller_id = s.id and c.policy = 'allowed' and c.active),
           'verified', s.verification_status = 'verified',
           'years_in_business', s.years_in_business,
           'rating', case when s.rating_count >= 3 then round(s.rating_avg, 1) end,
           'rating_count', case when s.rating_count >= 3 then s.rating_count end,
           'median_response_hours', case when s.quotes_sent >= 5 and s.avg_response_mins is not null
                                         then round(s.avg_response_mins / 60.0, 1) end))
         order by s.business_name), '[]'::jsonb)
    into v_sellers
    from public.sellers s
    join public.profiles p on p.id = s.id and p.status = 'active' and not p.is_review_account
    left join lateral (
      select c.id from public.cities c
       where s.center is not null and c.centroid is not null and st_dwithin(c.centroid, s.center, v_assign_m)
       order by c.centroid <-> s.center limit 1) sn on true
    left join lateral (
      select c.id from public.cities c
       where s.center is null and s.city is not null and lower(c.name) = lower(s.city)
       order by c.population desc nulls last limit 1) sb on true
    left join lateral (
      select b.id from public.cities b, public.cities t0
       where t0.id = coalesce(sn.id, sb.id) and t0.population is not null and t0.population < v_max_pop
         and v_merge_m > 0 and b.id <> t0.id and b.population >= v_max_pop
         and b.centroid is not null and t0.centroid is not null and st_dwithin(b.centroid, t0.centroid, v_merge_m)
       order by b.centroid <-> t0.centroid limit 1) sm on true
    left join public.cities sc on sc.id = coalesce(sm.id, sn.id, sb.id)
    left join _slug ssl on ssl.city_id = sc.id
   where s.seo_directory_opt_in and not s.hidden;

  v_data := jsonb_build_object(
    'country', v_country,
    'generated_at', to_char(p_now at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'source', 'supabase:seo_export',
    'thresholds', t,
    'categories', v_categories,
    'cities', v_cities,
    'pages', v_pages,
    'guides', v_guides,
    'sellers', v_sellers);

  if p_dry_run then
    return jsonb_build_object('run_id', null, 'country', v_country, 'data', v_data);
  end if;

  -- 10. Refresh seo_pages (status mirrors the site's gates in lib/seo.ts).
  create temp table _status on commit drop as
  select p.area_id, p.category_id, sl.slug as city_slug, cat.slug as category_slug,
         p.quotes_window, p.sellers_window, coalesce(p.local_sellers, 0) as local_sellers,
         coalesce(p.merged, '{}') as merged, p.last_quote_day,
         array_remove(array[
           case when p.quotes_window = 0 then 'no quotes in the last ' || v_window || ' days' end,
           case when p.quotes_window > 0 and not p.gates_met
                then format('below threshold (%s quotes / %s sellers; need %s / %s)',
                            p.quotes_window, p.sellers_window, v_min_q, v_min_s) end,
           case when p.gates_met and (st.p50 is null or private.seo_round_price(st.p25::numeric) <= 0)
                then 'no median price' end,
           case when p.last_quote_day < p_now - make_interval(days => v_stale)
                then 'stale (no quotes in ' || v_stale || ' days)' end,
           case when sp.manual_noindex then 'manually set to noindex' end], null) as reasons,
         coalesce(sp.manual_noindex, false) as manual_noindex,
         p.gates_met
    from _p p
    join _slug sl on sl.city_id = p.area_id
    join public.categories cat on cat.id = p.category_id
    left join _stats st on st.area_id = p.area_id and st.category_id = p.category_id
    left join public.seo_pages sp on sp.city_id = p.area_id and sp.category_id = p.category_id;

  insert into public.seo_pages as sp (city_id, category_id, city_slug, category_slug, path, status, reasons,
                                      quotes_window, sellers_window, local_sellers, merged_city_ids,
                                      last_quote_at, indexable_since, refreshed_at)
  select s.area_id, s.category_id, s.city_slug, s.category_slug,
         '/quotes/' || s.city_slug || '/' || s.category_slug,
         case when cardinality(s.reasons) = 0 then 'indexable'
              when s.quotes_window = 0 or not s.gates_met then 'waiting_for_data'
              else 'noindex' end,
         s.reasons, s.quotes_window, s.sellers_window, s.local_sellers, s.merged, s.last_quote_day,
         case when cardinality(s.reasons) = 0 then p_now end, p_now
    from _status s
  on conflict (city_id, category_id) do update set
    city_slug = excluded.city_slug, category_slug = excluded.category_slug, path = excluded.path,
    status = excluded.status, reasons = excluded.reasons, quotes_window = excluded.quotes_window,
    sellers_window = excluded.sellers_window, local_sellers = excluded.local_sellers,
    merged_city_ids = excluded.merged_city_ids, last_quote_at = excluded.last_quote_at,
    indexable_since = case when excluded.status = 'indexable' then coalesce(sp.indexable_since, excluded.indexable_since) end,
    refreshed_at = excluded.refreshed_at;

  -- pages without any quote in the last year disappear (manual flags are kept, zeroed)
  delete from public.seo_pages sp
   where not sp.manual_noindex
     and not exists (select 1 from _status s where s.area_id = sp.city_id and s.category_id = sp.category_id);
  update public.seo_pages sp
     set status = 'waiting_for_data', reasons = array['no quotes in the last 365 days', 'manually set to noindex'],
         quotes_window = 0, sellers_window = 0, indexable_since = null, refreshed_at = p_now
   where sp.manual_noindex
     and not exists (select 1 from _status s where s.area_id = sp.city_id and s.category_id = sp.category_id);

  insert into public.seo_export_runs (triggered_by, started_at, country, pages_total, indexable, noindex,
                                      waiting_for_data, guides, sellers)
  select left(coalesce(p_triggered_by, 'cron'), 80), p_now, v_country, count(*),
         count(*) filter (where status = 'indexable'), count(*) filter (where status = 'noindex'),
         count(*) filter (where status = 'waiting_for_data'),
         jsonb_array_length(v_guides), jsonb_array_length(v_sellers)
    from public.seo_pages
  returning id into v_run;

  return jsonb_build_object('run_id', v_run, 'country', v_country, 'data', v_data);
end $$;

-- Called by seo-export after the upload / deploy hook.
create or replace function public.seo_finish_export(
  p_run_id bigint, p_storage_path text, p_upload_ok boolean, p_deploy_hook text, p_error text default null)
returns public.seo_export_runs
language plpgsql
security definer
set search_path = ''
as $$
declare v public.seo_export_runs;
begin
  update public.seo_export_runs
     set finished_at = now(), storage_path = p_storage_path, upload_ok = p_upload_ok,
         deploy_hook = p_deploy_hook, error = left(p_error, 2000)
   where id = p_run_id returning * into v;
  if v.id is null then perform private.raise_error('run_not_found', 404); end if;
  return v;
end $$;

-- Admin: pages ----------------------------------------------------------------------------------------
create or replace function public.admin_set_seo_page_noindex(p_city_id bigint, p_category_id bigint, p_noindex boolean)
returns public.seo_pages
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v public.seo_pages;
begin
  update public.seo_pages
     set manual_noindex = coalesce(p_noindex, false),
         status = case when coalesce(p_noindex, false) and status = 'indexable' then 'noindex' else status end,
         reasons = case when coalesce(p_noindex, false)
                        then array_append(array_remove(reasons, 'manually set to noindex'), 'manually set to noindex')
                        else array_remove(reasons, 'manually set to noindex') end
   where city_id = p_city_id and category_id = p_category_id
  returning * into v;
  if v.city_id is null then perform private.raise_error('seo_page_not_found', 404); end if;
  perform private.audit('admin_set_seo_page_noindex', 'seo_page', v.path,
    jsonb_build_object('noindex', p_noindex));
  return v;
end $$;

-- Admin: guides -----------------------------------------------------------------------------------------
-- Creates (p_id null) or edits a guide. Any content edit sends an approved or
-- published guide back to draft (it needs a new review). New AI-assisted
-- guides are capped per rolling 7 days (seo_ai_guides_weekly_cap).
create or replace function public.admin_upsert_seo_guide(
  p_id uuid, p_slug text, p_title text, p_category_id bigint, p_body_md text,
  p_city_id bigint default null, p_description text default null, p_ai_assisted boolean default false)
returns public.seo_guides
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v public.seo_guides;
  v_old public.seo_guides;
  v_cap int := private.setting_int('seo_ai_guides_weekly_cap', 10);
  v_recent int;
  v_slug text := lower(trim(coalesce(p_slug, '')));
begin
  if v_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' then perform private.raise_error('invalid_slug', 400); end if;
  if not exists (select 1 from public.categories where id = p_category_id and policy <> 'blocked') then
    perform private.raise_error('invalid_category', 400);
  end if;
  if p_city_id is not null and not exists (select 1 from public.cities where id = p_city_id) then
    perform private.raise_error('invalid_city', 400);
  end if;

  if p_id is null then
    if coalesce(p_ai_assisted, false) then
      select count(*) into v_recent from public.seo_guides
       where ai_assisted and created_at > now() - interval '7 days';
      if v_recent >= v_cap then
        perform private.raise_error('ai_guide_weekly_cap', 429, format('%s of %s this week', v_recent, v_cap));
      end if;
    end if;
    insert into public.seo_guides (slug, title, description, city_id, category_id, body_md, ai_assisted, author_id)
    values (v_slug, trim(p_title), nullif(trim(p_description), ''), p_city_id, p_category_id, p_body_md,
            coalesce(p_ai_assisted, false), v_admin)
    returning * into v;
    perform private.audit('admin_create_seo_guide', 'seo_guide', v.id::text,
      jsonb_build_object('slug', v.slug, 'ai_assisted', v.ai_assisted));
  else
    select * into v_old from public.seo_guides where id = p_id for update;
    if v_old.id is null then perform private.raise_error('guide_not_found', 404); end if;
    if coalesce(p_ai_assisted, false) and not v_old.ai_assisted then
      perform private.raise_error('ai_flag_cannot_be_added', 400, 'create a new AI-assisted guide instead');
    end if;
    update public.seo_guides set
      slug = v_slug, title = trim(p_title), description = nullif(trim(p_description), ''),
      city_id = p_city_id, category_id = p_category_id, body_md = p_body_md,
      -- AI-assisted stays AI-assisted (the flag can only be removed by an
      -- explicit false when the text was fully rewritten by a person)
      ai_assisted = coalesce(p_ai_assisted, v_old.ai_assisted),
      status = 'draft', reviewer_id = null, reviewed_at = null, published_at = null
    where id = p_id returning * into v;
    perform private.audit('admin_edit_seo_guide', 'seo_guide', v.id::text,
      jsonb_build_object('slug', v.slug, 'from_status', v_old.status, 'ai_assisted', v.ai_assisted));
  end if;
  return v;
end $$;

-- p_action: approve (draft -> approved: records reviewer + date),
-- publish (approved -> published), unpublish (published -> approved),
-- reject (any -> draft, clears the review).
create or replace function public.admin_review_seo_guide(p_id uuid, p_action text)
returns public.seo_guides
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v public.seo_guides;
  v_old public.seo_guides;
begin
  select * into v_old from public.seo_guides where id = p_id for update;
  if v_old.id is null then perform private.raise_error('guide_not_found', 404); end if;
  if p_action = 'approve' then
    if v_old.status <> 'draft' then perform private.raise_error('invalid_transition', 409); end if;
    update public.seo_guides set status = 'approved', reviewer_id = v_admin, reviewed_at = now()
     where id = p_id returning * into v;
  elsif p_action = 'publish' then
    if v_old.status <> 'approved' then perform private.raise_error('guide_not_approved', 409); end if;
    update public.seo_guides set status = 'published', published_at = coalesce(published_at, now())
     where id = p_id returning * into v;
  elsif p_action = 'unpublish' then
    if v_old.status <> 'published' then perform private.raise_error('invalid_transition', 409); end if;
    update public.seo_guides set status = 'approved', published_at = null where id = p_id returning * into v;
  elsif p_action = 'reject' then
    update public.seo_guides set status = 'draft', reviewer_id = null, reviewed_at = null, published_at = null
     where id = p_id returning * into v;
  else
    perform private.raise_error('invalid_action', 400);
  end if;
  perform private.audit('admin_review_seo_guide', 'seo_guide', p_id::text,
    jsonb_build_object('action', p_action, 'from', v_old.status, 'to', v.status, 'slug', v.slug,
                       'ai_assisted', v.ai_assisted));
  return v;
end $$;

-- Grants ------------------------------------------------------------------------------------------------
revoke all on function private.validate_seo_setting(text, jsonb), private.app_settings_validate_seo(),
  private.seo_slugify(text), private.seo_city_slugs(), private.seo_round_price(numeric), private.seo_thresholds()
  from public, anon, authenticated;
revoke all on function public.seo_export(text, boolean, timestamptz),
  public.seo_finish_export(bigint, text, boolean, text, text),
  public.set_seller_directory_opt_in(boolean),
  public.admin_set_seo_page_noindex(bigint, bigint, boolean),
  public.admin_upsert_seo_guide(uuid, text, text, bigint, text, bigint, text, boolean),
  public.admin_review_seo_guide(uuid, text)
  from public, anon, authenticated;
grant execute on function public.seo_export(text, boolean, timestamptz),
  public.seo_finish_export(bigint, text, boolean, text, text) to service_role;
grant execute on function public.set_seller_directory_opt_in(boolean),
  public.admin_set_seo_page_noindex(bigint, bigint, boolean),
  public.admin_upsert_seo_guide(uuid, text, text, bigint, text, bigint, text, boolean),
  public.admin_review_seo_guide(uuid, text) to authenticated, service_role;
