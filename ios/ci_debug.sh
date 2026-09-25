#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
FLAVOR="${STIMMAPP_FLAVOR:-prod}"
case "$FLAVOR" in
  prod) FLUTTER_ENTRYPOINT=lib/main.dart ;;
  dev) FLUTTER_ENTRYPOINT=lib/main_dev.dart ;;
  *) echo "Unsupported STIMMAPP_FLAVOR: $FLAVOR" >&2; exit 1 ;;
esac
OUT_DIR="$REPO_ROOT/tmp/ci_debug_out/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/xcodebuild.log"

echo "=== SW VERSIONS ===" > "$LOG"
flutter --version >> "$LOG" 2>&1
xcodebuild -version >> "$LOG" 2>&1 || true
swift -version >> "$LOG" 2>&1 || true

echo "=== Flutter pub get ===" >> "$LOG"
flutter pub get --enforce-lockfile >> "$LOG" 2>&1 || { echo "flutter pub get failed" >> "$LOG"; exit 1; }

echo "=== Prepare Flutter SwiftPM integration ===" >> "$LOG"
flutter build ios --release --no-codesign --config-only --flavor "$FLAVOR" \
  -t "$FLUTTER_ENTRYPOINT" --dart-define-from-file="$REPO_ROOT/.env" >> "$LOG" 2>&1

ARCHIVE_PATH="$OUT_DIR/build.xcarchive"
DERIVED="$OUT_DIR/DerivedData"
RESULT="$OUT_DIR/result.xcresult"

echo "=== Running xcodebuild (normal, allowProvisioningUpdates) ===" >> "$LOG"
set +e
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme "$FLAVOR" \
  -destination generic/platform=iOS \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED" \
  -resultBundlePath "$RESULT" \
  -allowProvisioningUpdates \
  2>&1 | tee -a "$LOG"

EXIT_CODE=${PIPESTATUS[0]:-0}
set -e
echo "xcodebuild exit: $EXIT_CODE" >> "$LOG"

RESULT_NO_SIGN="$OUT_DIR/result-no-sign.xcresult"
if [ "$EXIT_CODE" -ne 0 ]; then
  echo "=== Running xcodebuild (no signing) ===" >> "$LOG"
  xcodebuild archive \
    -workspace ios/Runner.xcworkspace \
    -scheme "$FLAVOR" \
    -destination generic/platform=iOS \
    -archivePath "$OUT_DIR/build-no-sign.xcarchive" \
    -derivedDataPath "$DERIVED" \
    -resultBundlePath "$RESULT_NO_SIGN" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY= \
    2>&1 | tee -a "$LOG" || true
fi

for RESULT_PATH in "$RESULT" "$RESULT_NO_SIGN"; do
  if [ -d "$RESULT_PATH" ]; then
    echo "=== Exporting summary: $RESULT_PATH ===" >> "$LOG"
    xcrun xcresulttool get build-results --path "$RESULT_PATH" > "${RESULT_PATH%.xcresult}.json" 2>>"$LOG" || true
  fi
done

echo "=== Installed code signing identities ===" >> "$LOG"
security find-identity -p codesigning -v >> "$LOG" 2>&1 || true

echo "Debug output in $OUT_DIR"
exit $EXIT_CODE
