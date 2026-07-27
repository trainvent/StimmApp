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

After enabling Google, download the updated `GoogleService-Info.plist` for each
iOS app. Copy its `CLIENT_ID` into `GIDClientID` and add its
`REVERSED_CLIENT_ID` as a URL scheme in `ios/Runner/Info.plist`. Flavor-specific
values should be supplied through the existing Xcode build configurations.

If the iOS app is distributed through the App Store, review Apple's login
service requirements. Offering Google Sign-In can also require an equivalent
Sign in with Apple option.

## Web

Add every deployed site origin to the Firebase Authentication authorized
domains for the matching project. The app uses Firebase's Google popup flow, so
it does not require the `google_sign_in_web` meta tag.

## Address import

Basic Google sign-in supplies identity data such as email, name, and profile
photo. Address import is intentionally not requested during authentication. It
requires enabling the Google People API and a separate, explicit
`user.addresses.read` consent flow. The profile form should remain usable when
Google returns no address.
