# PID verifier interoperability fix — 2026-09-27

## Evidence and root cause

The failed request from the handoff was read directly from Askar by its
`authorizationRequestId`, without replay or record changes. It was in state
`Error`; its fixed failure category is `issuer_chain_untrusted`.

Original deployment: `stimmapp-dev`, Node 22.23.2, Credo 0.7.1, image
`sha256:41a4ea4bd489a6f5b8abebb4080fa7477eed4fbffb9c8dd63727c50a0d0490d7`.
The image has no source revision label. Checkout base: `245a40a3`.

The public PID certificate extracted from the wallet log is signed by the
D-Trust Deutschland PID-Signer Test CA 1-26-1 2026. Native Node verification
against the authenticated sandbox trust list succeeds. Credo's Askar-only KMS
fails because the CA certificate signature requires P-521/SHA-512 (ES512), which
Askar does not support. The chain builder swallows that backend error while
searching for an issuer and reports missing trust instead. This reproduces the
stored rejection and distinguishes it from the original status-list hypothesis.

After enabling ES512, a second failure is reproducible: the PID leaf has no SAN,
while Credo requires a present HTTPS `iss` to match a certificate SAN.
The fixed official preproduction issuer's HTTPS JWT VC issuer metadata publishes
the same signing public key. This enables an additional issuer-key binding
without accepting arbitrary issuer URLs or replacing X.509 chain trust.

## Implementation

- `pid_verifier_crypto.ts`: Askar remains the default persistent KMS. The
  installed Credo Node backend is restricted to ES512 public-key verification.
- `pid_verifier_issuer.ts`: verifier-instance compatibility adapter restricted
  to `dc+sd-jwt`, `urn:eudi:pid:de:1`, the exact preproduction issuer, and a leaf
  with no SAN. Its key must match the JWKS obtained over HTTPS from the fixed
  issuer metadata endpoint. Metadata `issuer` must match exactly. Redirects are
  rejected, requests time out after 10 seconds, and successful keys are cached
  for five minutes. Outages and key mismatches retain the original rejection;
  stale keys are not served after cache expiry. An explicit mismatching SAN is
  never overridden. AsyncLocalStorage isolates bindings between concurrent calls.
- `pid_verifier_trust.ts`: preserves signed-list verification and freshness,
  and pairs issuance/status anchors per trusted entity using the supported
  trusted-issuer API. Status signers from other entities are not pooled.
- `pid_verification.ts`: wires those modules into the actual verifier.
- `pid_verifier_diagnose.ts`: adds the fixed issuer-chain failure category.

The compatibility adapter uses a private synchronous name-check method because
Credo 0.7.1 has no public hook for an additional issuer binding. It changes only
this agent's service instance, not the global SDK prototype. A strict dependency
version guard and method check fail initialization on an unsupported SDK change.
Review/remove the adapter when Credo offers an equivalent supported policy hook.
This maintenance limitation is intentional and covered by integration tests.

No signed payload, certificate, claim, verification option or private key is
rewritten. The ordinary SDK still validates X.509 trust, credential signatures,
status signatures/revocation, and the holder proof including audience and nonce.
No package versions changed. Raw wallet logs are excluded from Git and are not
test fixtures.

## Validation

Node 22: all 18 backend tests pass; lint and `git diff --check` pass.
Synthetic cryptographic regressions exercise:

- P-521 chain failure with the old configuration and success with the fix;
- wrong CA, tampered certificate and expired certificate rejection;
- retained Askar private-key operations;
- exact HTTPS issuer/metadata binding, wrong key and metadata outage rejection;
- separate authorized status signer success, old issuance-only trust failure;
- wrong-entity status signer, invalid status signature and revoked PID rejection;
- invalid credential/holder signature and wrong audience/nonce rejection;
- no trust anchors, unrelated issuer/type and explicit SAN mismatch rejection;
- concurrent valid/invalid verification isolation.

All 10 distinct logged SD-JWT credential candidates pass isolated credential
verification with the complete fix and live status checks. This is not a replay
against the deployed endpoint and does not change any session or profile. It
does not establish physical-wallet acceptance: fresh iPhone and Android flows,
explicit app acceptance, cancellation and expiry remain device checks.

## Deployment

Rollback image retained as
`stimmapp-pid-verifier:rollback-before-pid-interop-20260927`.
Candidate image: `stimmapp-pid-verifier:pid-interop-20260927`.
Build and rollout results are recorded below once complete. Only the dev
verifier is eligible for replacement; PostgreSQL and secrets are preserved.
Changes are uncommitted.

## References

- Official issuer metadata: https://preprod.pid-provider.bundesdruckerei.de/.well-known/jwt-vc-issuer
- Official signed sandbox list: https://bmi.usercontent.opencode.de/eudi-wallet/test-trust-lists/pid-provider.jwt
- German PID rulebook supplied by the user: https://sandbox.eudi-wallet.org/api/schemas/assets/rulebooks/NQ3x1djJJVavDb70.md
- SD-JWT VC draft key discovery: https://www.ietf.org/ietf-ftp/internet-drafts/draft-ietf-oauth-sd-jwt-vc-19.html#section-2.5
- IETF report of Credo's absent-SAN incompatibility: https://mailarchive.ietf.org/arch/msg/oauth/aZFt21ffqIpE_B66s7qi5AyaNUM/

The rulebook does not specify a concrete SAN matching rule. The adapter does not
infer trust from that omission: it requires both the official CA trust chain and
an independently fetched HTTPS issuer-key binding.

## Completed dev rollout

Built and deployed image
`sha256:fddb3c5f15555debdbb3d99ef08796b949517ea6e89bdeabfec3916c5d6266f4`
using `docker compose up -d --no-deps --no-build verifier` after tagging the
candidate as `latest`. The Docker build independently passed all 18 tests.
Only `stimmapp-pid-verifier-verifier-1` was recreated.

Post-rollout checks passed:

- Container healthy, running as `node`, no published host ports.
- Local and public-origin health: HTTP 200, server origin marker present.
- Origin without proxy secret: HTTP 403.
- Origin with proxy secret but no Firebase user token: HTTP 401.
- Firebase public proxy without user token: HTTP 401 with server origin marker.
- Original failed Askar record remains readable in its original error state.
- PostgreSQL is still running with its unchanged start time of
  `2026-08-29T12:15:26.554437139Z`; no restart, migration or data reset was requested.

Next user action: start a NEW PID verification in StimmApp, approve it in the
wallet, return to the app, review the result, and explicitly accept the details.
The earlier failed request remains failed and must not be replayed. Repeat the
fresh flow on Android and check cancellation/expiry when devices are available.

Rollback if necessary: retag
`stimmapp-pid-verifier:rollback-before-pid-interop-20260927` as
`stimmapp-pid-verifier:latest`, then run the same Compose command for only
`verifier`. No database or secrets changes are part of rollback.
