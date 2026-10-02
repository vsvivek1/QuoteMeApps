-- 0710 Requests (buyer), keyword classifier, lead feed (seller).
set search_path = public, extensions;

-- Keyword classifier --------------------------------------------------------------------------
create or replace function private.normalize_text(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
  select lower(regexp_replace(trim(coalesce(p_text, '')), '\s+', ' ', 'g'))
$$;

create or replace function private.regex_escape(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
  select regexp_replace(p_text, '([.^$*+?()\[\]{}|\\-])', '\\\1', 'g')
$$;

-- First active 'block' keyword found in the text (whole-word match), if any.
create or replace function private.find_blocked_keyword(p_text text,
  out keyword text, out category_id bigint, out reason jsonb)
language sql
stable
security definer
set search_path = ''
as $$
  select k.keyword, k.category_id, coalesce(k.reason, c.policy_reason)
    from public.category_keywords k
    left join public.categories c on c.id = k.category_id
   where k.active and k.action = 'block'
     -- a keyword tied to a category only blocks while that category is blocked
     -- (so flipping e.g. insurance to 'restricted' in the admin panel also
     -- lifts its keywords)
     and (k.category_id is null or (select cp.policy from private.category_policy(k.category_id) cp) = 'blocked')
     and private.normalize_text(p_text) ~
         ('(^|[^[:alnum:]])' || private.regex_escape(private.normalize_text(k.keyword)) || '($|[^[:alnum:]])')
   order by length(k.keyword) desc
   limit 1
$$;

-- Category suggestions for free text (request wizard step 1).
create or replace function public.classify_request_text(p_text text, p_limit int default 5)
returns table (category_id bigint, slug text, names jsonb, parent_id bigint,
               policy text, score real, blocked boolean, reason jsonb)
language plpgsql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
#variable_conflict use_column
declare
  v_text text := private.normalize_text(p_text);
  b record;
begin
  select * into b from private.find_blocked_keyword(v_text);
  if b.keyword is not null then
    return query
      select c.id, c.slug, c.names, c.parent_id, 'blocked'::text, 1::real, true,
             coalesce(b.reason, jsonb_build_object('en', 'This kind of request is not allowed in this app.'))
        from (select 1) one
        left join public.categories c on c.id = b.category_id;
    return;
  end if;

  return query
  with leaf as (
    select c.*, p.names as parent_names
      from public.categories c
      left join public.categories p on p.id = c.parent_id
     where c.active
       and not exists (select 1 from public.categories ch where ch.parent_id = c.id and ch.active)
  ), scored as (
    select l.id, l.slug, l.names, l.parent_id,
           (select policy from private.category_policy(l.id)) as pol,
           greatest(
             -- any keyword hit scores >= 0.5; longer / more hits rank higher
             coalesce((select case when count(*) = 0 then 0 else least(1.0, 0.5 + 0.05 * sum(length(kw))) end
                         from unnest(l.keywords) kw
                        where v_text ~ ('(^|[^[:alnum:]])' || private.regex_escape(lower(kw)) || '($|[^[:alnum:]])')), 0),
             coalesce((select max(word_similarity(lower(n.value), v_text)) from jsonb_each_text(l.names) n), 0) * 0.8
           )::real as sc
      from leaf l
  )
  select s.id, s.slug, s.names, s.parent_id, s.pol, s.sc, s.pol = 'blocked', null::jsonb
    from scored s
   where s.sc >= 0.3
   order by s.sc desc, s.slug
   limit greatest(1, least(p_limit, 20));
end $$;

-- Validates request fields against the leaf category's field_schema:
-- {"fields":[{"key","type":"text|number|select|multiselect|boolean|date",
--   "required":bool,"scope":"request|quote|both","options":[{"value",...}],"min","max"}]}
create or replace function private.validate_fields(p_schema jsonb, p_fields jsonb, p_scope text)
returns void
language plpgsql
immutable
set search_path = ''
as $$
declare
  f jsonb;
  v jsonb;
  k text;
begin
  if p_schema is null or p_schema->'fields' is null then return; end if;
  if p_fields is not null and jsonb_typeof(p_fields) <> 'object' then
    raise exception using errcode = 'PT400', message = 'invalid_fields', detail = 'fields must be an object';
  end if;
  for f in select * from jsonb_array_elements(p_schema->'fields') loop
    if coalesce(f->>'scope', 'both') not in (p_scope, 'both') then continue; end if;
    k := f->>'key';
    v := p_fields->k;
    if v is null or v = 'null'::jsonb or v = '""'::jsonb then
      -- 'both' fields are required on the request; on the quote they are
      -- optional (the seller may confirm them), quote-only fields are required.
      if coalesce((f->>'required')::boolean, false)
         and (p_scope = 'request' or coalesce(f->>'scope', 'both') = p_scope) then
        raise exception using errcode = 'PT400', message = 'missing_required_field', detail = k;
      end if;
      continue;
    end if;
    case f->>'type'
      when 'number' then
        if jsonb_typeof(v) <> 'number'
           or (f ? 'min' and (v #>> '{}')::numeric < (f->>'min')::numeric)
           or (f ? 'max' and (v #>> '{}')::numeric > (f->>'max')::numeric) then
          raise exception using errcode = 'PT400', message = 'invalid_field_value', detail = k;
        end if;
      when 'select' then
        if not exists (select 1 from jsonb_array_elements(f->'options') o where o->>'value' = v #>> '{}') then
          raise exception using errcode = 'PT400', message = 'invalid_field_value', detail = k;
        end if;
      when 'multiselect' then
        if jsonb_typeof(v) <> 'array' or exists (
             select 1 from jsonb_array_elements_text(v) x
              where not exists (select 1 from jsonb_array_elements(f->'options') o where o->>'value' = x)) then
          raise exception using errcode = 'PT400', message = 'invalid_field_value', detail = k;
        end if;
      when 'boolean' then
        if jsonb_typeof(v) <> 'boolean' then
          raise exception using errcode = 'PT400', message = 'invalid_field_value', detail = k;
        end if;
      else
        if jsonb_typeof(v) = 'string' and length(v #>> '{}') > 500 then
          raise exception using errcode = 'PT400', message = 'invalid_field_value', detail = k;
        end if;
    end case;
  end loop;
end $$;

-- Does the seller's service area + category set cover this request?
create or replace function private.seller_covers_request(p_seller_id uuid, p_request_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select exists (
    select 1
      from public.requests r
      join public.sellers s on s.id = p_seller_id
     where r.id = p_request_id
       and (r.inviting_seller_id = s.id
            or (r.category_id = any(private.seller_category_ids(s.id))
                and ((s.area_type = 'radius' and st_dwithin(r.location, s.center, s.radius_km * 1000))
                     or (s.area_type = 'codes' and r.location_code = any(s.service_codes))
                     or (s.area_type = 'nationwide' and r.audience <> 'local')))))
$$;

-- Sellers matching a request (reverse match), best first. Shared by
-- create_request (count) and the match-request Edge Function.
create or replace function private.match_sellers(p_request_id uuid, p_limit int)
returns table (seller_id uuid, verified boolean, has_priority boolean, notify_mode text,
               quiet_hours_start time, quiet_hours_end time, timezone text, language text,
               rating_avg numeric, avg_response_mins int, distance_m double precision)
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  with r as (
    select r.*, b.is_review_account as buyer_review
      from public.requests r join public.profiles b on b.id = r.buyer_id
     where r.id = p_request_id
  ), cand as (
    select s.id from public.sellers s, r
     where s.area_type = 'radius' and st_dwithin(s.center, r.location, s.radius_km * 1000)
    union
    select s.id from public.sellers s, r
     where s.area_type = 'codes' and r.location_code = any(s.service_codes)
    union
    select s.id from public.sellers s, r
     where s.area_type = 'nationwide' and r.audience <> 'local'
    union
    select r.inviting_seller_id from r where r.inviting_seller_id is not null
  )
  select s.id, s.verification_status = 'verified', private.seller_has_priority(s.id),
         s.notify_mode, s.quiet_hours_start, s.quiet_hours_end,
         coalesce(s.timezone, p.timezone, private.setting_text('default_timezone', 'UTC')),
         p.language, s.rating_avg, s.avg_response_mins,
         case when s.center is not null and r.location is not null then st_distance(s.center, r.location) end
    from cand
    join public.sellers s on s.id = cand.id
    join public.profiles p on p.id = s.id
    cross join r
   where s.id <> r.buyer_id
     and not s.hidden
     and private.is_active_user(s.id)
     and p.is_review_account = r.buyer_review
     and not private.is_blocked_between(s.id, r.buyer_id)
     and (s.id = r.inviting_seller_id or r.category_id = any(private.seller_category_ids(s.id)))
   order by (s.id = r.inviting_seller_id) desc, (s.verification_status = 'verified') desc,
            s.rating_avg desc, s.avg_response_mins asc nulls last, s.id
   limit greatest(p_limit, 0)
$$;

-- create_request ------------------------------------------------------------------------------------------
create or replace function public.create_request(
  p_category_id bigint,
  p_title text,
  p_description text default null,
  p_fields jsonb default '{}'::jsonb,
  p_budget_min_minor bigint default null,
  p_budget_max_minor bigint default null,
  p_budget_visible boolean default true,
  p_needed_by date default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_location_code text default null,
  p_locality text default null,
  p_audience text default 'both',
  p_quote_window_hours int default 48,
  p_full_address text default null,
  p_buyer_phone text default null,
  p_reference_url text default null,
  p_inviting_seller_id uuid default null)
returns table (request_id uuid, status text, priority_until timestamptz,
               quote_window_ends_at timestamptz, matched_sellers int)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_user();
  v_pol record;
  v_schema jsonb;
  v_blocked record;
  v_fp text;
  v_dup uuid;
  v_code text;
  v_pc public.postal_codes;
  v_exact geography;
  v_coarse geography;
  v_req public.requests;
  v_phone text;
  v_matched int;
begin
  -- rate limit: N requests per rolling 24h
  if (select count(*) from public.requests r
       where r.buyer_id = v_uid and r.created_at > now() - interval '24 hours')
     >= private.setting_int('max_requests_per_buyer_per_day', 10) then
    perform private.raise_error('rate_limited', 429, 'Daily request limit reached');
  end if;

  if p_audience not in ('local','online','both') then
    perform private.raise_error('invalid_audience', 400);
  end if;
  if p_quote_window_hours not in (24, 48, 168) then
    perform private.raise_error('invalid_quote_window', 400, 'Use 24, 48 or 168 hours');
  end if;
  if coalesce(length(trim(p_title)), 0) < 3 then
    perform private.raise_error('title_too_short', 400);
  end if;
  if p_budget_min_minor is not null and p_budget_max_minor is not null and p_budget_min_minor > p_budget_max_minor then
    perform private.raise_error('invalid_budget', 400);
  end if;
  if p_needed_by is not null and p_needed_by < current_date then
    perform private.raise_error('needed_by_in_past', 400);
  end if;

  -- category + policy
  select * into v_pol from private.category_policy(p_category_id);
  if v_pol.policy is null or not v_pol.active then
    perform private.raise_error('category_not_found', 404);
  end if;
  if not v_pol.is_leaf then
    perform private.raise_error('category_not_leaf', 400, 'Pick a subcategory');
  end if;
  if v_pol.policy = 'blocked' then
    perform private.raise_error('category_blocked', 422,
      coalesce(v_pol.policy_reason->>'en', 'This category cannot be requested in this app'));
  end if;

  -- keyword classifier (catches blocked items typed into an allowed category)
  select * into v_blocked from private.find_blocked_keyword(
    coalesce(p_title, '') || ' ' || coalesce(p_description, '') || ' ' || coalesce(p_fields::text, ''));
  if v_blocked.keyword is not null then
    perform private.raise_error('blocked_content', 422,
      coalesce(v_blocked.reason->>'en', 'This request mentions something that is not allowed'), v_blocked.keyword);
  end if;

  select field_schema into v_schema from public.categories where id = p_category_id;
  perform private.validate_fields(v_schema, coalesce(p_fields, '{}'::jsonb), 'request');

  -- duplicate detection: same buyer, same category, same text within the window
  v_fp := md5(private.normalize_text(p_title) || '|' || private.normalize_text(p_description));
  select r.id into v_dup from public.requests r
   where r.buyer_id = v_uid and r.category_id = p_category_id and r.text_fingerprint = v_fp
     and r.status <> 'cancelled'
     and r.created_at > now() - make_interval(hours => private.setting_int('duplicate_window_hours', 24))
   limit 1;
  if v_dup is not null then
    perform private.raise_error('duplicate_request', 409, v_dup::text);
  end if;

  -- location: GPS pin and/or postal code
  if p_location_code is not null then
    v_code := public.normalize_postal_code(p_location_code);
    if v_code is null then
      perform private.raise_error('invalid_postal_code', 400);
    end if;
    select * into v_pc from public.postal_codes where code = v_code;
  end if;
  if p_lat is not null and p_lng is not null then
    if p_lat not between -90 and 90 or p_lng not between -180 and 180 then
      perform private.raise_error('invalid_location', 400);
    end if;
    v_exact := st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography;
    v_coarse := st_setsrid(st_makepoint(round(p_lng::numeric, 3)::float8, round(p_lat::numeric, 3)::float8), 4326)::geography;
    if v_pc.code is null then
      select * into v_pc from public.postal_codes pc
       where st_dwithin(pc.centroid, v_exact, 15000)
       order by pc.centroid <-> v_exact limit 1;
      v_code := coalesce(v_code, v_pc.code);
    end if;
  elsif v_code is not null then
    if v_pc.code is null then
      perform private.raise_error('unknown_postal_code', 422, v_code);
    end if;
    v_coarse := v_pc.centroid;
  elsif p_audience <> 'online' then
    perform private.raise_error('location_required', 400);
  end if;

  if p_inviting_seller_id is not null and not exists (
       select 1 from public.sellers s where s.id = p_inviting_seller_id and not s.hidden) then
    p_inviting_seller_id := null;
  end if;

  insert into public.requests (
    buyer_id, category_id, title, description, fields, budget_min_minor, budget_max_minor,
    currency, budget_visible, needed_by, location, location_code, locality, city, state,
    audience, max_quotes, priority_until, quote_window_ends_at, reference_url,
    inviting_seller_id, text_fingerprint)
  values (
    v_uid, p_category_id, trim(p_title), nullif(trim(p_description), ''), coalesce(p_fields, '{}'::jsonb),
    p_budget_min_minor, p_budget_max_minor,
    private.setting_text('currency', 'INR'), coalesce(p_budget_visible, true), p_needed_by,
    v_coarse, v_code, coalesce(nullif(trim(p_locality), ''), v_pc.district, v_pc.city), v_pc.city, v_pc.state,
    p_audience, private.setting_int('quote_cap', 10),
    now() + make_interval(mins => private.setting_int('priority_window_minutes', 15)),
    now() + make_interval(hours => p_quote_window_hours),
    p_reference_url, p_inviting_seller_id, v_fp)
  returning * into v_req;

  select phone into v_phone from public.profiles where id = v_uid;
  insert into public.request_private (request_id, full_address, buyer_phone, exact_location)
  values (v_req.id, p_full_address, coalesce(p_buyer_phone, v_phone), coalesce(v_exact, v_coarse));

  select count(*) into v_matched from private.match_sellers(v_req.id, private.setting_int('match_push_cap', 200));

  return query select v_req.id, v_req.status, v_req.priority_until, v_req.quote_window_ends_at, v_matched;
end $$;

-- Buyer closes or cancels an open request. Active quotes are declined.
create or replace function public.close_request(p_request_id uuid, p_status text default 'cancelled', p_reason text default null)
returns public.requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_req public.requests;
  q record;
begin
  if p_status not in ('cancelled','closed') then
    perform private.raise_error('invalid_status', 400);
  end if;
  select * into v_req from public.requests where id = p_request_id for update;
  if not found or v_req.buyer_id <> v_uid then
    perform private.raise_error('request_not_found', 404);
  end if;
  if v_req.status <> 'open' then
    perform private.raise_error('request_not_open', 409);
  end if;
  update public.requests set status = p_status, closed_at = now() where id = p_request_id
  returning * into v_req;
  for q in update public.quotes set status = 'declined', decline_reason = coalesce(p_reason, 'request_' || p_status)
            where request_id = p_request_id and status in ('sent','revised','shortlisted')
            returning seller_id, id loop
    perform private.notify(q.seller_id, 'request_closed',
      jsonb_build_object('title', v_req.title, 'request_id', p_request_id, 'quote_id', q.id,
                         'route', '/seller/quotes/' || q.id));
  end loop;
  return v_req;
end $$;

-- Safe request view for sellers (no buyer contact, exact address or hidden budget).
create or replace function private.request_safe_json(p_request public.requests, p_seller_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select jsonb_build_object(
    'id', p_request.id,
    'category_id', p_request.category_id,
    'title', p_request.title,
    'description', p_request.description,
    'fields', p_request.fields,
    'budget_min_minor', case when p_request.budget_visible then p_request.budget_min_minor end,
    'budget_max_minor', case when p_request.budget_visible then p_request.budget_max_minor end,
    'currency', p_request.currency,
    'needed_by', p_request.needed_by,
    'locality', p_request.locality,
    'city', p_request.city,
    'state', p_request.state,
    'location_code', p_request.location_code,
    'audience', p_request.audience,
    'status', p_request.status,
    'quote_count', p_request.quote_count,
    'max_quotes', p_request.max_quotes,
    'priority_until', p_request.priority_until,
    'quote_window_ends_at', p_request.quote_window_ends_at,
    'reference_url', p_request.reference_url,
    'created_at', p_request.created_at,
    'buyer_id', p_request.buyer_id,
    'is_invited', p_request.inviting_seller_id = p_seller_id,
    'distance_m', (select st_distance(s.center, p_request.location) from public.sellers s
                    where s.id = p_seller_id and s.center is not null and p_request.location is not null))
$$;

create or replace function public.get_request_for_seller(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_uid uuid := private.require_user();
  v_req public.requests;
  v_quote public.quotes;
  v_pol record;
begin
  if not exists (select 1 from public.sellers where id = v_uid) then
    perform private.raise_error('not_a_seller', 403);
  end if;
  select * into v_req from public.requests where id = p_request_id;
  if not found or v_req.hidden then
    perform private.raise_error('request_not_found', 404);
  end if;
  select * into v_quote from public.quotes q where q.request_id = p_request_id and q.seller_id = v_uid
   order by q.created_at desc limit 1;
  if v_quote.id is null and not (v_req.status = 'open' and private.seller_covers_request(v_uid, p_request_id)
                                 and not private.is_blocked_between(v_uid, v_req.buyer_id)) then
    perform private.raise_error('request_not_found', 404);
  end if;
  select * into v_pol from private.category_policy(v_req.category_id);

  insert into public.lead_states (seller_id, request_id, seen_at) values (v_uid, p_request_id, now())
  on conflict (seller_id, request_id) do update set seen_at = coalesce(lead_states.seen_at, now());

  return private.request_safe_json(v_req, v_uid) || jsonb_build_object(
    'category', (select jsonb_build_object('id', c.id, 'slug', c.slug, 'names', c.names,
                         'field_schema', c.field_schema, 'parent_id', c.parent_id)
                   from public.categories c where c.id = v_req.category_id),
    'policy', v_pol.policy,
    'required_licence_type', v_pol.required_licence_type,
    'disclaimer', v_pol.disclaimer,
    'media', (select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'file_path', m.file_path, 'type', m.type)
                                         order by m.sort), '[]')
                from public.request_media m where m.request_id = p_request_id and not m.hidden),
    'my_quote', case when v_quote.id is null then null else to_jsonb(v_quote) end,
    'can_quote', v_quote.id is null and v_req.status = 'open' and v_req.quote_count < v_req.max_quotes
                 and v_req.quote_window_ends_at > now()
                 and (v_req.priority_until <= now() or private.seller_has_priority(v_uid)
                      or v_req.inviting_seller_id = v_uid));
end $$;

-- Lead feed (Section 20.3) ---------------------------------------------------------------------------------
-- p_filters: {"category_ids":[..], "max_distance_km": n, "min_budget_minor": n,
--             "needed_by_before": "YYYY-MM-DD", "include_dismissed": bool,
--             "hide_quoted": bool, "audience": "local|online|both"}
-- p_cursor:  {"created_at": "...", "id": "..."} from the last row of the previous page.
create or replace function public.get_lead_feed(
  p_filters jsonb default '{}'::jsonb, p_cursor jsonb default null, p_limit int default 20)
returns table (
  request_id uuid, category_id bigint, category_slug text, category_names jsonb,
  title text, description text, fields jsonb,
  budget_min_minor bigint, budget_max_minor bigint, currency char(3),
  needed_by date, locality text, city text, state text, location_code text, audience text,
  quote_count int, max_quotes int, priority_until timestamptz, quote_window_ends_at timestamptz,
  created_at timestamptz, distance_m double precision, media_count int,
  is_invited boolean, my_quote_id uuid, my_quote_status text, seen_at timestamptz,
  required_licence_type text)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_user();
  v_seller public.sellers;
  v_cats bigint[];
  v_priority boolean;
  v_review boolean;
  v_cur_ts timestamptz := (p_cursor->>'created_at')::timestamptz;
  v_cur_id uuid := (p_cursor->>'id')::uuid;
  v_limit int := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_filter_cats bigint[];
  v_max_m double precision := (p_filters->>'max_distance_km')::double precision * 1000;
  v_radius_m double precision;
  v_center geography;
  v_codes text[];
  v_area text;
begin
  select * into v_seller from public.sellers where id = v_uid;
  if not found then
    perform private.raise_error('not_a_seller', 403);
  end if;
  if not private.rate_limit_hit('lead_feed:' || v_uid, private.setting_int('lead_feed_per_minute', 120), 60) then
    perform private.raise_error('rate_limited', 429);
  end if;

  v_cats := private.seller_category_ids(v_uid);
  if p_filters ? 'category_ids' and jsonb_typeof(p_filters->'category_ids') = 'array'
     and jsonb_array_length(p_filters->'category_ids') > 0 then
    select array_agg(x::bigint) into v_filter_cats from jsonb_array_elements_text(p_filters->'category_ids') x;
    -- a parent id in the filter selects its children
    select array_agg(c.id) into v_filter_cats from public.categories c
     where c.id = any(v_filter_cats) or c.parent_id = any(v_filter_cats);
    v_cats := array(select unnest(v_cats) intersect select unnest(v_filter_cats));
  end if;
  v_priority := private.seller_has_priority(v_uid);
  select is_review_account into v_review from public.profiles where id = v_uid;
  v_area := v_seller.area_type;
  v_center := v_seller.center;
  v_radius_m := v_seller.radius_km * 1000;
  v_codes := v_seller.service_codes;

  return query
  with cand as (
    -- radius sellers: explicit ST_DWithin so the GIST index on requests.location is used
    select r.id from public.requests r
     where v_area = 'radius'
       and r.status = 'open'
       and r.category_id = any(v_cats)
       and st_dwithin(r.location, v_center, v_radius_m)
       and (v_cur_ts is null or (r.created_at, r.id) < (v_cur_ts, v_cur_id))
    union all
    -- postal-code-list sellers
    select r.id from public.requests r
     where v_area = 'codes'
       and r.status = 'open'
       and r.category_id = any(v_cats)
       and r.location_code = any(v_codes)
       and (v_cur_ts is null or (r.created_at, r.id) < (v_cur_ts, v_cur_id))
    union all
    -- nationwide sellers: anything not restricted to local sellers
    select r.id from public.requests r
     where v_area = 'nationwide'
       and r.status = 'open'
       and r.category_id = any(v_cats)
       and r.audience <> 'local'
       and (v_cur_ts is null or (r.created_at, r.id) < (v_cur_ts, v_cur_id))
    union all
    -- requests where the buyer came through this seller's invite link
    select r.id from public.requests r
     where r.inviting_seller_id = v_uid
       and r.status = 'open'
       and (v_cur_ts is null or (r.created_at, r.id) < (v_cur_ts, v_cur_id))
  ), ids as (
    select distinct cand.id from cand
  )
  select r.id, r.category_id, c.slug, c.names,
         r.title, r.description, r.fields,
         case when r.budget_visible then r.budget_min_minor end,
         case when r.budget_visible then r.budget_max_minor end,
         r.currency, r.needed_by, r.locality, r.city, r.state, r.location_code, r.audience,
         r.quote_count, r.max_quotes, r.priority_until, r.quote_window_ends_at, r.created_at,
         case when v_center is not null and r.location is not null then st_distance(r.location, v_center) end,
         (select count(*)::int from public.request_media m where m.request_id = r.id and not m.hidden),
         r.inviting_seller_id is not distinct from v_uid,
         mq.id, mq.status, ls.seen_at,
         (select required_licence_type from private.category_policy(r.category_id))
    from ids
    join public.requests r on r.id = ids.id
    join public.categories c on c.id = r.category_id
    join public.profiles b on b.id = r.buyer_id
    left join public.lead_states ls on ls.seller_id = v_uid and ls.request_id = r.id
    left join lateral (
      select q.id, q.status from public.quotes q
       where q.request_id = r.id and q.seller_id = v_uid
       order by q.created_at desc limit 1) mq on true
   where r.buyer_id <> v_uid
     and not r.hidden
     and r.quote_window_ends_at > now()
     and b.status = 'active'
     and b.is_review_account = coalesce(v_review, false)
     and (r.quote_count < r.max_quotes or mq.id is not null)
     and (r.priority_until is null or r.priority_until <= now() or v_priority or r.inviting_seller_id = v_uid)
     and (ls.dismissed_at is null or coalesce((p_filters->>'include_dismissed')::boolean, false))
     and (mq.id is null or not coalesce((p_filters->>'hide_quoted')::boolean, false))
     and not exists (select 1 from public.blocks bl
                      where (bl.blocker_id = r.buyer_id and bl.blocked_id = v_uid)
                         or (bl.blocker_id = v_uid and bl.blocked_id = r.buyer_id))
     and (v_max_m is null or v_center is null or r.location is null or st_dwithin(r.location, v_center, v_max_m))
     and (p_filters->>'min_budget_minor' is null
          or (r.budget_visible and r.budget_max_minor >= (p_filters->>'min_budget_minor')::bigint))
     and (p_filters->>'needed_by_before' is null or r.needed_by <= (p_filters->>'needed_by_before')::date)
     and (p_filters->>'audience' is null or r.audience = p_filters->>'audience')
   order by r.created_at desc, r.id desc
   limit v_limit;
end $$;

create or replace function public.dismiss_lead(p_request_id uuid, p_dismiss boolean default true)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_uid uuid := private.require_user();
begin
  if not exists (select 1 from public.sellers where id = v_uid) then
    perform private.raise_error('not_a_seller', 403);
  end if;
  insert into public.lead_states (seller_id, request_id, dismissed_at)
  values (v_uid, p_request_id, case when p_dismiss then now() end)
  on conflict (seller_id, request_id) do update
    set dismissed_at = case when p_dismiss then now() end;
end $$;

create or replace function public.mark_leads_seen(p_request_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_uid uuid := private.require_user();
begin
  if not exists (select 1 from public.sellers where id = v_uid) then
    perform private.raise_error('not_a_seller', 403);
  end if;
  insert into public.lead_states (seller_id, request_id, seen_at)
  select v_uid, r.id, now() from public.requests r where r.id = any(p_request_ids[1:100])
  on conflict (seller_id, request_id) do update set seen_at = coalesce(lead_states.seen_at, now());
end $$;
