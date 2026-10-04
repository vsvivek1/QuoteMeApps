-- 3401 Group buy: a public request where more buyers join with a quantity.
-- Sellers quote per-unit price tiers ("10+ units: 900 each, 50+: 800"), so
-- the best price on offer drops as the group grows. The request's buyer
-- (the organiser) still accepts one quote; members then see the winning
-- seller and the final per-unit price, and that seller sees the members'
-- names, quantities and phone numbers to arrange each order.
-- Columns on requests (group_buy, group_unit, group_qty, group_members) are
-- added in 20261003400000_community_feed.sql.
set search_path = public, extensions;

insert into public.app_settings (key, value, is_public, description) values
  ('group_buy_max_qty_per_member', '1000', true, 'Max quantity one member may join a group buy with'),
  ('group_buy_max_tiers', '6', true, 'Max price tiers per quote')
on conflict (key) do nothing;

create table public.group_buy_members (
  request_id uuid not null references public.requests(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  qty numeric(12,3) not null check (qty > 0),
  note text check (note is null or length(note) <= 280),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (request_id, user_id)
);
create index group_buy_members_user_idx on public.group_buy_members (user_id);

create table public.quote_price_tiers (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid not null references public.quotes(id) on delete cascade,
  min_qty numeric(12,3) not null check (min_qty > 0),
  unit_price_minor bigint not null check (unit_price_minor >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (quote_id, min_qty)
);

do $$
declare t text;
begin
  foreach t in array array['group_buy_members','quote_price_tiers'] loop
    perform private.add_updated_at_trigger(('public.' || t)::regclass);
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

grant select on public.group_buy_members, public.quote_price_tiers to authenticated;
create policy group_buy_members_read on public.group_buy_members for select to authenticated
  using (user_id = auth.uid() or private.is_request_buyer(request_id) or private.is_admin());
create policy quote_price_tiers_read on public.quote_price_tiers for select to authenticated
  using (private.can_view_quote(quote_id) or private.is_admin());

-- Pricing helpers --------------------------------------------------------------------------------
-- A quote's per-unit price for a group of p_qty units (null: no tier applies).
create or replace function private.quote_unit_price_at(p_quote_id uuid, p_qty numeric)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select t.unit_price_minor from public.quote_price_tiers t
   where t.quote_id = p_quote_id and t.min_qty <= p_qty
   order by t.min_qty desc limit 1
$$;

-- Best price across all active tiered quotes for p_qty units.
create or replace function private.group_best_price_at(p_request_id uuid, p_qty numeric)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select min(private.quote_unit_price_at(q.id, p_qty)) from public.quotes q
   where q.request_id = p_request_id and q.status in ('sent','revised','shortlisted','accepted')
     and not q.hidden
$$;

-- The price ladder buyers see: at each tier threshold any seller offered,
-- the best per-unit price, keeping only steps where the price drops.
create or replace function private.group_ladder(p_request_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with thresholds as (
    select distinct t.min_qty from public.quote_price_tiers t
      join public.quotes q on q.id = t.quote_id
     where q.request_id = p_request_id and q.status in ('sent','revised','shortlisted','accepted')
       and not q.hidden
  ), priced as (
    select min_qty, private.group_best_price_at(p_request_id, min_qty) as price from thresholds
  ), stepped as (
    select min_qty, price,
           min(price) over (order by min_qty rows between unbounded preceding and 1 preceding) as best_before
      from priced
  )
  select coalesce(jsonb_agg(jsonb_build_object('min_qty', min_qty, 'unit_price_minor', price) order by min_qty), '[]')
    from stepped where price is not null and (best_before is null or price < best_before)
$$;

create or replace function private.refresh_group_totals(p_request_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.requests r
     set group_qty = coalesce((select sum(m.qty) from public.group_buy_members m where m.request_id = p_request_id), 0),
         group_members = (select count(*) from public.group_buy_members m where m.request_id = p_request_id)
   where r.id = p_request_id
$$;

-- Group summary as anyone who can see the post sees it; members and the
-- organiser also see the winning seller once a quote is accepted.
create or replace function private.group_buy_json(p_request public.requests, p_viewer uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with cur as (
    select private.group_best_price_at(p_request.id, p_request.group_qty) as price,
           private.group_ladder(p_request.id) as ladder
  ), nxt as (
    select (e->>'min_qty')::numeric as min_qty, (e->>'unit_price_minor')::bigint as price
      from cur, jsonb_array_elements(cur.ladder) e
     where (e->>'min_qty')::numeric > p_request.group_qty
       and (cur.price is null or (e->>'unit_price_minor')::bigint < cur.price)
     order by (e->>'min_qty')::numeric limit 1
  )
  select jsonb_build_object(
    'unit', p_request.group_unit,
    'total_qty', p_request.group_qty,
    'members', p_request.group_members,
    'my_qty', (select m.qty from public.group_buy_members m
                where m.request_id = p_request.id and m.user_id = p_viewer),
    'ladder', cur.ladder,
    'current_unit_price_minor', cur.price,
    'next_min_qty', (select min_qty from nxt),
    'next_unit_price_minor', (select price from nxt),
    'qty_to_next', (select min_qty - p_request.group_qty from nxt),
    'offers', (select count(distinct q.id) from public.quotes q join public.quote_price_tiers t on t.quote_id = q.id
                where q.request_id = p_request.id and q.status in ('sent','revised','shortlisted','accepted')
                  and not q.hidden),
    'accepted', case when p_request.accepted_quote_id is not null and p_viewer is not null and (
                       p_request.buyer_id = p_viewer
                       or exists (select 1 from public.group_buy_members m
                                   where m.request_id = p_request.id and m.user_id = p_viewer)) then (
                  select jsonb_build_object(
                    'seller_id', s.id, 'business_name', s.business_name,
                    'seller_verified', s.verification_status = 'verified',
                    'unit_price_minor', coalesce(private.quote_unit_price_at(q.id, p_request.group_qty),
                                                 (select t.unit_price_minor from public.quote_price_tiers t
                                                   where t.quote_id = q.id order by t.min_qty limit 1)))
                    from public.quotes q join public.sellers s on s.id = q.seller_id
                   where q.id = p_request.accepted_quote_id) end)
    from cur
$$;

-- The feed projection gains the group summary (replaces 3400's version).
create or replace function private.feed_post_json(p_request public.requests, p_viewer uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'request_id', p_request.id,
    'category_id', p_request.category_id,
    'category_slug', c.slug,
    'category_names', c.names,
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
    'audience', p_request.audience,
    'status', p_request.status,
    'quote_count', p_request.quote_count,
    'comment_count', p_request.comment_count,
    'like_count', p_request.like_count,
    'quote_window_ends_at', p_request.quote_window_ends_at,
    'created_at', p_request.created_at,
    'published_at', p_request.published_at,
    'author_name', private.public_display_name(p.name, p.status),
    'author_photo_url', p.photo_url,
    'is_mine', p_viewer is not null and p_request.buyer_id = p_viewer,
    'liked_by_me', p_viewer is not null and exists (
       select 1 from public.request_likes l where l.request_id = p_request.id and l.user_id = p_viewer),
    'group_buy', p_request.group_buy,
    'group', case when p_request.group_buy then private.group_buy_json(p_request, p_viewer) end)
    from public.categories c, public.profiles p
   where c.id = p_request.category_id and p.id = p_request.buyer_id
$$;

-- Organiser turns group buy on (with their own quantity) or off ------------------------------------
create or replace function public.set_group_buy(
  p_request_id uuid, p_enabled boolean, p_unit text default null, p_my_qty numeric default 1)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_req public.requests;
  v_unit text := nullif(trim(coalesce(p_unit, '')), '');
begin
  select * into v_req from public.requests where id = p_request_id for update;
  if not found or v_req.buyer_id <> v_uid then
    perform private.raise_error('request_not_found', 404);
  end if;
  if v_req.status <> 'open' then
    perform private.raise_error('request_not_open', 409);
  end if;
  if not p_enabled then
    if v_req.group_members > 1 then
      perform private.raise_error('group_has_members', 409);
    end if;
    delete from public.group_buy_members where request_id = p_request_id;
    update public.requests set group_buy = false, group_qty = 0, group_members = 0
     where id = p_request_id returning * into v_req;
    return private.feed_post_json(v_req, v_uid);
  end if;

  if coalesce(p_my_qty, 0) <= 0 or p_my_qty > private.setting_int('group_buy_max_qty_per_member', 1000) then
    perform private.raise_error('invalid_qty', 400);
  end if;
  if v_unit is not null and length(v_unit) > 24 then
    perform private.raise_error('invalid_unit', 400);
  end if;
  -- a group buy is always on the feed
  perform public.publish_request(p_request_id, true);
  update public.requests set group_buy = true, group_unit = coalesce(v_unit, group_unit, 'units')
   where id = p_request_id;
  insert into public.group_buy_members (request_id, user_id, qty) values (p_request_id, v_uid, p_my_qty)
  on conflict (request_id, user_id) do update set qty = excluded.qty;
  perform private.refresh_group_totals(p_request_id);
  select * into v_req from public.requests where id = p_request_id;
  return private.feed_post_json(v_req, v_uid);
end $$;

-- Anyone signed in joins (or changes their quantity) -------------------------------------------------------
create or replace function public.join_group_buy(p_request_id uuid, p_qty numeric, p_note text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_req public.requests;
  v_before bigint;
  v_after bigint;
  v_new boolean;
  m record;
  q record;
begin
  select * into v_req from public.requests where id = p_request_id for update;
  if not found or not private.is_feed_visible(v_req) or not v_req.group_buy then
    perform private.raise_error('post_not_found', 404);
  end if;
  if private.is_blocked_between(v_uid, v_req.buyer_id) then
    perform private.raise_error('blocked', 403);
  end if;
  if v_req.status <> 'open' or v_req.quote_window_ends_at <= now() then
    perform private.raise_error('group_closed', 409);
  end if;
  if coalesce(p_qty, 0) <= 0 or p_qty > private.setting_int('group_buy_max_qty_per_member', 1000) then
    perform private.raise_error('invalid_qty', 400);
  end if;
  if not private.rate_limit_hit('group_join:' || v_uid, 30, 3600) then
    perform private.raise_error('rate_limited', 429);
  end if;

  v_before := private.group_best_price_at(p_request_id, v_req.group_qty);
  v_new := not exists (select 1 from public.group_buy_members where request_id = p_request_id and user_id = v_uid);
  insert into public.group_buy_members (request_id, user_id, qty, note)
  values (p_request_id, v_uid, p_qty, nullif(left(trim(coalesce(p_note, '')), 280), ''))
  on conflict (request_id, user_id) do update set qty = excluded.qty, note = coalesce(excluded.note, group_buy_members.note);
  perform private.refresh_group_totals(p_request_id);
  select * into v_req from public.requests where id = p_request_id;
  v_after := private.group_best_price_at(p_request_id, v_req.group_qty);

  if v_new and v_req.buyer_id <> v_uid then
    perform private.notify(v_req.buyer_id, 'group_joined',
      jsonb_build_object('title', v_req.title, 'request_id', p_request_id, 'members', v_req.group_members,
                         'total_qty', v_req.group_qty, 'route', '/feed/' || p_request_id),
      'group_joined:' || p_request_id);
    -- sellers who quoted hear that the group grew (they may want to sharpen their tiers)
    for q in select distinct seller_id from public.quotes
              where request_id = p_request_id and status in ('sent','revised','shortlisted') loop
      perform private.notify(q.seller_id, 'group_grew',
        jsonb_build_object('title', v_req.title, 'request_id', p_request_id, 'members', v_req.group_members,
                           'total_qty', v_req.group_qty, 'route', '/seller/leads/' || p_request_id),
        'group_grew:' || p_request_id);
    end loop;
  end if;
  if v_after is not null and (v_before is null or v_after < v_before) then
    for m in select user_id from public.group_buy_members
              where request_id = p_request_id and user_id <> v_uid loop
      perform private.notify(m.user_id, 'group_price_drop',
        jsonb_build_object('title', v_req.title, 'request_id', p_request_id,
                           'unit_price_minor', v_after, 'currency', v_req.currency,
                           'route', '/feed/' || p_request_id),
        'group_price_drop:' || p_request_id);
    end loop;
  end if;
  return private.group_buy_json(v_req, v_uid);
end $$;

create or replace function public.leave_group_buy(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_req public.requests;
begin
  select * into v_req from public.requests where id = p_request_id for update;
  if not found or not v_req.group_buy then
    perform private.raise_error('post_not_found', 404);
  end if;
  if v_req.buyer_id = v_uid then
    perform private.raise_error('organiser_cannot_leave', 409);
  end if;
  if v_req.status <> 'open' then
    perform private.raise_error('group_closed', 409);
  end if;
  delete from public.group_buy_members where request_id = p_request_id and user_id = v_uid;
  perform private.refresh_group_totals(p_request_id);
  select * into v_req from public.requests where id = p_request_id;
  return private.group_buy_json(v_req, v_uid);
end $$;

create or replace function public.get_group_buy(p_request_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_req public.requests;
begin
  select * into v_req from public.requests where id = p_request_id;
  if not found or not v_req.group_buy
     or not (private.is_feed_visible(v_req) or coalesce(v_req.buyer_id = v_uid, false)
             or exists (select 1 from public.quotes q where q.request_id = p_request_id and q.seller_id = v_uid)) then
    perform private.raise_error('post_not_found', 404);
  end if;
  return private.group_buy_json(v_req, v_uid);
end $$;

-- Members list for the organiser and, after acceptance, the winning seller
-- (who needs names, quantities and phones to arrange each order).
create or replace function public.get_group_members(p_request_id uuid)
returns table (user_id uuid, display_name text, qty numeric, note text, phone text, joined_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_user();
  v_req public.requests;
  v_seller boolean;
begin
  select * into v_req from public.requests r where r.id = p_request_id;
  if not found then
    perform private.raise_error('request_not_found', 404);
  end if;
  v_seller := v_req.accepted_quote_id is not null and exists (
    select 1 from public.quotes q where q.id = v_req.accepted_quote_id and q.seller_id = v_uid);
  if not (v_req.buyer_id = v_uid or v_seller or private.is_admin()) then
    perform private.raise_error('request_not_found', 404);
  end if;
  return query
    select m.user_id, private.public_display_name(p.name, p.status), m.qty, m.note,
           case when v_seller or private.is_admin() then p.phone end, m.created_at
      from public.group_buy_members m join public.profiles p on p.id = m.user_id
     where m.request_id = p_request_id
     order by m.created_at;
end $$;

-- Seller sets per-unit price tiers on an own quote ----------------------------------------------------------
-- p_tiers: [{"min_qty": 1, "unit_price_minor": 100000}, {"min_qty": 10, "unit_price_minor": 90000}, ...]
-- Quantities strictly increase and prices strictly decrease. [] clears.
create or replace function public.set_quote_tiers(p_quote_id uuid, p_tiers jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_quote public.quotes;
  v_req public.requests;
  v_before bigint;
  v_after bigint;
  t jsonb;
  v_prev_qty numeric;
  v_prev_price bigint;
  v_qty numeric;
  v_price bigint;
  m record;
begin
  select * into v_quote from public.quotes where id = p_quote_id;
  if not found or v_quote.seller_id <> v_uid then
    perform private.raise_error('quote_not_found', 404);
  end if;
  if v_quote.status not in ('sent','revised','shortlisted') then
    perform private.raise_error('quote_not_editable', 409);
  end if;
  select * into v_req from public.requests where id = v_quote.request_id;
  if not v_req.group_buy then
    perform private.raise_error('not_a_group_buy', 409);
  end if;
  if v_req.status <> 'open' then
    perform private.raise_error('request_not_open', 409);
  end if;
  if p_tiers is null or jsonb_typeof(p_tiers) <> 'array'
     or jsonb_array_length(p_tiers) > private.setting_int('group_buy_max_tiers', 6) then
    perform private.raise_error('invalid_tiers', 400);
  end if;
  for t in select * from jsonb_array_elements(p_tiers) loop
    begin
      v_qty := (t->>'min_qty')::numeric;
      v_price := (t->>'unit_price_minor')::bigint;
    exception when others then
      perform private.raise_error('invalid_tiers', 400);
    end;
    if v_qty is null or v_price is null or v_qty <= 0 or v_price < 0
       or (v_prev_qty is not null and (v_qty <= v_prev_qty or v_price >= v_prev_price)) then
      perform private.raise_error('invalid_tiers', 400, 'Quantities must increase and prices must drop');
    end if;
    v_prev_qty := v_qty;
    v_prev_price := v_price;
  end loop;

  v_before := private.group_best_price_at(v_req.id, v_req.group_qty);
  delete from public.quote_price_tiers where quote_id = p_quote_id;
  insert into public.quote_price_tiers (quote_id, min_qty, unit_price_minor)
  select p_quote_id, (e->>'min_qty')::numeric, (e->>'unit_price_minor')::bigint
    from jsonb_array_elements(p_tiers) e;
  v_after := private.group_best_price_at(v_req.id, v_req.group_qty);

  perform private.notify(v_req.buyer_id, 'quote_tiers',
    jsonb_build_object('title', v_req.title, 'request_id', v_req.id, 'quote_id', p_quote_id,
                       'route', '/quotes/' || p_quote_id),
    'quote_tiers:' || p_quote_id);
  if v_after is not null and (v_before is null or v_after < v_before) then
    for m in select user_id from public.group_buy_members
              where request_id = v_req.id and user_id <> v_req.buyer_id loop
      perform private.notify(m.user_id, 'group_price_drop',
        jsonb_build_object('title', v_req.title, 'request_id', v_req.id,
                           'unit_price_minor', v_after, 'currency', v_req.currency,
                           'route', '/feed/' || v_req.id),
        'group_price_drop:' || v_req.id);
    end loop;
  end if;
  return private.group_buy_json(v_req, v_uid);
end $$;

-- When the organiser accepts a quote, every other member hears who won ---------------------------------------
create or replace function private.on_group_buy_awarded()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare m record;
begin
  if new.group_buy and new.status = 'awarded' and old.status <> 'awarded' then
    for m in select user_id from public.group_buy_members
              where request_id = new.id and user_id <> new.buyer_id loop
      perform private.notify(m.user_id, 'group_awarded',
        jsonb_build_object('title', new.title, 'request_id', new.id, 'route', '/feed/' || new.id));
    end loop;
  end if;
  return null;
end $$;

create trigger requests_group_buy_awarded
  after update of status on public.requests
  for each row when (new.group_buy) execute function private.on_group_buy_awarded();

-- Grants -------------------------------------------------------------------------------------------------------
revoke execute on function
  public.set_group_buy(uuid, boolean, text, numeric),
  public.join_group_buy(uuid, numeric, text),
  public.leave_group_buy(uuid),
  public.get_group_buy(uuid),
  public.get_group_members(uuid),
  public.set_quote_tiers(uuid, jsonb)
  from public, anon, authenticated;
grant execute on function
  public.set_group_buy(uuid, boolean, text, numeric),
  public.join_group_buy(uuid, numeric, text),
  public.leave_group_buy(uuid),
  public.get_group_buy(uuid),
  public.get_group_members(uuid),
  public.set_quote_tiers(uuid, jsonb)
  to authenticated, service_role;
grant execute on function public.get_group_buy(uuid) to anon;
