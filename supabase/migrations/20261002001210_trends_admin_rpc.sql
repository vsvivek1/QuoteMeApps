-- 1210 Admin RPCs for the trend board (admin/TRENDS_ADMIN_NEEDS.md).
--
-- The trends schema is not exposed to PostgREST and has no grants for
-- anon / authenticated, so the admin panel reads and changes it only through
-- these SECURITY DEFINER functions. Every one starts with private.require_admin()
-- (JWT roles claim AND profiles.roles contain admin, account active).
-- Read RPCs are STABLE and not logged; every data-changing RPC writes one
-- public.admin_audit_log row (private.audit) and, for publish decisions, one
-- trends.trend_publish_log row, in the same transaction as the change.
set search_path = public, extensions;

-- Internal helpers ------------------------------------------------------------------------------------
create or replace function trends.draft_summary(d trends.trend_drafts)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', d.id, 'topic_id', d.topic_id, 'country', d.country, 'slug', d.slug, 'status', d.status,
    'headline', coalesce(d.article ->> 'headline', t.title), 'place', t.place_name, 'place_slug', t.place_slug,
    'velocity', d.velocity, 'failed_gate', d.failed_gate, 'reason', d.reason, 'gates', d.gates,
    'sensitive', d.sensitive, 'sensitive_reasons', d.sensitive_reasons, 'review_stage', d.review_stage,
    'topic_reviewed_by', d.topic_reviewed_by, 'topic_reviewed_at', d.topic_reviewed_at,
    'reviewer_id', d.reviewer_id, 'reviewer_name', p.name, 'reviewed_at', d.reviewed_at, 'review_note', d.review_note,
    'has_article', d.article is not null, 'rewrites', d.rewrites, 'model', d.model,
    'published_at', d.published_at, 'last_update_at', d.last_update_at, 'superseded_by', d.superseded_by,
    'noindex_reason', d.noindex_reason, 'visits_14d_after_end', d.visits_14d_after_end,
    'storage_path', d.storage_path, 'dirty', d.dirty, 'created_at', d.created_at, 'updated_at', d.updated_at)
  from (select 1) x
  left join trends.trend_topics t on t.id = d.topic_id
  left join public.profiles p on p.id = d.reviewer_id
$$;

-- Health of a country for ramp step-ups: null when healthy, else the problem.
-- Same rules as supabase/functions/_shared/trends/ramp.ts (healthProblem).
create or replace function trends.health_problem(p_country text)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  h trends.trend_health;
  cfg jsonb := coalesce(trends.setting('ramp') -> 'health', '{}'::jsonb);
begin
  select * into h from trends.trend_health where country = p_country order by recorded_at desc limit 1;
  if h.id is null or h.recorded_at < now() - make_interval(days => coalesce((cfg ->> 'max_age_days')::int, 7)) then
    return 'no_recent_health';
  end if;
  if h.manual_action then return 'manual_action'; end if;
  if h.error_reports_24h > coalesce((cfg ->> 'max_error_reports_24h')::int, 5) then return 'error_reports'; end if;
  if h.sc_warnings > coalesce((cfg ->> 'max_sc_warnings')::int, 0) then return 'search_console_warnings'; end if;
  if h.indexed_share is null or h.indexed_share < coalesce((cfg ->> 'min_indexed_share')::numeric, 0.6) then
    return 'low_indexed_share';
  end if;
  if coalesce(h.clicks_prev_7d, 0) > 0
     and (h.clicks_prev_7d - coalesce(h.clicks_7d, 0))::numeric / h.clicks_prev_7d > coalesce((cfg ->> 'max_click_drop')::numeric, 0.3) then
    return 'traffic_drop';
  end if;
  return null;
end $$;

create or replace function trends.log_decision(
  p_decision text, p_reason text, p_draft trends.trend_drafts default null, p_details jsonb default '{}'::jsonb)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into trends.trend_publish_log (draft_id, topic_id, slug, country, decision, reason, details, actor_id)
  values ((p_draft).id, (p_draft).topic_id, (p_draft).slug, coalesce((p_draft).country, p_details ->> 'country'),
          p_decision, p_reason, coalesce(p_details, '{}'::jsonb), auth.uid())
$$;

-- Read RPCs (STABLE, not logged) ------------------------------------------------------------------------

-- Live trend board by place: active topics (last p_hours) grouped by place, plus feed health.
create or replace function public.admin_trends_board(p_country text default null, p_hours int default 24)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return jsonb_build_object(
    'generated_at', now(),
    'places', coalesce((
      select jsonb_agg(pl order by (pl ->> 'max_velocity')::numeric desc nulls last)
      from (
        select jsonb_build_object(
          'country', t.country, 'place_slug', t.place_slug, 'place_name', max(t.place_name), 'level', max(t.level),
          'max_velocity', max(t.velocity),
          'topics', jsonb_agg(jsonb_build_object(
              'id', t.id, 'title', t.title, 'status', t.status, 'velocity', t.velocity,
              'peak_velocity', t.peak_velocity, 'signal_count', t.signal_count, 'domain_count', t.domain_count,
              'domains', t.domains, 'first_seen', t.first_seen, 'last_seen', t.last_seen,
              'fired_at', t.fired_at, 'status_reason', t.status_reason, 'article_slug', t.article_slug)
            order by t.velocity desc)) pl
        from trends.trend_topics t
        where t.last_seen > now() - make_interval(hours => greatest(1, least(coalesce(p_hours, 24), 720)))
          and (p_country is null or t.country = p_country)
        group by t.country, t.place_slug) x), '[]'::jsonb),
    'sources', coalesce((
      select jsonb_agg(jsonb_build_object('id', s.id, 'kind', s.kind, 'country', s.country, 'geo', s.geo,
                 'place_slug', s.place_slug, 'place_name', s.place_name, 'level', s.level, 'query', s.query,
                 'enabled', s.enabled, 'last_polled_at', s.last_polled_at, 'last_status', s.last_status,
                 'last_error', s.last_error, 'last_items', s.last_items) order by s.country, s.kind, s.place_slug)
      from trends.trend_sources s where p_country is null or s.country = p_country), '[]'::jsonb));
end $$;

-- Topics by status (e.g. 'fired'), newest first.
create or replace function public.admin_trends_topics(
  p_status text default null, p_country text default null, p_limit int default 100)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return coalesce((
    select jsonb_agg(to_jsonb(t) order by coalesce(t.fired_at, t.last_seen) desc)
    from (select * from trends.trend_topics t
           where (p_status is null or t.status = p_status) and (p_country is null or t.country = p_country)
           order by coalesce(t.fired_at, t.last_seen) desc
           limit greatest(1, least(coalesce(p_limit, 100), 500))) t), '[]'::jsonb);
end $$;

-- Drafts list (published / queued / rejected / review / noindex) with gate results.
create or replace function public.admin_trends_drafts(
  p_status text default null, p_country text default null, p_limit int default 100, p_offset int default 0)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return coalesce((
    select jsonb_agg(trends.draft_summary(d) order by coalesce(d.published_at, d.created_at) desc)
    from (select * from trends.trend_drafts d
           where (p_status is null or d.status = p_status) and (p_country is null or d.country = p_country)
           order by coalesce(d.published_at, d.created_at) desc
           limit greatest(1, least(coalesce(p_limit, 100), 500)) offset greatest(0, coalesce(p_offset, 0))) d), '[]'::jsonb);
end $$;

-- One draft in full: article JSON, gates, topic, its signals, decision log.
create or replace function public.admin_trends_draft(p_draft_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare d trends.trend_drafts;
begin
  perform private.require_admin();
  select * into d from trends.trend_drafts where id = p_draft_id;
  if d.id is null then perform private.raise_error('draft_not_found', 404); end if;
  return trends.draft_summary(d) || jsonb_build_object(
    'article', d.article,
    'topic', (select to_jsonb(t) from trends.trend_topics t where t.id = d.topic_id),
    'signals', coalesce((select jsonb_agg(jsonb_build_object('id', s.id, 'source_kind', s.source_kind, 'topic', s.topic,
                     'url', s.url, 'publisher', s.publisher, 'publisher_domain', s.publisher_domain, 'citable', s.citable,
                     'snippet', s.snippet, 'score', s.score, 'first_seen', s.first_seen, 'last_seen', s.last_seen)
                     order by s.first_seen desc)
                   from (select * from trends.trend_signals s where s.topic_id = d.topic_id
                          order by s.first_seen desc limit 100) s), '[]'::jsonb),
    'log', coalesce((select jsonb_agg(to_jsonb(l) order by l.id desc)
               from trends.trend_publish_log l where l.draft_id = d.id), '[]'::jsonb));
end $$;

-- Sensitive-topic review queue (oldest first).
create or replace function public.admin_trends_review_queue(p_country text default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return coalesce((
    select jsonb_agg(trends.draft_summary(d) || jsonb_build_object('article', d.article) order by d.created_at)
    from trends.trend_drafts d
    where d.status = 'review' and (p_country is null or d.country = p_country)), '[]'::jsonb);
end $$;

-- Settings editor payload: every setting, effective caps, latest health, last runs, today's counts.
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
                      from (select distinct on (fn) * from trends.trend_runs order by fn, started_at desc) r), '{}'::jsonb));
end $$;

create or replace function public.admin_trends_publish_log(p_limit int default 100, p_draft_id uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return coalesce((
    select jsonb_agg(to_jsonb(l) order by l.id desc)
    from (select * from trends.trend_publish_log l where p_draft_id is null or l.draft_id = p_draft_id
           order by l.id desc limit greatest(1, least(coalesce(p_limit, 100), 1000))) l), '[]'::jsonb);
end $$;

-- Data-changing RPCs (audited) --------------------------------------------------------------------

-- Sensitive-topic review. Stage 'topic' (nothing drafted yet): approve lets trends-draft write it;
-- stage 'content' (finished draft): approve queues it for publishing (gate 6 still applies).
-- Reviewer and date are stored on the draft; the article carries review.approved_by / approved_at.
create or replace function public.admin_trends_review(p_draft_id uuid, p_approve boolean, p_note text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  d trends.trend_drafts;
  v_stage text;
begin
  select * into d from trends.trend_drafts where id = p_draft_id for update;
  if d.id is null then perform private.raise_error('draft_not_found', 404); end if;
  if d.status <> 'review' then perform private.raise_error('draft_not_in_review', 409); end if;
  v_stage := coalesce(d.review_stage, case when d.article is null then 'topic' else 'content' end);
  if not p_approve then
    update trends.trend_drafts
       set status = 'rejected', failed_gate = 'sensitive', reason = coalesce(p_note, 'rejected by reviewer'),
           reviewer_id = v_admin, reviewed_at = now(), review_note = p_note,
           gates = gates || jsonb_build_object('sensitive', coalesce(gates -> 'sensitive', '{}'::jsonb)
                    || jsonb_build_object('passed', false, 'review', 'rejected', 'stage', v_stage))
     where id = d.id returning * into d;
    update trends.trend_topics set status = 'dropped', status_reason = 'review_rejected' where id = d.topic_id;
  elsif v_stage = 'topic' then
    update trends.trend_drafts
       set status = 'queued', review_stage = null, topic_reviewed_by = v_admin, topic_reviewed_at = now(),
           review_note = p_note,
           gates = gates || jsonb_build_object('sensitive', coalesce(gates -> 'sensitive', '{}'::jsonb)
                    || jsonb_build_object('topic_approved', true))
     where id = d.id returning * into d;
    update trends.trend_topics set status = 'fired', status_reason = 'topic_approved' where id = d.topic_id;
  else
    update trends.trend_drafts
       set status = 'queued', review_stage = null, reviewer_id = v_admin, reviewed_at = now(), review_note = p_note,
           article = jsonb_set(article, '{review}', jsonb_build_object(
                       'approved_by', 'editor:' || left(v_admin::text, 8), 'approved_at', now())),
           gates = gates || jsonb_build_object('sensitive', coalesce(gates -> 'sensitive', '{}'::jsonb)
                    || jsonb_build_object('passed', true, 'review', 'approved'))
     where id = d.id returning * into d;
  end if;
  perform trends.log_decision(case when p_approve then 'review_approved' else 'review_rejected' end,
    p_note, d, jsonb_build_object('stage', v_stage));
  perform private.audit('admin_trends_review', 'trend_draft', d.id::text,
    jsonb_build_object('approve', p_approve, 'stage', v_stage, 'note', p_note, 'slug', d.slug,
                       'country', d.country, 'status', d.status));
  return trends.draft_summary(d);
end $$;

-- Settings editor (caps, thresholds, keyword lists, app links, pipeline switch, ramp schedule).
-- Kill switch and ramp level have their own RPCs. The brief's floors cannot be weakened:
-- >= 2 sources, >= 250 words, <= 3 per hour, <= 20 per day.
create or replace function public.admin_trends_set_setting(p_key text, p_value jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_old jsonb;
  v_new jsonb := p_value;
  v_prev int := 0;
  v_x jsonb;
begin
  if p_key in ('publishing') then perform private.raise_error('use_admin_trends_set_kill_switch', 400); end if;
  select value into v_old from trends.trend_settings where key = p_key for update;
  if v_old is null then perform private.raise_error('unknown_setting', 404); end if;
  if jsonb_typeof(v_old) <> jsonb_typeof(p_value) then perform private.raise_error('invalid_setting_type', 400); end if;

  if p_key in ('sensitive_tags', 'sensitive_keywords', 'banned_perspective_terms') then
    if exists (select 1 from jsonb_array_elements(p_value) e where jsonb_typeof(e) <> 'string' or length(e #>> '{}') = 0) then
      perform private.raise_error('invalid_setting_value', 400, 'array of non-empty strings');
    end if;
  elsif p_key = 'caps' then
    v_new := v_old || p_value;
    if jsonb_typeof(v_new -> 'ramp_levels') <> 'array' or jsonb_array_length(v_new -> 'ramp_levels') = 0 then
      perform private.raise_error('invalid_setting_value', 400, 'ramp_levels');
    end if;
    for v_x in select * from jsonb_array_elements(v_new -> 'ramp_levels') loop
      if jsonb_typeof(v_x) <> 'number' or (v_x #>> '{}')::numeric <= v_prev or (v_x #>> '{}')::numeric <> floor((v_x #>> '{}')::numeric) then
        perform private.raise_error('invalid_setting_value', 400, 'ramp_levels must be ascending positive integers');
      end if;
      v_prev := (v_x #>> '{}')::int;
    end loop;
    if coalesce((v_new ->> 'hard_max_per_day')::int, 99) > 20 or v_prev > coalesce((v_new ->> 'hard_max_per_day')::int, 20) then
      perform private.raise_error('invalid_setting_value', 400, 'at most 20 per day per country');
    end if;
    if coalesce((v_new ->> 'max_per_hour')::int, 99) not between 1 and 3 then
      perform private.raise_error('invalid_setting_value', 400, 'max_per_hour must be 1 to 3');
    end if;
  elsif p_key = 'gates' then
    v_new := v_old || p_value;
    if coalesce((v_new ->> 'min_sources')::int, 0) < 2 or coalesce((v_new ->> 'min_words')::int, 0) < 250
       or coalesce((v_new ->> 'max_similarity')::numeric, 1) > 0.5 or coalesce((v_new ->> 'max_rewrites')::int, 9) > 1 then
      perform private.raise_error('invalid_setting_value', 400, 'min_sources >= 2, min_words >= 250, max_similarity <= 0.5, max_rewrites <= 1');
    end if;
  elsif p_key = 'ramp' then
    -- schedule fields only; levels change through admin_trends_set_ramp
    v_new := (v_old || p_value) || jsonb_build_object('usa', v_old -> 'usa', 'india', v_old -> 'india');
    if coalesce((v_new ->> 'min_days_between_steps')::int, 0) < 30 then
      perform private.raise_error('invalid_setting_value', 400, 'min_days_between_steps >= 30');
    end if;
  elsif p_key in ('detection', 'pipeline', 'app_hosts') then
    v_new := v_old || p_value;
  end if;

  update trends.trend_settings set value = v_new, updated_by = v_admin where key = p_key;
  perform private.audit('admin_trends_set_setting', 'trend_setting', p_key,
    jsonb_build_object('from', v_old, 'to', v_new));
  return jsonb_build_object('key', p_key, 'value', v_new);
end $$;

-- Kill switch: pauses drafting and publishing at once (the site build also stops at paused_at).
create or replace function public.admin_trends_set_kill_switch(p_paused boolean, p_reason text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_old jsonb := trends.setting('publishing');
  v_new jsonb;
begin
  v_new := case when p_paused
    then jsonb_build_object('paused', true, 'paused_at', coalesce(v_old -> 'paused_at', 'null'::jsonb), 'paused_reason', p_reason, 'paused_by', v_admin)
    else jsonb_build_object('paused', false, 'paused_at', null, 'paused_reason', null, 'resumed_reason', p_reason, 'resumed_by', v_admin) end;
  if p_paused and (v_old ->> 'paused')::boolean is not true then
    v_new := jsonb_set(v_new, '{paused_at}', to_jsonb(now()));
  end if;
  update trends.trend_settings set value = v_new, updated_by = v_admin where key = 'publishing';
  perform trends.log_decision('kill_switch', p_reason, null, jsonb_build_object('paused', p_paused));
  perform private.audit('admin_trends_set_kill_switch', 'trend_setting', 'publishing',
    jsonb_build_object('paused', p_paused, 'reason', p_reason));
  return v_new;
end $$;

-- Ramp level per country. Down: any time. Up: one level, at least min_days_between_steps after
-- the last change, and only with a recent healthy health snapshot.
create or replace function public.admin_trends_set_ramp(p_country text, p_level int, p_reason text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  v_ramp jsonb;
  v_caps jsonb := trends.setting('caps');
  v_cur int;
  v_changed timestamptz;
  v_problem text;
begin
  if p_country not in ('usa', 'india') then perform private.raise_error('invalid_country', 400); end if;
  select value into v_ramp from trends.trend_settings where key = 'ramp' for update;
  v_cur := coalesce((v_ramp -> p_country ->> 'level')::int, 0);
  v_changed := (v_ramp -> p_country ->> 'changed_at')::timestamptz;
  if p_level < 0 or p_level >= jsonb_array_length(v_caps -> 'ramp_levels') then
    perform private.raise_error('invalid_ramp_level', 400);
  end if;
  if p_level = v_cur then return v_ramp; end if;
  if p_level > v_cur then
    if p_level > v_cur + 1 then perform private.raise_error('ramp_one_level_at_a_time', 409); end if;
    if v_changed is not null and v_changed > now() - make_interval(days => coalesce((v_ramp ->> 'min_days_between_steps')::int, 30)) then
      perform private.raise_error('ramp_step_too_soon', 409);
    end if;
    v_problem := trends.health_problem(p_country);
    if v_problem is not null then perform private.raise_error('ramp_unhealthy', 409, v_problem); end if;
  end if;
  v_ramp := jsonb_set(v_ramp, array[p_country], jsonb_build_object('level', p_level, 'changed_at', now(), 'changed_by', 'admin'));
  update trends.trend_settings set value = v_ramp, updated_by = v_admin where key = 'ramp';
  perform trends.log_decision(case when p_level > v_cur then 'ramp_up' else 'ramp_down' end, p_reason, null,
    jsonb_build_object('country', p_country, 'from', v_cur, 'to', p_level, 'per_day', trends.per_day_cap(p_country)));
  perform private.audit('admin_trends_set_ramp', 'trend_setting', 'ramp',
    jsonb_build_object('country', p_country, 'from', v_cur, 'to', p_level, 'reason', p_reason));
  return v_ramp;
end $$;

-- Health snapshot (indexed share, clicks, Search Console warnings / manual action, error reports).
-- A manual action or an error-report spike pauses publishing immediately; the ramp step-down is
-- applied by the next trends-publish run.
create or replace function public.admin_trends_record_health(
  p_country text, p_indexed_share numeric, p_clicks_7d int, p_clicks_prev_7d int,
  p_sc_warnings int default 0, p_manual_action boolean default false, p_error_reports_24h int default 0,
  p_note text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  h trends.trend_health;
  v_max_err int := coalesce((trends.setting('ramp') -> 'health' ->> 'max_error_reports_24h')::int, 5);
  v_pause text;
begin
  if p_country not in ('usa', 'india') then perform private.raise_error('invalid_country', 400); end if;
  insert into trends.trend_health (country, indexed_share, clicks_7d, clicks_prev_7d, sc_warnings, manual_action,
                                   error_reports_24h, note, recorded_by)
  values (p_country, p_indexed_share, p_clicks_7d, p_clicks_prev_7d, coalesce(p_sc_warnings, 0),
          coalesce(p_manual_action, false), coalesce(p_error_reports_24h, 0), p_note, v_admin)
  returning * into h;
  v_pause := case when h.manual_action then 'search_console_manual_action'
                  when h.error_reports_24h > v_max_err then 'error_report_spike' end;
  if v_pause is not null and (trends.setting('publishing') ->> 'paused')::boolean is not true then
    update trends.trend_settings
       set value = jsonb_build_object('paused', true, 'paused_at', now(), 'paused_reason', v_pause, 'paused_by', 'auto')
     where key = 'publishing';
    perform trends.log_decision('auto_pause', v_pause, null, jsonb_build_object('country', p_country, 'health_id', h.id));
  end if;
  perform private.audit('admin_trends_record_health', 'trend_health', h.id::text,
    jsonb_build_object('country', p_country, 'indexed_share', p_indexed_share, 'clicks_7d', p_clicks_7d,
                       'clicks_prev_7d', p_clicks_prev_7d, 'sc_warnings', p_sc_warnings,
                       'manual_action', p_manual_action, 'error_reports_24h', p_error_reports_24h, 'auto_pause', v_pause));
  return to_jsonb(h) || jsonb_build_object('auto_pause', v_pause, 'health_problem', trends.health_problem(p_country));
end $$;

-- Manual draft actions: reject (queued / review), noindex / index (published), unpublish
-- (removes the article from the bucket and index on the next trends-publish run).
create or replace function public.admin_trends_set_draft_status(p_draft_id uuid, p_action text, p_reason text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  d trends.trend_drafts;
  v_from text;
begin
  select * into d from trends.trend_drafts where id = p_draft_id for update;
  if d.id is null then perform private.raise_error('draft_not_found', 404); end if;
  v_from := d.status;
  if p_action = 'reject' and d.status in ('queued', 'review') then
    update trends.trend_drafts set status = 'rejected', failed_gate = coalesce(failed_gate, 'manual'),
           reason = coalesce(p_reason, 'rejected by admin') where id = d.id returning * into d;
  elsif p_action = 'noindex' and d.status = 'published' then
    update trends.trend_drafts set status = 'noindex', noindex_reason = coalesce(p_reason, 'manual'), dirty = true
     where id = d.id returning * into d;
  elsif p_action = 'index' and d.status = 'noindex' and d.superseded_by is null then
    update trends.trend_drafts set status = 'published', noindex_reason = null, dirty = true
     where id = d.id returning * into d;
  elsif p_action = 'unpublish' and d.status in ('published', 'noindex') then
    update trends.trend_drafts set status = 'rejected', failed_gate = 'manual',
           reason = coalesce(p_reason, 'unpublished by admin'), dirty = true
     where id = d.id returning * into d;
  else
    perform private.raise_error('invalid_draft_action', 409, p_action || ' from ' || d.status);
  end if;
  perform trends.log_decision(case p_action when 'reject' then 'rejected' when 'unpublish' then 'unpublished'
                                            when 'index' then 'indexed' else 'noindex' end, p_reason, d,
    jsonb_build_object('from', v_from, 'manual', true));
  perform private.audit('admin_trends_set_draft_status', 'trend_draft', d.id::text,
    jsonb_build_object('action', p_action, 'from', v_from, 'to', d.status, 'reason', p_reason, 'slug', d.slug));
  return trends.draft_summary(d);
end $$;

-- Correction on a published article: shown in its Corrections section, updated time bumped.
create or replace function public.admin_trends_add_correction(p_draft_id uuid, p_text text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  d trends.trend_drafts;
begin
  if length(trim(coalesce(p_text, ''))) < 10 then perform private.raise_error('correction_too_short', 400); end if;
  select * into d from trends.trend_drafts where id = p_draft_id for update;
  if d.id is null then perform private.raise_error('draft_not_found', 404); end if;
  if d.status not in ('published', 'noindex') then perform private.raise_error('draft_not_published', 409); end if;
  update trends.trend_drafts
     set article = jsonb_set(jsonb_set(article, '{corrections}',
                     coalesce(article -> 'corrections', '[]'::jsonb) || jsonb_build_array(
                       jsonb_build_object('at', now(), 'text', trim(p_text)))), '{updated_at}', to_jsonb(now())),
         dirty = true
   where id = d.id returning * into d;
  perform trends.log_decision('corrected', p_text, d, jsonb_build_object('manual', true));
  perform private.audit('admin_trends_add_correction', 'trend_draft', d.id::text,
    jsonb_build_object('slug', d.slug, 'text', p_text));
  return trends.draft_summary(d);
end $$;

-- Mark an article superseded by another (follow-up merged elsewhere): it becomes noindex with a
-- canonical to the newer article.
create or replace function public.admin_trends_supersede(p_slug text, p_by_slug text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  d trends.trend_drafts;
begin
  if p_slug = p_by_slug then perform private.raise_error('invalid_supersede', 400); end if;
  if not exists (select 1 from trends.trend_drafts where slug = p_by_slug and status in ('published', 'noindex')) then
    perform private.raise_error('superseding_article_not_found', 404);
  end if;
  update trends.trend_drafts set superseded_by = p_by_slug, status = 'noindex',
         noindex_reason = 'superseded by ' || p_by_slug, dirty = true
   where slug = p_slug and status in ('published', 'noindex') returning * into d;
  if d.id is null then perform private.raise_error('draft_not_found', 404); end if;
  perform trends.log_decision('superseded', p_by_slug, d, jsonb_build_object('manual', true));
  perform private.audit('admin_trends_supersede', 'trend_draft', d.id::text,
    jsonb_build_object('slug', p_slug, 'superseded_by', p_by_slug));
  return trends.draft_summary(d);
end $$;

-- Visits in the 14 days after the trend ended (from site analytics); drives the traffic noindex rule.
create or replace function public.admin_trends_record_traffic(p_slug text, p_visits_14d int)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  d trends.trend_drafts;
begin
  if p_visits_14d is null or p_visits_14d < 0 then perform private.raise_error('invalid_visits', 400); end if;
  update trends.trend_drafts set visits_14d_after_end = p_visits_14d, dirty = true
   where slug = p_slug and status in ('published', 'noindex') returning * into d;
  if d.id is null then perform private.raise_error('draft_not_found', 404); end if;
  perform private.audit('admin_trends_record_traffic', 'trend_draft', d.id::text,
    jsonb_build_object('slug', p_slug, 'visits_14d_after_end', p_visits_14d));
  return trends.draft_summary(d);
end $$;

-- Add or edit a polled source (geo list, Google News query, subreddit), or enable / disable it.
create or replace function public.admin_trends_upsert_source(p_source jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  s trends.trend_sources;
  v_id bigint := (p_source ->> 'id')::bigint;
begin
  if v_id is null then
    insert into trends.trend_sources (kind, country, geo, place_slug, place_name, state, level, query, enabled)
    values (p_source ->> 'kind', p_source ->> 'country', upper(p_source ->> 'geo'), p_source ->> 'place_slug',
            p_source ->> 'place_name', p_source ->> 'state', p_source ->> 'level', nullif(p_source ->> 'query', ''),
            coalesce((p_source ->> 'enabled')::boolean, true))
    returning * into s;
  else
    update trends.trend_sources set
      geo = coalesce(upper(p_source ->> 'geo'), geo),
      place_slug = coalesce(p_source ->> 'place_slug', place_slug),
      place_name = coalesce(p_source ->> 'place_name', place_name),
      state = case when p_source ? 'state' then p_source ->> 'state' else state end,
      level = coalesce(p_source ->> 'level', level),
      query = case when p_source ? 'query' then nullif(p_source ->> 'query', '') else query end,
      enabled = coalesce((p_source ->> 'enabled')::boolean, enabled)
    where id = v_id returning * into s;
    if s.id is null then perform private.raise_error('source_not_found', 404); end if;
  end if;
  if s.geo !~ '^(IN|US)(-[A-Z]{2})?$' or (s.kind <> 'google_trends' and s.query is null) then
    perform private.raise_error('invalid_source', 400);
  end if;
  perform private.audit('admin_trends_upsert_source', 'trend_source', s.id::text, to_jsonb(s));
  return to_jsonb(s);
exception
  when check_violation or not_null_violation or invalid_text_representation then
    perform private.raise_error('invalid_source', 400, sqlerrm);
  when unique_violation then
    perform private.raise_error('source_exists', 409);
end $$;

-- Grants: admin RPCs for authenticated (require_admin inside), helpers for nobody else.
do $$
declare f text;
begin
  foreach f in array array[
    'public.admin_trends_board(text,int)', 'public.admin_trends_topics(text,text,int)',
    'public.admin_trends_drafts(text,text,int,int)', 'public.admin_trends_draft(uuid)',
    'public.admin_trends_review_queue(text)', 'public.admin_trends_settings()',
    'public.admin_trends_publish_log(int,uuid)', 'public.admin_trends_review(uuid,boolean,text)',
    'public.admin_trends_set_setting(text,jsonb)', 'public.admin_trends_set_kill_switch(boolean,text)',
    'public.admin_trends_set_ramp(text,int,text)',
    'public.admin_trends_record_health(text,numeric,int,int,int,boolean,int,text)',
    'public.admin_trends_set_draft_status(uuid,text,text)', 'public.admin_trends_add_correction(uuid,text)',
    'public.admin_trends_supersede(text,text)', 'public.admin_trends_record_traffic(text,int)',
    'public.admin_trends_upsert_source(jsonb)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated, service_role', f);
  end loop;
end $$;
revoke all on all functions in schema trends from public, anon, authenticated;
grant execute on all functions in schema trends to service_role;
