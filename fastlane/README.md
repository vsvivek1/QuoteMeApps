# Release automation (fastlane): I Want USA and I Want India

One Flutter codebase, two apps, two stores each. Every lane takes `country:usa` or `country:india`, which selects:

| | I Want USA (`country:usa`) | I Want India (`country:india`) |
|---|---|---|
| Android package / iOS bundle ID | `com.calecute.iwant.usa` | `com.calecute.iwant.india` |
| Flutter flavor (Android variant, Xcode scheme) | `usaProd` | `indiaProd` |
| Entry point | `lib/main_usa.dart` | `lib/main_india.dart` |
| Play metadata | `fastlane/metadata/android/usa/{en-US,es-US}/` | `fastlane/metadata/android/india/{en-IN,hi-IN}/` |
| App Store metadata | `fastlane/metadata/ios/usa/{en-US,es-MX}/` | `fastlane/metadata/ios/india/{en-GB,hi}/` |
| Developer account (Play and Apple) | Calecute Technologies LLC | Calecute Technologies (OPC) Private Limited |
| Availability | United States only | India only |
| Env var suffix | `_USA` | `_INDIA` |

> **Confirm the English locale for India on the App Store.** App Store Connect has no `en-IN` localization; this setup uses **`en-GB` (English (U.K.))** as the India app's primary language, with **`hi` (Hindi)** as the second. Before the first upload, check the localizations App Store Connect offers for the India app and rename `fastlane/metadata/ios/india/en-GB/` (and `ios_primary_locale` in `fastlane/lib/iwant_release.rb`, and `LOCALES` in `check_metadata.py`) if you choose `en-US` or `en-AU` instead.

## Setup

```bash
gem install bundler
bundle install                                  # installs fastlane from the root Gemfile
# Running from the repo root (recommended): one env file for both platforms
cat android/fastlane/.env.example ios/fastlane/.env.example > fastlane/.env   # fill in, never commit
# Running from inside android/ or ios/: use that folder's fastlane/.env instead
```

fastlane loads `.env` from the folder of the Fastfile it runs: `fastlane/.env` from the root (the root `fastlane/Fastfile` imports both platform Fastfiles), `android/fastlane/.env` or `ios/fastlane/.env` from inside those folders. `.env` files are git-ignored (`.env`, `**/fastlane/.env`). In CI, set the same variables as secrets.

## Commands

Run from the repo root (the root `fastlane/Fastfile` imports `android/fastlane/Fastfile` and `ios/fastlane/Fastfile`), or from inside `android/` / `ios/`. fastlane writes a `report.xml` next to the Fastfile it runs; it is a build artefact (add `**/fastlane/report.xml` to `.gitignore`).

| Command | What it does |
|---|---|
| `bundle exec fastlane android test` | `flutter pub get`, `flutter analyze`, `flutter test` |
| `bundle exec fastlane android internal country:india` | Builds the `indiaProd` release AAB (`--obfuscate --split-debug-info`), checks the build number is above every Play track, uploads to **Internal testing** with `changelogs/default.txt`, uploads the R8 mapping and (optionally) Crashlytics Dart symbols |
| `bundle exec fastlane android closed country:india` | Promotes the latest Internal release to the closed testing track (`PLAY_CLOSED_TRACK`, default `alpha`) |
| `bundle exec fastlane android production country:india` | Promotes the closed-testing release to **Production** as a **staged rollout at 10%** |
| `bundle exec fastlane android production country:india rollout:0.5 update_rollout:true` | Raises the live production rollout to 50% (`rollout:1` completes it) |
| `bundle exec fastlane android metadata country:usa` | Uploads title, short and full description and images only (`skip_images:true` for text only) |
| `bundle exec fastlane android bump` | Increments the build number in `pubspec.yaml` and commits `chore(release): bump version to x.y.z+N` (`build_number:N`, `version:1.2.0`, `commit:false`) |
| `bundle exec fastlane ios test` | Same checks as Android |
| `bundle exec fastlane ios certs country:usa` | `match` App Store certificate and profile (read-only; `readonly:false` to create or renew) |
| `bundle exec fastlane ios beta country:usa` | `flutter build ios --config-only` for `usaProd`, archives with Xcode (`Release-usaProd`), uploads to **TestFlight** with the release notes, uploads dSYMs to Crashlytics (`external:true groups:"QA"` for external testers) |
| `bundle exec fastlane ios release country:usa` | Uploads metadata and review information and **submits the latest TestFlight build of the pubspec version for App Review** (phased release, manual release after approval; `build_number:N`, `automatic_release:true`) |
| `bundle exec fastlane ios metadata country:india` | Uploads App Store text, URLs, review information and screenshots (if any) without submitting |

Typical release: `android bump` → commit/tag → `android internal` and `ios beta` for both countries → test → `android closed` → `android production` and `ios release`.

Version and build number always come from `pubspec.yaml` (`version: 1.2.3+45`). Both apps share it, so a build number is used once per app. `ios beta` and `android internal` refuse to upload a build number the store already has.

## Metadata and placeholders

- Store text lives in `fastlane/metadata/<android|ios>/<country>/<locale>/`. Edit it there.
- Before every upload, the lanes run `python3 fastlane/check_metadata.py` and copy the folder to `build/fastlane/metadata/...`, replacing `{{NAME}}` with the env var `NAME_<COUNTRY>` (or `NAME`). The upload fails if any value is missing, so domains and demo credentials never live in git.
- Limits checked: Play title 30, short description 80, full description 4000, changelog 500; App Store name 30, subtitle 30, keywords 100 bytes (comma-separated, no spaces, no duplicates, no words already in the name), description 4000, promotional text 170, release notes 4000, `https://` URLs; no mention of the other store. Run it any time: `python3 fastlane/check_metadata.py -v`.
- Play images: add `images/icon.png`, `images/featureGraphic.png`, `images/phoneScreenshots/*.png` (and `sevenInchScreenshots`, `tenInchScreenshots`) under each Play locale folder.
- App Store screenshots: add them to `fastlane/screenshots/ios/<country>/<locale>/`; the iOS lanes upload them when present.
- Store listings link to the hosted legal pages (`/legal/privacy-policy`, `/legal/terms-of-service`, `/legal/contact-support`, India also `/legal/grievance-officer`) built by `legal/build.py`.
- Not settable through fastlane, do once in the consoles: Play **App access** (copy from `compliance/<country>/review-demo-access.md`), Data safety, content rating, target audience, countries/regions; App Store **App Privacy**, age rating, availability (one country), pricing (free) and in-app purchases. See `compliance/<country>/README.md`.

## Environment variables

Every variable may be set with a `_USA` or `_INDIA` suffix (preferred, because each app has its own developer accounts); the unsuffixed name is the fallback.

### Shared

| Variable | Required for | Description |
|---|---|---|
| `IWANT_COUNTRY` | optional | Default country when `country:` is not passed |
| `IWANT_REPO_ROOT` | optional | Repo root override (normally detected from the `Gemfile`) |
| `DART_DEFINE_FILE_<C>` | optional | JSON file passed as `--dart-define-from-file` (e.g. Supabase URL and anon key for prod). Never put secrets in it: everything in it ends up in the app |
| `WEB_DOMAIN_<C>` | metadata, internal, release | Country website domain used in store URLs, e.g. the I Want USA site (no `https://`) |
| `IWANT_PLACEHOLDER_LEN` | optional | Length assumed for `{{PLACEHOLDERS}}` by `check_metadata.py` (default 30) |
| `CI` | CI only | Enables `setup_ci` (temporary keychain) and manual signing on iOS |

### Android (`android/fastlane/.env`)

| Variable | Required for | Description |
|---|---|---|
| `PLAY_JSON_KEY_PATH_<C>` | internal, closed, production, metadata | Path to the Google Play service-account JSON for that app's developer account |
| `PLAY_JSON_KEY_DATA_<C>` | alternative | Raw JSON content of the key (CI secret) instead of a path |
| `ANDROID_KEYSTORE_PATH_<C>` | internal | Upload keystore (`.jks`). If unset, Gradle falls back to `android/key.properties` |
| `ANDROID_KEYSTORE_PASSWORD_<C>` | internal | Keystore password |
| `ANDROID_KEY_ALIAS_<C>` | internal | Key alias |
| `ANDROID_KEY_PASSWORD_<C>` | internal | Key password |
| `PLAY_RELEASE_STATUS` | optional | `completed` (default) or `draft` (needed until the app's first release has been reviewed) |
| `PLAY_CLOSED_TRACK` | optional | Closed testing track name (default `alpha`) |
| `PLAY_ROLLOUT` | optional | Production staged rollout fraction (default `0.1`) |
| `FIREBASE_ANDROID_APP_ID_<C>` | optional | Firebase Android app ID; enables `firebase crashlytics:symbols:upload` for the Dart symbols (Firebase CLI must be installed and logged in) |

| `MAPS_API_KEY_ANDROID_<C>` | internal | Google Maps Android API key injected into the manifest by Gradle (`MAPS_API_KEY_ANDROID`) |

**Gradle signing contract:** `android/app/build.gradle.kts` reads `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` (and `MAPS_API_KEY_ANDROID`) from the environment, with `android/key.properties` taking precedence when it exists. The `internal` lane copies the `_USA` / `_INDIA` values into those names for the build. Without a keystore Gradle falls back to debug keys, which Play rejects, so always set them for uploads. Play App Signing holds the app signing key; these are upload keys, one per app.

### iOS (`ios/fastlane/.env`)

| Variable | Required for | Description |
|---|---|---|
| `ASC_KEY_ID_<C>` | certs, beta, release, metadata | App Store Connect API key ID (Users and Access > Integrations), App Manager role |
| `ASC_ISSUER_ID_<C>` | same | API key issuer ID |
| `ASC_KEY_PATH_<C>` | same (or content) | Path to the `.p8` key |
| `ASC_KEY_CONTENT_<C>` | alternative | Base64 of the `.p8` content (CI) |
| `APPLE_TEAM_ID_<C>` | certs, beta | Apple Developer team ID of that entity |
| `ASC_TEAM_ID_<C>` | optional | App Store Connect team ID, only for Apple IDs in several teams |
| `MATCH_GIT_URL_<C>` | certs, beta | Private git repo for match certificates (one per team, or one repo with per-country branches) |
| `MATCH_GIT_BRANCH_<C>` | optional | Branch in the match repo (default `usa` / `india`) |
| `MATCH_PASSWORD` | certs, beta | Passphrase that encrypts the match repo |
| `MATCH_GIT_BASIC_AUTHORIZATION` | CI | Base64 `user:token` for HTTPS clones of the match repo |
| `MATCH_STORAGE_MODE` | optional | `git` (default), `google_cloud` or `s3` |
| `MATCH_READONLY` | optional | `true` (default); `false` lets `certs` create or renew |
| `IOS_FORCE_MANUAL_SIGNING` | optional | `true` switches `Release-<flavor>` to the match profile locally (always done in CI) |
| `TESTFLIGHT_GROUPS` | optional | Comma-separated TestFlight groups for `beta external:true` |
| `REVIEW_CONTACT_FIRST_NAME_<C>`, `REVIEW_CONTACT_LAST_NAME_<C>`, `REVIEW_CONTACT_PHONE_<C>`, `REVIEW_CONTACT_EMAIL_<C>` | release, metadata | App Review contact person |
| `REVIEW_BUYER_PHONE_<C>`, `REVIEW_BUYER_OTP_<C>` | release, metadata | Review buyer test phone number and fixed OTP (Supabase prod Auth > Phone > test numbers). Uploaded as demo user / password |
| `REVIEW_SELLER_PHONE_<C>`, `REVIEW_SELLER_OTP_<C>` | release, metadata | Review seller test phone number and OTP, included in the review notes |

**Xcode contract:** the iOS project needs schemes `usaProd` and `indiaProd` with build configurations `Release-usaProd` and `Release-indiaProd`, bundle IDs as above, `ITSAppUsesNonExemptEncryption = false`, and `ios/config/<country>/GoogleService-Info.plist` (git-ignored) for the Crashlytics dSYM upload.

## CI (GitHub Actions)

The workflow (brief Section 19) should run `bundle exec fastlane android test` on every push, and on tags `v*.*.*` run `android internal` and `ios beta` (macOS runner) for both `country:usa` and `country:india`, with the variables above as repository secrets. Lanes never print secret values.

## Files

```
Gemfile                              fastlane gem
fastlane/Fastfile                    root entry point (imports both platform Fastfiles)
fastlane/lib/iwant_release.rb        shared helpers (country config, pubspec version, metadata rendering)
fastlane/check_metadata.py           store character-limit checker
fastlane/metadata/android/<country>/<locale>/   Play listing text (supply)
fastlane/metadata/ios/<country>/<locale>/       App Store text and URLs (deliver)
fastlane/metadata/ios/<country>/review_information/  App Review contact and demo login (env placeholders)
android/fastlane/{Fastfile,Appfile,.env.example}
ios/fastlane/{Fastfile,Appfile,Matchfile,.env.example}
```
