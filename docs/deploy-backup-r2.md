# Backup no Cloudflare R2

Backup diário dos bancos PostgreSQL (Supabase, Pretium, Helio) + configs essenciais → Cloudflare R2 (10 GB grátis, zero egress).

## 1. Criar bucket no R2

Dashboard Cloudflare → R2 → Create bucket → `SEU_BUCKET` (região: Auto).

> Exemplo: `lotuz-backup` — substitua pelo seu bucket real.

## 2. Criar API Token R2

R2 → Manage API Tokens → Create API token:
- Permissions: Object Read & Write
- Bucket: `SEU_BUCKET`
- TTL: None (ou conforme sua política)

Anote:
- `Access Key ID`
- `Secret Access Key`
- `Account ID` (ex: `SEU_ACCOUNT_ID`)

## 3. Configurar rclone na VM

```bash
# Instalar rclone
curl -s https://rclone.org/install.sh | bash

# Configurar remote 'r2'
rclone config create r2 s3 \
  provider=Cloudflare \
  access_key_id=<ACCESS_KEY_ID> \
  secret_access_key=<SECRET_ACCESS_KEY> \
  endpoint=https://<ACCOUNT_ID>.r2.cloudflarestorage.com \
  acl=private \
  no_check_bucket=true

# Testar
rclone lsd r2:
```

## 4. Script de backup

`/opt/lotuz/backup-r2.sh` (já instalado na VM):

```bash
#!/usr/bin/env bash
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
```

## 5. Variáveis de ambiente

`/opt/lotuz/.backup.env` (chmod 600):

```bash
R2_BUCKET=SEU_BUCKET
```

## 6. Cron diário (03:00 UTC)

```bash
ln -sf /opt/lotuz/backup-r2.sh /etc/cron.daily/lotuz-backup
```

## 7. Retenção no R2 (Lifecycle)

Dashboard R2 → Bucket `SEU_BUCKET` → Settings → Object Lifecycle Rules:
- **Delete objects after 30 days**

Com dumps diários ~10-50 MB cada, o bucket fica bem dentro dos 10 GB grátis.

## 8. Testar manualmente

```bash
/opt/lotuz/backup-r2.sh
# Ver log
tail -f /var/log/lotuz-backup.log

# Ver no R2
rclone lsd r2:SEU_BUCKET/vm/
```
