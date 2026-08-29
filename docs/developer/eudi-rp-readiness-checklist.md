# EUDI Wallet Relying Party Readiness Checklist

Last reviewed: 2026-08-29

This document tracks StimmApp's German EUDI Wallet relying-party integration
from sandbox prototype to an operationally safe implementation. It follows the
official German EUDI Wallet RP integration sequence and the validation layers
described by the German PID presentation guide.

This is an engineering readiness record, not a legal or compliance approval.

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
- [x] Session ownership and lifecycle metadata are persisted privately in
  Firestore with a random trace ID and without PID claims or wallet payloads.
- [ ] Verification survives a Cloud Functions/Cloud Run instance replacement.
  Application ownership and lifecycle records are durable, but Credo's Askar
  protocol records remain instance-local.
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
- [ ] Document when verification is mandatory versus optional.
- [ ] Define the re-verification trigger and validity period.
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
- [x] Access Certificate and matching P-256 private key are stored as Firebase
  function secrets rather than in source control.
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
- [ ] Persist the Credo/Askar protocol store outside Cloud Run `/tmp`.
- [ ] Remove `maxInstances: 1` as a correctness dependency after durable storage
  is implemented.
- [ ] Make each successful presentation and acceptance single-use.
- [ ] Make acceptance idempotent without refreshing verification timestamps on
  repeated requests.
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
- [ ] Reconcile `pidVerificationRequestPreview`: it currently lists
  `address.region`, while the actual DCQL request does not request that claim.
- [ ] Review the requested claim set whenever petition eligibility rules change.

### Layer 6: StimmApp business rules

- [x] Original EUDI claim text is displayed without normalization.
- [x] A separately normalized representation is used for comparison and profile
  formatting.
- [x] Profile data changes only after explicit user acceptance.
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
- [ ] Store only necessary provenance, such as verification time, issuer,
  credential type, verified fields, and policy/version used.
- [ ] Define which profile fields may be overwritten and preserve unrelated
  user-entered data.

## Responsibility boundary

| Concern | Current owner | Readiness action |
| --- | --- | --- |
| OpenID4VP request and response processing | Credo | Document and negatively test each relied-on validation |
| Protocol keys and records | Credo + Askar | Replace instance-local SQLite with a durable supported store |
| Access and Registration Certificates | Firebase secrets + Credo | Add expiry monitoring and rotation runbook |
| PID issuer trust | StimmApp trust-list loader + Credo X.509 | Test freshness, chain, outage, and untrusted issuer cases |
| Session-to-user authorization | StimmApp backend + Firestore | Durable; add emulator authorization and lifecycle tests |
| Attribute normalization and profile formatting | StimmApp backend | Expand unit tests; never alter the displayed original values |
| Profile comparison UX | Flutter app | Localize, improve accessibility, and test all result states |
| Eligibility/business decision | Not yet formalized | Specify and enforce authoritatively on the backend |
| Consent to update the profile | Flutter + authenticated backend endpoint | Make acceptance single-use, idempotent, and auditable |

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
- [ ] Test that another Firebase user cannot read or accept a session.
- [ ] Test repeated acceptance, expired sessions, and deleted users.
- [ ] Test a simulated function restart between start, wallet response, status,
  and acceptance.
- [ ] Test concurrent sessions for the same user and different users.

### Wallet interoperability tests

- [x] Manually complete one same-device SD-JWT PID happy path.
- [x] Manually receive, display, compare, and explicitly accept verified PID
  details in StimmApp.
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

- [ ] Select and document a durable Credo/Askar storage architecture.
- [x] Store an application-level session record with owner, trace ID, mode,
  state, creation/update/expiry timestamps, format/type, and policy version.
- [x] Implement the states currently used by the flow: `pending`, `verified`,
  `accepted`, `expired`, and `failed`.
- [ ] Add `reviewed` or `rejected` only when the product flow gives those states
  concrete behavior.
- [ ] Add TTL cleanup for session records and any temporary verification data.
- [ ] Define a minimal retention period for verification provenance with
  product/privacy stakeholders.
- [ ] Do not retain raw credentials or complete presentations unless a separately
  reviewed requirement makes that necessary.

### Logging and monitoring

- [ ] Emit structured JSON events with timestamp, pseudonymous transaction ID,
  transition, invocation method, status, validation stage, and latency.
- [ ] Do not log names, addresses, birth dates, wallet identifiers, tokens,
  credentials, proofs, or complete authorization messages.
- [ ] Categorize failures as transport, trust, protocol, cryptographic,
  disclosure, business-rule, or user cancellation.
- [ ] Define log access controls, rotation, retention, and automatic deletion.
- [ ] Monitor request creation, wallet invocation, verified-response, acceptance,
  expiry, and failure rates.
- [ ] Alert on verifier downtime, elevated validation errors, replay attempts,
  stale trust lists, and certificates nearing expiry.
- [ ] Maintain a certificate renewal, replacement, and revocation runbook.

### Security and privacy review

- [ ] Threat-model the same-device and cross-device flows.
- [ ] Review endpoint authentication, authorization, replay resistance, rate
  limiting, Firebase App Check, and denial-of-service controls.
- [ ] Verify Firestore rules do not expose verification sessions or provenance.
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

1. Finalize the use-case, attribute, purpose, mismatch, and re-verification rules.
2. Add durable Credo storage. Session ownership/lifecycle records are already
   durable in Firestore.
3. Make acceptance single-use and idempotent; separate verification evidence
   from the mutable profile.
4. Audit and negatively test every Credo validation on which StimmApp relies.
5. Add the complete sandbox failure and cross-device test matrix.
6. Add privacy-preserving observability and certificate/trust-list operations.
7. Complete the production security, privacy, and ecosystem readiness review.
