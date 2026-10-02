# Google Play Data safety: I Want India

Package `com.calecute.iwant.india` · Source of truth: `legal/india/privacy-policy.md` Section 2. Includes data collected by the Supabase, Firebase (Cloud Messaging, Crashlytics, Analytics, Remote Config, App Check / Play Integrity) and Google Maps SDKs.

## Overview questions

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS/TLS to Supabase, Firebase, Google Maps) |
| Which account creation methods does your app support? | **OAuth** (Google, Sign in with Apple) and **Other**: phone number verified with a one-time SMS code (MSG91 (DLT-registered entity and templates)) |
| Delete account URL | `https://{{INDIA_WEB_DOMAIN}}/legal/account-deletion` |
| Can users request that some or all of their data be deleted without deleting their account? | **Yes** (delete individual requests, photos, reviews, saved addresses in the app; or email the privacy address) |
| Has your app undergone an independent security review (MASA)? | **No** |
| Is your app committed to the Play Families Policy? | **No** (not designed for children; target audience 18+) |

## Data sharing

**No data type is "shared".** Transfers to service providers that process data on our behalf (Supabase, Google Firebase, Google Maps Platform, Google Cloud Vision, MSG91 (DLT-registered entity and templates), Google Play Billing, Razorpay (web seller dashboard only), Vercel, email provider) are exempt as service-provider transfers. Disclosure of a buyer's phone number and exact address to the seller they accept, and of request details to matching sellers, are user-initiated actions the user expects, which Play also exempts. Answer **"No"** to "shared" for every row below. No data is sold and none is used for advertising.

## Data types collected

"Ephemeral" is **No** for every row (all collected data is stored). Analytics is off until the user consents, which Play treats as optional collection.

| Category | Data type | Collected | Required or optional | Purposes |
|---|---|---|---|---|
| Location | Approximate location | Yes | Required | App functionality, Analytics |
| Location | Precise location | Yes | Optional | App functionality |
| Personal info | Name | Yes | Required | App functionality, Account management |
| Personal info | Email address | Yes | Optional | Account management, Developer communications, Advertising or marketing (opted-in emails only) |
| Personal info | User IDs | Yes | Required | App functionality, Analytics, Fraud prevention, security and compliance, Account management |
| Personal info | Address | Yes | Required | App functionality, Fraud prevention, security and compliance |
| Personal info | Phone number | Yes | Required | App functionality, Account management, Fraud prevention, security and compliance, Developer communications, Advertising or marketing (opted-in messages only) |
| Personal info | Race and ethnicity, Political or religious beliefs, Sexual orientation, Other info | No | | |
| Financial info | Purchase history | Yes | Optional (sellers who buy plans or credits) | App functionality, Account management |
| Financial info | User payment info, Credit score, Other financial info | No | | |
| Health and fitness | Health info, Fitness info | No | | |
| Messages | Emails | No | | |
| Messages | SMS or MMS | No | | |
| Messages | Other in-app messages | Yes | Optional | App functionality, Fraud prevention, security and compliance |
| Photos and videos | Photos | Yes | Optional | App functionality, Fraud prevention, security and compliance |
| Photos and videos | Videos | Yes | Optional | App functionality, Fraud prevention, security and compliance |
| Audio | Voice or sound recordings, Music files, Other audio files | No | | (voice input is transcribed by the device's speech service; the app receives text only) |
| Files and docs | Files and docs | Yes | Optional (sellers who verify) | App functionality, Fraud prevention, security and compliance |
| Calendar | Calendar events | No | | |
| Contacts | Contacts | No | | |
| App activity | App interactions | Yes | Required (Google Maps SDK usage data; Firebase Analytics events themselves are off until the user opts in on the DPDP consent screen or in Settings > Privacy > Analytics) | Analytics, App functionality |
| App activity | In-app search history | No | | |
| App activity | Installed apps | No | | |
| App activity | Other user-generated content | Yes | Required | App functionality, Fraud prevention, security and compliance |
| App activity | Other actions | No | | |
| Web browsing | Web browsing history | No | | |
| App info and performance | Crash logs | Yes | Required | App functionality, Analytics |
| App info and performance | Diagnostics | Yes | Required | App functionality, Analytics |
| App info and performance | Other app performance data | No | | |
| Device or other IDs | Device or other IDs | Yes | Required | App functionality, Analytics, Fraud prevention, security and compliance |

## Mapping to the privacy policy

| Privacy policy row | Data safety row |
|---|---|
| Name | Personal info > Name |
| Email address | Personal info > Email address |
| Phone number | Personal info > Phone number |
| Address | Personal info > Address |
| Precise location | Location > Precise location |
| Approximate location | Location > Approximate location |
| User ID | Personal info > User IDs |
| Device or other IDs | Device or other IDs |
| Messages (chat and in-app support) | Messages > Other in-app messages |
| Photos and videos | Photos and videos > Photos, Videos |
| Files and documents | Files and docs |
| Other user content (requests, quotes, reviews, business IDs, licence numbers) | App activity > Other user-generated content |
| Purchase history | Financial info > Purchase history |
| App interactions | App activity > App interactions |
| Crash logs | App info and performance > Crash logs |
| Diagnostics | App info and performance > Diagnostics |

## Build requirements that keep these answers true

- [ ] Remove the advertising ID permission merged by Firebase: `<uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove"/>` and `<meta-data android:name="google_analytics_adid_collection_enabled" android:value="false"/>`
- [ ] Firebase Analytics: off until the user opts in on the DPDP consent screen or in Settings > Privacy > Analytics
- [ ] Photo picker (`ACTION_PICK_IMAGES` / `image_picker` with photo picker) instead of `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`
- [ ] No contacts, SMS, call log or background location permissions in the merged manifest
- [ ] No payment card fields in the app (web checkout and store billing only)
