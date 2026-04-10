#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f .env ]]; then
  bash ./ci_scripts/flutter_with_defines.sh build web --release --target lib/main.dart
else
  bash ./ci_scripts/flutter_with_defines.sh build web --release --target lib/main.dart
fi

# Flutter's web build does not reliably preserve custom dot-directories such as
# `web/.well-known`, so copy the platform association and ad metadata files
# explicitly.
mkdir -p build/web/.well-known
cp web/.well-known/assetlinks.json build/web/.well-known/assetlinks.json
cp web/apple-app-site-association build/web/apple-app-site-association
cp web/app-ads.txt build/web/app-ads.txt
