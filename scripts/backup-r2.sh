#!/usr/bin/env bash
# Daily encrypted PostgreSQL dumps + configs to R2.
set -euo pipefail
source /opt/lotuz/.backup.env
: "${R2_BUCKET:?R2_BUCKET is required}"
: "${BACKUP_AGE_PUBLIC_KEY:?BACKUP_AGE_PUBLIC_KEY is required; refusing plaintext backup}"
command -v age >/dev/null 2>&1 || { echo "age is required" >&2; exit 1; }
DATE=$(date +%F_%H-%M)
DEST="r2:${R2_BUCKET}/vm/${DATE}"
LOG=/var/log/lotuz-backup.log
BACKUPS=/opt/lotuz/backups
RUN_DIR="$BACKUPS/$DATE"
export HOME=/root
mkdir -p "$RUN_DIR"

ping_healthcheck() {
  local suffix=${1:-}
  [[ -n "${HEALTHCHECK_URL:-}" ]] || return 0
  curl -fsS -m 10 --retry 2 "${HEALTHCHECK_URL}${suffix}" >/dev/null 2>&1 || true
}

fail() {
  echo "[$DATE] FAIL: $*" >> "$LOG"
  ping_healthcheck /fail
  exit 1
}

dump() {
  local container=$1 user=$2 name=$3 out="$RUN_DIR/$3.dump"
  if ! docker exec "$container" pg_dump -U "$user" --format=custom --clean --if-exists > "$out" 2>>"$LOG"; then
    fail "pg_dump failed: $name"
  fi
  [[ -s "$out" ]] || fail "empty dump: $name"
  echo "[$DATE] dump ok: $name" >> "$LOG"
}

echo "[$DATE] backup started" >> "$LOG"
ping_healthcheck /start
dump supabase-db postgres supabase
dump pretium-postgres-1 pretium pretium
dump helio-selfhost-postgres-1 helio helio

tar -czf "$RUN_DIR/configs.tar.gz" \
  /opt/lotuz/crm/supabase/.env \
  /opt/lotuz/crm/atomic/.env.production \
  /opt/lotuz/.backup.env \
  /root/.config/rclone/rclone.conf \
  /var/lib/cronova/ \
  /opt/lotuz/uptime-kuma/ \
  /etc/nginx/sites-available/crm \
  /etc/cloudflared/config.yml \
  /etc/cronova/ 2>>"$LOG" || fail "config archive failed"

# Encrypt every remaining plaintext backup too, so pre-rollout files cannot leak via this run.
while IFS= read -r -d '' f; do
  age -r "$BACKUP_AGE_PUBLIC_KEY" -o "$f.age" "$f" 2>>"$LOG" || fail "age encryption failed: $(basename "$f")"
  rm -f "$f"
done < <(find "$BACKUPS" -type f \( -name '*.dump' -o -name '*.sql' -o -name '*.tar.gz' \) -print0)

rclone lsf "r2:${R2_BUCKET}/vm/" --dirs-only > /tmp/lotuz-r2-dirs.txt 2>>"$LOG" || fail "cannot list R2 backup prefix"
LATEST=$(sort /tmp/lotuz-r2-dirs.txt | tail -n 1 | tr -d '/')
if [[ -n "$LATEST" ]]; then
  LATEST_EPOCH=$(date -d "${LATEST%_*} ${LATEST#*_}" +%s 2>/dev/null || true)
  if [[ -n "$LATEST_EPOCH" ]] && (( $(date +%s) - LATEST_EPOCH > 48 * 3600 )); then
    echo "[$DATE] ALERT: latest R2 backup is older than 48 hours: $LATEST" >> "$LOG"
    [[ -n "${BACKUP_ALERT_URL:-}" ]] && curl -fsS -m 10 "$BACKUP_ALERT_URL" >/dev/null 2>&1 || true
  fi
else
  echo "[$DATE] no previous backup directory in R2" >> "$LOG"
  [[ -n "${BACKUP_ALERT_URL:-}" ]] && curl -fsS -m 10 "$BACKUP_ALERT_URL" >/dev/null 2>&1 || true
fi

rclone copy "$RUN_DIR/" "$DEST" --transfers 4 >>"$LOG" 2>&1 || fail "R2 copy failed"
echo "[$DATE] r2 copy ok: $DEST" >> "$LOG"
ping_healthcheck
find "$BACKUPS" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} +
echo "[$DATE] backup completed" >> "$LOG"
