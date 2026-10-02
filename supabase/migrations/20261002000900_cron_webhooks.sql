-- 0900 Database webhooks (pg_net) and scheduled jobs (pg_cron).
-- Both are guarded: when the extension is missing (bare local Postgres) the
-- calls become no-ops and no jobs are registered.
--
-- Configuration on a hosted project (see supabase/README.md):
--   update app_settings set value = '"https://<ref>.supabase.co/functions/v1"' where key = 'edge_functions_url';
--   select vault.create_secret('<random>', 'edge_webhook_secret');   -- same value as EDGE_WEBHOOK_SECRET
set search_path = public, extensions;

create or replace function private.edge_webhook_secret()
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v text;
begin
  if to_regclass('vault.decrypted_secrets') is not null then
    execute 'select decrypted_secret from vault.decrypted_secrets where name = $1 limit 1'
      into v using 'edge_webhook_secret';
  end if;
  return v;
end $$;

-- POSTs JSON to an Edge Function through pg_net. Returns the pg_net request
-- id, or null when pg_net / the URL are not configured.
create or replace function private.call_edge_function(p_name text, p_body jsonb)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_base text := private.setting_text('edge_functions_url', null);
  v_id bigint;
begin
  if v_base is null or to_regprocedure('net.http_post(text,jsonb,jsonb,jsonb,integer)') is null then
    return null;
  end if;
  execute 'select net.http_post(url := $1, body := $2, params := ''{}''::jsonb, headers := $3, timeout_milliseconds := $4)'
    into v_id
    using rtrim(v_base, '/') || '/' || p_name,
          p_body,
          jsonb_build_object('Content-Type', 'application/json',
                             'x-webhook-secret', coalesce(private.edge_webhook_secret(), '')),
          5000;
  return v_id;
exception when others then
  raise warning 'call_edge_function(%) failed: %', p_name, sqlerrm;
  return null;
end $$;

-- New request -> match-request (reverse match, priority window, digests, FCM).
create or replace function private.requests_after_insert_webhook()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.call_edge_function('match-request', jsonb_build_object(
    'type', 'INSERT', 'table', 'requests', 'schema', 'public',
    'record', jsonb_build_object('id', new.id, 'priority_until', new.priority_until,
                                 'category_id', new.category_id, 'buyer_id', new.buyer_id)));
  return null;
end $$;

create or replace trigger requests_match_webhook
  after insert on public.requests
  for each row execute function private.requests_after_insert_webhook();

-- New due notifications -> send-push (one call per statement).
create or replace function private.notifications_after_insert_webhook()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (select 1 from new_rows where push_status = 'queued' and push_after <= now() and type <> 'new_lead') then
    perform private.call_edge_function('send-push', jsonb_build_object('action', 'flush_due'));
  end if;
  return null;
end $$;

create or replace trigger notifications_push_webhook
  after insert on public.notifications
  referencing new table as new_rows
  for each statement execute function private.notifications_after_insert_webhook();

-- Scheduled jobs ---------------------------------------------------------------------------------
do $$
declare
  j record;
begin
  if to_regnamespace('cron') is null then
    raise notice 'pg_cron not installed: skipping job registration';
    return;
  end if;
  for j in select * from (values
      ('iwant-expire-stale',        '*/15 * * * *', 'select private.expire_stale()'),
      ('iwant-licence-expiry',      '15 3 * * *',   'select private.check_licence_expiry()'),
      ('iwant-push-digests',        '*/5 * * * *',  $c$select private.call_edge_function('send-push', '{"action":"flush_due"}'::jsonb)$c$),
      ('iwant-outreach-send',       '*/10 * * * 1-5', $c$select private.call_edge_function('outreach-send', '{"action":"run"}'::jsonb) where private.setting_bool('outreach_enabled', false)$c$),
      ('iwant-outreach-purge',      '30 2 * * *',   'select private.outreach_purge_uncontacted()'),
      ('iwant-rate-limit-cleanup',  '0 * * * *',    $c$delete from public.rate_limits where window_start < now() - interval '1 day'$c$)
    ) as t(name, schedule, command)
  loop
    execute 'select cron.unschedule(jobid) from cron.job where jobname = $1' using j.name;
    execute 'select cron.schedule($1, $2, $3)' using j.name, j.schedule, j.command;
  end loop;
end $$;
