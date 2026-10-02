# Export compliance: I Want India

| Item | Value |
|---|---|
| `Info.plist` key | `ITSAppUsesNonExemptEncryption` = **`false`** (Boolean NO) in `ios/Runner/Info.plist` for every flavor |
| Why | The app uses encryption only through the operating system and standard protocols: HTTPS/TLS (URLSession, Supabase, Firebase, Google Maps), Keychain storage of session tokens, and Sign in with Apple nonce hashing (SHA-256). This is exempt encryption, so no ERN / CCATS or annual self-classification report is needed |
| App Store Connect question "Does your app use encryption?" | Not asked per build once the key is present. If asked manually: **Yes**, then **"Only uses or accesses encryption within Apple's operating system"** / standard encryption exempt under Category 5 Part 2 |
| France encryption declaration | Not applicable (app is available only in India) |
| fastlane | `deliver` submission sets `export_compliance_uses_encryption: false` (see `ios/fastlane/Fastfile`) |
| Re-evaluate if | You add a proprietary or non-standard crypto library, end-to-end encrypted chat, or an encrypted local database (e.g. SQLCipher). Then re-check exemptions with counsel before setting the key |

Android: Google Play has no separate export declaration; the same reasoning applies (standard TLS only).
