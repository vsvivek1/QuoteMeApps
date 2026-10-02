# User-generated content requirements: I Want USA

Apps with chat, posts, photos and reviews must meet **Apple App Review Guideline 1.2** and the **Google Play User Generated Content policy**. Map each requirement to the build (brief Sections 2.6 and 9) and tick it off on the prod build.

| Requirement | Apple 1.2 | Google Play UGC | How I Want USA meets it | Verified |
|---|---|---|---|---|
| Users accept terms that define objectionable content and make clear there is no tolerance for it | Yes | Yes | First-launch consent screen: accept Terms and Privacy Policy (version recorded in `consents`); Community Guidelines linked | [ ] |
| Method for filtering objectionable material before it is posted | Yes | Yes (robust moderation) | Keyword/text classifier on requests and chat; blocked-category classifier; Cloud Vision SafeSearch on uploaded images; phone/email soft-warning in chat before acceptance | [ ] |
| In-app mechanism to report offensive content and users | Yes | Yes | **Report** on every chat, message, request, quote, review and profile | [ ] |
| Timely response to reports | Yes (act within 24 hours) | Yes | Reports queue in the admin panel; target first action within 24 hours; auto-hide after N reports pending review | [ ] |
| Ability to block abusive users | Yes | Yes | **Block** on chat and profile; blocked users cannot message, quote or see the blocker's requests | [ ] |
| Remove content and eject users who violate the terms | Yes | Yes | Admin: remove content, suspend, ban, remove Verified badge | [ ] |
| Published contact information | Yes | Yes | `https://{{USA_WEB_DOMAIN}}/legal/contact-support` linked in Settings and both store listings | [ ] |
| Content involving minors | | Yes (CSAE policy) | Zero tolerance in Community Guidelines; immediate removal and reporting to authorities; published child safety standards contact (Play "Child safety standards" declaration, if required for the app category) | [ ] |
| Reviews integrity | | | Reviews only from completed orders; seller may reply once | [ ] |
| Emergency guidance | | | Report flow shows "If someone is in immediate danger, call 911" | [ ] |

App Review notes (in `fastlane/metadata/ios/usa/review_information/notes.txt`) tell the reviewer where Report and Block are, so they can find them quickly.
