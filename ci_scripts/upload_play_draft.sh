#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# VS Code can use the ignored local credential file without inheriting an export.
export GOOGLE_PLAY_JSON_KEY="${GOOGLE_PLAY_JSON_KEY:-$PWD/fastlane/play-service-account.json}"
if [[ ! -f "$GOOGLE_PLAY_JSON_KEY" ]]; then
  echo "Google Play credentials not found: $GOOGLE_PLAY_JSON_KEY" >&2
  echo "Set GOOGLE_PLAY_JSON_KEY or save the key at fastlane/play-service-account.json." >&2
  echo "See docs/developer/publishing.md for one-time setup." >&2
  exit 1
fi

if command -v bundle >/dev/null 2>&1; then
  bundler_command=bundle
elif command -v bundle3.2 >/dev/null 2>&1; then
  bundler_command=bundle3.2
else
  echo "Install Ruby and Bundler first. See docs/developer/publishing.md." >&2
  exit 1
fi

if ! "$bundler_command" check; then
  echo "Install release dependencies with: $bundler_command install" >&2
  exit 1
fi
exec "$bundler_command" exec fastlane android draft
