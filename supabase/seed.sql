-- =============================================================================
-- Shared seed (both countries). Minimal: legal document versions and the
-- small `seed_tools` helpers the country seeds use to build the category
-- tree. Run order (see config.toml [db.seed] and README):
--   seed.sql -> seed/<country>.sql -> seed/demo_generator.sql -> seed/<country>_demo.sql
-- Plain SQL only (no psql meta-commands) so `supabase db reset` can run it.
-- =============================================================================

insert into public.app_settings (key, value, is_public, description) values
  ('legal_versions', '{"terms":"1.0","privacy":"1.0","seller_terms":"1.0"}', true,
   'Current legal document versions; consent rows record the version accepted'),
  ('languages', '["en"]', true, 'App languages (country seed overrides)')
on conflict (key) do nothing;

create schema if not exists seed_tools;

-- Localized label: {"en": .., "<second language of this country>": ..}
create or replace function seed_tools.l(p_en text, p_local text default null)
returns jsonb
language sql
stable
as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'en', p_en,
    case when (select value #>> '{}' from public.app_settings where key = 'country') = 'US' then 'es' else 'hi' end,
    p_local))
$$;

create or replace function seed_tools.opt(p_value text, p_en text, p_local text default null)
returns jsonb
language sql
stable
as $$ select jsonb_build_object('value', p_value, 'label', seed_tools.l(p_en, p_local)) $$;

-- One structured field. type: text | number | select | multiselect | boolean | date
-- scope: request | quote | both
create or replace function seed_tools.field(
  p_key text, p_type text, p_label jsonb, p_required boolean default false,
  p_scope text default 'request', p_options jsonb[] default null, p_extra jsonb default '{}'::jsonb)
returns jsonb
language sql
immutable
as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'key', p_key, 'type', p_type, 'label', p_label, 'required', p_required, 'scope', p_scope,
    'options', case when p_options is null then null else to_jsonb(p_options) end)) || coalesce(p_extra, '{}'::jsonb)
$$;

create or replace function seed_tools.schema(variadic p_fields jsonb[])
returns jsonb
language sql
immutable
as $$ select jsonb_build_object('version', 1, 'fields', to_jsonb(p_fields)) $$;

-- Upsert a category by slug.
create or replace function seed_tools.cat(
  p_slug text, p_parent_slug text, p_names jsonb, p_policy text default 'allowed',
  p_licence text default null, p_field_schema jsonb default null, p_keywords text[] default '{}',
  p_icon text default null, p_sort int default 0, p_disclaimer jsonb default null,
  p_policy_reason jsonb default null)
returns bigint
language plpgsql
as $$
declare v_id bigint;
begin
  insert into public.categories (slug, parent_id, names, policy, required_licence_type, field_schema,
                                 keywords, icon, sort, disclaimer, policy_reason)
  values (p_slug, (select id from public.categories where slug = p_parent_slug), p_names, p_policy,
          p_licence, p_field_schema, p_keywords, p_icon, p_sort, p_disclaimer, p_policy_reason)
  on conflict (slug) do update set
    parent_id = excluded.parent_id, names = excluded.names, policy = excluded.policy,
    required_licence_type = excluded.required_licence_type, field_schema = excluded.field_schema,
    keywords = excluded.keywords, icon = excluded.icon, sort = excluded.sort,
    disclaimer = excluded.disclaimer, policy_reason = excluded.policy_reason
  returning id into v_id;
  return v_id;
end $$;

create or replace function seed_tools.block_kw(p_category_slug text, p_lang text, variadic p_keywords text[])
returns void
language sql
as $$
  insert into public.category_keywords (keyword, lang, action, category_id)
  select lower(k), p_lang, 'block', (select id from public.categories where slug = p_category_slug)
    from unnest(p_keywords) k
  on conflict (keyword, lang, action) do update set category_id = excluded.category_id
$$;

create or replace function seed_tools.pc(p_code text, p_lat float8, p_lng float8, p_city text,
                                          p_district text, p_state text, p_state_code text)
returns void
language sql
as $$
  insert into public.postal_codes (code, centroid, city, district, state, state_code, source)
  values (p_code, extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography,
          p_city, p_district, p_state, p_state_code, 'seed')
  on conflict (code) do update set centroid = excluded.centroid, city = excluded.city,
    district = excluded.district, state = excluded.state, state_code = excluded.state_code
$$;

create or replace function seed_tools.city(p_name text, p_state text, p_state_code text, p_lat float8,
                                            p_lng float8, p_population bigint, p_tz text, p_priority int)
returns void
language sql
as $$
  insert into public.cities (name, ascii_name, slug, state, state_code, population, centroid, timezone, priority)
  select p_name, p_name, lower(regexp_replace(p_name, '[^A-Za-z0-9]+', '-', 'g')), p_state, p_state_code,
         p_population, extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography,
         p_tz, p_priority
   where not exists (select 1 from public.cities c where c.name = p_name and c.state = p_state)
$$;
