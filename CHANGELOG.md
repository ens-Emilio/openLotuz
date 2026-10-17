# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-14

### Added
- **CRM**: Atomic CRM (marmelab/atomic-crm) self-hosted over Supabase (12 containers)
- **Flow**: Cronova (MIT) replacing n8n (fair-code) — automation engine
- **SDR**: AgentSDR — sales agent automation
- **WhatsApp**: OpenWA (MIT) — WhatsApp Business API gateway
- **Marketing**: Helio selfhost — email marketing & campaigns
- **AI Gateway**: Hermes Agent (NousResearch/hermes-agent, MIT)
  - TUI/CLI local (`hermes`)
  - Discord gateway bot (`Hermes Agent`)
  - Custom skills: `lotuz-crm`, `lotuz-sdr`, `lotuz-wa`, `lotuz-mkt`
- **Backup**: Daily PostgreSQL dumps + configs → Cloudflare R2 via rclone (cron.daily)
- **Network**: Cloudflare Tunnel (no public IP) + proxied DNS `*.example.com`
- **Documentation**:
  - `docs/deploy-tunnel.md` — Cloudflare Tunnel via API
  - `docs/deploy-supabase.md` — Supabase self-host + Atomic CRM
  - `docs/deploy-backup-r2.md` — R2 backup with lifecycle
- **Scripts**:
  - `scripts/backup-r2.sh` — automated backup
  - `scripts/lotuz-crm.py` — CRM queries via PostgREST
  - `scripts/lotuz-wa.py` — WhatsApp sending via OpenWA
  - `scripts/lotuz-mkt.py` — Campaign management via Helio
  - `scripts/lotuz-sdr.py` — SDR sequences/messages
- **License**: Apache-2.0 (root level)
- **Security**: Robust `.gitignore` preventing secrets leakage; GitHub Actions workflow for secrets scanning

### Infrastructure
- VM: ShardCloud Core + add-on RAM
- Zero extra cost beyond existing VM
- All services healthy: containers + public endpoints via Tunnel

### Security Notes
- All secrets in `.env` files (ignored by git)
- Hermes `.env`: `HERMES_KODEO_KEY`, `DISCORD_BOT_TOKEN`, `DISCORD_ALLOW_ALL_USERS`, `ANON_KEY`
- Supabase `.env`: `POSTGRES_PASSWORD`, `JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY`, `VAULT_ENC_KEY`
- Cronova: `secure_cookie: true`
- Supabase pooler: `VAULT_ENC_KEY` fixed to 32-char raw string

## [0.2.0] - 2026-10-17

### Added
- Encrypted R2 backups with Age and weekly restore drill
- Loopback-only Hermes dashboard and HMAC webhook routes
- Host orchestration CLI, idempotent setup, versioned skills, reports skill
- MkDocs documentation site and GitHub Pages workflow
- External prerequisite checker and recovery/security runbooks

### Changed
- Supabase gateway and pooler ports bind to loopback
- Fase 1/Fase 2/Fase 3 status documented in `ROADMAP.md`

### Security
- Cloudflare Access enabled for Kuma, Studio, Hermes and webhook hostnames with administrator-only policy.
- Supabase origins remain loopback-only; Telegram token is stored only on the VPS.
- Revoked infrastructure credentials must never be committed; rotate Telegram tokens exposed outside the VM immediately.

## [Unreleased]

### Planned
- Add Telegram user allowlist after receiving the owner's numeric Telegram user ID.
