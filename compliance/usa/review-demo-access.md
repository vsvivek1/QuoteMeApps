# Review demo access: I Want USA

Both stores need a working login for the **prod** app. Phone OTP cannot receive real SMS during review, so each prod Supabase project has **test phone numbers with fixed OTPs** (Supabase Dashboard > Authentication > Providers > Phone > Test phone numbers and OTPs). The app code never special-cases them (brief Section 20.2).

## Accounts to create in the prod project

| Account | Env var for phone | Env var for OTP | Seed data |
|---|---|---|---|
| Review buyer | `REVIEW_BUYER_PHONE_USA` | `REVIEW_BUYER_OTP_USA` | 2 open requests with 3 quotes each, 1 accepted order, chat history |
| Review seller (Verified) | `REVIEW_SELLER_PHONE_USA` | `REVIEW_SELLER_OTP_USA` | Verified business profile, lead feed with demo requests, sent quotes |

Both are flagged `is_review_account = true` so their requests and quotes are hidden from real users' feeds and real requests are not sent to them. Example format: `+1 555 010 0001` (use a number range reserved for testing and keep the real values only in CI secrets and the local, git-ignored `fastlane/.env`).

Reviewer contact: `REVIEW_CONTACT_FIRST_NAME_USA`, `REVIEW_CONTACT_LAST_NAME_USA`, `REVIEW_CONTACT_PHONE_USA`, `REVIEW_CONTACT_EMAIL_USA`.

## Apple App Review Information

Filled automatically by `bundle exec fastlane ios metadata country:usa` and `release` from `fastlane/metadata/ios/usa/review_information/*.txt`, with `{{...}}` values substituted from the env vars above at upload time (the repo never contains the real values).

- Sign-in required: **Yes**
- User name: buyer phone number; Password: buyer OTP
- Notes: seller login, steps, where Report/Block live (see `notes.txt`)

## Google Play App access

Play Console > App content > App access > **All or some functionality is restricted** > Add instructions (not uploaded by fastlane; paste manually, substituting the env values):

```
Name: Buyer demo account
Username / phone: {{REVIEW_BUYER_PHONE}}
Password / OTP: {{REVIEW_BUYER_OTP}}
Other information: Open the app, tap "Continue with phone", enter the phone number above and the one-time code above (no SMS is sent to this test number). You land on the buyer home with demo requests and quotes. Language: English.

Name: Seller demo account
Username / phone: {{REVIEW_SELLER_PHONE}}
Password / OTP: {{REVIEW_SELLER_OTP}}
Other information: Same steps. You land in seller mode with the lead feed. Use Profile > Switch to buyer/seller to change modes. Report and Block are in the menu of every chat, request, quote and profile.
```

- [ ] Both accounts tested on the prod build from the store track before each submission
- [ ] OTPs not rotated without updating CI secrets and the Play App access entry
