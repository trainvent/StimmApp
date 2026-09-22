# Cloud Functions Deploy Runbook (Dev)

## Local Node/npm toolchain

Use a regular Node 22 installation and the npm-installed Firebase CLI. The
standalone Firebase executable can run its own embedded Node/npm instead of
the project's runtime. On this Mac, its Node 20.18.2/npm 8.19.4 runner failed
before TypeScript started with `Cannot read properties of undefined (reading
'stdin')` in `/snapshot/firepit/.../@npmcli/promise-spawn`.

This Mac uses the official Node 22.23.2 ARM64 distribution, verified against
Node's published SHA-256 checksum, installed under
`~/.local/share/stimmapp-toolchain/node`. Homebrew installation was attempted
but rejected the pre-release macOS 27 version. Both `.zprofile` and `.zshrc`
put this user-owned toolchain first on PATH.

In an existing terminal, refresh and check it with:

```sh
source ~/.zshrc
rehash
command -v node npm firebase
node --version
npm --version
npm --prefix functions run build
```

The `node`, `npm`, and `firebase` commands should all resolve under
`~/.local/share/stimmapp-toolchain/node/bin`, rather than using the standalone
Firebase executable at `/usr/local/bin/firebase`. Restart existing terminals
after changing PATH. The standard CLI is installed using `npm install -g
firebase-tools`; Firebase documents this supported installation method in its
[CLI reference](https://firebase.google.com/docs/cli).
Do not remove the predeploy build to work around a toolchain failure.

For the EUDI audience fix, Firebase Functions act as a proxy to the standalone
verifier. A Functions deployment alone does not update that verifier. Follow
[the verifier rollout plan](eudi-ios-audience-fix.md) to rebuild the dev
verifier container while retaining its database and secrets.

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
