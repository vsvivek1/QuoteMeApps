-- Schema-level guarantees: RLS everywhere, timestamps, extensions, buckets,
-- realtime, token hook, function privileges.
begin;
\ir _helpers.psql
select plan(16);

select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity),
  0, 'RLS is enabled on every table in public');

select is(
  (select array_agg(c.relname::text order by c.relname) from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
      and (not exists (select 1 from information_schema.columns ic where ic.table_schema = 'public' and ic.table_name = c.relname and ic.column_name = 'created_at')
        or not exists (select 1 from information_schema.columns ic where ic.table_schema = 'public' and ic.table_name = c.relname and ic.column_name = 'updated_at'))),
  null, 'every public table has created_at and updated_at');

select is(
  (select array_agg(c.relname::text order by c.relname) from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
      and not exists (select 1 from pg_trigger t where t.tgrelid = c.oid and t.tgname = 'set_updated_at')),
  null, 'every public table has the updated_at trigger');

select has_extension('postgis', 'PostGIS is installed');

select col_type_is('public', 'requests', 'location', 'geography(Point,4326)', 'requests.location is geography(Point,4326)');
select col_type_is('public', 'quotes', 'total_minor', 'bigint', 'money is stored as bigint minor units');

select is(
  (select array_agg(id order by id) from storage.buckets
    where id in ('seller-media','request-media','verification-docs','chat-media')),
  array['chat-media','request-media','seller-media','verification-docs'], 'storage buckets exist');
select is((select public from storage.buckets where id = 'seller-media'), true, 'seller-media is public');
select is((select bool_or(public) from storage.buckets where id in ('request-media','verification-docs','chat-media')),
  false, 'request/verification/chat buckets are private');

select is(
  (select array_agg(tablename::text order by tablename) from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename in ('messages','quotes','requests')),
  array['messages','quotes','requests'], 'realtime publishes messages, quotes and requests');

-- custom access token hook adds the roles claim
select tests.create_user('hook-admin', 'Hook Admin', '{buyer,admin}');
select is(
  public.custom_access_token_hook(jsonb_build_object(
    'user_id', md5('pgtap:hook-admin')::uuid, 'claims', '{"sub":"x","role":"authenticated"}'::jsonb)) -> 'claims' -> 'roles',
  '["buyer", "admin"]'::jsonb, 'token hook adds roles claim from the profile');
select ok(has_function_privilege('supabase_auth_admin', 'public.custom_access_token_hook(jsonb)', 'execute'),
  'supabase_auth_admin can run the token hook');
select ok(not has_function_privilege('authenticated', 'public.custom_access_token_hook(jsonb)', 'execute'),
  'authenticated cannot run the token hook');

-- anon may execute only an allow-list of public functions
select is(
  (select array_agg(p.proname::text order by p.proname) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute')
      and p.proname not in ('money_round_half_up','gst_line_tax','us_sales_tax','compute_quote_totals',
                            'normalize_postal_code','is_valid_gstin','is_valid_ein','get_app_settings',
                            'classify_request_text','get_community_feed','get_feed_post',
                            'get_feed_comments','get_group_buy')),
  null, 'anon can execute only the public allow-list');

select ok(not has_function_privilege('authenticated', 'public.match_sellers_for_request(uuid,int)', 'execute'),
  'service-only RPCs are not executable by authenticated');
select ok(has_function_privilege('authenticated', 'public.submit_quote(uuid,jsonb,bigint,int,text,date,text,int,text,text[],jsonb,int)', 'execute'),
  'authenticated can execute submit_quote');

select * from finish();
rollback;
