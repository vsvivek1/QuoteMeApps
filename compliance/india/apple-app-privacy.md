# Apple App Privacy (nutrition labels): I Want India

App Store Connect > App Privacy for bundle `com.calecute.iwant.india`. Source of truth: `legal/india/privacy-policy.md`. Must match `compliance/ios/PrivacyInfo.xcprivacy` (`NSPrivacyCollectedDataTypes`).

**Privacy policy URL:** `https://{{INDIA_WEB_DOMAIN}}/legal/privacy-policy`
**Do you or your third-party partners collect data from this app?** Yes
**Tracking:** No data is used to track users. No ATT prompt (no tracking). No IDFA (Firebase Analytics built without AdSupport: set `$FirebaseAnalyticsWithoutAdIdSupport = true` in the Podfile).

## Data Used to Track You

None.

## Data Linked to You

| Apple category | Data type | Purposes | Linked to user | Used for tracking |
|---|---|---|---|---|
| Contact Info | Name | App Functionality | Yes | No |
| Contact Info | Email Address | App Functionality, Developer's Advertising or Marketing (opted-in emails only) | Yes | No |
| Contact Info | Phone Number | App Functionality, Developer's Advertising or Marketing (opted-in messages only) | Yes | No |
| Contact Info | Physical Address | App Functionality | Yes | No |
| Location | Precise Location | App Functionality | Yes | No |
| Location | Coarse Location | App Functionality, Analytics | Yes | No |
| User Content | Emails or Text Messages (in-app chat) | App Functionality | Yes | No |
| User Content | Photos or Videos | App Functionality | Yes | No |
| User Content | Customer Support | App Functionality | Yes | No |
| User Content | Other User Content (requests, quotes, reviews, business profile) | App Functionality | Yes | No |
| Identifiers | User ID | App Functionality, Analytics | Yes | No |
| Identifiers | Device ID (push token, Firebase installation ID) | App Functionality, Analytics | Yes | No |
| Purchases | Purchase History | App Functionality | Yes | No |
| Usage Data | Product Interaction | Analytics, App Functionality | Yes | No |
| Diagnostics | Crash Data | App Functionality, Analytics | Yes | No |
| Diagnostics | Performance Data | App Functionality, Analytics | Yes | No |
| Diagnostics | Other Diagnostic Data | App Functionality, Analytics | Yes | No |
| Other Data | Other Data Types (seller verification documents, business tax IDs, licence numbers) | App Functionality | Yes | No |

"App Functionality" includes authentication, fraud prevention and security, as Apple defines it.

## Not collected

Health and Fitness, Financial Info (payment info, credit info, other financial info), Sensitive Info, Contacts, Audio Data (voice input is transcribed by Apple's speech recognizer; the app receives text only), Gameplay Content, Browsing History, Search History, Advertising Data, Other Usage Data.

## Third-party SDKs to re-check each release

Supabase (`supabase_flutter`), Firebase (Messaging, Crashlytics, Analytics, Remote Config, App Check), Google Maps SDK for iOS and Places, Google Sign-In, `sign_in_with_apple`, `in_app_purchase` (StoreKit). Each ships its own privacy manifest; Xcode > Product > Archive > Generate Privacy Report must show nothing beyond the table above.
