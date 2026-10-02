-- Trends pipeline schema (migrations 1200-1220): isolation from the app roles, seeded settings
-- (web/trends_site/data/config.json), output bucket, and the admin_trends_* RPCs
-- (admin only, audited, review queue, kill switch, ramp, settings floors, corrections).
begin;
\ir _helpers.psql
select plan(66);

select tests.create_user('tr-admin', 'Trends Admin', '{buyer,admin}') as admin \gset
select tests.create_user('tr-user', 'Plain User') as usr \gset

-- isolation -------------------------------------------------------------------------------------------
select has_schema('trends', 'trends schema exists');
select is(
  (select array_agg(c.relname::text order by c.relname) from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'trends' and c.relkind = 'r'),
  array['trend_drafts','trend_health','trend_publish_log','trend_runs','trend_settings','trend_signals','trend_sources','trend_topics'],
  'trends tables');
select is((select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'trends' and c.relkind = 'r' and not c.relrowsecurity), 0, 'RLS on every trends table');
select ok(not has_schema_privilege('anon', 'trends', 'usage'), 'anon has no access to the trends schema');
select ok(not has_schema_privilege('authenticated', 'trends', 'usage'), 'authenticated has no access to the trends schema');
select ok(has_schema_privilege('service_role', 'trends', 'usage'), 'service_role uses the trends schema');
select ok(has_table_privilege('service_role', 'trends.trend_drafts', 'select,insert,update'), 'service_role reads and writes drafts');
select ok(not has_table_privilege('service_role', 'trends.trend_publish_log', 'update'), 'publish log is not updatable');
select is((select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'trends' and (has_function_privilege('anon', p.oid, 'execute')
                                            or has_function_privilege('authenticated', p.oid, 'execute'))),
  0, 'no trends.* function is executable by anon or authenticated');
select is((select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname like 'admin\_trends\_%' and has_function_privilege('anon', p.oid, 'execute')),
  0, 'anon cannot execute admin_trends_* RPCs');
select is((select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname like 'admin\_trends\_%' and not p.prosecdef), 0,
  'admin_trends_* RPCs are security definer');
select is((select count(*)::int from information_schema.table_constraints tc
            where tc.constraint_type = 'FOREIGN KEY' and tc.table_schema = 'public'
              and exists (select 1 from information_schema.constraint_column_usage u
                           where u.constraint_name = tc.constraint_name and u.table_schema = 'trends')), 0,
  'nothing in public depends on trends (the schema can be dropped)');

-- seeded settings (config.json) ----------------------------------------------------------------------
select is((select value -> 'ramp_levels' from trends.trend_settings where key = 'caps'), '[1, 2, 5, 10, 20]'::jsonb, 'ramp levels');
select is((select (value ->> 'max_per_hour')::int from trends.trend_settings where key = 'caps'), 3, 'max 3 per hour');
select is((select (value ->> 'hard_max_per_day')::int from trends.trend_settings where key = 'caps'), 20, 'max 20 per day');
select is((select value from trends.trend_settings where key = 'gates') - 'max_rewrites',
  '{"min_sources": 2, "max_similarity": 0.2, "shingle_words": 6, "max_quote_words": 25, "min_words": 250,
    "min_section_words": 15, "max_perspective_ratio": 1.5, "noindex_min_visits_14d": 20}'::jsonb, 'gate thresholds as in config.json');
select is((select jsonb_array_length(value) from trends.trend_settings where key = 'sensitive_tags'), 20, 'sensitive tags');
select is((select jsonb_array_length(value) from trends.trend_settings where key = 'sensitive_keywords'), 43, 'sensitive keywords');
select is((select jsonb_array_length(value) from trends.trend_settings where key = 'banned_perspective_terms'), 20, 'banned perspective terms');
select is((select value ->> 'paused' from trends.trend_settings where key = 'publishing'), 'false', 'kill switch off');
select is(trends.pipeline_enabled(), false, 'pipeline cron disabled until enabled in one project');
select is(trends.per_day_cap('usa'), 1, 'month 1: 1 per day (usa)');
select is(trends.per_day_cap('india'), 1, 'month 1: 1 per day (india)');
select ok((select count(*) from trends.trend_sources where kind = 'google_trends' and geo ~ '^(IN|US)-') >= 6, 'state geos seeded');

select is((select public from storage.buckets where id = 'trends-public'), true, 'trends-public bucket is public');
select is((select allowed_mime_types from storage.buckets where id = 'trends-public'), array['application/json'], 'JSON only');

-- fixtures (as the superuser: the trends schema is not reachable from the API roles) ----------------
update trends.trend_settings set value = value || '{"usa": {"level": 0, "changed_at": null}}' where key = 'ramp';
delete from trends.trend_health;
insert into trends.trend_topics (id, country, place_slug, place_name, level, title, norm_title, status, velocity)
values ('00000000-0000-4000-8000-0000000000a1', 'usa', 'chicago', 'Chicago', 'metro', 'Chicago police close roads', 'chicago police close roads', 'review', 80),
       ('00000000-0000-4000-8000-0000000000a2', 'usa', 'chicago', 'Chicago', 'metro', 'Chicago snow', 'chicago snow', 'published', 60);
insert into trends.trend_drafts (id, topic_id, country, status, review_stage, sensitive, sensitive_reasons, gates)
values ('00000000-0000-4000-8000-0000000000d1', '00000000-0000-4000-8000-0000000000a1', 'usa', 'review', 'topic', true,
        '{keyword:police}', '{"sources": {"passed": true}, "sensitive": {"passed": false}}');
insert into trends.trend_drafts (id, topic_id, country, slug, status, article, published_at, storage_path)
values ('00000000-0000-4000-8000-0000000000d2', '00000000-0000-4000-8000-0000000000a2', 'usa', 'chicago-snow', 'published',
        '{"slug": "chicago-snow", "headline": "Chicago snow", "corrections": []}', now() - interval '2 hours', 'articles/chicago-snow.json'),
       ('00000000-0000-4000-8000-0000000000d3', '00000000-0000-4000-8000-0000000000a2', 'usa', 'chicago-snow-2', 'published',
        '{"slug": "chicago-snow-2", "headline": "Chicago snow 2"}', now() - interval '1 hour', 'articles/chicago-snow-2.json');

-- non-admins ---------------------------------------------------------------------------------------------
select tests.authenticate_as(:'usr');
select throws_ok($$ select public.admin_trends_board() $$, 'PT403', 'admin_only', 'non-admins cannot read the trend board');
select throws_ok($$ select public.admin_trends_set_kill_switch(true, 'x') $$, 'PT403', 'admin_only', 'non-admins cannot pause');
select throws_ok($$ select count(*) from trends.trend_drafts $$, '42501', null, 'authenticated cannot read trends tables');
select tests.clear_auth();
reset role;

-- admin reads ------------------------------------------------------------------------------------------------
select tests.authenticate_as(:'admin');
select is((select count(*)::int from jsonb_array_elements(public.admin_trends_board() -> 'places') p
            where p ->> 'place_slug' = 'chicago'), 1, 'board groups topics by place');
select is((select jsonb_array_length(p -> 'topics') from jsonb_array_elements(public.admin_trends_board('usa') -> 'places') p
            where p ->> 'place_slug' = 'chicago'), 2, 'board lists the topics of a place');
select is((select count(*)::int from jsonb_array_elements(public.admin_trends_review_queue()) q
            where q ->> 'id' = '00000000-0000-4000-8000-0000000000d1'), 1, 'review queue');
select is((select count(*)::int from jsonb_array_elements(public.admin_trends_drafts('published')) d
            where d ->> 'slug' like 'chicago-snow%'), 2, 'published list');
select is(public.admin_trends_draft('00000000-0000-4000-8000-0000000000d1') -> 'gates' -> 'sources' ->> 'passed', 'true', 'gate results per draft');
select is((public.admin_trends_settings() -> 'per_day' ->> 'usa')::int, 1, 'settings payload has the effective caps');
select throws_ok($$ select public.admin_trends_draft('00000000-0000-4000-8000-00000000ffff') $$, 'PT404', 'draft_not_found', 'unknown draft');

-- review queue: topic stage then content stage -------------------------------------------------------
select is(public.admin_trends_review('00000000-0000-4000-8000-0000000000d1', true, 'road closures only') ->> 'status', 'queued',
  'approving a sensitive topic queues it for drafting');
select throws_ok($$ select public.admin_trends_review('00000000-0000-4000-8000-0000000000d1', true) $$, 'PT409', 'draft_not_in_review',
  'only drafts in review can be reviewed');
select tests.clear_auth();
reset role;
select is((select topic_reviewed_by from trends.trend_drafts where id = '00000000-0000-4000-8000-0000000000d1'), :'admin'::uuid,
  'topic reviewer stored');
select is((select status from trends.trend_topics where id = '00000000-0000-4000-8000-0000000000a1'), 'fired', 'approved topic fires for drafting');
-- the pipeline drafts it and sends the finished text back to review
update trends.trend_drafts set status = 'review', review_stage = 'content', slug = 'chicago-police-close-roads',
       article = '{"slug": "chicago-police-close-roads", "review": {"approved_by": null, "approved_at": null}}'
 where id = '00000000-0000-4000-8000-0000000000d1';
select tests.authenticate_as(:'admin');
select is(public.admin_trends_review('00000000-0000-4000-8000-0000000000d1', true) ->> 'status', 'queued', 'content approval queues for publishing');
select tests.clear_auth();
reset role;
select is((select (reviewer_id = :'admin'::uuid and reviewed_at is not null) from trends.trend_drafts
            where id = '00000000-0000-4000-8000-0000000000d1'), true, 'reviewer and date stored');
select ok((select article -> 'review' ->> 'approved_by' like 'editor:%' and article -> 'review' ->> 'approved_at' is not null
             from trends.trend_drafts where id = '00000000-0000-4000-8000-0000000000d1'), 'article carries the recorded approval');
select is((select count(*)::int from public.admin_audit_log where action = 'admin_trends_review' and actor_id = :'admin'), 2,
  'both reviews audited');
select is((select array_agg(decision order by id) from trends.trend_publish_log where draft_id = '00000000-0000-4000-8000-0000000000d1'),
  array['review_approved', 'review_approved'], 'reviews in the publish decision log');
select throws_ok($$ update trends.trend_publish_log set reason = 'x' $$, 'PT403', 'publish_log_append_only', 'decision log is append-only');

-- kill switch -------------------------------------------------------------------------------------------------
select tests.authenticate_as(:'admin');
select is(public.admin_trends_set_kill_switch(true, 'checking a complaint') ->> 'paused', 'true', 'kill switch on');
select tests.clear_auth();
reset role;
select ok((select (value ->> 'paused_at') is not null from trends.trend_settings where key = 'publishing'), 'paused_at recorded');
select is((select count(*)::int from public.admin_audit_log where action = 'admin_trends_set_kill_switch'), 1, 'kill switch audited');
select tests.authenticate_as(:'admin');
select is(public.admin_trends_set_kill_switch(false, 'resolved') ->> 'paused', 'false', 'kill switch off again');

-- ramp ------------------------------------------------------------------------------------------------------------
select throws_ok($$ select public.admin_trends_set_ramp('usa', 2) $$, 'PT409', 'ramp_one_level_at_a_time', 'one level at a time');
select throws_ok($$ select public.admin_trends_set_ramp('usa', 1) $$, 'PT409', 'ramp_unhealthy', 'no step up without healthy indexing data');
select lives_ok($$ select public.admin_trends_record_health('usa', 0.85, 1000, 950, 0, false, 0, 'GSC weekly') $$, 'health recorded');
select is(public.admin_trends_set_ramp('usa', 1, 'month 2') -> 'usa' ->> 'level', '1', 'step up with healthy data');
select throws_ok($$ select public.admin_trends_set_ramp('usa', 2) $$, 'PT409', 'ramp_step_too_soon', 'steps at least a month apart');
select is(public.admin_trends_set_ramp('usa', 0, 'traffic dipped') -> 'usa' ->> 'level', '0', 'stepping down is always allowed');
select is(public.admin_trends_record_health('india', 0.9, 10, 10, 0, true, 0, 'manual action') ->> 'auto_pause',
  'search_console_manual_action', 'a manual action pauses publishing automatically');
select tests.clear_auth();
reset role;
select is((select value ->> 'paused' from trends.trend_settings where key = 'publishing'), 'true', 'publishing paused by the health signal');

-- settings floors ------------------------------------------------------------------------------------------------
select tests.authenticate_as(:'admin');
select throws_ok($$ select public.admin_trends_set_setting('caps', '{"max_per_hour": 4}') $$, 'PT400', 'invalid_setting_value', 'max 3 per hour');
select throws_ok($$ select public.admin_trends_set_setting('gates', '{"min_sources": 1}') $$, 'PT400', 'invalid_setting_value', 'at least 2 sources');
select throws_ok($$ select public.admin_trends_set_setting('publishing', '{"paused": false}') $$, 'PT400', 'use_admin_trends_set_kill_switch',
  'kill switch only through its RPC');
select is(public.admin_trends_set_setting('detection', '{"fire_threshold": 70}') -> 'value' ->> 'fire_threshold', '70',
  'thresholds editable (merged)');

-- corrections, noindex, supersede ------------------------------------------------------------------------------
select lives_ok($$ select public.admin_trends_add_correction('00000000-0000-4000-8000-0000000000d2',
  'The snowfall total was 4 inches, not 6.') $$, 'admin adds a correction');
select is(jsonb_array_length(public.admin_trends_draft('00000000-0000-4000-8000-0000000000d2') -> 'article' -> 'corrections'), 1,
  'correction appended to the article (re-uploaded by trends-publish)');
select is(public.admin_trends_supersede('chicago-snow', 'chicago-snow-2') ->> 'status', 'noindex', 'superseded article becomes noindex');
select is(public.admin_trends_set_draft_status('00000000-0000-4000-8000-0000000000d3', 'unpublish', 'duplicate') ->> 'status', 'rejected',
  'unpublish');

select * from finish();
rollback;
