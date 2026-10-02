# I Want USA and I Want India

[![CI](https://github.com/vsvivek1/QuoteMeApps/actions/workflows/ci.yml/badge.svg)](https://github.com/vsvivek1/QuoteMeApps/actions/workflows/ci.yml)
[![Supabase deploy](https://github.com/vsvivek1/QuoteMeApps/actions/workflows/supabase-deploy.yml/badge.svg)](https://github.com/vsvivek1/QuoteMeApps/actions/workflows/supabase-deploy.yml)
[![Store builds](https://github.com/vsvivek1/QuoteMeApps/actions/workflows/release.yml/badge.svg)](https://github.com/vsvivek1/QuoteMeApps/actions/workflows/release.yml)

A reverse-quote marketplace: buyers post what they want, local sellers send quotes. Two separate apps built from one Flutter codebase:

| | I Want USA | I Want India |
|---|---|---|
| Legal entity | Calecute Technologies LLC | Calecute Technologies (OPC) Private Limited |
| Package / bundle id | `com.calecute.iwant.usa` | `com.calecute.iwant.india` |
| Currency, tax | USD, seller-entered sales tax | INR, GST (CGST+SGST or IGST) |
| Payments (seller plans) | Stripe | Razorpay or Cashfree |
| Languages | English, Spanish | English, Hindi |
| Backend | Supabase (US region) | Supabase (Mumbai, `ap-south-1`) |

## Repository map

| Path | What |
|---|---|
| `lib/` | The app. `lib/core` (config, money and tax, routing, theme, cache, data), `lib/features/*` (presentation / application / domain), `lib/country/{usa,india}` (`CountryConfig`). |
| `supabase/` | Postgres migrations (PostGIS, RLS on every table, RPCs), Edge Functions (Deno), pgTAP tests, `config.toml`, seeds. See `supabase/API.md`. |
| `admin/` | Admin panel (Flutter web): verification, moderation, categories, flags, outreach CRM, brochures. |
| `web/` | Vercel sites: per-country app site (legal, deletion page, deep-link fallbacks, SEO pages) and the trends site. See `web/README.md`. |
| `legal/`, `compliance/` | Legal pages per country and store declarations (Data safety, App Privacy, ratings). |
| `branding/` | Brand source assets; `tool/branding/generate.py` regenerates icons and splash per flavor. |
| `fastlane/`, `android/fastlane/`, `ios/fastlane/` | Release lanes and store metadata per country. |
| `docs/` | `DECISIONS.md`, `BLOCKERS.md`, `PROGRESS.md`. |

## Run it in two minutes (demo mode)

With no Supabase URL configured the app runs on an in-memory marketplace: sign in with any phone number and OTP `123456`; simulated sellers send quotes.

```sh
flutter pub get
flutter run --flavor indiaDev -t lib/main_india.dart --dart-define-from-file=config/india.dev.json
flutter run --flavor usaDev   -t lib/main_usa.dart   --dart-define-from-file=config/usa.dev.json
```

Flavors are `<country><Env>`: `usaDev`, `usaStaging`, `usaProd`, `indiaDev`, `indiaStaging`, `indiaProd`. Each reads `config/<country>.<env>.json` (keys in `config/README.md`). Only public values go there; never the Supabase service role key.

## Development checks

```sh
dart run build_runner build --delete-conflicting-outputs   # freezed, riverpod, drift
flutter gen-l10n
dart format lib test
flutter analyze
flutter test
```

Strings live in `lib/l10n/app_{en,hi,es}.arb`. After adding an English string with placeholders, run `python3 tool/l10n/arb_meta.py` to add placeholder metadata.

## Backend setup (Supabase)

1. Install the [Supabase CLI](https://supabase.com/docs/guides/local-development) and Docker.
2. Local stack: `supabase start` runs every migration and `supabase/seed.sql`. Test logins (fictional numbers, code `123456`) are in `supabase/config.toml` under `[auth.sms.test_otp]`: USA `+1 555-0100` to `0103`, India `+91 0000000001` to `0004`.
3. Point a dev flavor at it: put the local API URL and anon key from `supabase status` in `config/<country>.dev.json`.
4. Tests: `supabase test db` (pgTAP) and `cd supabase/functions && deno test --allow-env --allow-net --allow-read`.
5. Hosted projects: create one project per country per environment (India in Mumbai), then `supabase link --project-ref <ref>`, `supabase db push`, `supabase functions deploy`. CI does this automatically (below).
6. In each hosted project: enable the Custom Access Token Hook, phone auth with your SMS provider (India needs DLT-registered templates), Google and Apple providers, CAPTCHA (Turnstile), and add Edge Function secrets listed in `supabase/API.md`. Add test numbers in Auth > Phone only for store-review demo accounts in production.
7. Postal codes and cities: import scripts live under `supabase/seed/`; India from the India Post PIN directory (data.gov.in), USA from Census ZCTA gazetteer files, city names and populations from GeoNames.

## Firebase (push, Crashlytics, Analytics, Remote Config, App Check)

Create one Firebase project per country (optionally per env), then per flavor:

```sh
flutterfire configure --project=<id> --android-package-name=com.calecute.iwant.india.dev ...
```

Place `google-services.json` in `android/app/src/<flavor>/` and `GoogleService-Info.plist` in `ios/config/<flavor>/` (both gitignored), and set `FIREBASE_ENABLED` to `true` in that flavor's config. Push is sent from Edge Functions through the FCM HTTP v1 API, so the Firebase service account goes into Supabase function secrets, never into the app.

## iOS

Flavor configurations and schemes come from `ruby tool/ios/setup_flavors.rb` (needs `gem install xcodeproj`); re-run it after changing bundle ids or adding a flavor. Per-flavor Google client ids go in `ios/Flutter/secrets/<flavor>.xcconfig` (copy `example.xcconfig`).

## Release builds

```sh
flutter build appbundle --release --flavor usaProd -t lib/main_usa.dart --dart-define-from-file=config/usa.prod.json
flutter build ipa       --release --flavor indiaProd -t lib/main_india.dart --dart-define-from-file=config/india.prod.json
bundle exec fastlane android internal country:india   # Play internal testing
bundle exec fastlane ios beta country:usa             # TestFlight
```

See `fastlane/README.md` for every lane and environment variable.

## Continuous delivery

| Workflow | When | What |
|---|---|---|
| `ci.yml` | every push and PR | codegen check, format, analyze, tests, release AAB for both apps, admin build, pgTAP and Deno tests, website builds |
| `supabase-deploy.yml` | push to `main` / tag `v*` | migrations and Edge Functions to staging / production for both countries |
| `release.yml` | nightly, tag `v*`, manual | fastlane uploads to Play internal testing and TestFlight for both apps |
| Vercel GitHub integration | every push | preview deploy per branch, production on `main` (configure per `web/README.md`) |

Production store releases stay manual (`fastlane android production`, `fastlane ios release`).

### Secrets (GitHub Actions; never in git)

| Where | Name | Get it from |
|---|---|---|
| Repo secret | `SUPABASE_ACCESS_TOKEN` | Supabase dashboard > Account > Access tokens |
| Environments `staging-usa`, `staging-india`, `production-usa`, `production-india` | `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD` | Each Supabase project's settings |
| Environments `store-usa`, `store-india` | `PLAY_SERVICE_ACCOUNT_JSON` | Play Console > API access (service account JSON) |
| | `ANDROID_UPLOAD_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Your upload keystore (`base64 -w0 upload.jks`) |
| | `MAPS_API_KEY_ANDROID` | Google Cloud console (restricted to the app's package and SHA-1) |
| | `APP_CONFIG_PROD_JSON` | Contents of `config/<country>.prod.json` with real public values |
| | `GOOGLE_SERVICES_JSON_PROD`, `GOOGLE_SERVICE_INFO_PLIST_PROD` | Firebase console |
| | `IOS_FLAVOR_XCCONFIG_PROD` | Contents of `ios/Flutter/secrets/<country>Prod.xcconfig` |
| | `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT` (base64 .p8) | App Store Connect > Users and Access > Integrations |
| | `APPLE_TEAM_ID`, `MATCH_GIT_URL`, `MATCH_PASSWORD`, `MATCH_GIT_BASIC_AUTHORIZATION` | Apple developer account; a private certificates repo for `match` |
| Supabase function secrets | Stripe, Razorpay, FCM service account, Upstash, Turnstile secret, email/SMS keys | See `supabase/API.md` |
| Vercel env vars | site settings, Turnstile site key, Supabase URL and anon key | See `web/README.md` |

Jobs whose secrets are missing skip with a warning, so CI stays green until accounts are linked. What still needs an account is tracked in `docs/BLOCKERS.md`.

## Hosting note

Vercel's free Hobby plan is for non-commercial use. Move the commercial sites to Vercel Pro (or another host; the sites are plain Astro static output) before taking payments or showing ads, and set spend limits.
