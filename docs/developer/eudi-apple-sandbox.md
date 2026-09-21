# Apple EUDI sandbox testing

Use the StimmApp **dev** flavor and the German EUDI sandbox wallet on an
iPhone. The existing SD-JWT VC verifier is shared with Android; Apple does not
need a separate verifier, mDoc integration, or Apple Wallet entitlement.

## Prepare the iPhone

1. Obtain German sandbox wallet access for your Apple account through the
   existing sandbox onboarding contact. Install the wallet using its TestFlight
   invitation and enable automatic updates. Android tester access alone does
   not establish iOS access.
2. In the wallet, enable **Use simulated eID card** and complete PID issuance.
   Use only sandbox test data. Record the wallet version used for testing.
3. Connect the iPhone to the Mac, trust the Mac, and enable Developer Mode.
   Check that `flutter devices` lists it as available.
4. Open `ios/Runner.xcworkspace` if signing needs attention. Select the `dev`
   scheme, your iPhone, and the project's development team. The dev bundle ID
   is `de.lemarq.stimmapp.dev`.

Official references: [sandbox access](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/sandbox/onboarding/)
and [wallet operation](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/sandbox/onboarding/wallet_use_instructions/).

## Build and run

From the repository root:

```sh
flutter pub get
cd ios
pod install
cd ..
flutter devices
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env -d <iphone-device-id>
```

VS Code also provides **Flutter: StimmApp Dev (Debug iOS)** and
**Flutter: StimmApp Dev (Profile iOS / EUDI)**. Select the physical iPhone as the
Flutter device before launching. For testing suspension and return in profile
mode, use:

```sh
flutter run --profile --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env -d <iphone-device-id>
```

Detach with `d` in the terminal after installation to leave the app running
without the Flutter tool attached.

All three dev configurations (`Debug-dev`, `Profile-dev`, `Release-dev`) use
the dev entrypoint, bundle ID, URL hosts, and Google sign-in configuration.
The app connects to Firebase project `stimmapp-dev` and its public
`https://stimmapp-dev.web.app/oid4vp` verifier proxy.

The wallet opens through `openid4vp://`. The verifier's native result page
returns through `stimmapp://pid-verification`; use its return button if Safari
does not follow the automatic redirect. Dev and production currently register
the same callback scheme, so keep only the dev StimmApp installed on the test
iPhone to avoid ambiguous callback routing.

## Device acceptance test

1. Sign in with a dev account and open PID verification from the profile.
2. Start verification and confirm that the German sandbox wallet opens.
3. Approve the PID presentation in the wallet, return to StimmApp, and verify
   that the result is displayed. Approval in the wallet must not itself apply
   the claims to the profile.
4. Explicitly accept the result in StimmApp and confirm the profile is verified.
5. Repeat with StimmApp backgrounded, then with it terminated before returning.
   The pending or verified session should be restored after authentication.
6. Test wallet cancellation, an expired request, and wallet absence. These must
   not mark the profile verified.
7. Record the commit, iOS version, wallet version, date, invocation method,
   pseudonymous trace ID, and outcome in the readiness checklist. Do not record
   PID claims, request URLs, tokens, or wallet payloads.

If repeated presentations start failing, reissue the sandbox PID: the current
wallet documentation describes a limited batch of single-use credentials.

## Simulator scope

The iPhone simulator can validate builds, app startup, and callback routing:

```sh
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env -d <simulator-device-id>
xcrun simctl openurl booted 'stimmapp://pid-verification'
```

A callback smoke test does not prove PID interoperability. The TestFlight
wallet flow must be completed on the physical iPhone before Apple PID support
is marked as verified.

## Local validation record — 2026-09-21

Working tree based on `bb0395a5`, with the Apple configuration and export fixes:

- Flutter analyzer: no issues; Flutter tests: 203 passed.
- iOS dev debug device builds: succeeded both without signing and with automatic
  development signing for team `MCVTMBQY74`. The signed app is available at
  `build/ios/iphoneos/Runner.app`; `codesign --verify --deep --strict` passed.
- iOS dev debug simulator build: succeeded; installed and launched on the
  iPhone 17 simulator running iOS 26.2. The dev welcome screen was visible.
- Opening `stimmapp://pid-verification` showed the iOS **Open in StimmApp**
  confirmation. Scheme registration is confirmed; authenticated callback
  handling and session restoration still require the device acceptance test.
- Xcode build settings for `Profile-dev` and `Release-dev` resolve to the dev
  bundle ID, entrypoint, entitlements, and hosts. CocoaPods integration succeeded.
- Unauthenticated dev `/oid4vp/resumable` request: expected HTTP 401,
  `Cache-Control: no-store`, and `x-stimmapp-verifier-origin: server`.
- The paired physical iPhone was offline. Device installation, TestFlight
  wallet access, and the complete iPhone PID flow have not been validated in
  this run.
