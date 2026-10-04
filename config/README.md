# Build-time config

Each flavor reads one JSON file with `--dart-define-from-file`:

```
flutter run --flavor indiaDev -t lib/main_india.dart --dart-define-from-file=config/india.dev.json
flutter build appbundle --flavor usaProd -t lib/main_usa.dart --dart-define-from-file=config/usa.prod.json
```

Copy `example.json` to `config/<country>.<env>.json`. Only public values go here
(Supabase URL and anon/publishable key, OAuth client IDs, Turnstile site key).
Never the service role key. Files named `*.local.json` are gitignored.

| Key | Meaning |
|---|---|
| `SUPABASE_URL` | Project URL. Empty means demo mode (in-memory backend, OTP `123456`). |
| `SUPABASE_ANON_KEY` | Anon / publishable key. |
| `GOOGLE_WEB_CLIENT_ID` | Google web client ID, used as `serverClientId` and in Supabase's Google provider. |
| `GOOGLE_IOS_CLIENT_ID` | iOS OAuth client ID. |
| `TURNSTILE_SITE_KEY` | Cloudflare Turnstile site key for OTP CAPTCHA. |
| `FIREBASE_ENABLED` | `true` once `flutterfire configure` has added the Firebase files for this flavor. |
| `DEMO_MODE` | `true` forces demo mode. |
| `PHONE_AUTH_ENABLED` | `false` hides phone sign-in and phone linking (no SMS provider yet). Defaults to `true`. |
