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

This repository must never contain real domains, tokens, passwords, customer data, or deployment-specific identifiers.

- Use `example.com` and `SEU_*` placeholders in examples.
- Keep runtime values in a secret manager or ignored environment files.
- Protect administrative listeners with an identity-aware access policy.
- Rotate any credential that appears in a public or shared location.
- CI runs gitleaks and placeholder checks on every push and pull request.

## Hardening checklist (VM)

- Cloudflare Tunnel only — no public IP / no open `22` to `0.0.0.0/0`
- `cronova` and `Supabase Studio` behind Cloudflare Access (admin group only)
- `secure_cookie: true` when serving behind HTTPS
- R2 backups encrypted (`age`) + weekly restore drill
