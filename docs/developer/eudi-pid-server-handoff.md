# Dev PID verification failure — server-agent handoff

## Task

Find the underlying verifier rejection, reproduce it, implement the narrow fix,
and prepare a tested dev rollout. Work on `dyn.aiomvp.com` as `leon`; the protected
verifier origin is `verifier.aiomvp.com`. Follow the server checkout's AGENTS.md.
The user requested this handoff for an agent running directly on the server.
This document does not independently authorize production changes or messages
to third parties. Prepare the concrete tested change before seeking any rollout
approval required by that agent's session.

## Established evidence

- Local checkout: `7b4b3b97`, inspected on 2026-09-27. Actual deployed revision
  needs checking. A previous rollout note records `2482249f`, image
  `41a4ea4bd489`, Credo 0.7.1; do not assume those are still deployed.
- Source log: `eudi-ios-wallet-logs 6.txt` on the user's Mac. Do not copy the raw
  export into the repository or task response: it contains protocol payloads.
- Wallet matches all seven requested PID fields, reaches consent, creates a
  presentation, and POSTs to the standalone verifier through Firebase.
- First relevant rejection: **2026-09-27 12:42:54 UTC / 14:42:54 Europe/Berlin**.
  Wallet log timestamps use `05:42:54-0700`.
- HTTP 400: `invalid_request`, `One or more presentations failed verification.`
  Header `x-stimmapp-verifier-origin: server` confirms the origin.
- Cloud trace: `81395ffdd11cc05210053dc9daf92366`.
- Authorization request ID (the `session` query parameter):
  `c4f7b914-85e5-42df-b230-6ed69fd57a1e`.
  **This is not necessarily the Askar record primary key.** Query the
  `authorizationRequestId` tag.
- At 12:43:07 UTC, retrying the request receives `Invalid state for authorization
  request`. This follows the first rejection; investigate the first error.
- The earlier JAR audience and wallet credential eligibility problems were
  passed in this attempt. Do not change claim paths or request audience on the
  strength of the subsequent generic failure.

## Leading hypothesis, not yet the confirmed root cause

`functions/src/pid_verification.ts` loads only `PID/Issuance` certificates into
the legacy X509 trusted-certificates callback. It ignores `PID/Revocation`
services and loses their association with their trusted entity.

The public sandbox trust list fetched on September 27:

- Returned HTTP 200; ES256 signature and signer-certificate match passed.
- List issue: `2026-09-26T22:04:08.985Z`; next update:
  `2026-09-27T22:04:08.985Z`. This confirms the downloaded list, not server access
  or the cache used at the time of the failure.
- Includes distinct D-Trust issuance and status-list CAs:
  `Deutschland PID-Signer Test CA 1-26-1 2026` and
  `Deutschland PID-Status-List-Signer Test CA 1-26-2 2026`.

In installed Credo 0.7.1, `SdJwtVcService.getStatusVerifier()` uses the matched
trusted issuer's `status` certificates, falling back to `issuance`. Without
dedicated status trust it additionally requires the status signer chain to
equal the credential issuer chain. Our legacy callback cannot express separate
status anchors. This is a concrete integration gap, but the wallet export does
not establish whether this credential hit it.

## First: inspect the stored failure without changing the session

1. Locate the running verifier container and its server-managed Compose project.
   Inspect image/revision and package versions. Do not print container environment
   variables or mounted secrets. Do not dump entire Askar records or raw logs.
2. Inspect only the known request. Credo stores its internal error in
   `OpenId4VcVerificationSessionRecord.errorMessage` after presentation validation
   fails. This should identify the check hidden by the public generic error.
3. Credo ConsoleLogger is deliberately Off. Do not enable broad SDK debug logs:
   they can expose tokens and claims. Existing lifecycle logs are generic and
   their random trace IDs are not necessarily the Cloud trace above.

The Mac changes include a read-only helper:

```sh
docker compose exec -T verifier node lib/pid_verifier_diagnose.js \
  c4f7b914-85e5-42df-b230-6ed69fd57a1e
```

It opens the existing Askar store directly, fetches by the request tag, and emits
only allowlisted state/error codes. No agent initialization, migration, session
replay, profile update, or provisioning. The helper and its tests are **local,
uncommitted and not deployed/pushed** at handoff time:

- `functions/src/pid_verifier_diagnose.ts`
- `functions/lib/pid_verifier_diagnose.js` and `.js.map`
- `functions/test/pid_verifier_diagnose.test.mjs`

If these files are not on the server, the following equivalent initial probe
runs against the existing image, from its Compose directory, without a rebuild.
Review the command and verify that the service is the **dev** verifier first:

```sh
docker compose exec -T verifier node --input-type=module <<'JS'
import { Store } from '@openwallet-foundation/askar-nodejs';
import runtime from './lib/pid_verifier_runtime_config.js';
const requestId = 'c4f7b914-85e5-42df-b230-6ed69fd57a1e';
let store, session;
try {
  const config = runtime.getPidAskarStoreConfig();
  const db = config.database;
  if (db.type !== 'postgres') throw new Error('Unexpected store');
  const uri = `postgres://${encodeURIComponent(db.credentials.account)}:${encodeURIComponent(db.credentials.password)}@${db.config.host}/${encodeURIComponent(config.id)}?connect_timeout=10&max_connections=1&min_connections=0`;
  store = await Store.open({ uri, passKey: config.key });
  session = await store.session().open();
  const records = await session.fetchAll({
    category: 'OpenId4VcVerificationSessionRecord',
    tagFilter: { authorizationRequestId: requestId },
    limit: 2, isJson: true, forUpdate: false,
  });
  if (records.length !== 1) {
    console.log(JSON.stringify({ result: 'request_not_uniquely_found' }));
  } else {
    const value = records[0].value;
    const record = typeof value === 'string' ? JSON.parse(value) : value;
    const message = typeof record.errorMessage === 'string' ? record.errorMessage : '';
    const checks = [
      ['The status list certificate chain could not be validated against the trusted status certificates.', 'status_list_trust_failed'],
      ['The status list signer chain does not match the credential issuer chain, and no dedicated trusted status certificates were configured for the trusted issuer.', 'status_list_dedicated_trust_missing'],
      ['The key binding JWT does not contain the expected audience', 'holder_audience_mismatch'],
      ['The key binding JWT does not contain the expected nonce', 'holder_nonce_mismatch'],
      ['The official EUDI sandbox PID trust list is not currently valid.', 'trust_list_expired'],
      ['The official EUDI sandbox PID trust list could not be downloaded.', 'trust_list_download_failed'],
    ];
    console.log(JSON.stringify({
      result: 'found',
      failed: record.state === 'Error',
      failureCode: checks.find(([text]) => message.includes(text))?.[1] ?? 'unclassified',
    }));
  }
} catch {
  console.error(JSON.stringify({ result: 'diagnostic_failed' }));
  process.exitCode = 1;
} finally {
  try { await session?.close(); await store?.close(); }
  catch { process.exitCode = 1; }
}
JS
```

`unclassified` does not disprove the hypothesis. Inspect the installed dependency
error messages and add precise fixed-code classifications locally. Do not print
the raw error: it can embed claims, tokens, or URLs. If the record is gone, prepare
equally narrow diagnostics and coordinate a fresh attempt with the user.

## Fix and validate against the actual failure

If separate status trust is confirmed, use Credo's supported trusted-issuer API
with **issuance and status anchors paired per trusted entity**, parsed from the
authenticated list. Verify the installed API/types before coding. Avoid combining
all issuance/revocation certificates into one global trust pool. Preserve signed
list verification, freshness, issuer association, credential signature and status
validation, holder binding, audience, nonce, and explicit profile acceptance.

Add a synthetic cryptographic regression that fails with the old configuration:
credential signed by an issuance key, status list signed by a separate authorized
status key. It should pass with correctly associated anchors and still reject an
untrusted/wrong-entity status signer, revoked credential, and invalid signature.
If another root cause is established, write the regression for that cause instead.
Do not weaken validation or rotate certificates speculatively.

Run Node 22 `npm test`, `npm run lint`, and `git diff --check`. Before a dev rollout,
retain/tag the current image, review the concrete diff and follow the current
session's deployment authorization. Replace only the dev verifier; preserve
PostgreSQL and all secrets. Do not run `down -v`, reset sessions or edit profiles.
Check health and proxy/auth boundaries after replacement.

Use a **fresh** app verification session for physical-iPhone acceptance. Confirm
wallet approval, app return, verified result review, and explicit acceptance.
Repeat on Android and test cancellation/expiry rejection. Backend unit tests do
not establish wallet interoperability; report device checks as pending if needed.

## Return handoff

Write a Markdown result with:

- Observed deployed revision/image and sanitized failure category.
- Confirmed root cause and evidence distinguishing it from the hypothesis.
- Changed files, commit/diff, regression and backend check results.
- Deployment status, retained rollback image, and health/auth results if deployed.
- Fresh iPhone/Android outcomes or exact remaining user action.

No raw claims, credentials, secrets, private keys, or complete protocol messages.

Local helper validation: Node 22.23.2, all 13 backend tests passed (including a
native Askar read/no-record-change test), lint passed. No verifier behavior change
or deployment was performed from the Mac. SSH authentication was unavailable;
the host-side agent should continue the investigation locally.

## References

- [Official PID presentation guide](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/rp/guide/presentation/pid_presentation/)
- Public trust-list base: `https://bmi.usercontent.opencode.de/eudi-wallet/test-trust-lists`
- `docs/developer/eudi-ios-audience-fix.md`
- `docs/developer/eudi-ios-claim-comparison.md` (historical eligibility diagnosis;
  read its later verifier-side follow-up first)
- `docs/developer/eudi-apple-sandbox.md`
- `deploy/pid-verifier/README.md`
