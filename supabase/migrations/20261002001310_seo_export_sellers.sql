-- 1310 SEO export: richer seller directory entries (Section 21.9).
--
-- public.seo_export() is redefined with the same body as migration 1100 except step 9, the
-- seller directory, whose entries gain:
--   id                the seller id (public directory pages link to the app's seller profile),
--   completed_orders  orders with status 'completed',
--   review_count      visible buyer-to-seller reviews,
-- and whose slug is now unique per city in the export (a collision gets "-" + the first 6
-- characters of the seller id; if that still collides, the full id without dashes).
-- Still service-role only and still opted-in, active, non-hidden, non-review sellers only.
set search_path = public, extensions;

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
  --    (1310) adds the seller id, completed orders and visible buyer reviews, and makes the
  --    slug unique per city: a collision gets "-" + the first 6 characters of the id, and a
  --    collision that remains after that gets the full id (ids are unique).
  with dir as (
    select s.id, s.business_name, s.description, s.verification_status, s.years_in_business,
           s.rating_count, s.rating_avg, s.quotes_sent, s.avg_response_mins, s.created_at,
           ssl.slug as city_slug, sc.name as city_name,
           coalesce(private.seo_slugify(s.slug), private.seo_slugify(s.business_name || '-' || left(s.id::text, 6))) as base_slug
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
     where s.seo_directory_opt_in and not s.hidden
  ), pass1 as (
    select d.*,
           case when row_number() over (partition by d.city_slug, d.base_slug order by d.created_at, d.id) = 1
                then d.base_slug else d.base_slug || '-' || left(d.id::text, 6) end as slug1
      from dir d
  ), pass2 as (
    select x.*,
           case when count(*) over (partition by x.city_slug, x.slug1) = 1
                  or row_number() over (partition by x.city_slug, x.slug1 order by (x.slug1 = x.base_slug) desc, x.created_at, x.id) = 1
                then x.slug1 else x.base_slug || '-' || replace(x.id::text, '-', '') end as slug
      from pass1 x
  )
  select coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
           'id', d.id,
           'slug', d.slug,
           'name', d.business_name,
           'description', left(d.description, 500),
           'city', d.city_slug,
           'city_name', d.city_name,
           'categories', (select coalesce(jsonb_agg(c.slug order by c.slug), '[]'::jsonb)
                            from public.seller_categories x join public.categories c on c.id = x.category_id
                           where x.seller_id = d.id and c.policy = 'allowed' and c.active),
           'verified', d.verification_status = 'verified',
           'years_in_business', d.years_in_business,
           'completed_orders', (select count(*)::int from public.orders o
                                 where o.seller_id = d.id and o.status = 'completed'),
           'review_count', (select count(*)::int from public.reviews rv
                             where rv.to_id = d.id and rv.role = 'buyer_to_seller' and not rv.hidden),
           'rating', case when d.rating_count >= 3 then round(d.rating_avg, 1) end,
           'rating_count', case when d.rating_count >= 3 then d.rating_count end,
           'median_response_hours', case when d.quotes_sent >= 5 and d.avg_response_mins is not null
                                         then round(d.avg_response_mins / 60.0, 1) end))
         order by d.business_name, d.id), '[]'::jsonb)
    into v_sellers
    from pass2 d;

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

revoke all on function public.seo_export(text, boolean, timestamptz) from public, anon, authenticated;
grant execute on function public.seo_export(text, boolean, timestamptz) to service_role;
