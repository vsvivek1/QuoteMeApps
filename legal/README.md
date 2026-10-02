# Legal pack: I Want USA and I Want India

> **WARNING: THESE ARE TEMPLATES. THEY MUST BE REVIEWED AND APPROVED BY A QUALIFIED LAWYER IN EACH COUNTRY (A US LAWYER FOR I WANT USA, AN INDIAN LAWYER FOR I WANT INDIA) BEFORE LAUNCH. DO NOT PUBLISH THEM, LINK THEM FROM A STORE LISTING OR SHOW THEM IN A PRODUCTION BUILD UNTIL THAT REVIEW IS DONE AND EVERY `{{PLACEHOLDER}}` IS FILLED IN.**

Each app has its own, stand-alone legal pack written for its own country's law:

| App | Legal entity | Payments | Data host |
|---|---|---|---|
| I Want USA (`legal/usa/`) | Calecute Technologies LLC | Stripe (payouts to Mercury), Google Play Billing, StoreKit | Supabase, AWS us-east-1 |
| I Want India (`legal/india/`) | Calecute Technologies (OPC) Private Limited | Razorpay, Google Play Billing, StoreKit | Supabase, AWS ap-south-1 (Mumbai) |

## Pages (brief Section 17)

| # | Page | Slug | USA | India |
|---|---|---|---|---|
| 1 | Privacy Policy | `privacy-policy` | ✓ | ✓ |
| 2 | Terms of Service / Terms of Use | `terms-of-service` | ✓ | ✓ |
| 3 | Seller Terms | `seller-terms` | ✓ | ✓ |
| 4 | Community Guidelines and Prohibited / Restricted Items (table generated from `category_policy.json`) | `community-guidelines` | ✓ | ✓ |
| 5 | Refund and Cancellation Policy | `refund-cancellation` | ✓ | ✓ |
| 6 | Subscription Terms | `subscription-terms` | ✓ | ✓ |
| 7 | Account Deletion (public URL for Google Play) | `account-deletion` | ✓ | ✓ |
| 8 | Cookie Policy | `cookie-policy` | ✓ | ✓ |
| 9 | Grievance Officer (IT Rules 2021) | `grievance-officer` | | ✓ |
| 9 | DPDP Act 2023 consent notice | `dpdp-consent-notice` | | ✓ |
| 10 | California privacy rights incl. "Do Not Sell or Share" | `ccpa-notice` | ✓ | |
| 10 | COPPA statement | `coppa` | ✓ | |
| 11 | Contact and Support | `contact-support` | ✓ | ✓ |
| 12 | Open-source licences | Flutter `showLicensePage()` in the app, no Markdown page | | |
| 13 | EULA (Apple Standard EULA note) | `eula` | ✓ | ✓ |

Every page has YAML front matter (`title`, `slug`, `version`, `last_updated`). Bump `version` and `last_updated` whenever wording changes; the app records the accepted Terms and Privacy versions in the `consents` table and asks users to accept again when they change.

## Placeholders

`legal/config.json` holds one block per country. Real values are already filled in for facts we know (company names, data regions, payment providers, free-quote defaults). Values that are still `{{PLACEHOLDER}}` must be filled in before launch:

| Placeholder | Country | What to put |
|---|---|---|
| `ADDRESS` | both | Registered office / registered address |
| `US_BUSINESS_ADDRESS` | USA | Mailing / business address shown to users |
| `STATE_OF_FORMATION`, `GOVERNING_STATE`, `ARBITRATION_COUNTY` | USA | LLC's state and dispute venue (lawyer to confirm) |
| `CIN`, `COMPANY_GSTIN`, `JURISDICTION_CITY` | India | Company identification number, GSTIN, court city |
| `SUPPORT_EMAIL`, `PRIVACY_EMAIL`, `SUPPORT_PHONE` | both | Support and privacy contacts |
| `GRIEVANCE_OFFICER` (+ `_DESIGNATION`, `GRIEVANCE_EMAIL`, `GRIEVANCE_PHONE` in India) | both | India: Grievance Officer required by IT Rules 2021 (must be resident in India). USA: privacy complaints contact |
| `EARLY_PARTNER_FREE_UNTIL` | both | Founding-partner free-until date (default 6 months after `monetization_enabled` flips) |
| `USA_WEB_DOMAIN`, `INDIA_WEB_DOMAIN`, `*_SELLER_DASHBOARD_DOMAIN` | each | Country website and seller dashboard domains |

## Building

```bash
python3 legal/build.py            # renders both countries, warns about pending placeholders
python3 legal/build.py --strict   # use in release CI: fails while any placeholder is pending
python3 legal/build.py --check    # validate only
```

Outputs (generated, do not edit by hand):

- `assets/legal/<country>/legal.json`: array of `{slug, title, version, last_updated, markdown}` bundled in the app for Settings > Legal and the sign-up consent screen. Internal links are relative (`/legal/<slug>`); the in-app Markdown renderer should open them as in-app legal screens.
- `web/content/legal/<country>/<slug>.md`: Markdown with front matter (`title`, `canonical`, `order`, ...) for the Vercel website at `https://<country-domain>/legal/<slug>`.

## Keeping things consistent

- The privacy policy data table is the single source for the Play **Data safety** form and Apple **App Privacy** labels in `compliance/<country>/` and `compliance/ios/PrivacyInfo.xcprivacy`. Change all of them together.
- `legal/<country>/category_policy.json` mirrors the default `category_policy` (brief Section 3.1). If the admin panel changes a category's state, update this file and rebuild so the published Community Guidelines stay accurate.
- Store listings (fastlane metadata) link to `/legal/privacy-policy`, `/legal/contact-support` and `/legal/account-deletion`.

## Points for the reviewing lawyer

- USA: arbitration clause, governing law and venue; state privacy law coverage beyond California; TCPA language in Seller Terms; insurance producer and attorney advertising disclaimers; contractor licence wording.
- India: intermediary and marketplace e-commerce entity positioning, grievance timelines, DPDP Rules 2025 timelines (rights requests, breach notice, inactive-account erasure), IRDAI wording if insurance is ever enabled, refund timelines required by Razorpay.
- Both: minimum age (set to 18 in both apps), retention periods, liability caps.
