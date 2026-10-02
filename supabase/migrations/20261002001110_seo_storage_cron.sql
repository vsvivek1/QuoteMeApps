-- 1110 Public bucket for the nightly SEO export and its pg_cron schedule.
--
--   public-data  public  seo/<country>.json   aggregated, anonymised SEO data read by web/app_site
--                                             at build time (SEO_DATA_URL). Written only by the
--                                             seo-export Edge Function with the service role.
--
-- Only aggregated, anonymised data may ever be written here: everything in
-- this bucket is world-readable at
--   https://<ref>.supabase.co/storage/v1/object/public/public-data/<path>
set search_path = public, extensions;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('public-data', 'public-data', true, 52428800, array['application/json'])
on conflict (id) do update set public = excluded.public, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Read for everyone; no insert / update / delete policy for clients: only the
-- service role (which bypasses RLS) writes.
create policy "public-data public read" on storage.objects for select to anon, authenticated
  using (bucket_id = 'public-data');

-- Nightly export at 02:40 UTC (08:10 IST, 22:40 EDT). The function logs a dry
-- run instead of calling the Vercel Deploy Hook while VERCEL_DEPLOY_HOOK_APP_SITE
-- is not set. Like every other job it does nothing until edge_functions_url
-- and the edge_webhook_secret Vault secret are configured.
do $$
begin
  if to_regnamespace('cron') is null then
    raise notice 'pg_cron not installed: skipping iwant-seo-export';
    return;
  end if;
  execute 'select cron.unschedule(jobid) from cron.job where jobname = $1' using 'iwant-seo-export';
  execute 'select cron.schedule($1, $2, $3)' using 'iwant-seo-export', '40 2 * * *',
    $c$select private.call_edge_function('seo-export', '{"action":"run","triggered_by":"cron"}'::jsonb)$c$;
end $$;
