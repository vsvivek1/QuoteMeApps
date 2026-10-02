# Blockers

Things only the owner can do. Everything else is built and stubbed behind interfaces so work continues.

| # | Needed | Why | Where it plugs in |
|---|---|---|---|
| 1 | **Supabase**: create 4 projects (usa-staging, usa-prod, india-staging, india-prod; India in Mumbai `ap-south-1`) and add their refs and DB passwords as GitHub environment secrets. | Hosted database, auth, storage and Edge Functions. Until then the app runs in demo mode. | `.github/workflows/supabase-deploy.yml` (environments `staging-usa`, `staging-india`, `production-usa`, `production-india`: `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD`; repo secret `SUPABASE_ACCESS_TOKEN`), then `config/<country>.<env>.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). |
| 2 | **Firebase**: one project per country (or per country and env), run `flutterfire configure` per flavor. | Push (FCM), Crashlytics, Analytics, Remote Config, App Check. | `android/app/src/<flavor>/google-services.json`, `ios/config/<flavor>/GoogleService-Info.plist` (both gitignored), `FIREBASE_ENABLED=true` in the flavor config. |
| 3 | **Vercel**: import the GitHub repo as one project per site (app site USA, app site India, trends site, admin). | Legal pages, deletion page, deep-link fallbacks, SEO pages. Hobby plan is non-commercial: move to Pro before payments or ads. | See `web/README.md`. |
| 4 | **Domains** for both apps (placeholders `iwantusa.app`, `iwantindia.app`). | Deep links, legal URLs, store listings. | See DECISIONS row on domains. |
| 5 | **Google Play** developer accounts (one per legal entity) and a service account JSON; upload keystores. | Store uploads. | GitHub environments `store-usa` / `store-india`: `PLAY_SERVICE_ACCOUNT_JSON`, `ANDROID_UPLOAD_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `MAPS_API_KEY_ANDROID`. |
| 6 | **Apple** developer accounts, App Store Connect API key, a private `match` certificates repo. | TestFlight uploads; Sign in with Apple. | `store-*` environments: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`, `APPLE_TEAM_ID`, `MATCH_GIT_URL`, `MATCH_PASSWORD`, `MATCH_GIT_BASIC_AUTHORIZATION`. |
| 7 | **Stripe** (USA, Calecute Technologies LLC) and **Razorpay or Cashfree** (India) accounts and webhook secrets. | Seller plan web checkout. Monetization stays off (`monetization_enabled=false`) until then. | Supabase Edge Function secrets (see `supabase/API.md`). |
| 8 | **Google Cloud** OAuth clients (web, Android, iOS) and Maps/Places API keys. | Google sign-in, address entry. | `config/*.json` (`GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`), `ios/Flutter/secrets/<flavor>.xcconfig`, `MAPS_API_KEY_ANDROID`. |
| 9 | **SMS provider** for phone OTP (Twilio/MessageBird for USA; an Indian provider with DLT template registration for India). | Real phone sign-in. Test numbers work without it. | Supabase dashboard, Auth > Phone. |
| 10 | **Cloudflare Turnstile** site and secret keys. | CAPTCHA on OTP and web forms. | `TURNSTILE_SITE_KEY` in app config and site env; secret in Supabase function secrets. |
| 11 | **Upstash Redis** (free tier) URL and token. | Rate limiting in Edge Functions. | Supabase function secrets. |
