-- 3400 Community feed: buyers may publish a request to a public feed where
-- anyone can read it and signed-in users can like and comment on it.
-- Requests stay private unless the buyer opts in (publish_request). The
-- public projection never includes the buyer's id, contact details, exact
-- location, media or a hidden budget.
set search_path = public, extensions;

insert into public.app_settings (key, value, is_public, description) values
  ('community_feed_enabled', 'true', true,
   'Show the community feed and allow publishing requests to it (kill switch for user-generated content)'),
  ('comments_per_10_min', '20', false, 'Max comments one user may post in 10 minutes'),
  ('comment_max_length', '1000', true, 'Max characters in a feed comment')
on conflict (key) do nothing;

-- requests: opt-in flag + denormalized counters --------------------------------------------
alter table public.requests
  add column is_public boolean not null default false,
  add column published_at timestamptz,
  add column comment_count int not null default 0 check (comment_count >= 0),
  add column like_count int not null default 0 check (like_count >= 0),
  -- group buy (20261003400100_group_buy.sql): others join with a quantity and
  -- sellers quote per-unit price tiers, so the price drops as the group grows
  add column group_buy boolean not null default false,
  add column group_unit text check (group_unit is null or length(trim(group_unit)) between 1 and 24),
  add column group_qty numeric(12,3) not null default 0 check (group_qty >= 0),
  add column group_members int not null default 0 check (group_members >= 0),
  add check (not group_buy or is_public);

create index requests_public_feed_idx on public.requests (published_at desc, id desc)
  where is_public and not hidden;

-- comments ------------------------------------------------------------------------------------
create table public.request_comments (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.requests(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  -- one level of replies: a reply's parent is always a top-level comment
  parent_id uuid references public.request_comments(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 4000),
  -- the author posted as their business (shows the seller badge + profile link)
  as_seller boolean not null default false,
  hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index request_comments_request_idx on public.request_comments (request_id, created_at);
create index request_comments_author_idx on public.request_comments (author_id, created_at desc);

create table public.request_likes (
  request_id uuid not null references public.requests(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (request_id, user_id)
);
create index request_likes_user_idx on public.request_likes (user_id);

do $$
declare t text;
begin
  foreach t in array array['request_comments','request_likes'] loop
    perform private.add_updated_at_trigger(('public.' || t)::regclass);
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- Clients read comments through get_feed_comments (display names, hidden
-- filtering, blocks); direct reads are limited to own rows and admins.
grant select on public.request_comments, public.request_likes to authenticated;
create policy request_comments_read on public.request_comments for select to authenticated
  using (author_id = auth.uid() or private.is_admin());
create policy request_likes_read_own on public.request_likes for select to authenticated
  using (user_id = auth.uid() or private.is_admin());

-- reports: comments can be reported and hidden like other content -------------------------------
alter table public.reports drop constraint if exists reports_target_type_check;
alter table public.reports add constraint reports_target_type_check
  check (target_type in ('request','quote','message','review','seller','user','comment'));

create or replace function private.refresh_comment_count(p_request_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.requests r
     set comment_count = (select count(*) from public.request_comments c
                           where c.request_id = p_request_id and not c.hidden)
   where r.id = p_request_id
$$;

create or replace function private.set_target_hidden(p_type text, p_id uuid, p_hidden boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_request uuid;
begin
  case p_type
    when 'request' then update public.requests set hidden = p_hidden where id = p_id;
    when 'quote' then update public.quotes set hidden = p_hidden where id = p_id;
    when 'message' then update public.messages set hidden = p_hidden where id = p_id;
    when 'review' then
      update public.reviews set hidden = p_hidden where id = p_id;
      perform private.refresh_seller_rating(r.to_id) from public.reviews r where r.id = p_id and r.role = 'buyer_to_seller';
    when 'seller' then update public.sellers set hidden = p_hidden where id = p_id;
    when 'comment' then
      update public.request_comments set hidden = p_hidden where id = p_id returning request_id into v_request;
      if v_request is not null then
        perform private.refresh_comment_count(v_request);
      end if;
    else null; -- 'user': admins decide (suspend/ban)
  end case;
end $$;

create or replace function public.report_content(
  p_target_type text, p_target_id uuid, p_reason text, p_details text default null)
returns public.reports
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_report public.reports;
  v_count int;
begin
  if p_target_type not in ('request','quote','message','review','seller','user','comment') then
    perform private.raise_error('invalid_target_type', 400);
  end if;
  if p_reason not in ('spam','fraud','abusive','inappropriate','prohibited_item','fake','other') then
    perform private.raise_error('invalid_reason', 400);
  end if;
  -- rate limit reports per user
  if not private.rate_limit_hit('report:' || v_uid, 30, 3600) then
    perform private.raise_error('rate_limited', 429);
  end if;
  insert into public.reports (reporter_id, target_type, target_id, reason, details)
  values (v_uid, p_target_type, p_target_id, p_reason, left(p_details, 2000))
  on conflict (reporter_id, target_type, target_id) do update set reason = excluded.reason, details = excluded.details
  returning * into v_report;

  select count(distinct reporter_id) into v_count from public.reports
   where target_type = p_target_type and target_id = p_target_id and status = 'open';
  if v_count >= private.setting_int('auto_hide_report_threshold', 3) then
    perform private.set_target_hidden(p_target_type, p_target_id, true);
  end if;
  return v_report;
end $$;

-- Helpers -----------------------------------------------------------------------------------------
-- "Priya S." style public name (same rule as get_profiles_public).
create or replace function private.public_display_name(p_name text, p_status text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case when p_status = 'deleted' then 'Deleted user'
              else coalesce(nullif(trim(split_part(coalesce(p_name, ''), ' ', 1) ||
                     coalesce(' ' || nullif(left(split_part(coalesce(p_name, ''), ' ', 2), 1), '') || '.', '')), ''),
                   'Member') end
$$;

-- A request that anyone may see on the feed right now.
create or replace function private.is_feed_visible(p_request public.requests)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_request.is_public and not p_request.hidden and p_request.status <> 'cancelled'
     and private.setting_bool('community_feed_enabled', true)
     and exists (select 1 from public.profiles p where p.id = p_request.buyer_id and p.status = 'active')
$$;

-- Buyer publishes (or unpublishes) an own request ----------------------------------------------------
-- Group-buy options are set by set_group_buy (next migration).
create or replace function public.publish_request(p_request_id uuid, p_public boolean default true)
returns public.requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_req public.requests;
begin
  select * into v_req from public.requests where id = p_request_id for update;
  if not found or v_req.buyer_id <> v_uid then
    perform private.raise_error('request_not_found', 404);
  end if;
  if p_public and not private.setting_bool('community_feed_enabled', true) then
    perform private.raise_error('feature_disabled', 403);
  end if;
  if p_public and v_req.status <> 'open' then
    perform private.raise_error('request_not_open', 409);
  end if;
  if p_public and v_req.hidden then
    perform private.raise_error('request_not_found', 404);
  end if;
  -- a group buy lives on the feed; it can only be taken down while nobody else joined
  if not p_public and v_req.group_buy and v_req.group_members > 1 then
    perform private.raise_error('group_has_members', 409);
  end if;
  update public.requests
     set is_public = p_public,
         group_buy = group_buy and p_public,
         published_at = case when p_public then coalesce(published_at, now()) else published_at end
   where id = p_request_id
  returning * into v_req;
  return v_req;
end $$;

-- Public post projection --------------------------------------------------------------------------------
-- Group-buy fields are filled in by the group-buy migration, which replaces
-- private.feed_post_json; until then they are absent.
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
       select 1 from public.request_likes l where l.request_id = p_request.id and l.user_id = p_viewer))
    from public.categories c, public.profiles p
   where c.id = p_request.category_id and p.id = p_request.buyer_id
$$;

-- Feed (anon + authenticated) ---------------------------------------------------------------------------
-- p_filters: {"category_id": n, "state": "...", "city": "...", "q": "text",
--             "group_buy_only": bool, "open_only": bool, "mine": bool}
-- p_cursor:  {"published_at": "...", "id": "..."} from the last row of the previous page.
create or replace function public.get_community_feed(
  p_filters jsonb default '{}'::jsonb, p_cursor jsonb default null, p_limit int default 20)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_f jsonb := coalesce(p_filters, '{}'::jsonb);
  v_q text := nullif(private.normalize_text(v_f->>'q'), '');
  v_cur_at timestamptz := (p_cursor->>'published_at')::timestamptz;
  v_cur_id uuid := (p_cursor->>'id')::uuid;
begin
  if not private.setting_bool('community_feed_enabled', true) then
    return;
  end if;
  return query
    select private.feed_post_json(r, v_uid)
      from public.requests r
     where r.is_public and not r.hidden and r.status <> 'cancelled'
       and exists (select 1 from public.profiles p where p.id = r.buyer_id and p.status = 'active')
       and (v_uid is null or not private.is_blocked_between(v_uid, r.buyer_id))
       and (v_f->>'category_id' is null
            or r.category_id = (v_f->>'category_id')::bigint
            or r.category_id in (select c.id from public.categories c where c.parent_id = (v_f->>'category_id')::bigint))
       and (v_f->>'state' is null or r.state = v_f->>'state')
       and (v_f->>'city' is null or r.city = v_f->>'city')
       and (coalesce((v_f->>'open_only')::boolean, false) = false or r.status = 'open')
       and (coalesce((v_f->>'mine')::boolean, false) = false or r.buyer_id = v_uid)
       and (v_q is null or private.normalize_text(r.title || ' ' || coalesce(r.description, '')) like '%' || v_q || '%')
       and (coalesce((v_f->>'group_buy_only')::boolean, false) = false
            or r.group_buy)
       and (v_cur_at is null or (r.published_at, r.id) < (v_cur_at, v_cur_id))
     order by r.published_at desc, r.id desc
     limit greatest(1, least(coalesce(p_limit, 20), 50));
end $$;

create or replace function public.get_feed_post(p_request_id uuid)
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
  if not found or not (private.is_feed_visible(v_req) or coalesce(v_req.buyer_id = v_uid, false))
     or (v_uid is not null and v_req.buyer_id <> v_uid and private.is_blocked_between(v_uid, v_req.buyer_id)) then
    perform private.raise_error('post_not_found', 404);
  end if;
  return private.feed_post_json(v_req, v_uid);
end $$;

-- Comments -------------------------------------------------------------------------------------------------
create or replace function public.get_feed_comments(
  p_request_id uuid, p_cursor jsonb default null, p_limit int default 50)
returns table (
  id uuid, parent_id uuid, body text, created_at timestamptz,
  author_name text, author_photo_url text, as_seller boolean, seller_id uuid,
  business_name text, seller_verified boolean, is_mine boolean, is_post_author boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid();
  v_req public.requests;
  v_cur_at timestamptz := (p_cursor->>'created_at')::timestamptz;
  v_cur_id uuid := (p_cursor->>'id')::uuid;
begin
  select * into v_req from public.requests r where r.id = p_request_id;
  if not found or not (private.is_feed_visible(v_req) or coalesce(v_req.buyer_id = v_uid, false)) then
    perform private.raise_error('post_not_found', 404);
  end if;
  return query
    select c.id, c.parent_id, c.body, c.created_at,
           case when c.as_seller and s.id is not null then s.business_name
                else private.public_display_name(p.name, p.status) end,
           case when p.status = 'deleted' then null
                when c.as_seller and s.id is not null then s.logo_url
                else p.photo_url end,
           c.as_seller and s.id is not null,
           case when c.as_seller then s.id end,
           case when c.as_seller then s.business_name end,
           coalesce(c.as_seller and s.verification_status = 'verified', false),
           v_uid is not null and c.author_id = v_uid,
           c.author_id = v_req.buyer_id
      from public.request_comments c
      join public.profiles p on p.id = c.author_id
      left join public.sellers s on s.id = c.author_id and not s.hidden
     where c.request_id = p_request_id
       and (not c.hidden or (v_uid is not null and c.author_id = v_uid))
       and (v_uid is null or c.author_id = v_uid or not private.is_blocked_between(v_uid, c.author_id))
       and (v_cur_at is null or (c.created_at, c.id) > (v_cur_at, v_cur_id))
     order by c.created_at, c.id
     limit greatest(1, least(coalesce(p_limit, 50), 200));
end $$;

create or replace function public.post_comment(
  p_request_id uuid, p_body text, p_parent_id uuid default null, p_as_seller boolean default false)
returns public.request_comments
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_uid uuid := private.require_user();
  v_req public.requests;
  v_parent public.request_comments;
  v_body text := trim(coalesce(p_body, ''));
  v_blocked record;
  v_c public.request_comments;
  v_name text;
begin
  select * into v_req from public.requests where id = p_request_id;
  if not found or not private.is_feed_visible(v_req) then
    perform private.raise_error('post_not_found', 404);
  end if;
  if private.is_blocked_between(v_uid, v_req.buyer_id) then
    perform private.raise_error('blocked', 403);
  end if;
  if length(v_body) = 0 then
    perform private.raise_error('comment_empty', 400);
  end if;
  if length(v_body) > private.setting_int('comment_max_length', 1000) then
    perform private.raise_error('comment_too_long', 400);
  end if;
  if not private.rate_limit_hit('comment:' || v_uid, private.setting_int('comments_per_10_min', 20), 600) then
    perform private.raise_error('rate_limited', 429);
  end if;
  select * into v_blocked from private.find_blocked_keyword(v_body);
  if v_blocked.keyword is not null then
    perform private.raise_error('blocked_content', 422,
      coalesce(v_blocked.reason->>'en', 'This comment mentions something that is not allowed'), v_blocked.keyword);
  end if;
  if p_as_seller and not exists (select 1 from public.sellers s where s.id = v_uid and not s.hidden) then
    perform private.raise_error('not_a_seller', 403);
  end if;
  if p_parent_id is not null then
    select * into v_parent from public.request_comments where id = p_parent_id;
    if not found or v_parent.request_id <> p_request_id or v_parent.hidden then
      perform private.raise_error('comment_not_found', 404);
    end if;
    -- replies to a reply attach to the top-level comment
    p_parent_id := coalesce(v_parent.parent_id, v_parent.id);
  end if;

  insert into public.request_comments (request_id, author_id, parent_id, body, as_seller)
  values (p_request_id, v_uid, p_parent_id, v_body, coalesce(p_as_seller, false))
  returning * into v_c;
  update public.requests set comment_count = comment_count + 1 where id = p_request_id;

  select case when v_c.as_seller then (select business_name from public.sellers where id = v_uid)
              else private.public_display_name(name, status) end
    into v_name from public.profiles where id = v_uid;
  if v_req.buyer_id <> v_uid then
    perform private.notify(v_req.buyer_id, 'feed_comment',
      jsonb_build_object('title', v_req.title, 'request_id', p_request_id, 'comment_id', v_c.id,
                         'author', v_name, 'route', '/feed/' || p_request_id),
      'feed_comment:' || p_request_id);
  end if;
  if v_parent.id is not null then
    -- the top-level comment's author hears about replies in their thread
    select * into v_parent from public.request_comments where id = p_parent_id;
    if v_parent.author_id not in (v_uid, v_req.buyer_id) then
      perform private.notify(v_parent.author_id, 'feed_reply',
        jsonb_build_object('title', v_req.title, 'request_id', p_request_id, 'comment_id', v_c.id,
                           'author', v_name, 'route', '/feed/' || p_request_id),
        'feed_reply:' || p_parent_id);
    end if;
  end if;
  return v_c;
end $$;

-- Authors delete their comments; the post's author may remove comments on it.
create or replace function public.delete_comment(p_comment_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_c public.request_comments;
begin
  select * into v_c from public.request_comments where id = p_comment_id;
  if not found or not (v_c.author_id = v_uid or private.is_request_buyer(v_c.request_id) or private.is_admin()) then
    perform private.raise_error('comment_not_found', 404);
  end if;
  delete from public.request_comments where id = p_comment_id;
  perform private.refresh_comment_count(v_c.request_id);
end $$;

-- Likes ----------------------------------------------------------------------------------------------------
create or replace function public.toggle_request_like(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_req public.requests;
  v_liked boolean;
  v_count int;
begin
  select * into v_req from public.requests where id = p_request_id;
  if not found or not private.is_feed_visible(v_req) or private.is_blocked_between(v_uid, v_req.buyer_id) then
    perform private.raise_error('post_not_found', 404);
  end if;
  if not private.rate_limit_hit('like:' || v_uid, 120, 60) then
    perform private.raise_error('rate_limited', 429);
  end if;
  delete from public.request_likes where request_id = p_request_id and user_id = v_uid;
  if found then
    v_liked := false;
  else
    insert into public.request_likes (request_id, user_id) values (p_request_id, v_uid);
    v_liked := true;
  end if;
  update public.requests
     set like_count = (select count(*) from public.request_likes where request_id = p_request_id)
   where id = p_request_id
  returning like_count into v_count;
  return jsonb_build_object('liked', v_liked, 'like_count', v_count);
end $$;

-- Grants ---------------------------------------------------------------------------------------------------
revoke execute on function
  public.publish_request(uuid, boolean),
  public.get_community_feed(jsonb, jsonb, int),
  public.get_feed_post(uuid),
  public.get_feed_comments(uuid, jsonb, int),
  public.post_comment(uuid, text, uuid, boolean),
  public.delete_comment(uuid),
  public.toggle_request_like(uuid)
  from public, anon, authenticated;
grant execute on function
  public.publish_request(uuid, boolean),
  public.get_community_feed(jsonb, jsonb, int),
  public.get_feed_post(uuid),
  public.get_feed_comments(uuid, jsonb, int),
  public.post_comment(uuid, text, uuid, boolean),
  public.delete_comment(uuid),
  public.toggle_request_like(uuid)
  to authenticated, service_role;
-- signed-out visitors (website, app before sign-in) may read the feed
grant execute on function
  public.get_community_feed(jsonb, jsonb, int),
  public.get_feed_post(uuid),
  public.get_feed_comments(uuid, jsonb, int)
  to anon;
