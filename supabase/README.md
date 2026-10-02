# Supabase backend: I Want USA / I Want India

One schema, four projects. The client contract for the Flutter app (tables, RPCs, buckets,
realtime, Edge Functions, errors) is in [API.md](API.md).

| Project | Region | App package / bundle id |
|---|---|---|
| `iwant-usa-staging` | us-east-1 | `com.calecute.iwant.usa` (staging flavor) |
| `iwant-usa-prod` | us-east-1 | `com.calecute.iwant.usa` |
| `iwant-india-staging` | **ap-south-1** (Mumbai) | `com.calecute.iwant.india` (staging flavor) |
| `iwant-india-prod` | **ap-south-1** (Mumbai) | `com.calecute.iwant.india` |

Indian personal data stays in `ap-south-1`. Create each project in its region from the dashboard
(the region cannot be changed later).

```
supabase/
  config.toml            local stack: auth (phone + test OTPs, Google, Apple, captcha), token hook, functions
  migrations/            schema, RLS, RPCs, storage, realtime, outreach CRM, web forms, cron, admin audit log, KPIs, outreach safety, app sync, sales tax ppm (23 files)
  seed.sql               shared seed (legal versions, languages, seed_tools helpers)
  seed/<country>.sql     categories (policies, labels, field schemas), keywords, postal codes, metros
  seed/demo_generator.sql + seed/<country>_demo.sql   demo data (local + staging only)
  functions/             Edge Functions (Deno, deno.json import map, _shared/, tests/)
  tests/database/        pgTAP suites (11 files, 321 tests)
  tests/local/           Docker-free harness: Postgres + PostGIS + pgTAP + Supabase shims
  tests/fixtures/        money rounding cases shared by SQL, Deno and Dart
tool/data/geo_import.py  postal code + city import (India Post, GeoNames, US Census ZCTA)
```

## Local stack

```bash
cp supabase/.env.example supabase/.env               # config.toml env(...) values
cp supabase/.env.example supabase/functions/.env     # Edge Function secrets
supabase start                                       # applies migrations + India seed + demo data
supabase functions serve --env-file supabase/functions/.env
```

Studio: http://127.0.0.1:54323. Sign in from the app with a test number (code `123456`, no SMS
sent):

| | USA | India |
|---|---|---|
| buyer | +1 555-555-0100 | +91 0000000001 |
| seller | +1 555-555-0101 | +91 0000000002 |
| verified seller | +1 555-555-0102 | +91 0000000003 |
| admin | +1 555-555-0103 | +91 0000000004 |
| store-review buyer | +1 555-555-0104 | +91 0000000005 |
| store-review seller | +1 555-555-0105 | +91 0000000006 |

(`15555550100` ... and `910000000001` ... in `[auth.sms.test_otp]`.)

### Test OTPs in production

Test OTPs live in `config.toml` for the local stack and in the dashboard (Authentication >
Providers > Phone > Test phone numbers) for hosted projects. Never in `seed.sql` or migrations.

- **staging**: all twelve numbers may be enabled.
- **production**: keep test OTPs **disabled**, except the two store-review demo accounts of that
  country (USA `15555550104`, `15555550105`; India `910000000005`, `910000000006`), which App
  Review and Play review need. Prefer a non-guessable code for these two in production, share it
  only in the review notes, and remove them when review access is no longer needed.

### Per-country seeds

`config.toml` seeds India by default. For the USA locally:

```bash
supabase db reset --no-seed
DB=postgresql://postgres:postgres@127.0.0.1:54322/postgres
psql "$DB" -f supabase/seed.sql -f supabase/seed/usa.sql \
           -f supabase/seed/demo_generator.sql -f supabase/seed/usa_demo.sql
```

(or switch `sql_paths` in `[db.seed]` to the `usa` files).

Hosted projects:

| File | staging | prod |
|---|---|---|
| `seed.sql`, `seed/<country>.sql` | yes | yes |
| `seed/demo_generator.sql`, `seed/<country>_demo.sql` | yes | **no** (prod gets only the review accounts: load `demo_generator.sql`, then run `select seed_tools.generate_review_data(...)` with the two review numbers, then `drop schema seed_tools cascade`) |
| `tool/data/geo_import.py` (all postal codes and cities) | yes | yes |

```bash
psql "$PROD_DB_URL" -f supabase/seed.sql -f supabase/seed/india.sql
```

The country seed sets `app_settings.country`, the currency and the default time zone. Never load
the other country's seed into a project.

## Linking and migrating hosted projects

```bash
supabase login
supabase link --project-ref <iwant-india-staging-ref>    # one project at a time
supabase db push                                       # applies supabase/migrations
supabase functions deploy                              # all functions; per-function verify_jwt from config.toml
supabase secrets set --env-file supabase/functions/.env.india-staging
```

Repeat for each of the four refs (keep one `.env.<country>-<env>` per project, never committed).
Migrations are additive and are applied to staging first, then prod. `pg_net` and `pg_cron` must
be enabled (Dashboard > Database > Extensions) before `db push`; the migrations skip them
otherwise and print a notice.

Auth settings for hosted projects (dashboard, or `supabase config push`):

- Phone provider (Twilio Verify in the USA; India: Twilio or a Send SMS hook to MSG91 with a
  DLT-registered template), Google, and Apple (client ids as in `.env.example`).
- Authentication > Hooks > Custom Access Token: `public.custom_access_token_hook`. It adds the
  `roles`, `active_mode`, `account_status` and `seller_verified` claims.
- Attack protection: Turnstile captcha (`SUPABASE_AUTH_CAPTCHA_SECRET`).

### Database webhooks and cron (`edge_functions_url` + Vault secret)

New requests call `match-request`, and new notifications and the 5-minute digest job call
`send-push`, through `pg_net`. Outreach sending and the cleanup jobs run on `pg_cron`. After the
first `db push` on each project:

```sql
-- 1. where the functions live
update public.app_settings set value = '"https://<ref>.supabase.co/functions/v1"'
 where key = 'edge_functions_url';
-- 2. shared secret, the same value as the EDGE_WEBHOOK_SECRET function secret
select vault.create_secret('<long random string>', 'edge_webhook_secret');
-- rotate: select vault.update_secret((select id from vault.secrets where name = 'edge_webhook_secret'), '<new>');
```

Until both are set, the triggers do nothing (no error), so local development without functions
keeps working. Jobs (`select jobname, schedule from cron.job`): `iwant-expire-stale` (*/15),
`iwant-licence-expiry` (daily), `iwant-push-digests` (*/5), `iwant-outreach-send` (*/10 on
weekdays, only when `outreach_enabled`; it sends only for campaigns an admin activated and only
once `outreach_business_address` holds a real postal address), `iwant-outreach-purge` (daily), `iwant-rate-limit-cleanup`
(hourly), `iwant-expire-web-forms` (hourly), `iwant-seo-export` (02:40 UTC daily, see below).

### External webhooks to register

| Provider | URL | Secret |
|---|---|---|
| Stripe (USA) | `/functions/v1/stripe-webhook` | `STRIPE_WEBHOOK_SECRET` |
| Razorpay (India) | `/functions/v1/razorpay-webhook` | `RAZORPAY_WEBHOOK_SECRET` |
| Google Play RTDN (Pub/Sub push) | `/functions/v1/play-rtdn` | OIDC auth (`PLAY_RTDN_AUDIENCE`) |
| App Store Server Notifications V2 | `/functions/v1/appstore-notifications` | JWS (see the TODO in the function) |
| Resend (outreach domain) | `/functions/v1/outreach-webhook` | `RESEND_WEBHOOK_SECRET` |
| Brevo | `/functions/v1/outreach-webhook?provider=brevo&secret=<EDGE_WEBHOOK_SECRET>` | query secret |
| Websites (forms) | `/functions/v1/web-forms` | Turnstile + CORS allow-list |

## Tests

### Database (pgTAP)

With the Supabase CLI: `supabase test db` (runs `supabase/tests/database/*.test.sql`).

Without Docker, the harness in `tests/local/` starts a throwaway Postgres 16 with PostGIS and
pgTAP and adds minimal Supabase shims (auth/storage schemas, API roles, realtime publication). It
applies every migration, the shared seed, one country seed and its demo data, then runs
`pg_prove`:

```bash
supabase/tests/local/run_local.sh            # india + usa
supabase/tests/local/run_local.sh usa        # one country
KEEP_CLUSTER=1 PGPORT=55433 supabase/tests/local/run_local.sh india   # leave it running for psql
```

Current result: India 14 files / 467 tests PASS, USA 14 files / 467 tests PASS.

### Edge Functions (Deno)

```bash
cd supabase/functions
deno check */index.ts _shared/*.ts
deno test --allow-env --allow-read=../tests/fixtures tests/
```

These cover the pure helpers: money rounding (shared fixtures), rate-limit keys, webhook
signatures (Stripe, Razorpay, Svix with independent vectors), the anti-spam content rules, reply
classification, push scheduling (priority window, digests, quiet hours), store status mapping,
lead import mapping, the Apple ES256 client secret, web-forms validation, the outreach-send
`send_one` flow (with fakes: request checks, gate order, server-built footer, recording, audit)
and the brochure format aliases, and the `seo-export` flow (data checks, upload, deploy hook
dry run, run bookkeeping), and the trends pipeline (`tests/trends_*_test.ts`: feed parsing,
clustering, velocity, every quality gate, the Claude drafting flow against a mocked Messages API,
caps, ramp, kill switch, publish index and full poll / draft / publish runs on an in-memory store;
`trends_store_test.ts` runs the same flow on a real database when `TRENDS_TEST_DB_URL` is set).

## Conventions

- Money: integer minor units; GST rates are integer basis points, US sales tax rates integer parts
  per million (8.875 % = 88750). `round_half_up(n, d) = (2n + d) div (2d)`.
  The same code exists in SQL (`public.money_round_half_up`, `gst_line_tax`, `us_sales_tax`,
  `compute_quote_totals`), TypeScript (`functions/_shared/money.ts`) and Dart. Fixtures:
  `tests/fixtures/money_rounding_cases.json`.
- Errors: RPCs raise `SQLSTATE PTnnn` (HTTP `nnn` via PostgREST) with a stable snake_case code as
  the message. Edge Functions return the same `{code, message, details, hint}` shape.
- Every client write goes through RPCs or column-limited grants. RLS is on for every table.
  `anon` can read only `app_settings` (public keys), `postal_codes`, `cities`, `categories`,
  `sellers`, `seller_categories` and `reviews`.

## SEO data export (Section 21.9)

Migrations `20261002001100_seo_export.sql` and `20261002001110_seo_storage_cron.sql`; contract in
[API.md section 12](API.md#12-seo-data-export-and-guide-review-section-219-migrations-1100-1110).
The nightly job calls the `seo-export` Edge Function, which runs `public.seo_export()`, uploads
`seo/<country>.json` to the public bucket `public-data` and POSTs the Vercel Deploy Hook of that
country's `app_site` project. Per project, once:

1. `supabase functions deploy seo-export` (with the others).
2. In Vercel (project `iwant-usa-web` or `iwant-india-web`) > Settings > Git > Deploy Hooks, create a
   hook for `main`, then store it as a function secret (never commit it):
   `supabase secrets set VERCEL_DEPLOY_HOOK_APP_SITE=<hook url> --project-ref <ref>`.
   Until it is set the function uploads the file and logs a dry run instead of rebuilding.
3. In Vercel set `SEO_DATA_URL=https://<ref>.supabase.co/storage/v1/object/public/public-data/seo/<country>.json`
   and, on Production, `SEO_DATA_REQUIRED=1` (see `web/README.md`).
4. Thresholds (`seo_thresholds`, default 10 quotes / 3 sellers / 90 days), the weekly AI-guide cap
   and the guide review queue live in the admin panel (SEO pages). Run a first export there with
   **Run export now**, or `select private.call_edge_function('seo-export', '{"action":"run"}')`.

Sellers appear in the exported directory only after `set_seller_directory_opt_in(true)` (default
off). pgTAP: `tests/database/12_seo_export.test.sql`; Deno: `functions/tests/seo_export_test.ts`.

## Trends pipeline (Section 21.10)

Migrations `20261002001200_trends_schema.sql`, `..._1210_trends_admin_rpc.sql` and
`..._1220_trends_storage_cron.sql`; contract in [API.md section 13](API.md#13-trends-pipeline-section-2110-migrations-1200-1220).
Everything lives in the `trends` schema (not exposed through the API, no grants for app users), the
public bucket `trends-public` and the cron jobs `trends-poll`, `trends-draft`, `trends-publish`
(every 5 minutes) and `trends-cleanup` (daily). Run it in **one** project only (it covers both
countries), once:

1. `supabase functions deploy trends-poll trends-draft trends-publish`.
2. Secrets (never commit them): `supabase secrets set ANTHROPIC_API_KEY=... VERCEL_DEPLOY_HOOK_TRENDS_SITE=...`
   and, optionally, `REDDIT_CLIENT_ID`, `REDDIT_CLIENT_SECRET`, `REDDIT_USER_AGENT`,
   `ANTHROPIC_MODEL` (default `claude-sonnet-5-5`). Without the Anthropic key the pipeline polls and
   routes topics but drafts nothing.
3. In Vercel (trends_site project) set `TRENDS_DATA_URL=https://<ref>.supabase.co/storage/v1/object/public/trends-public/`.
4. Turn it on from the admin panel (`admin_trends_set_setting('pipeline', '{"enabled": true}')`).
   Publishing starts at 1 article per day per country; the kill switch, caps, ramp and review queue
   are in the admin panel (`admin/TRENDS_ADMIN_NEEDS.md`).

pgTAP: `tests/database/20_trends.test.sql`; Deno: `functions/tests/trends_*_test.ts`.
