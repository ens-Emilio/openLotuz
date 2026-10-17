#!/usr/bin/env bash
# Restore the newest encrypted Supabase dump from R2 into a temporary Postgres container.
set -euo pipefail
source /opt/lotuz/.backup.env
: "${R2_BUCKET:?R2_BUCKET is required}"
: "${BACKUP_AGE_IDENTITY:?BACKUP_AGE_IDENTITY path is required}"
[[ -r "$BACKUP_AGE_IDENTITY" ]] || { echo "age identity is unreadable" >&2; exit 1; }
export HOME=/root
TMP=$(mktemp -d /tmp/lotuz-restore.XXXXXX)
CONTAINER="lotuz-restore-test-$$"
cleanup() { docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; rm -rf "$TMP"; }
trap cleanup EXIT
fail() {
  echo "restore-test: FAIL: $*" >&2
  [[ -n "${HEALTHCHECK_URL:-}" ]] && curl -fsS -m 10 "${HEALTHCHECK_URL}/fail" >/dev/null 2>&1 || true
  exit 1
}

rclone lsf "r2:${R2_BUCKET}/vm/" --dirs-only > "$TMP/dirs" || fail "cannot list R2"
LATEST=$(sort "$TMP/dirs" | tail -n 1 | tr -d '/')
[[ -n "$LATEST" ]] || fail "R2 has no backup directories"
rclone copy "r2:${R2_BUCKET}/vm/${LATEST}" "$TMP/backup" || fail "download failed"

ENCRYPTED=$(find "$TMP/backup" -maxdepth 1 -type f -name 'supabase.dump.age' -print -quit)
[[ -n "$ENCRYPTED" ]] || fail "latest directory has no encrypted Supabase dump"
age -d -i "$BACKUP_AGE_IDENTITY" -o "$TMP/supabase.dump" "$ENCRYPTED" || fail "decryption failed"
docker run -d --rm --name "$CONTAINER" -e POSTGRES_PASSWORD=restore-test supabase/postgres:17.6.1.136 >/dev/null || fail "cannot start temporary Supabase Postgres"
for _ in $(seq 1 180); do
  STATUS=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$CONTAINER" 2>/dev/null || true)
  [[ "$STATUS" == "healthy" ]] && break
  [[ "$STATUS" == "exited" ]] && fail "temporary Supabase Postgres exited during initialization"
  sleep 1
done
[[ "$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null)" == "healthy" ]] || fail "temporary Supabase Postgres did not become healthy"
docker exec "$CONTAINER" pg_isready -U postgres >/dev/null 2>&1 || fail "temporary Postgres not ready"
docker exec -i "$CONTAINER" pg_restore --list < "$TMP/supabase.dump" > "$TMP/toc" || fail "dump is not a valid pg_dump archive"
grep -q 'TABLE DATA' "$TMP/toc" || fail "archive contains no table data entries"
docker exec "$CONTAINER" createdb -U supabase_admin restore_test || fail "cannot create temporary restore database"
docker exec -i "$CONTAINER" pg_restore -U supabase_admin --dbname=restore_test --exit-on-error --no-owner --no-privileges < "$TMP/supabase.dump" >/dev/null 2>"$TMP/restore.log" || fail "pg_restore failed: $(head -n 8 "$TMP/restore.log" | tr '\n' ' ')"


[[ -n "${HEALTHCHECK_URL:-}" ]] && curl -fsS -m 10 --retry 2 "$HEALTHCHECK_URL" >/dev/null 2>&1 || true
echo "restore-test: PASS ($LATEST)"
