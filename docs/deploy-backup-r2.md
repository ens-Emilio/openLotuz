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
## 4. Criptografar backups e configurar alertas

Instale `age` na VM e gere uma chave:

```bash
apt-get update && apt-get install -y age
install -d -m 0700 /root/.config/age
age-keygen -o /root/.config/age/lotuz-backup.txt
chmod 600 /root/.config/age/lotuz-backup.txt
age-keygen -y /root/.config/age/lotuz-backup.txt
```

Guarde a identidade (`lotuz-backup.txt`) fora da VM e do R2, em um cofre. A chave pública exibida por `age-keygen -y` pode ser usada pelo job de backup. Sem a identidade privada, os arquivos criptografados são irrecuperáveis.

Adicione a `/opt/lotuz/.backup.env` (modo `0600`):

```bash
R2_BUCKET=SEU_BUCKET
BACKUP_AGE_PUBLIC_KEY=age1...
BACKUP_AGE_IDENTITY=/root/.config/age/lotuz-backup.txt
# opcional: UUID privado criado no Healthchecks.io
HEALTHCHECK_URL=https://hc-ping.com/SEU_UUID
# opcional: ping dedicado para alerta de backup antigo
BACKUP_ALERT_URL=https://hc-ping.com/SEU_UUID_ALERTA
```

Copie `scripts/backup-r2.sh` para `/opt/lotuz/backup-r2.sh` e dê permissão `0700`. O script falha fechado: se `age` ou a chave pública faltarem, nenhum backup é enviado sem criptografia.

## 5. Script de backup

## 6. Restore drill semanal

Copie `scripts/restore-test.sh` para `/opt/lotuz/restore-test.sh` e rode primeiro manualmente:

```bash
chmod 0700 /opt/lotuz/restore-test.sh
/opt/lotuz/restore-test.sh
```

Agende no domingo às 05:30 UTC, após o backup diário:

```cron
30 5 * * 0 root /opt/lotuz/restore-test.sh >> /var/log/lotuz-restore-test.log 2>&1
```

O teste baixa o dump mais recente, descriptografa, valida e restaura em Postgres temporário. Não altera bancos de produção.

## 7. Retenção no R2 (Lifecycle)

Dashboard R2 → Bucket `SEU_BUCKET` → Settings → Object Lifecycle Rules:
- **Delete objects after 30 days**

## 8. Testar manualmente

```bash
/opt/lotuz/backup-r2.sh
/opt/lotuz/restore-test.sh
rclone lsf "r2:SEU_BUCKET/vm/" --dirs-only
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
