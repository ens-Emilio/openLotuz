# Platform Operations

## Host orchestration

The stacks remain independent because they own different Compose projects, networks, volumes, and upgrade lifecycles. `scripts/lotuz` is the single host interface:

```bash
sudo scripts/setup.sh --yes
lotuz ps all
lotuz up crm
lotuz up all
lotuz logs sdr
lotuz down mkt
```

`setup.sh` validates the existing Compose files, installs `lotuz`, `lotuz-hook`, backup scripts, and the four Hermes skills. It does not recreate containers unless `--start` is explicitly passed.

## Hermes webhook gateway

Hermes listens on `127.0.0.1:8644` only. Four HMAC-SHA256 routes are installed:

```text
http://127.0.0.1:8644/webhooks/lotuz-crm
http://127.0.0.1:8644/webhooks/lotuz-sdr
http://127.0.0.1:8644/webhooks/lotuz-wa
http://127.0.0.1:8644/webhooks/lotuz-mkt
```

Each route has its own secret stored in `/root/.hermes/webhook_subscriptions.json` (mode `0600`). The request must include:

```http
Content-Type: application/json
X-Hub-Signature-256: sha256=<HMAC-SHA256(secret, raw request body)>
```

Invalid signatures receive `401`; valid requests are accepted asynchronously with `202`. The listener is not published through Cloudflare until Cloudflare Access is enabled and an allow policy exists.

Use `scripts/lotuz-hook` to manage routes instead of editing the JSON by hand:

```bash
sudo lotuz-hook list crm
sudo lotuz-hook test crm lotuz-crm
```

## Skills

Versioned skills live in `skills/lotuz/{crm,sdr,wa,mkt}/SKILL.md`. `scripts/skill-check.py` validates frontmatter and wrapper names. External side-effect skills require explicit confirmation before sending messages or creating campaigns.

## Telegram and Hermes UI

Telegram requires a real `TELEGRAM_BOT_TOKEN`, which is intentionally absent from the public repo and current VM. Hermes web UI/dashboard can run on loopback, but public access requires Cloudflare Access. Do not add either route to the Tunnel until the account's Access product is enabled and the policy is tested.

## Remaining platform prerequisites

- Enable Cloudflare Access in the account, then protect `kuma`, Cronova, Supabase Studio, Hermes dashboard, and webhook ingress.
- Add a Telegram bot token to `/root/.hermes/.env`, configure the gateway, and test a private chat before exposing it.
- Keep Supabase ports bound to loopback; the current VM rollout already restricts `8000`, `5432`, and `6543`.
