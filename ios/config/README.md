Put each flavor's Firebase file at `ios/config/<flavor>/GoogleService-Info.plist`
(for example `ios/config/usaProd/GoogleService-Info.plist`). These files are gitignored;
the "Copy GoogleService-Info.plist for flavor" build phase copies the right one into the app.
Flavors and schemes are created by `ruby tool/ios/setup_flavors.rb`.
