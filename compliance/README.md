# Store compliance: I Want USA and I Want India

One set of store declarations per app (brief Section 17, "Compliance work"):

| Folder | App | Entity | Package / bundle ID |
|---|---|---|---|
| [`usa/`](usa/README.md) | I Want USA | Calecute Technologies LLC | `com.calecute.iwant.usa` |
| [`india/`](india/README.md) | I Want India | Calecute Technologies (OPC) Private Limited | `com.calecute.iwant.india` |
| [`ios/PrivacyInfo.xcprivacy`](ios/PrivacyInfo.xcprivacy) | both | | iOS privacy manifest template (copy to `ios/Runner/`) |

Each country folder has: Play Data safety, Play app content declarations (target audience, ads, advertising ID, government, financial features, health, account deletion), IARC content rating answers, Apple App Privacy labels, Apple age rating, export compliance, UGC requirements, review demo access, and the permissions justification list, plus a pre-submission checklist in its `README.md`.

## Rules

- **One source of truth.** The data table in `legal/<country>/privacy-policy.md` drives the Play Data safety form, the Apple App Privacy labels and `PrivacyInfo.xcprivacy`. A change to any of them is a change to all of them.
- **Templates.** Store forms change. Verify each answer in the current Play Console and App Store Connect before submitting, and have counsel review the legal pack first (`legal/README.md`).
- **No secrets here.** Demo login values live only in CI secrets and the git-ignored `fastlane/.env` files; these documents name the environment variables.

## Defaults chosen (record in `docs/DECISIONS.md`)

- Minimum age **18** in both apps (sign-up age confirmation). Covers "no under-13s" (COPPA, USA) and "no under-18s without parental consent" (DPDP, India) without building a parental-consent flow. Play target audience: 18+.
- **No ads, no advertising ID, no tracking, no ATT prompt** in either app.
- Analytics: **opt-in (off by default) in India** (DPDP consent), **on by default with an opt-out in the USA**.
- Payment card data never enters the apps: store billing in-app, Stripe (USA) / Razorpay (India) only on the web seller dashboard.
- `ITSAppUsesNonExemptEncryption = false` (standard OS/TLS encryption only).
