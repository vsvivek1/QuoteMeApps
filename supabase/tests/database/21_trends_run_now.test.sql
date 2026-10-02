-- Admin "Run now" rate limit for the trends Edge Functions (migration 1300): at most 6 admin
-- runs per function per rolling hour per project, recorded in trends.trend_runs, cron runs not
-- counted, Retry-After from the oldest run in the window, usage shown in admin_trends_settings.
begin;
\ir _helpers.psql
select plan(24);

select tests.create_user('trn-admin', 'Run Admin', '{buyer,admin}') as admin \gset
select tests.create_user('trn-user', 'Plain User') as usr \gset

-- schema and grants -----------------------------------------------------------------------------------
select has_column('trends', 'trend_runs', 'trigger', 'trend_runs.trigger');
select has_column('trends', 'trend_runs', 'actor_id', 'trend_runs.actor_id');
select is((select column_default from information_schema.columns
            where table_schema = 'trends' and table_name = 'trend_runs' and column_name = 'trigger'), '''cron''::text',
  'runs default to cron');
select throws_ok($$ insert into trends.trend_runs (fn, trigger) values ('trends-poll', 'manual') $$, '23514', null,
  'trigger is cron or admin');
select is(trends.run_now_limit(), '{"max_per_window": 6, "window_seconds": 3600}'::jsonb, '6 per hour');
select ok(not has_function_privilege('authenticated', 'trends.start_admin_run(text,uuid,boolean)', 'execute'),
  'authenticated cannot start runs directly');
select ok(not has_function_privilege('anon', 'trends.run_now_usage(text)', 'execute'), 'anon cannot read usage');
select ok(has_function_privilege('service_role', 'trends.start_admin_run(text,uuid,boolean)', 'execute'),
  'service_role (Edge Functions) starts admin runs');
select is((select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'trends' and (has_function_privilege('anon', p.oid, 'execute')
                                            or has_function_privilege('authenticated', p.oid, 'execute'))),
  0, 'still no trends.* function executable by anon or authenticated');

-- limit ------------------------------------------------------------------------------------------------
delete from trends.trend_runs;
-- cron runs never count
insert into trends.trend_runs (fn) select 'trends-draft' from generate_series(1, 20);
select is((trends.run_now_usage('trends-draft') ->> 'used')::int, 0, 'cron runs are not counted');

select is((trends.start_admin_run('trends-draft', :'admin', false) ->> 'allowed')::boolean, true, 'first admin run allowed');
select is((select trigger || ':' || (actor_id = :'admin')::text from trends.trend_runs where trigger = 'admin'), 'admin:true',
  'admin run recorded with the admin id');
select is((select count(*)::int from public.admin_audit_log where action = 'admin_trends_run_now' and actor_id = :'admin'), 1,
  'admin run audited');

-- four more inside the hour (5 used), one older than the window (not counted)
insert into trends.trend_runs (fn, trigger, actor_id, started_at)
select 'trends-draft', 'admin', :'admin'::uuid, now() - interval '50 minutes' from generate_series(1, 2)
union all select 'trends-draft', 'admin', :'admin'::uuid, now() - interval '10 minutes' from generate_series(1, 2)
union all select 'trends-draft', 'admin', :'admin'::uuid, now() - interval '61 minutes';
select is((trends.run_now_usage('trends-draft') ->> 'used')::int, 5, 'runs older than an hour drop out of the window');

select is(trends.start_admin_run('trends-draft', :'admin', true) - 'run_id',
  '{"allowed": true, "used": 6, "limit": 6, "remaining": 0, "window_seconds": 3600, "retry_after_seconds": 600}'::jsonb,
  'sixth run allowed, nothing left');
select is(trends.start_admin_run('trends-draft', :'admin', false),
  '{"allowed": false, "used": 6, "limit": 6, "remaining": 0, "window_seconds": 3600, "retry_after_seconds": 600}'::jsonb,
  'seventh run refused; Retry-After = when the oldest run in the window leaves it');
select is((select count(*)::int from trends.trend_runs where fn = 'trends-draft' and trigger = 'admin'
             and started_at > now() - interval '1 hour'), 6, 'refused run is not recorded');
select is((trends.start_admin_run('trends-poll', :'admin', false) ->> 'allowed')::boolean, true,
  'the limit is per function');
select throws_ok($$ select trends.start_admin_run('trends-other', md5('x')::uuid, false) $$, 'PT400', 'invalid_function',
  'unknown function');
select throws_ok($$ select trends.start_admin_run('trends-poll', null, false) $$, 'PT400', 'actor_required',
  'admin id required');

-- admin_trends_settings shows the usage ------------------------------------------------------------------------
select tests.authenticate_as(:'admin');
select is((public.admin_trends_settings() -> 'run_now' -> 'trends-draft' ->> 'remaining')::int, 0,
  'settings payload: draft window used up');
select is((public.admin_trends_settings() -> 'run_now' -> 'trends-poll' ->> 'remaining')::int, 5,
  'settings payload: poll has 5 left');
select ok(public.admin_trends_settings() -> 'runs' -> 'trends-draft' ? 'trigger', 'last run shows its trigger');
select tests.clear_auth();
reset role;
select tests.authenticate_as(:'usr');
select throws_ok($$ select public.admin_trends_settings() $$, 'PT403', 'admin_only', 'non-admins cannot read the usage');
select tests.clear_auth();
reset role;

select * from finish();
rollback;
