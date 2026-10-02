-- 0100 Extensions and schemas
-- PostGIS and pgcrypto are required. pg_cron and pg_net are optional: on a
-- hosted Supabase project they are available; on a bare local Postgres they
-- may be missing, so they are created only when available and the cron /
-- webhook migrations further down are guarded the same way.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists postgis with schema extensions;
create extension if not exists pg_trgm with schema extensions;

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_net') then
    begin
      execute 'create extension if not exists pg_net with schema extensions';
    exception when others then
      raise notice 'pg_net not created: %', sqlerrm;
    end;
  else
    raise notice 'pg_net not available; request webhooks will be no-ops';
  end if;

  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    begin
      execute 'create extension if not exists pg_cron';
    exception when others then
      -- e.g. pg_cron not in shared_preload_libraries on a local cluster
      raise notice 'pg_cron not created: %', sqlerrm;
    end;
  else
    raise notice 'pg_cron not available; scheduled jobs will not be registered';
  end if;
end $$;

-- `private` holds internal helpers. It is NOT exposed through PostgREST
-- (only `public` is), but API roles need USAGE so RLS policies can call
-- the helper functions.
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated, service_role;

-- Functions created in public are executable by anon/authenticated by default
-- on Supabase. We revoke that per-schema default and grant per function
-- instead. The global PUBLIC execute default cannot be revoked per schema
-- (and revoking it globally would also affect extensions), so every
-- migration that creates public functions revokes PUBLIC explicitly; a pgTAP
-- test asserts that anon can execute only an allow-list of functions.
alter default privileges in schema public revoke execute on functions from anon;
alter default privileges in schema public revoke execute on functions from authenticated;
alter default privileges in schema public grant execute on functions to service_role;
