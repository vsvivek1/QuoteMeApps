# I Want admin panel (Flutter web)

Separate Flutter web app (`iwant_admin`) for running **I Want USA** and **I Want
India**: dashboard KPIs, seller verification, reports and moderation, category
policy editor, monetization switch and remote flags, the seller acquisition CRM
(Section 21) and the brochure generator.

One build serves **one country project**. The country and backend come from
`--dart-define-from-file` (same JSON shape as the app's `config/`, plus
`COUNTRY` and `ENV`):

```
cd admin
flutter pub get
flutter run -d chrome --dart-define-from-file=config/usa.dev.json
flutter build web --release --dart-define-from-file=config/india.prod.json
```

| Key | Meaning |
|---|---|
| `COUNTRY` | `usa` or `india` |
| `ENV` | `dev`, `staging`, `prod` (shown as a badge) |
| `SUPABASE_URL` | Project URL. Empty = demo mode on in-memory data. |
| `SUPABASE_ANON_KEY` | Anon / publishable key only. **Never the service role key.** |
| `DEMO_MODE` | `true` forces demo mode. |

Put real values in `config/<country>.<env>.local.json` (gitignored).

## Sign-in and roles

Email + password through Supabase Auth, then two checks: the access token's
`roles` claim (custom access token hook) must contain `admin`, and the
`profiles` row must still have the role and `status = active`. Otherwise the
panel signs the user out again. Every write goes through admin-checked RPCs
(`private.require_admin()`) or admin-only RLS; the client has no privilege of
its own.

Demo mode: `admin@demo.local` / `demo-admin` (admin) and `seller@demo.local` /
`demo-seller` (refused: not an admin). Demo data is fictional and nothing is sent.

## Seller outreach rules in the panel

- Sending is never automatic from the panel: one lead, one reviewed message, an
  explicit confirmation, then the `outreach-send` Edge Function.
- `lib/features/outreach/domain/anti_spam.dart` enforces the Section 21.8
  rulebook before the Send button is enabled; the Edge Function and the
  database (`outreach_can_send`, event triggers) enforce it again.
- `lib/features/outreach/domain/stage_machine.dart` only lets leads move
  forward (`sourced -> contacted -> replied -> onboarding -> live seller ->
  active`, plus `not interested` / `do not contact`); `do not contact` is
  permanent and adds the business to the shared suppression list.
- CSV import accepts compliant business sources only (OSM, Places API,
  registries, the business's own site, inbound, referral, field) and rejects
  scraped directories, bought lists and consumer records.
- India first contact is a manual `wa.me` message the admin sends personally.

## Brochures

`lib/features/brochures/application/brochure_pdf.dart` builds A4 brochures,
A5 one-pagers and 1080x1350 images (rasterised with `printing`) per city x
category x language, with a QR code to the UTM-tagged signup link and the
legal entity name. Logos come from `branding/` (`tool/sync_branding.sh`).

## Checks

```
dart run build_runner build   # after changing @riverpod / @freezed code
flutter gen-l10n
flutter analyze
flutter test
flutter build web --dart-define-from-file=config/usa.dev.json
```

Backend tables, RPCs and Edge Functions the panel depends on, and what is still
missing, are listed in [BACKEND_NEEDS.md](BACKEND_NEEDS.md).
