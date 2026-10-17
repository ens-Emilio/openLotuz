# OpenLotuz

OpenLotuz is a self-hosted, open source operations stack for CRM, automation, SDR, WhatsApp, marketing, and an AI gateway.

## Current state

- Apache-2.0 repository with sanitized examples only.
- Cloudflare Tunnel origins bound to loopback.
- Encrypted R2 backups with a weekly restore drill.
- Hermes HMAC webhooks and dashboard bound to loopback.
- Public Access routes require Cloudflare Access to be enabled first.

## Start here

1. Read the [platform operations guide](platform.md).
2. Copy `.env.example` and keep real values outside Git.
3. Run `make check` before opening a pull request.
4. Use [Contribuição](contributing.md) for skills and changes.
