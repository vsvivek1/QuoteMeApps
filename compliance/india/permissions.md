# Permissions and justifications: I Want India

Request only what is needed, at the moment it is needed, after an in-app rationale screen (brief Sections 12.1 and 17). Check the **merged** manifest (`build/app/intermediates/merged_manifests/`) each release: plugins can add permissions.

## Android (`android/app/src/main/AndroidManifest.xml`)

| Permission | Type | When requested | Justification (also used for the rationale screen) |
|---|---|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | Normal | Install time | Talk to Supabase, Firebase and Google Maps; show offline state and retry the outbox |
| `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` | Runtime, **while in use only** | When the user taps "Use my location" on the request or seller service-area screen | Drop the request pin at the user's location and show distance to sellers. Optional: the user can type a postal code instead. No background location |
| `CAMERA` | Runtime | When the user taps "Take photo" | Photograph the item or problem for a request, a shop photo or a verification document. Optional |
| `RECORD_AUDIO` | Runtime | When the user taps the microphone on "What do you need?" | Voice input converted to text by the device speech service. Optional; audio is not stored or uploaded |
| `POST_NOTIFICATIONS` (Android 13+) | Runtime | After the first request is posted or seller onboarding finishes, not on first launch | New quotes, messages and order updates. Optional |
| `com.android.vending.BILLING` | Normal | Install time (added by `in_app_purchase`) | Seller plans and quote credits via Google Play Billing |
| `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED`, `com.google.android.c2dm.permission.RECEIVE` | Normal | Install time (added by Firebase Messaging) | Deliver push notifications |
| `com.google.android.gms.permission.AD_ID` | **Removed** with `tools:node="remove"` | Never | No ads, no advertising ID |
| Photo picker (no permission) | | When the user taps "Add photos" | Android photo picker (`ACTION_PICK_IMAGES`, backported via Play services). **Do not** declare `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` or `READ_EXTERNAL_STORAGE` |

Not used and must not appear: `ACCESS_BACKGROUND_LOCATION`, `READ_CONTACTS`, `READ_SMS`, `RECEIVE_SMS` (OTP autofill uses the SMS Retriever / User Consent API, which needs no permission), `READ_PHONE_STATE`, `READ_CALL_LOG`, `SYSTEM_ALERT_WINDOW`, `QUERY_ALL_PACKAGES`, `SCHEDULE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, foreground service types.

## iOS (`ios/Runner/Info.plist`, localized in `InfoPlist.strings` for each app language)

| Key | Purpose string (English) | Requested when |
|---|---|---|
| `NSLocationWhenInUseUsageDescription` | "I Want India uses your location to place your request on the map and show how far sellers are. You can type a postal code instead." | User taps "Use my location" |
| `NSCameraUsageDescription` | "I Want India uses the camera so you can add photos of what you need, your shop or your documents." | User taps "Take photo" |
| `NSPhotoLibraryUsageDescription` | "I Want India lets you choose photos to add to your request, profile or review." | Only if a plugin needs full library access; prefer `PHPickerViewController`, which needs no permission |
| `NSMicrophoneUsageDescription` | "I Want India uses the microphone when you tap the mic to describe what you need by voice." | User taps the mic |
| `NSSpeechRecognitionUsageDescription` | "I Want India converts your voice to text so you can post a request faster. Audio is not stored by I Want India." | User taps the mic |
| `ITSAppUsesNonExemptEncryption` | `false` | n/a (see `export-compliance.md`) |
| `UIBackgroundModes` | `remote-notification` only | Push delivery |

Not used: `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSContactsUsageDescription`, `NSUserTrackingUsageDescription` (no ATT prompt, no tracking), `NSBluetooth*`, `NSHealth*`. Push permission is requested with `UNUserNotificationCenter` after the first success moment, not at launch.
