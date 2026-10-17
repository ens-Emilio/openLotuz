# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| `main` | ✅ |
| `v0.1.x` | ✅ (security fixes only) |

## Reporting a Vulnerability

**Do not open a public issue for security reports.**

Email: **security@truuz.com.br** (or open a [private security advisory](https://github.com/ens-Emilio/openLotuz/security/advisories/new)).

Include:
- description + impact
- reproduction steps or PoC
- affected commit/tag

We aim to acknowledge within **48h** and ship a fix within **7 days** for high severity.

## Secrets hygiene

This repo must never contain real domains, tokens, or passwords.

- Use `example.com` / `SEU_*` placeholders (see `.env.example`).
- Real values live only on the VM: `/opt/lotuz/crm/supabase/.env`, `/root/.hermes/.env`, `/etc/cloudflared/creds.json` (all gitignored).
- CI runs `gitleaks` + custom block for `*.truuz.com.br` / `Lotuz*` patterns. A leak fails the check.
- If you accidentally committed a secret: **rotate it immediately** on the VM (`scripts/rotate-vm-secrets.sh`) — history rewriting alone is not enough.

## Hardening checklist (VM)

- Cloudflare Tunnel only — no public IP / no open `22` to `0.0.0.0/0`
- `cronova` and `Supabase Studio` behind Cloudflare Access (admin group only)
- `secure_cookie: true` when serving behind HTTPS
- R2 backups encrypted (`age`) + weekly restore drill
