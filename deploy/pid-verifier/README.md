# PID verifier server deployment

This deployment runs only the EUDI PID verifier. It connects to the existing
PostgreSQL service over the external `stimmapp-dev-internal` Docker network and
is reachable by Traefik over the external `proxy` network.

## Runtime contract

- Image build never connects to PostgreSQL and requires no runtime secrets.
- The verifier listens on container port `8080`.
- PostgreSQL is reached as `postgres:5432` and must not publish port `5432`.
- `PID_ASKAR_POSTGRES_DATABASE` becomes Credo's Askar store/database id.
- Mounted secret files are read only when the container starts.
- All non-health HTTP requests require `x-stimmapp-verifier-proxy` to match the
  mounted proxy shared secret.
- The public verifier base URL remains
  `https://stimmapp-dev.web.app/oid4vp`; `verifier.aiomvp.com` is only the
  protected origin reached by Firebase.

## Required server files

Create `deploy/pid-verifier/secrets/` on the server. This directory is ignored
by Git. It must contain:

```text
pid-verifier-postgres-password
pid-verifier-askar-store-key
pid-verifier-proxy-shared-secret
pid-access-certificate.pem
pid-access-private-key.pem
pid-registration-certificate.json
firebase-service-account.json
```

Generate the Askar store key and proxy shared secret independently with a
cryptographically secure random generator. Never rotate the Askar store key
without first exporting or deliberately replacing its database: the existing
Askar store cannot be opened with a different key.

The Firebase service account should be dedicated to the verifier and limited
to verifying Firebase users plus the specific Firestore reads/writes required
for PID sessions and accepted user-profile fields.

## Start

Copy `docker-compose.example.yml` to a server-managed Compose file, add the
Traefik labels used by that server, and run:

```bash
docker compose build verifier
docker compose up -d verifier
docker compose ps verifier
```

The origin health endpoint is `GET /healthz`. All `/oid4vp/**` traffic must go
through the Firebase proxy and carry the shared-secret header added there.

## Firebase cutover

Use the exact contents of `secrets/pid-verifier-proxy-shared-secret` for the
Firebase `PID_VERIFIER_PROXY_SHARED_SECRET` secret without printing it:

```bash
firebase functions:secrets:set PID_VERIFIER_PROXY_SHARED_SECRET \
  --data-file secrets/pid-verifier-proxy-shared-secret \
  --project stimmapp-dev
```

Configure the non-secret function environment value:

```text
PID_VERIFIER_ORIGIN_URL=https://verifier.aiomvp.com
```

Until `PID_VERIFIER_ORIGIN_URL` is set, the Firebase function continues to run
the embedded verifier. Once it is set, the function becomes a transparent
proxy and does not initialize its local Credo/SQLite instance.
