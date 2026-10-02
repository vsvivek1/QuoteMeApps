# Progress

Milestone summaries (brief Sections 15 and 22). Each entry says what builds and passes.

## 2026-10-02

- **Milestone 0, scaffolding**: repo, `.gitignore`, `branding/` with generated placeholder icons and splash per flavor, fastlane for Android and iOS with per-country metadata, GitHub Actions (CI, Supabase deploy, nightly store builds).
- **Milestone 1, foundation**: six flavors (USA and India x dev, staging, prod) on Android and iOS, `CountryConfig`, theme, l10n in English, Hindi and Spanish, routing with deep links, phone OTP / Google / Apple sign-in screens, consent, profile, buyer/seller mode switch, account deletion screen.
- **Milestones 2 to 5 on the demo backend**: post-request wizard, my requests, request detail, seller onboarding, lead feed, quote form with GST and US sales tax, compare and accept, counter-offer, orders, chat, notifications inbox, reviews, report and block, seller plan screen with billing abstraction.
- **Milestone 8, legal**: legal pages for both countries in `legal/`, in-app legal screens, store compliance drafts in `compliance/`.
- Tests: 34 unit and widget tests pass (money and tax, validators, marketplace flow, post-request wizard, quote form for both countries); `flutter analyze` clean.

## 2026-10-02 (later)

- **Backend (Supabase)**: schema with PostGIS and RLS on every table, atomic RPCs, storage, realtime, cron, 16+ Edge Functions (matching, push, payments for Stripe, Play and App Store, outreach, web forms, SEO export, trends). 467 pgTAP tests per country and 123 Deno tests pass, locally and in CI.
- **App on Supabase**: every repository has a Supabase implementation with an offline cache and an outbox for chat; blocked-account screen; seller directory opt-in; exact US sales tax in parts per million (8.875 % NYC). 200 Flutter tests pass, plus a buyer-seller happy path integration test that runs in CI against the local Supabase stack for both countries.
- **Milestones 6 and 7**: admin panel (verification, moderation, categories, flags, audit log, KPIs, sellers with manual UPI/bank payments, outreach CRM with anti-spam checks, brochures, SEO pages and guide review, trends board); billing through Play Billing, StoreKit and Stripe (USA); India stays free until a gateway is approved.
- **Growth (Section 21)**: app websites with legal pages, deletion flow with OTP, deep-link fallbacks, gated SEO price pages, buying guides and seller directory; trends site with detection, gated Claude drafting and publishing (switched off until the owner turns it on).
- **CI**: green on `27431cd`: analyze, format, tests, both release AABs, admin build, website builds, pgTAP, Deno and the integration test.
- **Waiting on the owner**: accounts and keys in `docs/BLOCKERS.md`.
