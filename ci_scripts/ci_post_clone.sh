#!/bin/bash
set -euo pipefail

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
FLUTTER_VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/.flutter-version")"
FLUTTER_DIR="$REPO_ROOT/.xcode-cloud/flutter"
FLAVOR="${STIMMAPP_FLAVOR:-${CI_XCODE_SCHEME:-prod}}"
if [ "$FLAVOR" = "Runner" ]; then
  FLAVOR=prod
fi
case "$FLAVOR" in
  prod) FLUTTER_ENTRYPOINT=lib/main.dart ;;
  dev) FLUTTER_ENTRYPOINT=lib/main_dev.dart ;;
  *) echo "Unsupported iOS flavor: $FLAVOR" >&2; exit 1 ;;
esac
SCHEME_FLAVOR="${CI_XCODE_SCHEME:-$FLAVOR}"
if [ "$SCHEME_FLAVOR" = "Runner" ]; then
  SCHEME_FLAVOR=prod
fi
if [ "$SCHEME_FLAVOR" != "$FLAVOR" ]; then
  echo "STIMMAPP_FLAVOR must match CI_XCODE_SCHEME (${CI_XCODE_SCHEME:-})" >&2
  exit 1
fi

echo "ci_post_clone.sh"
echo "repo root: $REPO_ROOT"
echo "scheme: ${CI_XCODE_SCHEME:-unknown}"
echo "action: ${CI_XCODEBUILD_ACTION:-unknown}"

mkdir -p "$(dirname "$FLUTTER_DIR")"

if [ ! -d "$FLUTTER_DIR/.git" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

git -C "$FLUTTER_DIR" fetch --depth 1 origin "refs/tags/$FLUTTER_VERSION"
git -C "$FLUTTER_DIR" checkout --detach FETCH_HEAD

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics
flutter config --enable-swift-package-manager
flutter precache --ios

cd "$REPO_ROOT"
flutter pub get --enforce-lockfile
flutter build ios --release --no-codesign --config-only --flavor "$FLAVOR" \
  -t "$FLUTTER_ENTRYPOINT" --dart-define-from-file="$REPO_ROOT/.env"
