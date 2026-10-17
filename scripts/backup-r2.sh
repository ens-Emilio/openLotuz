#!/usr/bin/env bash
# Diário via cron.daily — dump Postgres (supabase, pretium, helio) + configs → rclone → R2
set -uo pipefail
source /opt/lotuz/.backup.env
DATE=$(date +%F_%H-%M)
DEST="r2:${R2_BUCKET}/vm/${DATE}"
LOG=/var/log/lotuz-backup.log
mkdir -p /opt/lotuz/backups

dump() {
  docker exec "$1" pg_dump -U "$2" --clean --if-exists 2>/dev/null \
    > "/opt/lotuz/backups/$3_$DATE.sql" \
    && echo "ok $3" \
    || echo "fail $3"
}

echo "[$DATE] dumping dbs" >> "$LOG"
dump supabase-db postgres supabase
dump pretium-postgres-1 pretium pretium
dump helio-selfhost-postgres-1 helio helio

tar -czf "/opt/lotuz/backups/configs_$DATE.tar.gz" \
  /opt/lotuz/crm/supabase/.env \
  /opt/lotuz/crm/atomic/.env.production \
  /etc/nginx/sites-available/crm \
  /etc/cronova/ \
  2>/dev/null

export HOME=/root
rclone sync /opt/lotuz/backups/ "$DEST" --transfers 4 >> "$LOG" 2>&1 \
  && echo "[$DATE] r2 sync ok" >> "$LOG" \
  || echo "[$DATE] r2 sync FAIL" >> "$LOG"

find /opt/lotuz/backups -type f -mtime +7 -delete
echo "[$DATE] done" >> "$LOG"