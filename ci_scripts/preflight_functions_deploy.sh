#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${1:-stimmapp-dev}"
REGION="${2:-us-central1}"

echo "== Functions Deploy Preflight =="
echo "Project: ${PROJECT_ID}"
echo "Region : ${REGION}"
echo

ACCOUNT="$(gcloud config get-value account 2>/dev/null || true)"
ACTIVE_PROJECT="$(gcloud config get-value project 2>/dev/null || true)"

echo "Active account : ${ACCOUNT}"
echo "Active project : ${ACTIVE_PROJECT}"
echo

if [[ "${ACTIVE_PROJECT}" != "${PROJECT_ID}" ]]; then
  echo "ERROR: Active gcloud project is '${ACTIVE_PROJECT}', expected '${PROJECT_ID}'."
  echo "Run: gcloud config set project ${PROJECT_ID}"
  exit 1
fi

echo "Checking effective policy: iam.allowedPolicyMemberDomains"
APMD="$(
  gcloud org-policies describe constraints/iam.allowedPolicyMemberDomains \
    --effective --project="${PROJECT_ID}" 2>/dev/null || true
)"
echo "${APMD}"

if ! grep -q "allowAll: true" <<< "${APMD}"; then
  echo
  echo "ERROR: Domain restricted sharing is not open for ${PROJECT_ID}."
  echo "Public invoker (allUsers) may fail for Gen2 HTTP functions."
  exit 1
fi

echo
echo "Checking effective policy: iam.managed.allowedPolicyMembers"
MAPM="$(
  gcloud org-policies describe constraints/iam.managed.allowedPolicyMembers \
    --effective --project="${PROJECT_ID}" 2>/dev/null || true
)"
echo "${MAPM}"

if grep -q "enforce: true" <<< "${MAPM}"; then
  echo
  echo "ERROR: iam.managed.allowedPolicyMembers is enforced."
  echo "Public invoker (allUsers) may be blocked."
  exit 1
fi

echo
echo "Preflight OK."
echo "Run: firebase deploy --only functions --project ${PROJECT_ID}"
