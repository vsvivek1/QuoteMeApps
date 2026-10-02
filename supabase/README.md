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
  migrations/            schema, RLS, RPCs, storage, realtime, outreach CRM, web forms, cron, admin audit log, KPIs, outreach safety, app sync (22 files)
  seed.sql               shared seed (legal versions, languages, seed_tools helpers)
  seed/<country>.sql     categories (policies, labels, field schemas), keywords, postal codes, metros
  seed/demo_generator.sql + seed/<country>_demo.sql   demo data (local + staging only)
  functions/             Edge Functions (Deno, deno.json import map, _shared/, tests/)
  tests/database/        pgTAP suites (11 files, 298 tests)
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
(hourly), `iwant-expire-web-forms` (hourly).

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

Current result: India 11 files / 298 tests PASS, USA 11 files / 298 tests PASS.

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
and the brochure format aliases.

## Conventions

- Money: integer minor units; tax rates are integer basis points. `round_half_up(n, d) = (2n + d) div (2d)`.
  The same code exists in SQL (`public.money_round_half_up`, `gst_line_tax`, `us_sales_tax`,
  `compute_quote_totals`), TypeScript (`functions/_shared/money.ts`) and Dart. Fixtures:
  `tests/fixtures/money_rounding_cases.json`.
  **Known limitation:** integer basis points cannot represent rates such as NYC's 8.875 %
  (the demo uses 888). A finer unit (for example 1/100 bp, 887500) needs a coordinated change
  in all three implementations and in the fixtures.
- Errors: RPCs raise `SQLSTATE PTnnn` (HTTP `nnn` via PostgREST) with a stable snake_case code as
  the message. Edge Functions return the same `{code, message, details, hint}` shape.
- Every client write goes through RPCs or column-limited grants. RLS is on for every table.
  `anon` can read only `app_settings` (public keys), `postal_codes`, `cities`, `categories`,
  `sellers`, `seller_categories` and `reviews`.
