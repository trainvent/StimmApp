#!/bin/bash
set -euo pipefail

WORKSPACE_ROOT="${CI_WORKSPACE:-$PWD}"
FLUTTER_CHANNEL="$(awk -F'"' '/channel:/ {print $2}' "$WORKSPACE_ROOT/.metadata")"
FLUTTER_REVISION="$(awk -F'"' '/revision:/ {print $2}' "$WORKSPACE_ROOT/.metadata")"
FLUTTER_DIR="$WORKSPACE_ROOT/.xcode-cloud/flutter"
FLAVOR="${STIMMAPP_FLAVOR:-prod}"

mkdir -p "$(dirname "$FLUTTER_DIR")"

if [ ! -d "$FLUTTER_DIR/.git" ]; then
  git clone --depth 1 --branch "$FLUTTER_CHANNEL" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

if [ -n "$FLUTTER_REVISION" ]; then
  git -C "$FLUTTER_DIR" fetch --depth 1 origin "$FLUTTER_REVISION" || true
  git -C "$FLUTTER_DIR" checkout "$FLUTTER_REVISION" || true
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics
flutter precache --ios

cd "$WORKSPACE_ROOT"
flutter pub get
flutter build ios --release --no-codesign --flavor "$FLAVOR"

cd ios
pod install --repo-update
