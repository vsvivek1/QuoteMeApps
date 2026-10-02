-- 1220 Trends pipeline: public output bucket and pg_cron schedule.
--
-- trends-public (public read, JSON only): articles/<slug>.json + index.json, written only by
-- the trends-publish Edge Function with the service role. The trends site build reads it through
-- TRENDS_DATA_URL (web/README.md). No storage.objects policy grants writes to anon/authenticated,
-- so public = read-only over the CDN URL.
--
-- Cron (every 5 minutes, staggered; no-ops until edge_functions_url + the Vault secret are set,
-- and only while trends.trend_settings.pipeline.enabled = true):
--   trends-poll     */5        feeds -> signals -> clusters -> velocity -> fired topics
--   trends-draft    2-59/5     gates 1-2, Claude draft, gates 3-5, balance, live updates
--   trends-publish  4-59/5     ramp + kill switch + caps (gate 6), bucket upload, deploy hook
set search_path = public, extensions;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('trends-public', 'trends-public', true, 1048576, array['application/json'])
on conflict (id) do update set public = excluded.public, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

do $$
declare
  j record;
begin
  if to_regnamespace('cron') is null then
    raise notice 'pg_cron not installed: skipping trends job registration';
    return;
  end if;
  for j in select * from (values
      ('trends-poll',    '*/5 * * * *',    $c$select private.call_edge_function('trends-poll', '{"action":"run"}'::jsonb) where trends.pipeline_enabled()$c$),
      ('trends-draft',   '2-59/5 * * * *', $c$select private.call_edge_function('trends-draft', '{"action":"run"}'::jsonb) where trends.pipeline_enabled()$c$),
      ('trends-publish', '4-59/5 * * * *', $c$select private.call_edge_function('trends-publish', '{"action":"run"}'::jsonb) where trends.pipeline_enabled()$c$),
      ('trends-cleanup', '40 3 * * *',     $c$select trends.cleanup()$c$)
    ) as t(name, schedule, command)
  loop
    execute 'select cron.unschedule(jobid) from cron.job where jobname = $1' using j.name;
    execute 'select cron.schedule($1, $2, $3)' using j.name, j.schedule, j.command;
  end loop;
end $$;

-- Retention: signals 30 days (topics keep their counts), runs 30 days, stale topics without a
-- draft 30 days. Drafts, health and the publish log are kept.
create or replace function trends.cleanup()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_signals int; v_runs int; v_topics int;
begin
  delete from trends.trend_signals where last_seen < now() - interval '30 days';
  get diagnostics v_signals = row_count;
  delete from trends.trend_runs where started_at < now() - interval '30 days';
  get diagnostics v_runs = row_count;
  delete from trends.trend_topics t where t.last_seen < now() - interval '30 days'
     and not exists (select 1 from trends.trend_drafts d where d.topic_id = t.id);
  get diagnostics v_topics = row_count;
  return jsonb_build_object('signals', v_signals, 'runs', v_runs, 'topics', v_topics);
end $$;
revoke all on function trends.cleanup() from public, anon, authenticated;
grant execute on function trends.cleanup() to service_role;
