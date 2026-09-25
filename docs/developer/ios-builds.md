# iOS builds with Swift Package Manager

Use Flutter **3.44.5** (recorded in `.flutter-version`) and Xcode **27.0**. Keep the Flutter version in `codemagic.yaml` synchronized with `.flutter-version`. Xcode Cloud installs the version from `.flutter-version`; select Xcode 27.0 in the hosted workflow settings.

SwiftPM is enabled in `pubspec.yaml` for this project. Do not install Firebase separately in Xcode or run `pod install`. Flutter generates the local plugin packages under `ios/Flutter/ephemeral/Packages`. The workspace remains `ios/Runner.xcworkspace`.

## Dependencies

```bash
flutter pub get --enforce-lockfile
```

Commit `pubspec.lock` and the SwiftPM `Package.resolved` files under the Xcode project/workspace. Do not commit generated plugin packages, SDK checkouts, or build outputs. Ordinary builds should retain lockfiles. Review intentional dependency updates separately.

## Flavors

| Flavor | Dart entrypoint | Bundle identifier | Firebase project |
| --- | --- | --- | --- |
| dev | `lib/main_dev.dart` | `de.lemarq.stimmapp.dev` | `stimmapp-dev` |
| prod | `lib/main.dart` | `de.lemarq.stimmapp` | `stimmapp-f0141` |

Each flavor has Debug, Profile, and Release configurations. The `Runner` scheme uses the production bundle; use the named flavor schemes for repeatable builds. Firebase runtime options come from the entrypoint's `firebase_options_*.dart`; symbol uploads use the matching `FIREBASE_APP_ID` in the flavor xcconfig.

## Simulator

Run on a selected simulator to build for its architecture:

```bash
flutter run -d <simulator-id> --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env
```

The existing generic dual-architecture simulator build failed Flutter's framework architecture verification with Flutter 3.44.5 / Xcode 27.0 before this migration. Codemagic's Apple Silicon simulator workflow prepares the Flutter configuration, then explicitly builds arm64:

```bash
flutter build ios --simulator --debug --config-only --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env
xcodebuild build -workspace ios/Runner.xcworkspace -scheme dev \
  -configuration Debug-dev -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/ios_sim \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO
```

## Device release and archive

```bash
flutter build ios --release --no-codesign --flavor prod -t lib/main.dart --dart-define-from-file=.env
flutter build ipa --release --flavor prod -t lib/main.dart --dart-define-from-file=.env
```

The IPA command requires signing credentials and an appropriate provisioning profile. Xcode Cloud's post-clone script prepares configuration with `--config-only`; its archive action then performs the build. Select the `prod` or `dev` scheme: the script derives the flavor from `CI_XCODE_SCHEME` (`Runner` maps to `prod`). An explicit `STIMMAPP_FLAVOR` must match the selected flavor scheme.

## Crashlytics symbols

The final Runner build phase invokes `ios/scripts/upload_crashlytics_symbols.sh`. It locates the SwiftPM Firebase checkout for Flutter builds, Flutter archives, and direct Xcode builds, skips simulators, and invokes Firebase's official `Crashlytics/run` wrapper with the flavor's app ID. That wrapper validates configuration synchronously and uploads dSYMs in the background. Runner configurations generate dSYMs. No `GoogleService-Info.plist` is needed by this upload script because it passes the Firebase app ID explicitly.

A successful build does not prove that a crash report is symbolicated. Verify a controlled dev report in the Firebase console before closing the migration checklist.

## Diagnostics

For hosted verification, run Codemagic `ios-preview` and `ios-validation` on the migration branch. `ios-validation` reuses release signing/archive/export steps but has no publishing stage. The existing `ios-release` workflow still publishes to TestFlight. Supply the existing `.env` configuration through your CI setup before either build; it is not committed to the repository.

```bash
bash ios/ci_debug.sh
STIMMAPP_FLAVOR=dev bash ios/ci_debug.sh
```

The helper writes logs and xcresult bundles under `tmp/ci_debug_out/`, attempts a signed archive and an unsigned diagnostic archive if signing/building fails, and returns the signed archive's exit status. It does not dump environment variables into logs.

If SwiftPM reports that an upstream version does not exist, first inspect the upstream tag and the local repository cache; the initial migration encountered stale GoogleUtilities and GoogleAppMeasurement tags. Refresh or reset the affected package cache using Xcode, then resolve again. Do not work around stale caches by changing published dependency constraints.

Track outstanding build, CI, and runtime verification in [the migration checklist](firebase-spm-migration.md).
