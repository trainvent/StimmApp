# Firebase Apple SDK: Swift Package Manager migration

Created: 2026-09-25

Goal: move StimmApp's iOS Firebase dependencies to Flutter-managed Swift Package Manager (SwiftPM), with working local builds and CI. Aim to complete the migration before Firebase stops publishing CocoaPods updates in October 2026.

Existing Firebase CocoaPods releases remain installable and functional; October is an update cutoff, not an app shutdown. Firebase 12 is the last major release distributed through CocoaPods.

## Initial inspection (before migration)

These findings describe the starting state; the validation record below describes the migrated project:

- Generated plugin metadata reports Flutter 3.44.5 and SwiftPM disabled for iOS and macOS.
- All installed FlutterFire iOS plugins contain `Package.swift` manifests.
- The iOS Xcode project still integrates CocoaPods.
- `ios/Podfile` sets iOS 16.0 and patches the Firestore podspec's deployment target.
- `codemagic.yaml` removes the Pod lockfile and runs `pod deintegrate` / `pod install`; the Xcode Cloud setup in `ci_scripts/ci_post_clone.sh` also runs `pod install`.
- The installed `path_provider_foundation` package had no `Package.swift` in the initial inspection. Check its current integration mechanism before treating it as a blocker or removing CocoaPods.
- Migration is in progress. See the validation record below; unchecked gates remain unverified.

## 1. Establish the baseline

- [ ] Record the Flutter, Xcode, Dart, and resolved FlutterFire versions used locally and in CI.
- [x] Preserve existing working changes, including `ios/Podfile.lock`, and create a migration branch or checkpoint.
- [ ] Confirm the current iOS simulator build and production release/archive build work; record any pre-existing failures.
- [x] Check current Flutter and FlutterFire migration guidance and plugin compatibility; update dependencies only where needed.
- [x] Audit all iOS plugins and their native dependencies for SwiftPM support, including RevenueCat, Google Sign-In, mobile scanner, and path provider.
- [x] Scope decision: focus this migration on iOS, matching the existing release workflows. Track macOS separately; its project remains unvalidated. This is the stated default assumption pending any user correction.

## 2. Enable Flutter-managed SwiftPM

- [x] Determine why SwiftPM is disabled and remove or update the relevant local, project, or CI setting.
- [x] Enable SwiftPM consistently for the project and CI. `pubspec.yaml` now sets `flutter.config.enable-swift-package-manager: true`, overriding the local global setting without changing other projects; CI also explicitly enables it.
- [x] Run `flutter pub get`, then build/run through Flutter to trigger its automatic Xcode migration.
- [x] Review the generated Xcode project changes: confirm `FlutterGeneratedPluginSwiftPackage` is integrated with the Runner target.
- [x] Verify the prepare-framework build pre-action for every used scheme: `Runner`, `dev`, and `prod`.
- [x] Confirm Firebase resolves through SwiftPM without duplicate Firebase libraries from CocoaPods or manually added Xcode packages.
- [x] Review the Firestore deployment-target patch. Both the resolved Firestore plugin and Firebase Apple SDK 12.19.0 declare iOS 15.0, compatible with the app's iOS 16.0 target. Remove the podspec patch with CocoaPods cleanup.
- [x] Check Crashlytics build scripts and symbol-upload paths against the SwiftPM integration.
- [x] Record which dependencies, if any, still require Flutter's CocoaPods fallback.

Use Flutter's plugin integration rather than manually adding a second Firebase SDK dependency to Runner. Keep CocoaPods available while plugins still require its fallback.

## 3. Update CI and dependency management

- [ ] Align the Flutter toolchain used locally, by Codemagic, and by Xcode Cloud.
- [x] Update both Codemagic workflows to prepare Flutter's SwiftPM integration before Flutter or direct `xcodebuild` builds.
- [x] Update `ci_scripts/ci_post_clone.sh` and verify its wrapper at `ios/ci_scripts/ci_post_clone.sh` still works. Stubbed-tool smoke checks passed for dev/prod/Runner routing and rejection of invalid/mismatched flavors; hosted execution remains pending.
- [x] Remove unconditional CocoaPods cleanup/reinstallation where no longer needed; retain necessary fallback installation while any plugins require it.
- [x] Preserve appropriate dependency lockfiles and review Swift package resolution/caching so CI builds are reproducible.
- [ ] Verify CI from a clean checkout without relying on local generated packages or caches.

## 4. Validate builds and behavior

- [x] Build and launch the `dev` flavor using `lib/main_dev.dart` on an iOS simulator.
- [x] Build and launch the `prod` flavor using `lib/main.dart` with the expected configuration.
- [x] Produce a local signed production archive and App Store IPA; verify the archived app signature and dSYM presence.
- [ ] Confirm signing/export works through the intended hosted CI pipeline.
- [ ] Verify each flavor connects to its intended Firebase project.
- [x] Verify native email/password login, logout, and session restoration after restarting the dev app. Disposable account deleted afterward.
- [ ] Verify the app UI login and custom email verification flows with a receiving test mailbox.
- [ ] Verify Google Sign-In and its return-to-app flow on a device.
- [x] Verify native Firestore server reads, writes, streamed updates, and fixture deletion in dev.
- [ ] Verify petition/poll flows through the app UI.
- [x] Verify native Storage upload and byte-for-byte download in dev; delete the fixture.
- [ ] Verify profile-picture uploads through the app UI.
- [x] Verify native callable transport against dev: `assertSignupEligible` returns the expected validation error for an empty request.
- [ ] Verify successful callable workflows, including email verification.
- [x] Submit a labelled Analytics event and controlled nonfatal Crashlytics report from the dev native SDK.
- [ ] Confirm Analytics event receipt and Crashlytics report receipt with symbolicated stack traces in the test environment.
- [ ] Verify RevenueCat purchase/restore flows using the sandbox environment.
- [ ] Smoke-test camera/QR scanning, image picking, sharing, and URL launching.
- [ ] Run relevant existing analyzer/tests and integration checks; record results below.

## 5. Remove obsolete CocoaPods integration

Complete this section only when all required plugins work without CocoaPods.

- [x] Remove CocoaPods integration following Flutter's guide, including obsolete Podfiles, lockfiles, generated pod directories, build phases, and `.xcconfig` includes.
- [x] Remove the obsolete Firestore podspec patch and remaining unnecessary CI pod commands.
- [x] Preserve the Flutter Xcode workspace and flavor configuration required by the project; do not apply the native-only Firebase workspace deletion instructions blindly.
- [x] Update `ios/ci_debug.sh`, developer documentation, and applicable build instructions to match the final workflow.
- [ ] Repeat clean local and CI builds after cleanup.
- [x] Review and commit the migration changes and required lockfiles, excluding generated build artifacts.

## Implementation and evidence notes

- Branch: `chore/firebase-swift-package-manager`. Build instructions: [iOS builds](ios-builds.md).
- Local toolchain: Flutter 3.44.5 (`f94f4fc76b`), Dart 3.12.2, Xcode 27.0 (`27A266a`). CI configuration now pins these Flutter/Xcode versions; actual hosted-run versions remain unobserved.
- Resolved FlutterFire: core 4.15.0, auth 6.7.0, Firestore 6.10.0, Functions 6.5.0, Analytics 12.6.0, Storage 13.6.0, Crashlytics 5.4.0; native Firebase 12.19.0. No Dart dependency upgrade was required.
- All 18 native iOS plugins support SwiftPM. `path_provider_foundation` 2.6.0 uses Dart/FFI (`native_build: false`) and needs no Swift package or pod. No iOS CocoaPods fallback remains.
- `pubspec.yaml` enables SwiftPM at project level, overriding the existing disabled global setting without changing other projects. Both native lockfiles pin the same 18 packages and restored identically in the clean source snapshot.
- `dev` now has its own Release/Profile configurations. All three schemes have Flutter's prepare action; the base Runner configurations explicitly select the production entrypoint.
- Crashlytics declares dSYM/executable build inputs and uses per-flavor app IDs matching Dart options and Firebase's official `run` wrapper. It validates synchronously and uploads in the background. Flutter build/archive and direct Xcode checkout paths are covered; successful archive validation does not prove completed upload or console symbolication.
- CI wrapper checks with stubbed tools passed for pinned SDK selection, locked restore, flavor routing, and invalid/mismatched-flavor failures. Diagnostic-helper checks passed for preserving archive failure status and skipping redundant builds after success.
- Initial migration hit stale GoogleUtilities/GoogleAppMeasurement cache tags and insufficient disk space. Refreshing the project-local caches and removing disposable project build outputs resolved these blockers.
- Pre-migration working changes, including the Pod lockfile, are preserved under `tmp/firebase-spm-baseline/`. Logs and screenshots referenced below are local ignored artifacts in the same directory.
- iOS is the current scope. The shared SwiftPM flag also applies to future macOS builds; the macOS project remains separately unvalidated.
- The existing Patrol suite is excluded from the production dependency graph. The 24 selected Dart tests and temporary native-plugin smoke checks do not replace full account/device acceptance testing.

## Validation record

| Check | Toolchain / flavor / environment | Result or evidence |
| --- | --- | --- |
| Baseline build | Flutter 3.44.5 / Xcode 27 / dev simulator | Failed before migration: Flutter framework architecture verification rejects `arm64 x86_64` despite `lipo -info` listing both. Full log: `tmp/firebase-spm-baseline/simulator.log`. Production baseline archive not verified. |
| SwiftPM simulator build | Flutter 3.44.5 / Xcode 27.0 / iPhone 18 Pro iOS 27 | Dev build and launch passed (133.2s); welcome screen inspected. Log: `tmp/firebase-spm-baseline/spm-dev-run.log`; screenshot: `dev-launch.png`. Prod build and launch also passed (92.5s), with Firebase initialized (`spm-prod-run.log`, `prod-launch.png`). |
| Release archive/export | Local prod / Flutter 3.44.5 / Xcode 27.0 | Final signed archive passed (232.0s), App Store IPA export passed (23.4s), and `codesign --verify --deep --strict` passed with access to macOS trust services. Artifact: `build/ios/ipa/Vivot.ipa`; archive: `build/ios/archive/Runner.xcarchive`. Final log: `final-archive.log`. Nothing published. Hosted CI export remains pending. |
| Clean CI build | Local source snapshot, Codemagic simulator command | Locked pub restore and SwiftPM `--config-only` passed without copied project caches. Full Codemagic simulator command passed (`** BUILD SUCCEEDED **` in `clean-ci-build.log`). Both native lockfiles retained identical pins. Final sequential simulator rebuild with the dSYM build inputs also passed (`final-simulator-inputs-retry.log`); an overlapping archive/simulator attempt had failed in the shared Flutter cache. Hosted CI remains unverified. |
| Firebase behavior | Dev disposable native smoke app / iOS simulator | Login, restart/session restoration, logout, account deletion, Firestore server read/write/stream/delete, Storage upload/download, and callable validation passed. Logs: `native-fixture-smoke.log`, `native-fixture-restart.log`, `storage-cleanup.log`; result ledger: `disposable-native-results.json`. Temporary code ran only in a disposable source snapshot. All cloud fixtures and credential files removed; normal dev app restored. UI acceptance flows remain pending. |
| Crashlytics / Analytics | Script checks and dev native smoke app | Simulator skip and checkout-path handling passed stub checks; per-flavor app IDs match Dart Firebase options. SDK submission of `spm_migration_smoke` and labelled nonfatal report passed. Subsequent dev Crashlytics API query returned no issue groups: receipt, completed symbol upload, and symbolication remain unverified. |
| Purchases and native plugins | Dev simulator | RevenueCat customer-info retrieval observed. Purchase/restore and other plugin interactions remain pending. |
| Analyzer / automated tests | Flutter 3.44.5 | `flutter analyze`: no issues (3.4s), after excluding generated SwiftPM package copies. 24 existing auth/onboarding tests passed (`tests.log`). |

## Remaining access and manual acceptance

- Run the nonpublishing Codemagic `ios-validation` workflow and Xcode Cloud build on this migration branch; local reproduction is not evidence of a hosted run.
- Use a dev account with a receiving mailbox for custom email verification, and interactive Google/StoreKit sandbox accounts for Google Sign-In and purchase/restore checks. Existing configured test credentials were rejected; the disposable native test account used a reserved non-deliverable address and has been deleted.
- Complete the device/UI checks above and confirm telemetry arrival. Do not treat SDK submission as dashboard receipt or native symbolication.
- The dev Storage rules denied deletion of the smoke object through the client SDK. The exact fixture was removed using authorized project access and absence verified; no rules were changed as part of this migration.

## References

- [Firebase CocoaPods deprecation and Flutter guidance](https://firebase.google.com/docs/ios/cocoapods-deprecation)
- [Flutter SwiftPM migration for app developers](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)
- [FlutterFire release notes](https://firebase.google.com/support/release-notes/flutter)
- [Crashlytics dSYM inputs and symbol upload](https://firebase.google.com/docs/crashlytics/ios/get-deobfuscated-reports)
