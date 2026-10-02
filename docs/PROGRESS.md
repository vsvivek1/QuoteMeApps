# Progress

Milestone summaries (brief Sections 15 and 22). Each entry says what builds and passes.

## 2026-10-02

- **Milestone 0, scaffolding**: repo, `.gitignore`, `branding/` with generated placeholder icons and splash per flavor, fastlane for Android and iOS with per-country metadata, GitHub Actions (CI, Supabase deploy, nightly store builds).
- **Milestone 1, foundation**: six flavors (USA and India x dev, staging, prod) on Android and iOS, `CountryConfig`, theme, l10n in English, Hindi and Spanish, routing with deep links, phone OTP / Google / Apple sign-in screens, consent, profile, buyer/seller mode switch, account deletion screen.
- **Milestones 2 to 5 on the demo backend**: post-request wizard, my requests, request detail, seller onboarding, lead feed, quote form with GST and US sales tax, compare and accept, counter-offer, orders, chat, notifications inbox, reviews, report and block, seller plan screen with billing abstraction.
- **Milestone 8, legal**: legal pages for both countries in `legal/`, in-app legal screens, store compliance drafts in `compliance/`.
- Tests: 34 unit and widget tests pass (money and tax, validators, marketplace flow, post-request wizard, quote form for both countries); `flutter analyze` clean.
