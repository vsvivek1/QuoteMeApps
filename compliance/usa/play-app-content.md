# Google Play App content declarations: I Want USA

Package `com.calecute.iwant.usa` · Developer: Calecute Technologies LLC

| Declaration | Answer | Notes |
|---|---|---|
| Privacy policy | `https://{{USA_WEB_DOMAIN}}/legal/privacy-policy` | Must be public, non-PDF, and match `play-data-safety.md` |
| App access | **All or some functionality is restricted** | Enter the instructions in `review-demo-access.md` (buyer and seller demo logins) |
| Ads | **No, my app does not contain ads** | No ad SDKs. Sponsored seller placement is first-party, labelled "Sponsored", and not an ad network; it is disclosed in the Seller Terms |
| Advertising ID | **No**, the app does not use advertising ID | Remove the `AD_ID` permission merged by Firebase (see `play-data-safety.md`) |
| Content rating | See `play-content-rating.md` | |
| Target audience and content | **18 and over** only | Store listing has no child-directed imagery; app not designed for children; "Appeals to children" = **No** |
| News app | **No** | |
| COVID-19 contact tracing and status apps | **No** | |
| Data safety | See `play-data-safety.md` | |
| Government apps | **No**: the app is not developed by or on behalf of a government | |
| Financial features | **My app doesn't provide any financial features** | Loans, credit, investments, crypto and insurance are blocked categories; seller plans are ordinary subscriptions. If insurance is ever enabled for licensed sellers, re-answer this declaration first |
| Health apps | **My app does not have any health features** | Medical providers can only quote for appointments/services; no health data is collected |
| Account deletion | In-app path **Settings > Delete account** and web URL `https://{{USA_WEB_DOMAIN}}/legal/account-deletion` | |
| Photo and video permissions | Not applicable: the app uses the Android photo picker and does not request `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` | |
| Foreground service permissions | Not applicable (none declared) | |
| Full-screen intent, exact alarms | Not applicable (none declared) | |
| Store settings | Category: **Shopping** · Tags: Shopping, Local services, Home services | Contact email = support email; website = `https://{{USA_WEB_DOMAIN}}` |
| Countries / regions | United States only | Production and testing tracks |
| Store listing languages | en-US (default), es-US | Managed by `fastlane android metadata country:usa` |
