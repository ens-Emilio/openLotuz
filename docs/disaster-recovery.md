# Backup, restore and VM hardening

The runbook is intentionally split between repository preparation and VM rollout. The public repo contains no live credentials. Do not run the commands until values are set locally on the VM.

## Backup encryption setup

Install `age` and create a keypair on the VM:

```bash
apt-get update && apt-get install -y age
install -d -m 0700 /root/.config/age
age-keygen -o /root/.config/age/lotuz-backup.txt
chmod 600 /root/.config/age/lotuz-backup.txt
age-keygen -y /root/.config/age/lotuz-backup.txt
```

Store the printed recipient in `/opt/lotuz/.backup.env` as `BACKUP_AGE_PUBLIC_KEY`. Keep the identity file private and outside R2/repo; set `BACKUP_AGE_IDENTITY=/root/.config/age/lotuz-backup.txt` for restore tests. Save an offline copy of that identity in a password manager. Without the identity, encrypted dumps cannot be restored.

Optional Healthchecks.io: create a private check and set `HEALTHCHECK_URL=https://hc-ping.com/<UUID>` in `/opt/lotuz/.backup.env`. The backup script sends `/start`, success, and `/fail` pings. Never commit that URL.

Install the updated backup script to `/opt/lotuz/backup-r2.sh`, mode `0700`. It requires `age` and `BACKUP_AGE_PUBLIC_KEY`; it exits rather than upload plaintext. Then run once and check:

```bash
/opt/lotuz/backup-r2.sh
rclone lsf "r2:${R2_BUCKET}/vm/" --dirs-only
```

## Weekly restore drill

Copy `scripts/restore-test.sh` to `/opt/lotuz/restore-test.sh`, mode `0700`. Schedule it after the daily backup:

```cron
30 5 * * 0 root /opt/lotuz/restore-test.sh >> /var/log/lotuz-restore-test.log 2>&1
```

The drill downloads the newest R2 directory, decrypts the Supabase custom-format dump, validates its archive, restores it into an ephemeral Postgres container, and deletes the container. It does not overwrite production data. A Healthchecks failure ping is sent if the run fails.

## Cloudflare Access and Uptime Kuma

The repo's Cloudflare example includes `kuma.example.com` on loopback port `3010`. Deploy Uptime Kuma only bound to `127.0.0.1:3010`, then configure a Cloudflare Access self-hosted application and an allow policy for administrator identities **before** adding the DNS route. Do not publish Kuma unauthenticated. Add the ingress to `/etc/cloudflared/config.yml`, validate the config, restart `cloudflared`, then test both the Access login gate and a monitor check.

## Cronova secure cookie

Set `secure_cookie: true` under `auth` in `/etc/cronova/cronova.yaml`, then restart and verify the login flow through the HTTPS hostname:

```bash
cp -a /etc/cronova/cronova.yaml /etc/cronova/cronova.yaml.bak.$(date +%F-%H%M%S)
# edit secure_cookie: true
systemctl restart cronova
systemctl is-active cronova
```

## Firewall audit

Docker-published ports bypass ordinary UFW INPUT rules on many setups. This VM currently has public Docker bindings for Supabase Kong `8000`, Supavisor `5432/6543`, and another service on `80`; UFW is inactive. Do not enable UFW blindly: first ensure SSH on `22` stays allowed and add Docker-aware filtering. Preferred correction is to bind Supabase Kong and pooler to `127.0.0.1`, keep origins behind Cloudflare Tunnel, and allow only required inbound SSH from a trusted source. Verify from an external host that `8000`, `5432`, and `6543` are unreachable before considering this complete.

## Recovery outline

1. Provision a clean supported Ubuntu VM and install Docker, `age`, `rclone`, `cloudflared`, and the services.
2. Restore `.env` and Cloudflare credentials from the separate encrypted/offline copy; never source credentials from this repo.
3. Download the latest encrypted R2 backup and decrypt with the age identity.
4. Start the target Postgres and restore using `pg_restore --clean --if-exists --no-owner --no-privileges` after reviewing the dump/target.
5. Restore service configs and app data, then validate service health locally.
6. Reattach the Tunnel, confirm Cloudflare Access policies, and verify public health checks.

A full-time recovery target is not claimed until this procedure has been timed successfully on a clean VM and the supporting service data/configs are all backed up.
