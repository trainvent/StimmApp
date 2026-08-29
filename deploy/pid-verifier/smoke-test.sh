#!/usr/bin/env bash
set -euo pipefail

compose_file="${COMPOSE_FILE:-docker-compose.yml}"
origin_url="${PID_VERIFIER_ORIGIN_URL:-https://verifier.aiomvp.com}"
public_base_url="${PID_VERIFIER_PUBLIC_BASE_URL:-}"
proxy_secret_file="${PID_VERIFIER_PROXY_SHARED_SECRET_FILE:-./secrets/pid-verifier-proxy-shared-secret}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

expect_status() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  [[ "$actual" == "$expected" ]] || fail "$label returned HTTP $actual; expected $expected"
  echo "ok: $label"
}

has_origin_marker() {
  local header_file="$1"
  local line
  while IFS= read -r line; do
    line="${line%$'\r'}"
    [[ "${line,,}" == "x-stimmapp-verifier-origin: server" ]] && return 0
  done <"$header_file"
  return 1
}

[[ -f "$compose_file" ]] || fail "Compose file not found: $compose_file"
[[ -f "$proxy_secret_file" ]] || fail "Proxy secret file not found: $proxy_secret_file"

docker network inspect stimmapp-dev-internal >/dev/null
docker network inspect proxy >/dev/null
docker compose --file "$compose_file" config --quiet
echo "ok: external networks and Compose configuration"

docker compose --file "$compose_file" build verifier
docker compose --file "$compose_file" up --detach verifier

container_id="$(docker compose --file "$compose_file" ps --quiet verifier)"
[[ -n "$container_id" ]] || fail "Verifier container was not created"

health=""
for _ in $(seq 1 60); do
  health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id")"
  [[ "$health" == "healthy" ]] && break
  [[ "$health" == "exited" || "$health" == "dead" ]] && break
  sleep 2
done
[[ "$health" == "healthy" ]] || {
  docker compose --file "$compose_file" logs --tail 100 verifier >&2
  fail "Verifier did not become healthy (state: $health)"
}
echo "ok: verifier initialized Credo and connected to PostgreSQL"

container_user="$(docker inspect --format '{{.Config.User}}' "$container_id")"
[[ "$container_user" == "node" ]] || fail "Verifier is not running as the node user"
[[ -z "$(docker port "$container_id")" ]] || fail "Verifier publishes a host port unexpectedly"

internal_network="$(docker inspect --format '{{with index .NetworkSettings.Networks "stimmapp-dev-internal"}}attached{{end}}' "$container_id")"
proxy_network="$(docker inspect --format '{{with index .NetworkSettings.Networks "proxy"}}attached{{end}}' "$container_id")"
[[ "$internal_network" == "attached" ]] || fail "Verifier is not on stimmapp-dev-internal"
[[ "$proxy_network" == "attached" ]] || fail "Verifier is not on proxy"
echo "ok: non-root container and isolated network attachment"

health_headers="$(mktemp)"
trap 'rm -f "$health_headers" "$origin_headers" "$public_headers"' EXIT
origin_headers="$(mktemp)"
public_headers="$(mktemp)"

health_status="$(curl --silent --show-error --output /dev/null --dump-header "$health_headers" --write-out '%{http_code}' "$origin_url/healthz")"
expect_status "200" "$health_status" "origin health endpoint"
has_origin_marker "$health_headers" || fail "Origin marker header is missing"

unauthorized_status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' "$origin_url/oid4vp/status/smoke-test")"
expect_status "403" "$unauthorized_status" "origin request without proxy secret"

proxy_secret="$(<"$proxy_secret_file")"
exec 3< <(printf 'header = "x-stimmapp-verifier-proxy: %s"\n' "$proxy_secret")
protected_status="$(curl --silent --show-error --config /dev/fd/3 --output /dev/null --dump-header "$origin_headers" --write-out '%{http_code}' "$origin_url/oid4vp/status/smoke-test")"
exec 3<&-
unset proxy_secret
expect_status "401" "$protected_status" "protected origin route without Firebase bearer token"

if [[ -n "$public_base_url" ]]; then
  public_status="$(curl --silent --show-error --output /dev/null --dump-header "$public_headers" --write-out '%{http_code}' "$public_base_url/status/smoke-test")"
  expect_status "401" "$public_status" "Firebase public proxy route"
  has_origin_marker "$public_headers" ||
    fail "Firebase response did not traverse the standalone verifier origin"
  echo "ok: Firebase proxy reached the standalone origin"
else
  echo "skip: set PID_VERIFIER_PUBLIC_BASE_URL=https://stimmapp-dev.web.app/oid4vp after Firebase cutover"
fi

echo "PID verifier infrastructure smoke test passed."
