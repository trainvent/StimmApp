#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
flutter build web --release --target lib/main_dev.dart

# Flutter's web build does not reliably preserve custom dot-directories such as
# `web/.well-known`, so copy the platform association and ad metadata files
# explicitly.
mkdir -p build/web/.well-known
cp web/.well-known/assetlinks.json build/web/.well-known/assetlinks.json
cp web/apple-app-site-association build/web/apple-app-site-association
cp web/app-ads.txt build/web/app-ads.txt
