#!/usr/bin/env bash
set -euo pipefail
OUT_DIR="$PWD/ci_debug_out"
mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/xcodebuild.log"

echo "=== ENVIRONMENT ===" > "$LOG"
env | sort >> "$LOG"
echo "=== SW VERSIONS ===" >> "$LOG"
xcodebuild -version >> "$LOG" 2>&1 || true
swift -version >> "$LOG" 2>&1 || true

echo "=== Flutter pub get ===" >> "$LOG"
flutter pub get >> "$LOG" 2>&1 || { echo "flutter pub get failed" >> "$LOG"; exit 1; }

echo "=== Pod install ===" >> "$LOG"
cd ios
pod repo update >> "../$LOG" 2>&1 || true
pod install --repo-update >> "../$LOG" 2>&1 || { echo "pod install failed" >> "../$LOG"; exit 1; }
cd ..

ARCHIVE_PATH="$OUT_DIR/build.xcarchive"
DERIVED="$OUT_DIR/DerivedData"
RESULT="$OUT_DIR/result.xcresult"

echo "=== Running xcodebuild (normal, allowProvisioningUpdates) ===" >> "$LOG"
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -destination generic/platform=iOS \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED" \
  -resultBundlePath "$RESULT" \
  -allowProvisioningUpdates \
  | tee -a "$LOG" || true

EXIT_CODE=${PIPESTATUS[0]:-0}
echo "xcodebuild exit: $EXIT_CODE" >> "$LOG"

echo "=== Running xcodebuild (no signing) ===" >> "$LOG"
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -destination generic/platform=iOS \
  -archivePath "$ARCHIVE_PATH.no_sign" \
  -derivedDataPath "$DERIVED.no_sign" \
  -resultBundlePath "$RESULT.no_sign" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY= \
  | tee -a "$LOG" || true

if [ -d "$RESULT" ] || [ -d "$RESULT.no_sign" ]; then
  echo "=== xcresult available, exporting summary ===" >> "$LOG"
  if command -v xcrun >/dev/null 2>&1; then
    xcrun xcresulttool get --path "$RESULT" --format json > "$OUT_DIR/result.json" 2>>"$LOG" || true
    xcrun xcresulttool get --path "$RESULT" --format text > "$OUT_DIR/result.txt" 2>>"$LOG" || true
  else
    echo "xcresulttool not found" >> "$LOG"
  fi
fi

echo "=== Installed code signing identities ===" >> "$LOG"
security find-identity -p codesigning -v >> "$LOG" 2>&1 || true

echo "Debug output in $OUT_DIR"
exit $EXIT_CODE
