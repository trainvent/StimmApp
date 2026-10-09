# Dev PID registration-certificate fix — 2026-10-09

## Source and runtime

- Server checkout base: `18fb637a4cf446a6c43cfbdcbca8d0430004da6c`, plus the uncommitted request fix and regression in this checkout.
- Actual Compose project: `/opt/homeserver/stimmapp/deploy/pid-verifier/docker-compose.yml`.
- Previous image: `sha256:fddb3c5f15555debdbb3d99ef08796b949517ea6e89bdeabfec3916c5d6266f4`. It has no revision label; its source revision cannot be established from image metadata.
- Deployed image: `sha256:4ebb5b25fa70a4a57b739e861e2b95b9c5ace70678950553c798f0f21eb757e2` (`stimmapp-pid-verifier:latest`).
- Running Node: 22.23.2; installed Credo OpenID4VC: 0.7.1.

## Change and validation

Removed `credential_ids` from the `registration_cert` verifier-info entry.
Extracted the existing authorization-request construction into
`createPidAuthorizationRequest`, called by both the production session flow
and the existing real Credo X.509/Askar regression. The test decodes the signed,
persisted request and checks the registration format/data, absence of
`credential_ids`, and the complete unchanged DCQL credential selection and seven
claims. Existing signature, audience, client-ID, response-mode, nonce and state
checks remain. Test credentials are ephemeral; no real protocol payloads were
printed.

- `npm test`: 25 passed, 0 failed, in the Node 22 Docker build.
- `npm run lint`: passed using the same build dependency layer in an isolated Node 22 container.
- `git diff --check`: passed.
- Rebuilt via actual Compose configuration and replaced only `verifier` with `up -d --no-deps`.
- Buildx is missing on this host; `DOCKER_BUILDKIT=0` enabled the installed legacy Docker builder.
- Existing `smoke-test.sh` passed with `PID_VERIFIER_PUBLIC_BASE_URL=https://stimmapp-dev.web.app/oid4vp` and `DOCKER_BUILDKIT=0`.
- Container healthy; Credo initialized against PostgreSQL; non-root, no published host ports, expected networks.
- Origin health: HTTP 200 with server marker.
- Origin without proxy secret: HTTP 403.
- Origin with proxy secret but no Firebase bearer token: HTTP 401.
- Public Firebase proxy: HTTP 401 with server marker, proving traversal to standalone origin.

No Firebase redeploy was needed. PostgreSQL, mounted secrets, Askar store key,
and user profiles were preserved.

## Rollback

Retained image: `stimmapp-pid-verifier:rollback-20261009-registration-cert`.
From the actual Compose project directory:

```bash
docker tag stimmapp-pid-verifier:rollback-20261009-registration-cert stimmapp-pid-verifier:latest
docker compose up -d --no-deps --no-build verifier
docker compose ps verifier
```

Repeat health/auth checks after rollback. Do not run the existing smoke script
unchanged during rollback: it rebuilds the current checkout and would replace
the retained image again.

## Device acceptance pending

Start fresh sessions; previously signed requests retain the rejected field.
The user must confirm updated Android reaches consent without
`MalformedRegistrationCertificate`, completes presentation, returns verified
details, and persists them only after explicit acceptance. Repeat on iOS and
check cancellation/expiry rejection. No physical-device outcomes are claimed.
