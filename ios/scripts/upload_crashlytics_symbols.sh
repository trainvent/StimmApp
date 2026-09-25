#!/bin/bash
set -euo pipefail

# Simulator builds do not produce the device dSYMs used by Crashlytics.
if [[ "${PLATFORM_NAME:-}" != "iphoneos" ]]; then
  exit 0
fi

: "${FIREBASE_APP_ID:?Set FIREBASE_APP_ID in the flavor xcconfig}"

# Flutter supplies -clonedSourcePackagesDirPath; direct Xcode builds use
# DerivedData/SourcePackages. Support both without relying on CocoaPods.
UPLOAD_SYMBOLS="${BUILD_DIR}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"
if [[ ! -x "$UPLOAD_SYMBOLS" ]]; then
  UPLOAD_SYMBOLS="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"
fi
if [[ ! -x "$UPLOAD_SYMBOLS" ]]; then
  # `flutter build ipa` leaves BUILD_DIR in DerivedData so Xcode copies dSYMs
  # into the archive, but still clones packages under Flutter's build directory.
  FLUTTER_OUTPUT="${FLUTTER_BUILD_DIR:-build}"
  if [[ "$FLUTTER_OUTPUT" != /* ]]; then
    FLUTTER_OUTPUT="${FLUTTER_APPLICATION_PATH:-$SRCROOT/..}/$FLUTTER_OUTPUT"
  fi
  UPLOAD_SYMBOLS="$FLUTTER_OUTPUT/ios/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"
fi
if [[ ! -x "$UPLOAD_SYMBOLS" ]]; then
  echo "error: Firebase Swift package upload-symbols tool is missing. Resolve packages and rebuild." >&2
  exit 1
fi

# Firebase's supported wrapper fails the build for invalid configuration, then
# uploads asynchronously so a network delay cannot hold up an archive.
exec /bin/sh "${UPLOAD_SYMBOLS%/upload-symbols}/run" --app-id "$FIREBASE_APP_ID"
