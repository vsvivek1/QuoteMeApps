# I Want India: store compliance checklist

App: **I Want India** · Developer / seller name: **Calecute Technologies (OPC) Private Limited** · Android package and iOS bundle ID: `com.calecute.iwant.india`
Availability: India only (Play: Countries/regions = India; App Store: Availability = India)
Store locales: Play en-IN (default), hi-IN; App Store en-GB (primary; confirm which English locale App Store Connect offers for India), hi

Every answer in this folder is derived from the data table in `legal/india/privacy-policy.md`. If the app starts collecting anything new (a new SDK, a new field), update the privacy policy, `play-data-safety.md`, `apple-app-privacy.md` and `compliance/ios/PrivacyInfo.xcprivacy` **in the same change**.

> Templates: confirm every answer against the current Play Console and App Store Connect forms before submitting, and have the legal pack reviewed by a lawyer (see `legal/README.md`).

## Files

| File | Store form |
|---|---|
| [play-data-safety.md](play-data-safety.md) | Play Console > App content > Data safety |
| [play-app-content.md](play-app-content.md) | Play Console > App content: target audience, ads, government apps, financial features, health, news, account deletion, advertising ID |
| [play-content-rating.md](play-content-rating.md) | Play Console > App content > Content rating (IARC questionnaire) |
| [apple-app-privacy.md](apple-app-privacy.md) | App Store Connect > App Privacy (nutrition labels) |
| [apple-age-rating.md](apple-age-rating.md) | App Store Connect > App Information > Age Rating |
| [export-compliance.md](export-compliance.md) | App Store Connect export compliance, `ITSAppUsesNonExemptEncryption` |
| [ugc-requirements.md](ugc-requirements.md) | Apple Guideline 1.2 and Play User Generated Content policy |
| [review-demo-access.md](review-demo-access.md) | Play App access and App Review Information (demo login) |
| [permissions.md](permissions.md) | Android permissions and iOS purpose strings, with justifications |

## Pre-submission checklist

- [ ] Legal pages reviewed by a lawyer, placeholders filled, `python3 legal/build.py --strict` passes
- [ ] Public URLs live: `https://{{INDIA_WEB_DOMAIN}}/legal/privacy-policy`, `/legal/terms-of-service`, `/legal/account-deletion`, `/legal/contact-support`, `/legal/dpdp-consent-notice`, `/legal/grievance-officer`
- [ ] Play: Privacy policy URL = `https://{{INDIA_WEB_DOMAIN}}/legal/privacy-policy`
- [ ] Play: Data safety form completed exactly as `play-data-safety.md`
- [ ] Play: Account deletion URL = `https://{{INDIA_WEB_DOMAIN}}/legal/account-deletion`
- [ ] Play: Target audience 18+, Ads = No, Advertising ID = No, Government = No, Financial features = None, Health = None
- [ ] Play: Content rating questionnaire submitted as `play-content-rating.md`
- [ ] Play: App access instructions entered (`review-demo-access.md`), demo accounts tested on the **prod** build
- [ ] Play: Organization developer account for Calecute Technologies (OPC) Private Limited with D-U-N-S number; developer name, email, address and phone match the legal pages
- [ ] Play: Countries/regions limited to India
- [ ] App Store: App Privacy answers entered as `apple-app-privacy.md`; privacy policy URL set
- [ ] App Store: Age rating questionnaire answered as `apple-age-rating.md`
- [ ] App Store: `ITSAppUsesNonExemptEncryption = false` in `Info.plist` (no export compliance prompt per build)
- [ ] App Store: `PrivacyInfo.xcprivacy` (from `compliance/ios/`) added to the Runner target; Xcode privacy report shows no missing reasons
- [ ] App Store: Sign in with Apple offered (Google sign-in is offered), in-app account deletion works and revokes the Apple token
- [ ] App Store: License Agreement = Apple Standard EULA; paywall links Terms, Privacy, EULA and has Restore Purchases
- [ ] App Store: Review information (demo login, notes) filled from env by `fastlane ios release` / `metadata`
- [ ] App Store: Availability limited to India
- [ ] Both: UGC controls (report, block, filtering, contact) verified as `ugc-requirements.md`
- [ ] Both: permissions match `permissions.md`; no extra permissions merged from plugins (check the merged manifest)
- [ ] DPDP consent notice shown before sign-up (`/legal/dpdp-consent-notice`), consents recorded with version in `consents`
- [ ] Grievance Officer page live (`/legal/grievance-officer`) and linked from Settings > Help and the Play listing
- [ ] Analytics collection disabled until consent (`setAnalyticsCollectionEnabled(false)` at start-up)
- [ ] MSG91 DLT entity and OTP template approved before launch
