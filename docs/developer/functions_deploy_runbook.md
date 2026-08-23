# Cloud Functions Deploy Runbook (Dev)

## Problem this prevents

Gen2 HTTP Functions are Cloud Run services.
Deploy can fail on new functions when Firebase tries to set public invoker (`allUsers`) and org policy blocks it.

Typical errors:
- `Failed to set the IAM Policy on the Service ...`
- `FAILED_PRECONDITION: ... do not belong to a permitted customer`

## Required effective org policy for `stimmapp-dev` (public endpoints)

- `constraints/iam.allowedPolicyMemberDomains` → `allowAll: true`
- `constraints/iam.managed.allowedPolicyMembers` → `enforce: false`

Check:

```bash
gcloud org-policies describe constraints/iam.allowedPolicyMemberDomains --effective --project=stimmapp-dev
gcloud org-policies describe constraints/iam.managed.allowedPolicyMembers --effective --project=stimmapp-dev
```

## Standard deploy flow

```bash
./ci_scripts/preflight_functions_deploy.sh
firebase deploy --only functions --project stimmapp-dev
```

## Quick triage if deploy fails again

```bash
gcloud config get-value account
gcloud config get-value project
```

```bash
gcloud run services add-iam-policy-binding updatepollgroup \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker" \
  --project=stimmapp-dev
```

If that command fails with permitted-customer / precondition errors, org policy is blocking public invokers.
