# Crashlytics Developer Report

Date: 2026-06-28

## Goal

Enable Firebase Crashlytics so production crashes produce developer-facing reports while keeping user-facing error messages short.

## Implementation Status

- Added the Flutter Crashlytics plugin: `firebase_crashlytics`.
- Registered the Android Crashlytics Gradle plugin in `android/settings.gradle.kts`.
- Applied the Crashlytics Gradle plugin in `android/app/build.gradle.kts`.
- Added Firebase Crashlytics and Analytics Android SDK dependencies through the Firebase BoM.
- Wired Flutter framework errors and uncaught async errors to Crashlytics in `lib/app_entry.dart`.
- Kept the existing local `errorLogTool` calls so in-app diagnostic behavior is preserved.
- Fixed a Gradle typo in `android/build.gradle.kts` that would have blocked Android builds.

## Current Error Reporting Behavior

Crashlytics is configured after `Firebase.initializeApp`.

- `FlutterError.onError` records Flutter framework errors as fatal Crashlytics reports.
- `PlatformDispatcher.instance.onError` records uncaught async errors as fatal Crashlytics reports.
- Web builds skip Crashlytics setup.
- Crashlytics collection is explicitly enabled in app startup.

## Verification Completed

Commands run:

```bash
flutter analyze
flutter build apk --debug --flavor dev -t lib/main_dev.dart
```

Results:

- `flutter analyze`: no issues found.
- Dev debug APK build: succeeded.
- Output APK: `build/app/outputs/flutter-apk/app-dev-debug.apk`

## Firebase Console Verification

Install and run the Android app, then trigger one test report from the profile page. It can take a few minutes before the Firebase console shows the first event.

Do not validate this from Chrome/web. The app skips Crashlytics setup on web, and the temporary profile-page test crash button is hidden there because `firebase_crashlytics` is meant for the Android/iOS Crashlytics SDK path in this project.

Suggested forced-crash test button code:

```dart
FirebaseCrashlytics.instance.crash();
```

The current profile-page test button uses `recordError(..., fatal: true)` instead. This creates a fatal-style Crashlytics report without killing the app, which is easier to diagnose while verifying upload behavior.

If logcat prints `Cannot send reports. Timed out while fetching settings`, reopen the app and leave it running in the foreground for a minute without pressing the crash button again. The forced crash is captured locally first; Crashlytics uploads it on a later run after it has fetched remote settings. If the timeout repeats on every fresh launch, check emulator/device internet access and whether `firebase-settings.crashlytics.com` is reachable on that network.

On startup, look for logs like:

```text
[Crashlytics] collectionEnabled=true didCrashOnPreviousExecution=true
[Crashlytics] sendUnsentReports requested
```

If `didCrashOnPreviousExecution` is false immediately after a forced crash, the SDK did not persist the crash locally. If it is true but no report appears, focus on upload/network/Firebase-console app selection.

## Notes

- Analytics events and Crashlytics reports are separate systems. Paywall failures are currently logged through Firebase Analytics; actual Dart/Android crashes now go to Crashlytics.
- Crashlytics is currently enabled programmatically. If crash reporting should follow an explicit user privacy setting, add a separate crash-reporting consent toggle and call `setCrashlyticsCollectionEnabled` with that value.
- The Android setup follows the Firebase Android Crashlytics guide for Kotlin Gradle projects: https://firebase.google.com/docs/crashlytics/android/get-started?hl=de#kotlin
