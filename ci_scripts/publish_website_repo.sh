#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${TARGET_REPO:-}" ]]; then
  echo "TARGET_REPO is required" >&2
  exit 1
fi

if [[ -z "${TARGET_DOMAIN:-}" ]]; then
  echo "TARGET_DOMAIN is required" >&2
  exit 1
fi

if [[ -z "${WEBSITE_DEPLOY_TOKEN:-}" ]]; then
  echo "WEBSITE_DEPLOY_TOKEN is required" >&2
  exit 1
fi

SOURCE_DIR_INPUT="${1:-website/out}"
TARGET_BRANCH="${TARGET_BRANCH:-main}"

if [[ ! -d "$SOURCE_DIR_INPUT" ]]; then
  echo "Source directory '$SOURCE_DIR_INPUT' does not exist" >&2
  exit 1
fi

SOURCE_DIR="$(cd "$SOURCE_DIR_INPUT" && pwd -P)"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARGET_DIR="$TMP_DIR/target"
REPO_URL="https://x-access-token:${WEBSITE_DEPLOY_TOKEN}@github.com/${TARGET_REPO}.git"

git clone "$REPO_URL" "$TARGET_DIR"

pushd "$TARGET_DIR" >/dev/null

git checkout "$TARGET_BRANCH"

find "$TARGET_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
rsync -a --delete --exclude '.git' "$SOURCE_DIR"/ "$TARGET_DIR"/
printf '%s\n' "$TARGET_DOMAIN" > "$TARGET_DIR/CNAME"
touch "$TARGET_DIR/.nojekyll"

git config user.name "${GIT_AUTHOR_NAME:-github-actions[bot]}"
git config user.email "${GIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"

if git diff --quiet && git diff --cached --quiet; then
  echo "No changes to publish for ${TARGET_REPO}"
  exit 0
fi

git add -A
git commit -m "Publish website from shared source"
git push origin "HEAD:${TARGET_BRANCH}"

popd >/dev/null
