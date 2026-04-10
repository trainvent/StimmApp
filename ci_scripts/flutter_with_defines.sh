#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

declare -a cmd=("flutter")

for arg in "$@"; do
  cmd+=("$arg")
done

if [[ -f "$REPO_ROOT/.env" ]]; then
  cmd+=("--dart-define-from-file=$REPO_ROOT/.env")
else
  define_keys=(
    ADMIN_EMAIL
    OWNER_EMAIL
    NOREPLY_EMAIL
    GOOGLE_PLACES_API_KEY
    TOMTOM_SEARCH_API_KEY
    GOOGLE_ADMOB_APP_ID
    GOOGLE_ADMOB_BANNER_AD_UNIT_ID
    GOOGLE_ADMOB_APP_ID_IOS
    GOOGLE_ADMOB_BANNER_AD_UNIT_ID_IOS
    GOOGLE_ADSENSE_CLIENT_ID
    ADSENSE_LIST_TILE_SLOT_ID
    IMAP_SERVER
    REVENUECAT_API_KEY_DEV_ANDROID
    REVENUECAT_API_KEY_DEV_IOS
    REVENUECAT_API_KEY_DEV_WEB
    REVENUECAT_API_KEY_PROD_ANDROID
    REVENUECAT_API_KEY_PROD_IOS
    REVENUECAT_API_KEY_PROD_WEB
    TEST_MAIL
    TEST_SECURE_PASSWORD
    TEST_WEAK_PASSWORD
    TEST_NAME
    TEST_SURNAME
    TEST_LIVING_ADDRESS
  )

  for key in "${define_keys[@]}"; do
    value="${!key:-}"
    if [[ -n "$value" ]]; then
      cmd+=("--dart-define=$key=$value")
    fi
  done
fi

exec "${cmd[@]}"
