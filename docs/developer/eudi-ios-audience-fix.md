# EUDI iOS request audience fix

## Diagnosis and scope

The iOS wallet log on 2026-09-21 at 17:04:35 CEST shows that it downloaded the
StimmApp signed authorization request with HTTP 200, then rejected its `aud`
claim: `Invalid aud value, should be: https://self-issued.me/v2`.

The locked Credo 0.7.0 request builder delegates to
`@openid4vc/openid4vp` 0.4.6 without supplying an audience override. That library
defaults the signed request audience to its request URI. The expired live
requests returned 404 when inspected later, so their actual payloads could not
be independently decoded. The log and locked dependency source identify the
failure path; deployment verification must confirm the corrected live payload.

**No database migration or manual database edits are needed.** Do not modify
Firestore profiles, verification evidence, PostgreSQL records, certificates,
or existing signed requests. Newly created requests must contain the correct
audience before signing and persistence. Old pending requests should expire
normally; testing must start a new request after deployment.

References:
- [German PID presentation guide](https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/rp/guide/presentation/pid_presentation/)
- [OpenID4VP request audience, section 5.8](https://openid.net/specs/openid-4-verifiable-presentations-1_0-final.html#section-5.8)

## Implementation strategy

1. Inspect the installed-version APIs and current upstream releases. Prefer a
   supported request-construction option or a narrowly scoped dependency fix.
   Avoid global runtime monkey-patching or rewriting an already signed JWT.
2. Ensure this static-discovery flow signs the string audience
   `https://self-issued.me/v2`. Preserve nonce, state, expiry, client ID,
   certificates, DCQL, response URI, encryption, and response verification.
   In particular, the **response** audience remains the verifier client ID.
3. Add a regression test against actual request generation and verify the
   signed JWT cryptographically. Include request-URI independence and preserve
   any explicitly supplied audience for other discovery flows.
4. Compile TypeScript and run the backend tests/lint. Verify a clean dependency
   installation applies the correction in both local and Docker builds.

## Dev rollout

1. Identify the current deployed image/commit and retain it for rollback.
2. Rebuild and replace only the standalone **dev verifier** container using the
   existing deployment procedure. Keep the PostgreSQL volume and all secrets.
   The Firebase proxy only needs deployment if its code/configuration changes.
3. Check container health and the authenticated proxy boundary. Create a fresh
   request through the signed-in dev app. Inspect only its audience and safe
   protocol metadata; do not retain tokens, claims, or request URLs in reports.
4. On iPhone, verify wallet request display, approval, return, session recovery,
   and explicit profile acceptance. Repeat the happy path on Android.
5. Confirm expired/cancelled requests cannot verify a profile. Record app,
   wallet, and backend versions and sanitized outcomes in the readiness record.

Local validation commands (Node 22):

```sh
cd functions
npm ci
npm test
npm run lint
```

On the dev host, after updating the checkout to the reviewed change, use the
existing server-managed Compose file under `deploy/pid-verifier`:

```sh
docker compose images verifier  # record the current image before replacement
docker compose build verifier
docker compose up -d --no-deps verifier
docker compose ps verifier
```

Keep/tag the current image before building so it is still available for
rollback. Do not run `down -v`. The Docker build now runs the backend tests,
including the native request-audience regression, before producing the runtime
image. These tests use in-memory SQLite, not the deployed PostgreSQL database.

## Acceptance and rollback

Complete only when a newly signed request has the expected audience, iOS
passes the previous failure point and completes verification, and Android
still completes its flow. Passing unit tests alone is insufficient.

If deployment fails or interoperability regresses, restore the previous dev
verifier image with the same database and secrets. No data rollback is needed
for this request-generation change. Start fresh sessions after either rollout.

## Progress

- [x] Identify the wallet validation failure and dependency default.
- [x] Establish that database edits/migration are unnecessary.
- [x] Implement and test the request-construction correction using stable
  upstream releases: pin the four Credo packages to 0.7.1, whose locked
  OpenID4VP dependency is 0.5.6. No custom patch or audience override is needed.
- [x] Validate clean installation and backend checks locally on Node 22.
- [x] Deploy to the standalone dev verifier and inspect a fresh request.
- [ ] Complete physical-iPhone and Android acceptance tests.

Deployment currently requires access to the verifier host; the local Firebase
CLI was also unauthenticated during diagnosis. Resolve access before rollout,
without copying secrets into the repository.

### Dev deployment — 2026-09-22

- Deployed checkout `2482249f` to the standalone dev verifier at
  `verifier.aiomvp.com`; runtime image `41a4ea4bd489`, Credo 0.7.1.
- Built with the updated lockfile and Dockerfile. Used
  `DOCKER_BUILDKIT=0 docker compose build verifier` because the host's Buildx
  plugin was missing. All 11 backend tests passed during the build.
- Replaced only the verifier with `docker compose up -d --no-deps verifier`.
  Existing secrets and PostgreSQL storage were preserved; no manual database
  changes or Firebase Functions deployment were performed.
- Container healthy; origin health returned 200. Origin without the proxy
  secret returned 403; with the proxy secret but no Firebase token returned
  401. The public Firebase proxy also returned 401 with the standalone-origin
  marker.
- Generated a fresh request through the deployed Credo API using the deployed
  request options and existing signing configuration, then fetched it through
  the public Firebase proxy. HTTP 200, standalone-origin marker present,
  `aud` exactly `https://self-issued.me/v2`, signature verified, request unexpired,
  and response mode `direct_post.jwt`. This probe did not exercise signed-in
  app request creation or wallet completion; no user profile was changed.
- Retained the previous image `2efa3e638fd9` as
  `stimmapp-pid-verifier:rollback-pre-ios-audience-20260922`. To roll back, tag
  that image as `stimmapp-pid-verifier:latest`, then run
  `docker compose up -d --no-deps verifier` from the deployment directory.
- Physical iPhone and Android acceptance remain pending. Start a new app
  verification request for these tests.

### Evidence and limits

- Clean `npm ci` succeeded with the new lockfile.
- `npm test`: TypeScript build and all 11 backend tests passed. `npm run lint`
  and `git diff --check` passed.
- Credo's framework storage migration registry is byte-identical between
  0.7.0 and 0.7.1; this upgrade introduces no framework storage migration.
- Signed-request tests verify the audience, cryptographic signature, protocol
  fields, expiry, and independence from the request URL; explicit audience
  overrides continue to work.
- Native integration test creates a Credo agent, imports an ephemeral P-256
  key, creates an X.509 certificate, signs a request, persists it in Askar, and
  verifies the signature and audience of the record read back from storage.
- This Mac has no Docker executable, so the Docker build gate must also run on
  the deployment host. Local native tests are not PostgreSQL rollout evidence.
- Live deployment and a fresh signed-request check are recorded above; wallet
  success and Android regression results remain unverified.
