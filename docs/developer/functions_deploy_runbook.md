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

On 2026-09-22, the latest official standalone release (15.30.2) was also
checked: its embedded npm still failed with the same `stdin` error.
The original `/usr/local/bin/firebase` entrypoint now launches the npm-installed
Firebase CLI 15.30.2 with Node 22 and explicitly sets PATH for its subprocesses.
Existing terminals can therefore keep using the usual command:

```sh
firebase deploy --only functions --project dev
```

The previous standalone executable is backed up at
`~/.local/share/stimmapp-toolchain/firebase-standalone-15.8.0.backup`.
The launcher depends on the user-local Node installation; retain that directory.
Future CLI updates use:

```sh
PATH="$HOME/.local/share/stimmapp-toolchain/node/bin:$PATH" npm install -g firebase-tools
```

Firebase documents the npm installation and standalone update methods in its
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

Keep dev Functions configuration in `functions/.env.stimmapp-dev` only.
Do not also create `functions/.env.dev`: Firebase rejects having both the
project-ID file and its alias file, even when their values are identical.

```bash
./ci_scripts/preflight_functions_deploy.sh
firebase deploy --only functions:pidVerifier --project stimmapp-dev
```

The example deploys only the PID proxy. Select the functions changed for each
task instead of redeploying every function. On 2026-09-22 an all-functions dev
deployment updated 20 functions but failed three with `Quota exceeded for total
allowable CPU per project per region`. Retry failed functions one at a time,
waiting for each command to finish:

```bash
firebase deploy --only functions:pidVerifier --project dev
firebase deploy --only functions:syncProdToDev --project dev
firebase deploy --only functions:updatePollGroup --project dev
```

All three isolated retries succeeded on 2026-09-22 without resource-setting
changes: `pidVerifier`, followed by `syncProdToDev` and `updatePollGroup`.
Each deployment completed before the next began. The scheduled sync was updated
without manually invoking its data-copy job.

If an isolated deployment still fails with the CPU quota error, inspect current
regional CPU use and quota in Google Cloud before changing resource settings or
requesting a quota increase. The accompanying container healthcheck message alone
does not establish an application startup bug.

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
