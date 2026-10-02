-- 1200 Trends pipeline schema (brief Section 21.10): the backend of the separate
-- local-trends news site. Kept apart from the apps' data on purpose:
--
--   * its own schema `trends`, NOT exposed through PostgREST and with no grants
--     for anon / authenticated; only service_role (and the postgres owner used
--     by the Edge Functions through SUPABASE_DB_URL) can touch it;
--   * the admin panel reaches it only through the public.admin_trends_* RPCs
--     (migration 1210: admin JWT + profiles.roles, audited in admin_audit_log);
--   * nothing in public references trends, so the whole schema can be dropped
--     (`drop schema trends cascade` + the trends-public bucket + the three
--     trends-* cron jobs) without touching the apps.
--
-- Tables
--   trend_sources      polled feeds (Google Trends geo, Google News query, Reddit subreddit)
--   trend_signals      one row per headline / trend item seen (headline + link + short snippet only)
--   trend_topics       clustered signals per place, velocity, fired_at, status
--   trend_drafts       draft article JSON (web/trends_site format), per-gate results, status, reviewer
--   trend_settings     caps, ramp level + schedule, thresholds, kill switch, keyword lists
--   trend_health       indexing / traffic / error-report health snapshots (drive the ramp)
--   trend_publish_log  append-only audit of every publish decision
--   trend_runs         one row per Edge Function run (observability for the admin board)
set search_path = public, extensions;

create schema if not exists trends;
revoke all on schema trends from public, anon, authenticated;
grant usage on schema trends to service_role;

-- Settings ---------------------------------------------------------------------------------------
create table trends.trend_settings (
  key text primary key,
  value jsonb not null,
  description text,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Sources ----------------------------------------------------------------------------------------
create table trends.trend_sources (
  id bigint generated always as identity primary key,
  kind text not null check (kind in ('google_trends','google_news','reddit')),
  country text not null check (country in ('usa','india')),
  geo text not null,                       -- IN, IN-MH, US, US-CA ... (Google Trends geo code of the place)
  place_slug text not null check (place_slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  place_name text not null,
  state text,
  level text not null check (level in ('country','state','metro')),
  query text,                              -- google_news: search query; reddit: subreddit name
  enabled boolean not null default true,
  last_polled_at timestamptz,
  last_status text,                        -- ok | error | skipped
  last_error text,
  last_items int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (kind, geo, place_slug, query)
);
create unique index trend_sources_uniq_null_query on trends.trend_sources (kind, geo, place_slug) where query is null;

-- Topics -----------------------------------------------------------------------------------------
create table trends.trend_topics (
  id uuid primary key default gen_random_uuid(),
  country text not null check (country in ('usa','india')),
  place_slug text not null,
  place_name text not null,
  state text,
  level text not null check (level in ('country','state','metro')),
  title text not null,
  norm_title text not null,
  alt_titles text[] not null default '{}',     -- a few member headlines used for clustering
  status text not null default 'watching'
    check (status in ('watching','fired','review','drafted','published','waiting_sources','dropped','ended')),
  velocity numeric not null default 0,
  peak_velocity numeric not null default 0,
  signal_count int not null default 0,
  domain_count int not null default 0,         -- distinct citable publisher domains
  domains text[] not null default '{}',
  domains_at_reject int,                        -- waiting_sources: re-fire only with more domains than this
  first_seen timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  fired_at timestamptz,
  ended_at timestamptz,                         -- trend_ended_at of the article
  status_reason text,
  article_slug text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index trend_topics_place_idx on trends.trend_topics (country, place_slug, last_seen desc);
create index trend_topics_status_idx on trends.trend_topics (status, velocity desc);

-- Signals ----------------------------------------------------------------------------------------
create table trends.trend_signals (
  id bigint generated always as identity primary key,
  source_id bigint references trends.trend_sources(id) on delete set null,
  source_kind text not null check (source_kind in ('google_trends','google_news','reddit')),
  country text not null check (country in ('usa','india')),
  place_slug text not null,
  geo text,
  topic text not null check (length(topic) <= 400),
  norm_title text not null,
  dedupe_key text not null,
  url text check (url is null or url ~ '^https?://'),
  publisher text,
  publisher_domain text,
  citable boolean not null default false,      -- url is on the publisher's own domain (can be cited)
  snippet text check (snippet is null or length(snippet) <= 600),  -- feed snippet only, never article bodies
  score numeric not null default 0,
  topic_id uuid references trends.trend_topics(id) on delete set null,
  first_seen timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  seen_count int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source_kind, place_slug, dedupe_key)
);
create index trend_signals_topic_idx on trends.trend_signals (topic_id, first_seen desc);
create index trend_signals_recent_idx on trends.trend_signals (country, place_slug, first_seen desc);

-- Drafts -----------------------------------------------------------------------------------------
create table trends.trend_drafts (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid references trends.trend_topics(id) on delete set null,
  country text not null check (country in ('usa','india')),
  slug text unique check (slug is null or slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  status text not null default 'queued' check (status in ('queued','review','rejected','published','noindex')),
  -- queued + article null: awaiting the Claude draft (gates 1-2 passed or topic approved)
  -- queued + article:      passed gates 3-5, waiting for gate 6 (caps / kill switch) in trends-publish
  -- review:                sensitive topic; review_stage says whether the topic or the finished text waits
  article jsonb,                                -- web/trends_site/data/fixtures format
  gates jsonb not null default '{}'::jsonb,     -- {sources:{passed,...}, sensitive:{...}, originality:{...}, facts, value, balance, caps}
  failed_gate text,
  reason text,
  sensitive boolean not null default false,
  sensitive_reasons text[] not null default '{}',
  review_stage text check (review_stage in ('topic','content')),
  topic_reviewed_by uuid references public.profiles(id) on delete set null,
  topic_reviewed_at timestamptz,
  reviewer_id uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  review_note text,
  model text,
  rewrites int not null default 0,
  velocity numeric not null default 0,
  published_at timestamptz,
  last_update_at timestamptz,
  superseded_by text,
  noindex_reason text,
  visits_14d_after_end int,
  storage_path text,
  dirty boolean not null default false,          -- published article changed: trends-publish re-uploads it
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trend_drafts_published_has_article check (status not in ('published','noindex') or (article is not null and slug is not null))
);
create index trend_drafts_status_idx on trends.trend_drafts (status, country, created_at desc);
create index trend_drafts_topic_idx on trends.trend_drafts (topic_id);
create index trend_drafts_published_idx on trends.trend_drafts (country, published_at desc) where published_at is not null;

-- Health (drives the automatic step-down / optional step-up of the ramp) --------------------------
create table trends.trend_health (
  id bigint generated always as identity primary key,
  country text not null check (country in ('usa','india')),
  recorded_at timestamptz not null default now(),
  indexed_share numeric check (indexed_share is null or indexed_share between 0 and 1),
  clicks_7d int check (clicks_7d is null or clicks_7d >= 0),
  clicks_prev_7d int check (clicks_prev_7d is null or clicks_prev_7d >= 0),
  sc_warnings int not null default 0,
  manual_action boolean not null default false,
  error_reports_24h int not null default 0,
  note text,
  recorded_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index trend_health_country_idx on trends.trend_health (country, recorded_at desc);

-- Publish decisions (append-only) ---------------------------------------------------------------
create table trends.trend_publish_log (
  id bigint generated always as identity primary key,
  draft_id uuid,
  topic_id uuid,
  slug text,
  country text,
  decision text not null,   -- published | updated | corrected | capped | paused | rejected | review | review_approved
                            -- | review_rejected | noindex | superseded | unpublished | ramp_down | ramp_up | auto_pause | kill_switch
  reason text,
  details jsonb not null default '{}'::jsonb,
  actor_id uuid,            -- admin for manual decisions, null for the pipeline
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index trend_publish_log_created_idx on trends.trend_publish_log (created_at desc);
create index trend_publish_log_draft_idx on trends.trend_publish_log (draft_id, created_at desc);

create or replace function trends.publish_log_append_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = 'PT403', message = 'publish_log_append_only';
end $$;
create trigger trend_publish_log_append_only
  before update or delete on trends.trend_publish_log
  for each row execute function trends.publish_log_append_only();

-- Runs ---------------------------------------------------------------------------------------------
create table trends.trend_runs (
  id bigint generated always as identity primary key,
  fn text not null check (fn in ('trends-poll','trends-draft','trends-publish')),
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  dry_run boolean not null default false,
  ok boolean,
  stats jsonb not null default '{}'::jsonb,
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index trend_runs_fn_idx on trends.trend_runs (fn, started_at desc);

-- updated_at triggers, RLS (no policies: only service_role / owner), grants ---------------------
do $$
declare t text;
begin
  foreach t in array array['trend_settings','trend_sources','trend_topics','trend_signals','trend_drafts',
                           'trend_health','trend_publish_log','trend_runs'] loop
    execute format('create trigger set_updated_at before update on trends.%I for each row execute function private.set_updated_at()', t);
    execute format('alter table trends.%I enable row level security', t);
    execute format('revoke all on trends.%I from public, anon, authenticated', t);
    execute format('grant select, insert, update, delete on trends.%I to service_role', t);
  end loop;
end $$;
revoke update, delete on trends.trend_publish_log from service_role;
grant usage, select on all sequences in schema trends to service_role;
alter default privileges in schema trends revoke all on tables from public, anon, authenticated;
alter default privileges in schema trends revoke all on functions from public, anon, authenticated;

-- Helpers --------------------------------------------------------------------------------------------
create or replace function trends.setting(p_key text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$ select value from trends.trend_settings where key = p_key $$;

create or replace function trends.pipeline_enabled()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$ select coalesce((select (value ->> 'enabled')::boolean from trends.trend_settings where key = 'pipeline'), false) $$;

-- Daily cap of a country at its current ramp level (ramp_levels[level], never above hard_max_per_day).
create or replace function trends.per_day_cap(p_country text)
returns int
language sql
stable
security definer
set search_path = ''
as $$
  select least(
    coalesce((c.value -> 'ramp_levels' ->> greatest(0, least(coalesce((r.value -> p_country ->> 'level')::int, 0),
                                                             jsonb_array_length(c.value -> 'ramp_levels') - 1)))::int, 1),
    coalesce((c.value ->> 'hard_max_per_day')::int, 20))
  from trends.trend_settings c, trends.trend_settings r
  where c.key = 'caps' and r.key = 'ramp'
$$;

revoke all on all functions in schema trends from public, anon, authenticated;
grant execute on all functions in schema trends to service_role;

-- Seed settings (values from web/trends_site/data/config.json) ------------------------------------
insert into trends.trend_settings (key, value, description) values
  ('pipeline', '{"enabled": false}',
   'Master switch for the pg_cron jobs (poll, draft, publish). Enable it in ONE project only.'),
  ('publishing', '{"paused": false, "paused_at": null, "paused_reason": null}',
   'Kill switch: paused=true stops drafting and publishing at once (polling continues).'),
  ('caps', '{"ramp_levels": [1, 2, 5, 10, 20], "hard_max_per_day": 20, "max_per_hour": 3,
             "timezones": {"usa": "America/New_York", "india": "Asia/Kolkata"},
             "max_drafts_per_run": 3, "queue_ttl_hours": 6}',
   'Rate caps: per-country daily cap = ramp_levels[ramp.<country>.level], max per rolling hour, queue expiry.'),
  ('ramp', '{"usa": {"level": 0, "changed_at": null}, "india": {"level": 0, "changed_at": null},
             "min_days_between_steps": 30, "auto_step_up": false,
             "health": {"max_age_days": 7, "min_indexed_share": 0.6, "max_click_drop": 0.3,
                        "max_sc_warnings": 0, "max_error_reports_24h": 5}}',
   'Ramp 1 -> 2 -> 5 -> 10 -> 20 per day. Up: manually (one level, 30+ days apart) or by health signal when auto_step_up; down: automatic on bad health.'),
  ('gates', '{"min_sources": 2, "max_similarity": 0.2, "shingle_words": 6, "max_quote_words": 25,
              "min_words": 250, "min_section_words": 15, "max_perspective_ratio": 1.5,
              "noindex_min_visits_14d": 20, "max_rewrites": 1}',
   'Quality gate thresholds (same names and values as the site build).'),
  ('detection', '{"fire_threshold": 60, "min_signals": 3, "cluster_similarity": 0.5,
                  "velocity_window_minutes": 60, "baseline_hours": 6, "topic_ttl_hours": 48,
                  "merge_window_days": 7, "end_velocity": 10, "end_after_hours": 6,
                  "update_min_interval_minutes": 60, "max_updates": 10,
                  "source_weights": {"google_trends": 3, "google_news": 1, "reddit": 1},
                  "non_publisher_domains": ["news.google.com", "trends.google.com", "google.com", "reddit.com",
                                            "redd.it", "x.com", "twitter.com", "facebook.com", "youtube.com",
                                            "instagram.com", "msn.com", "yahoo.com"]}',
   'Clustering, velocity and firing thresholds.'),
  ('sensitive_tags', '["religion", "caste", "communal", "ethnic-conflict", "death", "deaths", "disaster-casualties", "crime",
     "health", "medical", "election", "elections", "politics", "legal-case", "court", "finance-advice",
     "markets", "minors", "children", "private-individual"]',
   'Topic tags that never auto-publish (human review queue).'),
  ('sensitive_keywords', '["killed", "dead", "death", "deaths", "died", "murder", "rape", "assault", "riot", "riots", "communal", "caste",
     "religious", "mosque", "temple", "church", "gurdwara", "election", "elections", "poll", "vote", "voting", "minister",
     "senator", "congressman", "party", "court", "lawsuit", "arrested", "police", "vaccine", "disease", "outbreak",
     "cancer", "stock tips", "invest now", "crypto", "child", "children", "minor", "suicide", "terror", "shooting"]',
   'Whole-word keywords in a topic title, headline or summary that route it to human review.'),
  ('banned_perspective_terms', '["left", "right", "left-wing", "right-wing", "liberal", "conservative", "communist", "capitalist", "socialist",
     "progressive", "democrat", "republican", "bjp", "congress", "aap", "hindu", "muslim", "christian", "sikh", "secular"]',
   'Partisan / ideological / religious labels never allowed as perspective labels.'),
  ('app_links', '[
     {"country": "india", "keywords": ["heatwave", "heat wave", "temperature", "summer"], "category": "air-conditioner-repair", "label": "Get AC repair quotes in {place} on I Want India"},
     {"country": "india", "keywords": ["monsoon", "flooding", "waterlogging", "leak"], "category": "plumbing", "label": "Get plumbing quotes in {place} on I Want India"},
     {"country": "india", "keywords": ["moving", "relocation", "transfer season"], "category": "packers-and-movers", "label": "Get packers and movers quotes in {place} on I Want India"},
     {"country": "usa", "keywords": ["snow", "snowstorm", "blizzard", "freeze", "cold snap"], "category": "furnace-repair", "label": "Get furnace repair quotes in {place} on I Want USA"},
     {"country": "usa", "keywords": ["heatwave", "heat wave", "heat advisory"], "category": "ac-repair", "label": "Get AC repair quotes in {place} on I Want USA"},
     {"country": "usa", "keywords": ["moving", "moving season", "relocation"], "category": "movers", "label": "Get moving quotes in {place} on I Want USA"}
   ]',
   'Contextual app links: only when a keyword matches the topic. URL = https://<app host>/quotes/<place>/<category> (UTM added by the site).'),
  ('app_hosts', '{"usa": "iwantusa.app", "india": "iwantindia.app"}', 'App hosts for contextual links (must be in the site APP_LINK_HOSTS).')
on conflict (key) do nothing;

-- Seed sources: Google Trends per geo, Google News per place, Reddit per city ---------------------
insert into trends.trend_sources (kind, country, geo, place_slug, place_name, state, level, query) values
  ('google_trends', 'india', 'IN',    'india',          'India',          null,             'country', null),
  ('google_trends', 'india', 'IN-MH', 'maharashtra',    'Maharashtra',    'Maharashtra',    'state',   null),
  ('google_trends', 'india', 'IN-KA', 'karnataka',      'Karnataka',      'Karnataka',      'state',   null),
  ('google_trends', 'india', 'IN-DL', 'delhi',          'Delhi',          'Delhi',          'state',   null),
  ('google_trends', 'india', 'IN-TN', 'tamil-nadu',     'Tamil Nadu',     'Tamil Nadu',     'state',   null),
  ('google_trends', 'india', 'IN-TG', 'telangana',      'Telangana',      'Telangana',      'state',   null),
  ('google_trends', 'india', 'IN-WB', 'west-bengal',    'West Bengal',    'West Bengal',    'state',   null),
  ('google_trends', 'usa',   'US',    'usa',            'United States',  null,             'country', null),
  ('google_trends', 'usa',   'US-CA', 'california',     'California',     'California',     'state',   null),
  ('google_trends', 'usa',   'US-NY', 'new-york-state', 'New York State', 'New York',       'state',   null),
  ('google_trends', 'usa',   'US-TX', 'texas',          'Texas',          'Texas',          'state',   null),
  ('google_trends', 'usa',   'US-IL', 'illinois',       'Illinois',       'Illinois',       'state',   null),
  ('google_trends', 'usa',   'US-FL', 'florida',        'Florida',        'Florida',        'state',   null),
  ('google_news',   'india', 'IN-MH', 'mumbai',         'Mumbai',         'Maharashtra',    'metro',   'Mumbai'),
  ('google_news',   'india', 'IN-MH', 'pune',           'Pune',           'Maharashtra',    'metro',   'Pune'),
  ('google_news',   'india', 'IN-KA', 'bengaluru',      'Bengaluru',      'Karnataka',      'metro',   'Bengaluru'),
  ('google_news',   'india', 'IN-DL', 'delhi',          'Delhi',          'Delhi',          'state',   'Delhi'),
  ('google_news',   'india', 'IN-TN', 'chennai',        'Chennai',        'Tamil Nadu',     'metro',   'Chennai'),
  ('google_news',   'india', 'IN-TG', 'hyderabad',      'Hyderabad',      'Telangana',      'metro',   'Hyderabad'),
  ('google_news',   'india', 'IN-WB', 'kolkata',        'Kolkata',        'West Bengal',    'metro',   'Kolkata'),
  ('google_news',   'usa',   'US-NY', 'new-york',       'New York',       'New York',       'metro',   'New York City'),
  ('google_news',   'usa',   'US-CA', 'los-angeles',    'Los Angeles',    'California',     'metro',   'Los Angeles'),
  ('google_news',   'usa',   'US-IL', 'chicago',        'Chicago',        'Illinois',       'metro',   'Chicago'),
  ('google_news',   'usa',   'US-TX', 'dallas',         'Dallas',         'Texas',          'metro',   'Dallas'),
  ('google_news',   'usa',   'US-TX', 'houston',        'Houston',        'Texas',          'metro',   'Houston'),
  ('google_news',   'usa',   'US-FL', 'miami',          'Miami',          'Florida',        'metro',   'Miami'),
  ('reddit',        'india', 'IN-MH', 'mumbai',         'Mumbai',         'Maharashtra',    'metro',   'mumbai'),
  ('reddit',        'india', 'IN-MH', 'pune',           'Pune',           'Maharashtra',    'metro',   'pune'),
  ('reddit',        'india', 'IN-KA', 'bengaluru',      'Bengaluru',      'Karnataka',      'metro',   'bangalore'),
  ('reddit',        'india', 'IN-DL', 'delhi',          'Delhi',          'Delhi',          'state',   'delhi'),
  ('reddit',        'usa',   'US-NY', 'new-york',       'New York',       'New York',       'metro',   'nyc'),
  ('reddit',        'usa',   'US-IL', 'chicago',        'Chicago',        'Illinois',       'metro',   'chicago'),
  ('reddit',        'usa',   'US-TX', 'dallas',         'Dallas',         'Texas',          'metro',   'Dallas'),
  ('reddit',        'usa',   'US-CA', 'los-angeles',    'Los Angeles',    'California',     'metro',   'LosAngeles')
on conflict do nothing;
