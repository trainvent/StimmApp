# App Check device validation

Tracking: [issue #59](https://github.com/trainvent/StimmApp/issues/59).
Keep enforcement disabled until all clients using shared services are validated.

## Evidence recorded on 2026-10-12

- Physical iPhone on iOS 27.0, Flutter 3.47.7, Xcode 27.0.
- Signed dev debug build installed and launched successfully.
- Signed dev app includes the production App Attest entitlement and the expected
  `MCVTMBQY74.de.lemarq.stimmapp.dev` application identifier.
- Embedded dev provisioning profile permits both `development` and `production`
  App Attest environments and expires on 2027-10-12.
- Initial debug exchange returned HTTP 403 before device-token registration.
- Registered the device token in the dev Firebase iOS app; a subsequent forced
  exchange logged `[AppCheck] Token verified`.
- Signed dev release installed and launched with its RevenueCat key omitted.
  Its token-free device artifact confirms a forced production-provider exchange
  succeeded at `2026-10-12T12:21:28.908320Z` (14:21 Berlin time).
- Signed prod release installed and launched. Initial App Attest exchange
  returned HTTP 400 `FAILED_PRECONDITION`, "App not registered". Both Firebase
  iOS app records were missing `teamId`; registered `MCVTMBQY74` on both using
  Firebase Management API. Prod App Attest token TTL was explicitly set to one
  hour. A subsequent forced prod release exchange succeeded at
  `2026-10-12T12:36:33.481743Z` (14:36 Berlin time).
- Prod signed app has the production App Attest entitlement. Its profile permits
  both App Attest environments and expires on 2027-10-12.
- User confirmed dev release sign-in and content loading. Profile pictures are
  explicitly disabled in dev mode before an upload is attempted, so dev Storage
  upload remains untested.
- User reported the requested prod release service-flow smoke checks all seemed
  to work. This is manual confirmation; Firebase verified-request metrics have
  not yet been reviewed, and no individual callable was identified in the report.
- Read backend settings: prod Auth, Firestore, and Storage are `UNENFORCED`; dev
  has no enforcement configuration for these services. No enforcement changed.
- Signed prod debug installed and exchanged a fresh token successfully after
  temporary device-token registration. Both dev and prod temporary debug tokens
  were then deleted, and the validated prod release app restored on the device.
- TestFlight, verified-request metrics, individual callable coverage, and
  unsupported-hardware fallback remain pending. Web and Android validation are
  also required before enforcing shared services.

Debug tokens and raw device logs are private local artifacts; do not commit them
or paste them into the issue.

## Reproduce

Restore dependencies with `flutter pub get --enforce-lockfile`. Keep Flutter
builds and package restores sequential in this checkout.

```bash
flutter run -d <device-id> --release --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=.env --dart-define=APP_CHECK_DIAGNOSTICS=true \
  --dart-define=REVENUECAT_API_KEY_DEV_IOS= --no-pub
```

For prod, use `--flavor prod -t lib/main.dart`. For debug token registration,
use `--debug` and register the SDK's device token in the matching Firebase app.
The diagnostic flag forces a token exchange without logging the resulting token
and without blocking startup. It does not change provider selection. Omit it
from ordinary release builds.

The dev validation command omits the RevenueCat key because the configured Test
Store key aborts release startup. Purchases are not validated in this run; an
ordinary dev release needs a valid RevenueCat configuration.

On native platforms the flag also saves `Documents/app-check-validation.json`
inside the app container with project, mode, status, error code, and UTC time.
Retrieve this token-free artifact when Dart logs are unavailable:

```bash
xcrun devicectl device copy from --device <device-id> \
  --domain-type appDataContainer --domain-identifier de.lemarq.stimmapp.dev \
  --source Documents/app-check-validation.json \
  --destination /private/tmp/stimmapp-appcheck-dev-result.json
```

Inspect the built app with `codesign -d --entitlements - <app-path>`. Decode its
embedded provisioning profile with `security cms -D -i <profile-path>` and check
that it permits the App Attest entitlement. Regenerate signing profiles if needed.

The combined Apple provider selects DeviceCheck when App Attest is unsupported;
it does not retry a failed App Attest exchange with DeviceCheck. Record fallback
as untested unless tested on hardware reporting App Attest as unsupported.

Before rollout, validate web and Android clients, review Firebase App Check
request metrics, and check enforcement separately for each service and callable.
Delete temporary debug registrations when testing is finished.

References: [Firebase App Attest setup](https://firebase.google.com/docs/app-check/ios/app-attest-provider),
[Flutter debug provider](https://firebase.google.com/docs/app-check/flutter/debug-provider).
