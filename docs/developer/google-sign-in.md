# Google Sign-In setup

The Flutter implementation is shared by the `dev` and `prod` flavors, but
Google authentication must be configured separately in both Firebase projects:

- `dev` → `stimmapp-dev` (`de.lemarq.stimmapp.dev`)
- `prod` → `stimmapp-f0141` (`de.lemarq.stimmapp`)

## Firebase

1. In **Authentication → Sign-in method**, enable **Google**.
2. In **Project settings → Your apps**, add the SHA-1 and SHA-256 fingerprints
   for every Android signing configuration used by that flavor.
3. Download the updated `google-services.json`. It must contain:
   - an Android OAuth client for the correct package and signing certificate;
   - a web OAuth client with `"client_type": 3`.
4. Replace:
   - `android/app/src/dev/google-services.json`
   - `android/app/src/prod/google-services.json`

Use `cd android && ./gradlew signingReport` to print Android fingerprints.

## iOS

Google client values are configured per flavor in:

- `ios/Flutter/Debug-dev.xcconfig`
- `ios/Flutter/Debug-prod.xcconfig`
- `ios/Flutter/Profile-prod.xcconfig`
- `ios/Flutter/Release-prod.xcconfig`

`ios/Runner/Info.plist` reads those values through `GOOGLE_CLIENT_ID` and
`GOOGLE_REVERSED_CLIENT_ID`. When an OAuth client changes, download a new
`GoogleService-Info.plist` and update those two settings from its `CLIENT_ID`
and `REVERSED_CLIENT_ID`. The downloaded Firebase plist itself is not committed
because Firebase is initialized from the flavor-specific Dart options.

If the iOS app is distributed through the App Store, review Apple's login
service requirements. Offering Google Sign-In can also require an equivalent
Sign in with Apple option.

## Web

Add every deployed site origin to the Firebase Authentication authorized
domains for the matching project. The app uses Firebase's Google popup flow, so
it does not require the `google_sign_in_web` meta tag.

For the current deployments, verify these domains in **Authentication →
Settings → Authorized domains**:

- `stimmapp-dev` → `stimmapp-dev.web.app`
- `stimmapp-f0141` → `web.stimmapp.net`

## Sign in with Apple on web

The production web app exposes Apple sign-in and uses Firebase's Apple popup
flow. In addition to enabling Apple in **Firebase Authentication → Sign-in
method**, configure Apple's web authorization for the production Firebase
project:

1. Create a **Services ID** in Apple Developer and associate it with the
   StimmApp primary App ID.
2. Add `stimmapp-f0141.firebaseapp.com` as a web domain.
3. Add
   `https://stimmapp-f0141.firebaseapp.com/__/auth/handler` as the return URL.
4. Create a Sign in with Apple private key and enter the Services ID, Team ID,
   Key ID, and private key in Firebase's Apple provider configuration.
5. Keep `web.stimmapp.net` in Firebase Authentication's authorized domains.

Apple sign-in remains hidden for dev and non-StimmApp flavors because their
Apple Services IDs are not configured.

## Birthday and address import

Basic Google sign-in supplies identity data such as email, name, and profile
photo. Birthday and address import is intentionally not requested during
authentication.

For both `stimmapp-dev` and `stimmapp-f0141`:

1. Enable the **Google People API** in Google Cloud Console.
2. Configure the OAuth consent screen for these scopes:
   - `https://www.googleapis.com/auth/userinfo.profile`
   - `https://www.googleapis.com/auth/user.birthday.read`
   - `https://www.googleapis.com/auth/user.addresses.read`
3. Add developer accounts as test users while the consent screen is in testing.

The optional import action requests consent interactively and calls
`people/me?personFields=names,locations,birthdays`. Google may return incomplete
names, multiple locations, or a birthday without a year. The app prefers the
current location, ignores incomplete birthdays, and resolves imported location
text through TomTom before profile submission.

When periodic synchronization is enabled, Google-managed profile fields are
locked in StimmApp. A silent synchronization runs when the app starts or
resumes, at most once every six hours. The settings page also provides a
user-triggered synchronization action that can request Google authorization.
