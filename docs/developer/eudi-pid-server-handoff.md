# Updated Android wallet rejects PID request — server handoff

## Task

Apply the narrow backend request-format fix below to the dev PID verifier,
validate it, and prepare or perform the dev rollout according to the server
agent's existing deployment authorization. Work on `dyn.aiomvp.com` as `leon`;
the protected verifier origin is `verifier.aiomvp.com`. Follow the server
checkout's AGENTS.md and its actual server-managed Compose configuration.

This handoff replaces the September 27 investigation: the current October 9
failure occurs during wallet request resolution, before PID presentation.
The prior status-list trust hypothesis is not the cause demonstrated here.
This document does not independently authorize production changes.

## Confirmed evidence (2026-10-09)

Source: `/home/leonmarq/Downloads/Telegram Desktop/android-wallet-logs0 (4).txt`
on the user's local computer. The server agent may not have this file. Do not
copy the raw export into Git or print complete protocol messages; it contains
sensitive payloads. Local checkout inspected: `d9fca15c`; verify the deployed
revision and image separately.

All three StimmApp attempts fail with the same wallet error:

```text
MalformedRegistrationCertificate(cause=Provided credentialIds with registrations certificate while not expected)
```

Occurrences in the source export: lines 287, 2502, and 2616. The three attempts
are at 09:48:26, 09:51:38, and 09:51:59 as logged (three distinct request IDs).

The authorization request fetch succeeds with HTTP 200. Its response carries
`x-stimmapp-verifier-origin: server`, establishing that the standalone verifier
produced the request. Decoding the request payload confirms this entry:

```json
{
  "format": "registration_cert",
  "data": "<registration certificate JWT>",
  "credential_ids": ["pid-sd-jwt"]
}
```

The current source explicitly adds `credential_ids` in
`functions/src/pid_verification.ts`, in `createPidVerificationRequest()`.
The wallet rejects that combination before consent/presentation, then dispatches
an error to our authorize endpoint. Its subsequent `server_error` is secondary.
This log establishes the rejected field; stricter validation introduced by the
wallet update is an inference, not a verified release-history claim.

## Required change

Remove only `credential_ids` from the `registration_cert` entry:

```diff
     verifierInfo: [
       {
         format: 'registration_cert',
         data: registrationCertificate,
-        credential_ids: ['pid-sd-jwt'],
       },
     ],
```

Keep the `verifierInfo` array accepted by Credo. Keep the certificate JWT in
`data`. The existing DCQL query still selects `pid-sd-jwt` and its seven claims;
removing this extra certificate field does not remove credential selection.

The official registrar guide shows `format` and `data` for the registration
certificate. The wallet error and actual request provide the decisive evidence
for omitting `credential_ids` in this integration.

Do not change the certificate, request signer, `x509_hash` client ID, audience,
nonce, claim paths, issuer/status trust, holder binding, or profile acceptance
flow as part of this fix. No certificate rotation or Flutter change is indicated
by this failure. A broad verifier rewrite is unnecessary.

## Validate before rollout

1. Inspect the deployed revision/image and installed Credo version without
   printing environment variables or mounted secrets. The local package pins
   `@credo-ts/openid4vc` to `0.7.1`; verify the server's actual version.
2. Implement the diff in the server checkout.
3. Add a request-generation regression using the project's real Credo test
   setup (see `functions/test/pid_request_audience.test.mjs`). Decode a generated
   authorization request locally and assert that the `registration_cert` entry
   contains the expected `format` and `data` and has no `credential_ids` property.
   Also assert that DCQL still selects `pid-sd-jwt` with the existing claims.
   Never print the JWT or its certificate data. Prefer testing the production
   request construction, rather than a separately copied configuration.
4. Run the backend checks using the project's supported Node runtime:

   ```bash
   cd functions
   npm test
   npm run lint
   git diff --check
   ```

Record results accurately. This local handoff update did not modify backend
code or run its tests. Request-generation tests cannot prove acceptance by the
physical updated wallet; that remains a device check after rollout.

## Dev rollout

The affected requests came from `https://stimmapp-dev.web.app/oid4vp` and the
standalone origin. Update that dev verifier image. A Firebase proxy redeploy
should not be needed for this isolated origin request-generation change;
confirm the actual deployment topology first.

From the actual server-managed Compose project:

1. Retain/tag the currently running image and record the rollback reference.
2. Review the tested diff and use the server session's deployment authorization.
3. Build and replace only the verifier service:

   ```bash
   docker compose build verifier
   docker compose up -d --no-deps verifier
   docker compose ps verifier
   ```

4. Run the existing smoke test with its appropriate server paths/configuration:

   ```bash
   PID_VERIFIER_PUBLIC_BASE_URL=https://stimmapp-dev.web.app/oid4vp \
     ./smoke-test.sh
   ```

See `deploy/pid-verifier/README.md` for health, origin/proxy authentication, and
public origin-marker checks. Preserve PostgreSQL, mounted secrets, and the
Askar store key. Do not use `down -v`, reset the database, or edit user profiles.
If rollback is needed, restore the retained image through the same Compose
configuration and rerun health/auth checks.

## Fresh device acceptance

Create a new StimmApp verification session after deployment; old signed requests
still contain the rejected field and must not be reused.

- With the updated Android wallet, confirm request resolution reaches consent
  without `MalformedRegistrationCertificate`.
- Approve the PID presentation, confirm the app returns and shows verified
  details, then explicitly accept them and confirm the profile update.
- Repeat with iOS to check interoperability. Check cancellation/expiry rejection.
- If a new error appears after consent, diagnose that new stage separately;
  removing this blocker does not prove all subsequent validation will succeed.

If needed, use the existing read-only stored-session diagnosis helper with a
fresh request ID. Do not enable broad Credo logging or dump Askar records.

## Return result

Report the deployed revision/image, precise code diff, regression/check results,
deployment status, rollback reference, health/auth results, and fresh Android/iOS
outcomes. Mark device checks pending if the user must perform them. Include no
raw PID claims, credentials, tokens, secrets, or complete protocol messages.

## References

- [Official registrar certificate usage](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/rp/guide/presentation/registrar_certificate_usage/)
- [Official PID presentation guide](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/rp/guide/presentation/pid_presentation/)
- `functions/src/pid_verification.ts`
- `functions/test/pid_request_audience.test.mjs`
- `deploy/pid-verifier/README.md`
