# Trends admin: backend contract (Section 21.10)

The trend board for the separate trends news site. The backend is done (migrations
`20261002001200`-`1220` and `1300`, Edge Functions `trends-poll`, `trends-draft`,
`trends-publish`) and so is the panel: **Trends** in the navigation rail (`/trends`). Contract
summary: `supabase/API.md` section 13.

## What the panel has (built)

Code: `lib/features/trends/` (domain models and validation, `SupabaseTrendsRepository` over the
RPCs below, `DemoTrendsRepository` with sample data for both countries, Riverpod providers, five
tabs and a draft screen). Tests: `test/trends_test.dart`. Without `SUPABASE_URL` the demo
repository runs the same rules as the RPCs (review stages, draft actions, setting floors, ramp,
kill switch, health auto-pause, 6 runs per function per hour), so every screen works offline.

| Tab / screen | Shows | Actions (RPC) |
|---|---|---|
| Country filter (app bar) | All / USA / India for every tab (the pipeline covers both countries) | |
| Live board | places by hottest topic, topics with status, velocity bar, signals / publishers, fired time; failing feeds in a red card on top; window 6 / 24 / 72 h; place filter; refreshes every minute | sources table: enable / disable, add source with client-side checks (`admin_trends_upsert_source`) |
| Fired topics | topics by status (default `fired`), publishers, reason | |
| Drafts | published / queued / review / rejected / noindex lists, a pass / fail / waiting chip per gate (tooltip: the gate's useful fields), failed gate and reason, reviewer and dates | reject, noindex, index, unpublish (reason), add correction, record traffic, supersede (`admin_trends_set_draft_status`, `_add_correction`, `_record_traffic`, `_supersede`) |
| Draft screen (`/trends/draft/:id`) | header (review record, model, noindex, bucket path), every gate with its details, the article rendered in the site's sections (incl. updates, corrections, sources, review stamp), headlines behind it, decision log | same actions |
| Review queue | oldest first, stage `topic` or `final text`, why it is sensitive, gate chips, summary | approve (note optional) / reject (note required) via `admin_trends_review`; `409 draft_not_in_review` shows a message and refreshes |
| Controls | kill switch (who / why / since, auto-pause), pipeline switch, Run now with last run and the hourly allowance, ramp per country (per-day cap, published in 24 h, step up blocked with the reason: too soon, unhealthy, top level), health snapshots and problems, settings editor, decision log | `admin_trends_set_kill_switch` (confirm dialog both ways, reason required to pause), `admin_trends_set_setting('pipeline')` (confirm), Edge Functions with the admin JWT (confirm), `admin_trends_set_ramp` (confirm), `admin_trends_record_health` (form: indexed share %, clicks 7 d / previous 7 d, Search Console warnings, manual action, error reports, note), `admin_trends_record_traffic`, `admin_trends_set_setting` |

The settings editor edits every key except `publishing`: object settings field by field (one
level of nesting, e.g. `ramp.health`, `caps.timezones`; only changed keys are sent, a nested
object whole), word lists one per line, `app_links` as JSON. The brief's floors are checked
live with the server's wording (Save disabled), and a server refusal (`invalid_setting_value`
with its detail, `invalid_setting_type`, ...) is shown inside the dialog. Ramp levels of
`usa` / `india` change only through the ramp buttons.

Not built: traffic / revenue / conversion stats (see "Not covered yet").


The trends data lives in the Postgres schema `trends`, which is **not** exposed through
PostgREST, so the panel cannot query its tables. Everything goes through `supabase.rpc(...)`:

- every RPC checks the admin JWT `roles` claim **and** `profiles.roles` (`403 admin_only`);
- read RPCs are `stable` and not logged;
- every change writes one `admin_audit_log` row (`private.audit`, visible in the existing audit
  log screen with `target_type` `trend_draft`, `trend_setting`, `trend_health` or `trend_source`)
  and, for publish decisions, one row in the trends decision log (`admin_trends_publish_log`);
- errors follow the usual shape: `PTnnn` → HTTP `nnn`, message = stable code.

Run the pipeline in one project only (it covers both countries). Show its country filter as
`usa` / `india`.

## Screens and RPCs

### 1. Live trend board (by place)

`admin_trends_board(p_country text = null, p_hours int = 24) → jsonb`

```json
{ "generated_at": "...",
  "places": [ { "country": "india", "place_slug": "pune", "place_name": "Pune", "level": "metro",
                "max_velocity": 82,
                "topics": [ { "id": "uuid", "title": "pune rains", "status": "fired", "velocity": 82,
                              "peak_velocity": 85, "signal_count": 9, "domain_count": 3,
                              "domains": ["hindustantimes.com", "indiatimes.com", "thehindu.com"],
                              "first_seen": "...", "last_seen": "...", "fired_at": "...",
                              "status_reason": "velocity 82", "article_slug": null } ] } ],
  "sources": [ { "id": 1, "kind": "google_trends", "country": "india", "geo": "IN-MH",
                 "place_slug": "maharashtra", "place_name": "Maharashtra", "level": "state", "query": null,
                 "enabled": true, "last_polled_at": "...", "last_status": "ok | error | skipped",
                 "last_error": null, "last_items": 24 } ] }
```

Places are sorted by their hottest topic. Refresh every minute (polling runs every 5 minutes).
Topic statuses: `watching`, `fired`, `review`, `drafted`, `published`, `waiting_sources` (fewer
than 2 independent publishers, or sources conflict), `dropped`, `ended`. Show source errors
prominently (a failing feed means a blind spot).

Sources editor: `admin_trends_upsert_source(p_source jsonb) → jsonb` with
`{id?, kind: google_trends | google_news | reddit, country, geo: "IN" | "IN-MH" | "US" | "US-CA", place_slug,
place_name, state?, level: country | state | metro, query?, enabled?}`. `query` is the Google News
search or the subreddit name (required except for `google_trends`). Errors `400 invalid_source`,
`409 source_exists`, `404 source_not_found`. To disable a feed send `{id, enabled: false}`.

### 2. Fired topics

`admin_trends_topics(p_status text = null, p_country text = null, p_limit int = 100) → jsonb[]`
(full topic rows; use `p_status = 'fired'` for the "fired, waiting for drafting" list).

### 3. Drafts: published / queued / rejected / noindex lists, and gate results per draft

`admin_trends_drafts(p_status text = null, p_country text = null, p_limit int = 100, p_offset int = 0) → jsonb[]`

Each item: `id, topic_id, country, slug, status, headline, place, place_slug, velocity,
failed_gate, reason, gates, sensitive, sensitive_reasons, review_stage, topic_reviewed_by,
topic_reviewed_at, reviewer_id, reviewer_name, reviewed_at, review_note, has_article, rewrites,
model, published_at, last_update_at, superseded_by, noindex_reason, visits_14d_after_end,
storage_path, dirty, created_at, updated_at`.

Statuses: `queued` (`has_article = false`: waiting for the Claude draft; `true`: passed gates 3-5,
waiting for the caps), `review`, `rejected`, `published`, `noindex`.

`gates` holds one object per gate that ran, in order; show a row of pass/fail chips:

| key | gate | useful fields |
|---|---|---|
| `sources` | 1. at least 2 independent publishers | `domains[]`, `detail` |
| `sensitive` | 2. sensitive-topic block | `reasons[]` (`keyword:police`, `tag:health`), `topic_approved`, `review`, `stage` |
| `originality` | 3. n-gram overlap vs every source, one rewrite | `max_similarity`, `worst_source`, `long_quote`, `rewrites` |
| `facts` | 4. fact consistency (second model pass) | `unsupported_claims_removed`, `conflicts`, `notes` |
| `value` | 5. length and sections | `words`, `reason` |
| `balance` | 5b. balance (local + model pass) | `ratio`, `weaker_side`, `loaded_terms`, `reason` |
| `caps` | 6. kill switch, daily / hourly caps | `passed`, `reason`, `at` |

`admin_trends_draft(p_draft_id uuid) → jsonb`: the same fields plus `article` (the full article
JSON, render it like the site: headline, 3-line summary, the two perspectives, where they agree,
local angle, context, what to watch, updates, corrections, sources), `topic`, `signals[]` (the
headlines behind it) and `log[]` (decision log). `404 draft_not_found`.

Actions on a draft: `admin_trends_set_draft_status(p_draft_id, p_action, p_reason text = null) → jsonb`

| action | allowed from | effect |
|---|---|---|
| `reject` | queued, review | never published |
| `noindex` | published | page stays, `noindex`, out of the sitemap |
| `index` | noindex (not superseded) | indexable again |
| `unpublish` | published, noindex | removed from the bucket and site on the next publish run |

Other moves: `409 invalid_draft_action`.

### 4. Sensitive-topic review queue

`admin_trends_review_queue(p_country text = null) → jsonb[]` (oldest first; each item as in the
drafts list plus `article`).

`admin_trends_review(p_draft_id uuid, p_approve boolean, p_note text = null) → jsonb`

Two stages (`review_stage`):

- `topic`: nothing has been drafted yet (sensitive topics never reach the model before a human
  says yes). Show the topic, its reasons and its headlines (`admin_trends_draft`). Approve → the
  pipeline drafts it on its next run; reject → dropped.
- `content`: the finished draft (passed gates 3-5) is sensitive. Show the full article. Approve →
  queued for publishing (caps still apply) and the article records `review.approved_by` /
  `approved_at`, which the site build requires; reject → rejected.

Reviewer and date are stored on the draft (`reviewer_id` / `reviewed_at`, and
`topic_reviewed_by` / `topic_reviewed_at` for the first stage). `409 draft_not_in_review` when
someone else got there first: refresh the queue.

### 5. Caps, ramp and thresholds editor

`admin_trends_settings() → jsonb`:

```json
{ "settings": { "pipeline": {...}, "publishing": {...}, "caps": {...}, "ramp": {...}, "gates": {...},
                "detection": {...}, "sensitive_tags": [...], "sensitive_keywords": [...],
                "banned_perspective_terms": [...], "app_links": [...], "app_hosts": {...} },
  "descriptions": { "<key>": "help text" },
  "per_day": { "usa": 1, "india": 1 },
  "health": { "usa": { ...latest snapshot... } | null, "india": ... },
  "health_problem": { "usa": "no_recent_health | manual_action | error_reports | search_console_warnings | low_indexed_share | traffic_drop" | null, "india": ... },
  "published_24h": { "usa": 0, "india": 0 },
  "runs": { "trends-poll": { "started_at", "finished_at", "ok", "dry_run", "stats", "error" }, "trends-draft": ..., "trends-publish": ... } }
```

Edit with `admin_trends_set_setting(p_key text, p_value jsonb) → {key, value}`. Object settings
are merged (send only the changed fields); list settings are replaced. Server-side floors from the
brief (`400 invalid_setting_value`, detail says which): at least 2 sources, at least 250 words,
`max_similarity` at most 0.5, at most one rewrite, at most 3 per hour, at most 20 per day,
ascending integer `ramp_levels`, at least 30 days between ramp steps. `publishing` cannot be set
here (`400 use_admin_trends_set_kill_switch`); ramp levels change only through the ramp RPC.
`pipeline` `{enabled}` starts or stops the cron jobs.

Ramp (per country, levels 1 → 2 → 5 → 10 → 20 per day):
`admin_trends_set_ramp(p_country, p_level int, p_reason text = null) → ramp`

- step down: any time;
- step up: one level at a time (`409 ramp_one_level_at_a_time`), at least
  `min_days_between_steps` after the last change (`409 ramp_step_too_soon`), and only with a
  healthy snapshot from the last `max_age_days` (`409 ramp_unhealthy`, detail = the problem);
- the pipeline steps down by itself (one level) when a new snapshot is unhealthy, and steps up by
  itself only if `ramp.auto_step_up` is on;
- the site's `web/trends_site/data/config.json` caps are a ceiling: the site never builds more
  than the lower of the two, so raise the repo value when ramping up.

Health snapshots (enter weekly from Search Console and site analytics until an integration exists):
`admin_trends_record_health(p_country, p_indexed_share numeric 0-1, p_clicks_7d int, p_clicks_prev_7d int,
p_sc_warnings int = 0, p_manual_action boolean = false, p_error_reports_24h int = 0, p_note text = null) → jsonb`
(returns the row plus `auto_pause` and `health_problem`). A manual action or more error reports
than `ramp.health.max_error_reports_24h` pauses publishing immediately.

Traffic for the noindex rule: `admin_trends_record_traffic(p_slug, p_visits_14d int) → jsonb`
(visits in the 14 days after the trend ended; below `gates.noindex_min_visits_14d` the article
becomes noindex).

### 6. Kill switch

`admin_trends_set_kill_switch(p_paused boolean, p_reason text = null) → publishing`

Pauses drafting (no model spend) and publishing at once; polling continues so the board stays
live. `paused_at` is published in the bucket index, and the site build refuses articles
published after it. Show who paused and why (`paused_by` = admin id or `auto`, `paused_reason`),
and a confirmation dialog for resuming.

### 7. Corrections and superseded articles

- `admin_trends_add_correction(p_draft_id, p_text) → jsonb`: appends a dated correction (shown in
  the article's Corrections section) and re-publishes it within 5 minutes (`409 draft_not_published`,
  `400 correction_too_short`).
- `admin_trends_supersede(p_slug, p_by_slug) → jsonb`: the old article becomes noindex with a
  canonical to the newer one.

### 8. Decision log

`admin_trends_publish_log(p_limit int = 100, p_draft_id uuid = null) → jsonb[]`: `decision`
(`queued`, `review`, `rejected`, `published`, `capped`, `updated`, `corrected`, `noindex`,
`superseded`, `unpublished`, `indexed`, `review_approved`, `review_rejected`, `ramp_up`,
`ramp_down`, `auto_pause`, `kill_switch`), `reason`, `details`, `actor_id` (null = pipeline),
`created_at`.

### 9. Run now

`supabase.functions.invoke('trends-poll' | 'trends-draft' | 'trends-publish', body: {action: 'run'})`
with the admin JWT → `{ok, dry_run, reason?, stats}`. `dry_run` with `reason` means a secret is
missing (no Claude key: nothing drafted; no bucket credentials: nothing uploaded).

Admin runs are limited to **6 per function per rolling hour per project** (migration 1300; cron
runs do not count): past that the function answers `429 rate_limited` with `Retry-After` and
`details: {fn, limit, window_seconds, used, retry_after_seconds}`, and nothing runs.
`admin_trends_settings().run_now` gives the current allowance per function
(`{used, limit, remaining, window_seconds, retry_after_seconds}`), and `runs.<fn>.trigger` says
whether the last run was `cron` or `admin`. The panel disables the button when the allowance is
used up and shows the wait.

## Not covered yet

- Traffic, revenue and conversion stats for the trends site (needs Search Console / analytics /
  AdSense integrations; UTM `utm_source=trends` links are already on every app link).
- Automatic import of Search Console health; snapshots are entered by hand for now.
