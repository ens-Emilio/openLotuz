# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| `main` | ✅ |
| `v0.1.x` | ✅ (security fixes only) |

## Reporting a Vulnerability

**Do not open a public issue for security reports.**

Use GitHub's [private security advisory](https://github.com/ens-Emilio/openLotuz/security/advisories/new). Do not report vulnerabilities in public issues.

Include:
- description + impact
- reproduction steps or PoC
- affected commit/tag

We aim to acknowledge within **48h** and ship a fix within **7 days** for high severity.

## Secrets hygiene

This repo must never contain real domains, tokens, or passwords.

- Use `example.com` / `SEU_*` placeholders (see `.env.example`).
- Real values live only on the VM: `/opt/lotuz/crm/supabase/.env`, `/root/.hermes/.env`, `/etc/cloudflared/creds.json` (all gitignored).
- CI runs `gitleaks` plus checks that reject real deployment domains, IDs, and passwords.
- If you accidentally committed a secret: **rotate it immediately** on the affected service — history rewriting alone is not enough.

## Hardening checklist (VM)

- Cloudflare Tunnel only — no public IP / no open `22` to `0.0.0.0/0`
- `cronova` and `Supabase Studio` behind Cloudflare Access (admin group only)
- `secure_cookie: true` when serving behind HTTPS
- R2 backups encrypted (`age`) + weekly restore drill
