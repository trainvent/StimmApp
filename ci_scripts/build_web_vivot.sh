#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
flutter build web --release --target lib/main_vivot.dart
