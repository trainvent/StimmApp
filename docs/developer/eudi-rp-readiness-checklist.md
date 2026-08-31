# EUDI Wallet Relying Party Readiness Checklist

Last reviewed: 2026-08-31

This document tracks StimmApp's German EUDI Wallet relying-party integration
from sandbox prototype to an operationally safe implementation. It follows the
official German EUDI Wallet RP integration sequence and the validation layers
described by the German PID presentation guide.

This is an engineering readiness record, not a legal or compliance approval.

## Readiness assessment

**Current verdict: sandbox happy path operational; production readiness not
yet asserted.**

The same-device German sandbox PID flow has completed successfully through the
deployed path:

`Flutter app -> Firebase Hosting/Function proxy -> verifier.aiomvp.com ->`
`Credo/Askar -> PostgreSQL`

The infrastructure and one end-to-end application run provide positive-path
evidence. They do not yet prove restart recovery during an active transaction,
replay resistance, idempotent acceptance, the negative trust/protocol matrix,
cross-device interoperability, backup recovery, production operations, or
legal/privacy approval. A checked item below means evidence exists in code,
deployment inspection, a smoke test, or the 2026-08-30 sandbox application run;
it does not imply broader certification.

### Assertion gates

| Assertion | Status | Evidence or blocker |
| --- | --- | --- |
| Sandbox same-device PID happy path works | **Asserted** | Completed in the Flutter dev app on 2026-08-30 after server cutover |
| Public requests traverse Firebase to the protected verifier | **Asserted** | Public route returned expected `401` with `x-stimmapp-verifier-origin: server` |
| Credo protocol state uses durable PostgreSQL | **Asserted** | Askar initialized its schema in `stimmapp_pid_verifier`; running container is healthy |
| Verifier origin is not directly usable without Firebase proxying | **Asserted** | Origin returns `403` without the shared secret and `401` without Firebase authentication |
| Versioned 12-month re-verification policy is active in dev | **Asserted** | Standalone verifier, Firebase function, and Firestore rules deployed and smoke-tested on 2026-08-30 |
| Editing a verified identity field requires re-verification | **Asserted** | Manually confirmed in the Flutter dev app on 2026-08-30; a fresh PID presentation completed after resetting and re-enrolling the sandbox wallet |
| An active transaction survives verifier restart | **Asserted** | Sandbox restart test completed on 2026-08-31 before wallet approval and again before profile acceptance |
| Replay and repeated acceptance are safe | **Not yet asserted** | Negative replay and idempotency tests remain open |
| Database data is recoverable after loss | **Not yet asserted** | Server-local database backups exist, but an independent backup destination and a recorded restore drill remain open |
| Operational monitoring is sufficient | **Not yet asserted** | Structured events, metrics, alerts, and certificate monitoring remain open |
| Production RP readiness | **Not asserted** | Production certificates, conformance, privacy, security, and operations remain open |

## Primary references

- [Relying Party Technical Integration](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/rp/onboarding/rp_highlevel_onboarding/)
- [PID Presentations with OpenID4VP](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/rp/guide/presentation/pid_presentation/)
- [Using Registrar Certificates in Presentation Requests](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/rp/guide/presentation/registrar_certificate_usage/)
- [Relying Party Readiness Checklist](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/sandbox/onboarding/sandbox_readiness_checklist/)
- [Logging and Monitoring](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/rp/guide/arch/logging_and_monitoring/)
- [OpenID for Verifiable Presentations 1.0](https://openid.net/specs/openid-4-verifiable-presentations-1_0-final.html)

## Current implementation snapshot

- [x] Firebase-authenticated StimmApp user can create a PID presentation request.
- [x] Backend creates an OpenID4VP request with Credo and opens the German EUDI
  Wallet sandbox app on the same device.
- [x] Request uses SD-JWT VC (`dc+sd-jwt`) for `urn:eudi:pid:de:1`.
- [x] Access Certificate is included through the request's `x5c` signer.
- [x] Registration Certificate is included as `verifier_info`.
- [x] Sandbox PID issuer certificates come from a signature-checked official
  trust list with issue-time and next-update validation.
- [x] Raw PID values remain visible to the user while normalized values are used
  for profile comparison and application.
- [x] Profile mutation requires an explicit user action after successful
  verification.
- [x] Registration and re-verification modes are represented in the UI.
- [x] The backend, rather than the client, selects registration versus
  re-verification mode from server-held verification history.
- [x] Successful PID verification is valid for 12 calendar months under the
  versioned `pid-profile-v1` policy.
- [x] Changes to verified identity fields atomically invalidate verification
  and advance the identity revision; unrelated profile changes do not.
- [x] Session ownership and lifecycle metadata are persisted privately in
  Firestore with a random trace ID and without PID claims or wallet payloads.
- [x] Credo/Askar protocol state is stored in PostgreSQL on the deployment
  server rather than Firebase or container-local `/tmp` storage.
- [x] Firebase proxies public `/oid4vp` traffic to the protected standalone
  verifier origin using a Secret Manager shared secret.
- [x] The standalone verifier runs as a non-root container, joins only the
  `stimmapp-dev-internal` and `proxy` networks, and publishes no host port.
- [x] The public Firebase route was proven to traverse the standalone origin,
  and a complete same-device sandbox flow succeeded after the cutover.
- [x] Manually confirmed that changing a verified identity field makes the
  profile require re-verification and that a fresh PID can satisfy it.
- [ ] Verification survives a verifier-container replacement during an active
  transaction. Durable storage is deployed, but the documented mid-flow
  restart test has not yet been executed.
- [ ] Cross-device QR presentation is supported and tested.
- [ ] The complete failure, replay, expiry, cancellation, and trust test matrix
  has automated evidence.
- [ ] Production certificates, trust configuration, retention policy, and
  operational ownership are ready.

## Step 1: Define the verification use case

### Product flow

- [x] Integration point is the signed-in user's profile registration or
  re-verification flow.
- [x] Same-device remote presentation is implemented.
- [ ] Document whether cross-device presentation is a product requirement.
- [x] Publishing or signing a petition requires current PID verification.
  Browsing, composing the unpublished form, and ordinary profile use remain
  available without one. Firestore rules are authoritative and the Flutter UI
  provides a verification preflight.
- [x] Define the re-verification trigger and validity period: verification is
  current for 12 calendar months and becomes non-current immediately when a
  verified identity field changes or the policy version changes.
- [ ] Define whether a verified mismatch blocks an action, offers a profile
  correction, or requires manual review.
- [ ] Define user-visible behavior for cancellation, timeout, wallet absence,
  unsupported credentials, and backend unavailability.

### Requested credential and attributes

- [x] Primary credential format is SD-JWT VC.
- [x] Requested credential type is German PID `urn:eudi:pid:de:1`.
- [x] Current request asks for given name, family name, birth date, street,
  postal code, locality, and country.
- [ ] Write down the business reason for every requested attribute.
- [ ] Confirm with product/legal stakeholders that a full residential address,
  rather than a smaller proof or subset, is necessary for the petition flow.
- [ ] Define the minimum address components required for a valid petition.
- [ ] Decide whether age verification could use an age attestation instead of
  disclosing the complete birth date in any applicable flow.
- [ ] Confirm that mDoc is not needed for the declared use case; do not add it
  merely for theoretical format coverage.
- [ ] Ignore and do not persist attributes disclosed beyond the request.

### Purpose binding

- [ ] Record the final registration purpose in this repository or a linked
  decision record.
- [ ] Confirm the purpose shown by the wallet comes from the active Registration
  Certificate and accurately describes the StimmApp flow.
- [ ] Ensure the StimmApp screen uses the same meaning and does not present a
  client-supplied purpose as authoritative.
- [ ] Repeat the review whenever the requested attributes or business purpose
  changes; obtain an updated Registration Certificate when required.

## Step 2: Integrate and audit the verifier

The verifier must fail fast in the order below. Business rules must run only
after trust, protocol, cryptographic, and disclosure validation succeeds.

### Layer 1: Trust and transport

- [x] Public verifier endpoints are exposed over Firebase Hosting HTTPS.
- [x] `verifier.aiomvp.com` serves the standalone verifier over HTTPS; its
  non-health routes reject requests without the proxy secret.
- [x] Access Certificate and matching P-256 private key are stored as mounted
  server secrets and retained in Firebase Secret Manager for the temporary
  embedded fallback, never in source control.
- [x] Backend checks that the private key matches the Access Certificate.
- [x] Registration Certificate is supplied to Credo as `registration_cert`.
- [x] Official sandbox PID trust-list JWT signature is verified.
- [x] Trust-list issue time and next update are checked before certificates are
  accepted.
- [x] Only PID issuance service certificates are extracted from the trust list.
- [ ] Validate trust-list certificate-chain and signer assumptions against the
  latest German trust-list profile, not only the currently observed sandbox
  document shape.
- [ ] Define fail-closed behavior, retry policy, cache lifetime, and monitoring
  for trust-list download failures.
- [ ] Add request-body and token size limits before parsing wallet responses.
- [ ] Confirm response headers prevent caching of authorization requests and
  responses (`Cache-Control: no-store`, `Pragma: no-cache`).
- [ ] Separate sandbox and production base URLs, certificates, secrets, and
  trust anchors explicitly.

### Layer 2: Session and transaction binding

- [x] Credo creates the authorization request and protocol session.
- [x] The response mode is `direct_post.jwt`.
- [x] Status and accept endpoints require a valid Firebase ID token.
- [x] A private durable record associates each Credo session with its Firebase
  user and a non-sensitive trace ID.
- [ ] Verify with tests that Credo rejects incorrect or reused `nonce`, `state`,
  audience/client ID, timestamps, response URI, and session bindings.
- [x] Persist session ownership and lifecycle outside process memory.
- [x] Assign every session a random, non-sensitive trace ID for future logs.
- [x] Persist the Credo/Askar protocol store outside Cloud Run `/tmp` in the
  isolated `stimmapp_pid_verifier` PostgreSQL database.
- [ ] Remove the Firebase proxy's `maxInstances: 1` limit after load and
  concurrency testing. PostgreSQL means the limit is no longer the protocol
  store's durability mechanism, but it remains configured.
- [x] Make acceptance single-use and idempotent: the accepted session and
  profile evidence are written atomically, and retries do not refresh the
  verification timestamp or identity revision.
- [x] Keep verified-but-unaccepted presentations resumable for a 30-minute
  review window and prefer them over newer pending retries.
- [ ] Expire sessions server-side and automatically delete stale ownership and
  protocol records.
- [ ] Remove client-configurable return URLs or enforce an exact allowlist if
  they become necessary.

### Layer 3: Holder binding

- [ ] Document the exact Credo API/version responsible for SD-JWT key-binding
  validation.
- [ ] Add a negative test proving that a response without valid holder binding
  is rejected.
- [ ] Add a negative test proving that a presentation bound to another verifier
  or transaction is rejected.
- [ ] Record a non-sensitive validation outcome for troubleshooting without
  logging the proof or PID payload.

### Layer 4: Credential assurance

- [x] Credo extracts only a verified authorization response before claims are
  made available to StimmApp.
- [x] Credo receives trusted PID issuer certificates through the X.509 module.
- [ ] Document and test the Credo checks for issuer signature, credential type,
  validity interval, issuer trust, and revocation/status where applicable.
- [ ] Reject unsupported credential formats and unexpected credential types.
- [ ] Test an untrusted issuer, invalid signature, expired credential, and
  malformed credential independently.
- [ ] Pin and periodically review Credo, Askar, OpenID4VC, and native dependency
  versions against the current German profile and changelog.

### Layer 5: Selective disclosure and data minimization

- [x] DCQL declares one required `pid-sd-jwt` credential set.
- [x] DCQL names the individual PID claims needed by the current prototype.
- [ ] Prove that all mandatory attributes are present before any business or
  profile update occurs.
- [ ] Reject unexpected extra credentials and ignore over-disclosed attributes.
- [ ] Add a test for a valid PID missing each required claim individually.
- [x] `pidVerificationRequestPreview` matches the DCQL request and does not
  claim that `address.region` is disclosed. For German PID addresses, the
  After acceptance, Flutter best-effort derives the Bundesland from the
  verified address through the same TomTom resolver used during onboarding.
  `state` is ordinary derived profile metadata, not a PID-disclosed or
  PID-verified field, and enrichment failure does not affect PID acceptance.
- [ ] Review the requested claim set whenever petition eligibility rules change.

### Layer 6: StimmApp business rules

- [x] Original EUDI claim text is displayed without normalization.
- [x] A separately normalized representation is used for comparison and profile
  formatting.
- [x] Profile data changes only after explicit user acceptance.
- [x] The acceptance endpoint records server-issued, versioned verification
  evidence: verified time, valid-until time, verified fields, and the identity
  revision to which the evidence applies.
- [x] Client profile writes cannot mint or extend verification evidence.
- [x] Editing a verified identity field makes the profile unverified in the
  same transaction and increments its identity revision.
- [x] Address comparison tolerates casing, punctuation, and localized locality
  differences when street, postal code, and country identify the same address.
- [ ] Move matching and eligibility rules into a backend/domain component so a
  client modification cannot change the authoritative decision.
- [ ] Define and test name matching, including multiple names, prefixes,
  diacritics, hyphens, apostrophes, transliteration, and `ß`/`ss`.
- [ ] Define and test address matching across countries and postal formats.
- [ ] Define behavior for a changed legal name, birth date conflict, or address
  change during re-verification.
- [ ] Separate the immutable verification result from the mutable user profile.
  The current implementation stores tamper-protected evidence on the profile,
  but does not yet retain an independent append-only verification record.
- [x] Store the minimal profile-level provenance needed by the current policy:
  verification and expiry times, verified fields, policy version, and matching
  identity revision. Issuer and credential type remain available at the
  verifier/session layer and are not copied into the public profile document.
- [ ] Define which profile fields may be overwritten and preserve unrelated
  user-entered data.

## Responsibility boundary

| Concern | Current owner | Readiness action |
| --- | --- | --- |
| OpenID4VP request and response processing | Credo | Document and negatively test each relied-on validation |
| Protocol keys and records | Credo + Askar PostgreSQL | Restart-test active sessions; add backup and restore operations |
| Access and Registration Certificates | Mounted server secrets + Credo; Firebase secrets retained for fallback | Add expiry monitoring and rotation runbook; remove duplicate fallback after stabilization |
| PID issuer trust | StimmApp trust-list loader + Credo X.509 | Test freshness, chain, outage, and untrusted issuer cases |
| Session-to-user authorization | StimmApp backend + Firestore | Durable; add emulator authorization and lifecycle tests |
| Attribute normalization and profile formatting | StimmApp backend | Expand unit tests; never alter the displayed original values |
| Profile comparison UX | Flutter app | Localize, improve accessibility, and test all result states |
| Eligibility/business decision | Not yet formalized | Specify and enforce authoritatively on the backend |
| Consent to update the profile | Flutter + authenticated backend endpoint | Single-use and idempotent; add structured audit events |

### Durable session record

The server-only `pidVerificationSessions/{sessionId}` record contains:

- Firebase owner UID for authorization, never for logging
- Random trace ID intended for pseudonymous operational correlation
- Lifecycle state and state-transition timestamps
- Creation, update, and expiry timestamps
- Registration or re-verification mode and fixed server-selected purpose
- Credential format/type, invocation method, and matching-policy version

It must not contain PID claims, authorization requests or responses, VP tokens,
wallet identifiers, cryptographic proofs, or private key material. Firestore
rules deny all client access, including the authenticated application admin;
Cloud Functions access it through the Admin SDK.

## Step 3: Test and validate in the sandbox

### Automated unit and component tests

- [ ] Add unit tests for PID claim extraction and required-field validation.
- [ ] Add unit tests for display normalization and postal/address formatting.
- [ ] Add table-driven tests for semantic name and address matching.
- [ ] Add authenticated endpoint tests for start, status, and accept.
- [x] Add unit tests for the 12-calendar-month validity calculation, backend
  mode selection, policy version, expiry, and identity-revision checks.
- [x] Compile the verification-evidence Firestore rules with the emulator and
  add a source-level regression test for their protected-field contract.
- [ ] Test that another Firebase user cannot read or accept a session.
- [ ] Test repeated acceptance, expired sessions, and deleted users.
- [ ] Test a simulated function restart between start, wallet response, status,
  and acceptance.
- [ ] Test concurrent sessions for the same user and different users.

### Wallet interoperability tests

- [x] Manually complete one same-device SD-JWT PID happy path through the
  PostgreSQL-backed standalone verifier after Firebase cutover (2026-08-30).
- [x] Manually receive, display, compare, and explicitly accept verified PID
  details in StimmApp.
- [x] Manually edit a verified identity field, observe re-verification become
  required, and successfully complete the re-verification flow (2026-08-30).
- [x] Recover from exhausted sandbox one-time PID credentials by resetting and
  re-enrolling the sandbox wallet, then complete a fresh presentation. Wallet
  logs showed the catalog button looping back to the pending presentation after
  failed automatic reissuance; this is recorded as a sandbox-wallet limitation,
  not a StimmApp verifier failure.
- [ ] Repeat the happy path on each supported Android version/device class.
- [ ] Test cross-device invocation with a QR code.
- [ ] Test wallet cancellation and user denial.
- [ ] Test an expired authorization request.
- [ ] Test a PID missing requested attributes.
- [ ] Test invalid, expired, and untrusted credentials or available official
  negative fixtures.
- [ ] Test wallet and backend network interruption at every transition.
- [ ] Run the available ERICA/conformance tooling and retain the report or link.

### User experience and accessibility

- [x] User can see the EUDI original, normalized comparison, and profile value.
- [x] User explicitly decides whether verified details update the profile.
- [x] Leaving and reopening the PID screen restores the latest verified,
  unaccepted presentation so explicit consent is not lost.
- [ ] Localize every PID verification string through `AppLocalizations`.
- [ ] Explain which attributes are requested and why before opening the wallet.
- [ ] Add an automatic verified App Link/deep-link return to StimmApp, with a
  visible browser fallback.
- [ ] Provide actionable errors for wallet absence, cancellation, timeout,
  unsupported PID, trust failure, and server failure without leaking internals.
- [ ] Complete screen-reader, text-scaling, contrast, keyboard, and scroll tests.

### Evidence record

For each manual or conformance run, record only non-sensitive evidence:

- [ ] Test date and app/backend version or commit.
- [ ] Sandbox wallet and credential format/version.
- [ ] Same-device or cross-device invocation.
- [ ] Pseudonymous session/trace identifier.
- [ ] Expected and actual state transition.
- [ ] Cryptographic validation outcome without credential contents.
- [ ] Result, issue link, and sanitized logs/screenshots if necessary.

Never commit authorization responses, VP tokens, private keys, real PID data, or
downloaded secrets/certificates to this repository.

## Step 4: Operate and maintain

### Durable state and lifecycle

- [x] Select and document a durable Credo/Askar storage architecture: an
  isolated verifier container and Askar PostgreSQL database on the deployment
  server, reached through a protected Firebase HTTPS proxy.
- [x] Store an application-level session record with owner, trace ID, mode,
  state, creation/update/expiry timestamps, format/type, and policy version.
- [x] Implement the states currently used by the flow: `pending`, `verified`,
  `accepted`, `expired`, and `failed`.
- [x] Deploy PostgreSQL without a published host port and attach the verifier
  only to the external `stimmapp-dev-internal` and `proxy` Docker networks.
- [x] Run the verifier as the non-root `node` user with mounted secret files.
- [x] Verify origin health, `403` without the proxy secret, `401` with the proxy
  secret but without Firebase authentication, and `401` plus the standalone
  origin marker through the public Firebase route.
- [x] Run the documented restart test during an active PID transaction, both
  before wallet approval and before profile acceptance. Completed successfully
  against the sandbox verifier on 2026-08-31.
- [ ] Add `reviewed` or `rejected` only when the product flow gives those states
  concrete behavior.
- [ ] Add TTL cleanup for session records and any temporary verification data.
- [ ] Define a minimal retention period for verification provenance with
  product/privacy stakeholders.
- [ ] Do not retain raw credentials or complete presentations unless a separately
  reviewed requirement makes that necessary.

### Logging and monitoring

- [x] Emit structured JSON events with timestamp, pseudonymous transaction ID,
  transition, invocation method, status, validation stage, and latency. The
  verifier uses a strict allowlist and random trace ID; sandbox adds only a
  safe protocol-stage enum, while production omits it.
- [x] Do not log names, addresses, birth dates, wallet identifiers, tokens,
  credentials, proofs, or complete authorization messages. The logger discards
  unallowlisted inputs and has automated coverage for that boundary.
- [ ] Categorize failures as transport, trust, protocol, cryptographic,
  disclosure, business-rule, or user cancellation.
- [ ] Define log access controls, rotation, retention, and automatic deletion.
- [ ] Monitor request creation, wallet invocation, verified-response, acceptance,
  expiry, and failure rates.
- [ ] Alert on verifier downtime, elevated validation errors, replay attempts,
  stale trust lists, and certificates nearing expiry.
- [ ] Maintain a certificate renewal, replacement, and revocation runbook.

### Deployment and recovery operations

- [x] Standalone verifier and PostgreSQL containers report healthy after the
  Firebase cutover and successful application flow.
- [x] PostgreSQL is isolated from public host ports.
- [x] The dedicated Firebase service account is restricted to
  `roles/datastore.user`; service-account key creation is disabled again at the
  project policy level.
- [x] Remove the stale `docker-credential-desktop` helper setting on the
  deployment server and prove a fresh verifier image pull/rebuild succeeds. A
  pre-change backup remains at
  `~/.docker/config.json.before-stimmapp-verifier`.
- [x] Maintain a server-local PostgreSQL backup mechanism. This provides a
  recovery point for database-level incidents, but is not independent disaster
  recovery because the backups remain on the verifier server.
- [ ] Select an encrypted, access-controlled backup destination independent of
  the verifier server, then replicate the local backups to it.
- [ ] Define backup frequency, retention, access, deletion, and ownership.
- [ ] Automate PostgreSQL backups and alert on failed or stale backups.
- [ ] Perform and record a restore drill into an isolated database before
  relying on backups operationally.
- [ ] Document verifier image rollback, secret rotation, database migration,
  and disaster-recovery procedures.

### Security and privacy review

- [ ] Threat-model the same-device and cross-device flows.
- [ ] Review endpoint authentication, authorization, replay resistance, rate
  limiting, Firebase App Check, and denial-of-service controls.
- [x] Firestore rules deny all client reads and writes to
  `pidVerificationSessions`, including the authenticated application admin.
- [x] Firestore rules prevent ordinary clients from creating, extending, or
  preserving a verified state across a verified identity-field edit.
- [ ] Complete the applicable GDPR privacy assessment and retention decisions
  before real PID data is processed.
- [ ] Document incident ownership and the Orchestrator notification path.
- [ ] Review the official ecosystem documentation and changelog on a scheduled
  cadence.

### Production transition

- [ ] Confirm the registered production legal entity, use case, technical
  contact, and operational contact.
- [ ] Obtain production Access and Registration Certificates.
- [ ] Configure the production domain, HTTPS endpoints, application links, DNS,
  secrets, and trust sources independently of sandbox.
- [ ] Verify production wallet purpose text, privacy-policy URL, and requested
  attributes against the registered use case.
- [ ] Run load, availability, cold-start, recovery, and certificate-rotation
  exercises.
- [ ] Complete the current official readiness/conformance process and retain its
  approval evidence.

## Recommended implementation order

1. Restore a server-local backup into an isolated PostgreSQL database and
   record the result. Then add encrypted replication to an independent backup
   destination to cover loss of the verifier server.
2. Add authenticated endpoint and concurrency tests for repeated acceptance,
   expiry, and cross-user access; use their results as the replay/idempotency
   evidence.
3. Add TTL cleanup for temporary session data after agreeing the minimum
   retention period for verification provenance.
4. Audit and negatively test every Credo validation on which StimmApp relies,
   then add the complete sandbox failure and cross-device test matrix.
5. Add privacy-preserving monitoring, alerting, and certificate/trust-list
   operations.
6. Complete the production security, privacy, and ecosystem readiness review.
