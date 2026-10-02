-- 1300 Rate limit for the admin "Run now" buttons of trends-poll / trends-draft / trends-publish.
--
-- An admin JWT may start each trends function at most 6 times per rolling hour per project
-- (across all admins), so repeated clicks cannot run up Claude spend. The cron calls
-- (x-webhook-secret / service role) are not limited. Admin runs are recorded in
-- trends.trend_runs with trigger = 'admin' and the admin's id; the Edge Function asks
-- trends.start_admin_run() before doing anything and answers 429 rate_limited with
-- Retry-After when the window is full. The check and the insert happen under one
-- transaction-level advisory lock per function, so concurrent clicks cannot both pass.
set search_path = public, extensions;

alter table trends.trend_runs
  add column if not exists trigger text not null default 'cron' check (trigger in ('cron', 'admin')),
  add column if not exists actor_id uuid;
create index if not exists trend_runs_admin_idx on trends.trend_runs (fn, started_at desc) where trigger = 'admin';

comment on column trends.trend_runs.trigger is 'cron (pg_cron / service role) or admin (Run now from the admin panel)';
comment on column trends.trend_runs.actor_id is 'admin profile id for trigger = admin';

-- The limit (not a setting: the panel must not be able to raise it).
create or replace function trends.run_now_limit()
returns jsonb
language sql
immutable
set search_path = ''
as $$ select jsonb_build_object('max_per_window', 6, 'window_seconds', 3600) $$;

-- Usage of the admin "Run now" window for one function (no side effects).
create or replace function trends.run_now_usage(p_fn text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_lim jsonb := trends.run_now_limit();
  v_max int := (v_lim ->> 'max_per_window')::int;
  v_window interval := make_interval(secs => (v_lim ->> 'window_seconds')::int);
  v_used int;
  v_oldest timestamptz;
begin
  select count(*)::int, min(started_at) into v_used, v_oldest
    from trends.trend_runs
   where fn = p_fn and trigger = 'admin' and started_at > now() - v_window;
  return jsonb_build_object(
    'used', v_used, 'limit', v_max, 'window_seconds', (v_lim ->> 'window_seconds')::int,
    'remaining', greatest(v_max - v_used, 0),
    'retry_after_seconds', case when v_used >= v_max
      then greatest(1, ceil(extract(epoch from (v_oldest + v_window - now())))::int) else 0 end);
end $$;

-- Called by the Edge Function (SUPABASE_DB_URL) for an admin "Run now": records the run in
-- trend_runs and returns {allowed: true, run_id, used, limit, remaining}, or
-- {allowed: false, retry_after_seconds, used, limit} without recording anything.
create or replace function trends.start_admin_run(p_fn text, p_actor uuid, p_dry_run boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usage jsonb;
  v_id bigint;
begin
  if p_fn not in ('trends-poll', 'trends-draft', 'trends-publish') then
    raise exception using errcode = 'PT400', message = 'invalid_function';
  end if;
  if p_actor is null then
    raise exception using errcode = 'PT400', message = 'actor_required';
  end if;
  perform pg_advisory_xact_lock(hashtext('trends_run_now:' || p_fn));
  v_usage := trends.run_now_usage(p_fn);
  if (v_usage ->> 'remaining')::int <= 0 then
    return v_usage || jsonb_build_object('allowed', false);
  end if;
  insert into trends.trend_runs (fn, dry_run, trigger, actor_id)
  values (p_fn, coalesce(p_dry_run, false), 'admin', p_actor)
  returning id into v_id;
  insert into public.admin_audit_log (actor_id, action, target_type, target_id, details)
  values ((select id from public.profiles where id = p_actor), 'admin_trends_run_now', 'trend_run', v_id::text,
          jsonb_build_object('fn', p_fn, 'dry_run', coalesce(p_dry_run, false)));
  return trends.run_now_usage(p_fn) || jsonb_build_object('allowed', true, 'run_id', v_id);
end $$;

-- admin_trends_settings: same payload as 1210 plus run_now = {fn: usage} for the Run now buttons.
create or replace function public.admin_trends_settings()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return jsonb_build_object(
    'settings', coalesce((select jsonb_object_agg(key, value) from trends.trend_settings), '{}'::jsonb),
    'descriptions', coalesce((select jsonb_object_agg(key, description) from trends.trend_settings), '{}'::jsonb),
    'per_day', jsonb_build_object('usa', trends.per_day_cap('usa'), 'india', trends.per_day_cap('india')),
    'health', jsonb_build_object(
      'usa', (select to_jsonb(h) from trends.trend_health h where country = 'usa' order by recorded_at desc limit 1),
      'india', (select to_jsonb(h) from trends.trend_health h where country = 'india' order by recorded_at desc limit 1)),
    'health_problem', jsonb_build_object('usa', trends.health_problem('usa'), 'india', trends.health_problem('india')),
    'published_24h', jsonb_build_object(
      'usa', (select count(*) from trends.trend_drafts where country = 'usa' and published_at > now() - interval '24 hours'),
      'india', (select count(*) from trends.trend_drafts where country = 'india' and published_at > now() - interval '24 hours')),
    'runs', coalesce((select jsonb_object_agg(fn, to_jsonb(r) - 'fn')
                      from (select distinct on (fn) * from trends.trend_runs order by fn, started_at desc) r), '{}'::jsonb),
    'run_now', jsonb_build_object(
      'trends-poll', trends.run_now_usage('trends-poll'),
      'trends-draft', trends.run_now_usage('trends-draft'),
      'trends-publish', trends.run_now_usage('trends-publish')));
end $$;

revoke all on function trends.run_now_limit() from public, anon, authenticated;
revoke all on function trends.run_now_usage(text) from public, anon, authenticated;
revoke all on function trends.start_admin_run(text, uuid, boolean) from public, anon, authenticated;
grant execute on function trends.run_now_limit() to service_role;
grant execute on function trends.run_now_usage(text) to service_role;
grant execute on function trends.start_admin_run(text, uuid, boolean) to service_role;
