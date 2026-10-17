# Phase 2 rollout

## Hermes dashboard

Install the user unit only on the VM:

```bash
install -D -m 0644 systemd/hermes-dashboard.service /root/.config/systemd/user/hermes-dashboard.service
systemctl --user daemon-reload
systemctl --user enable --now hermes-dashboard
curl -fsSI http://127.0.0.1:9119/
```

Keep `127.0.0.1:9119`. Before a public hostname exists, enable Cloudflare Access and create an allow policy for the administrator identity. Then add `hermes.example.com` to the Tunnel ingress and test the Access login first.

## Telegram

**Rotacione imediatamente qualquer token colado em chat, issue, log ou terminal compartilhado.** No BotFather, use `/revoke` para o bot e gere um token novo. O token novo deve ser escrito somente em `/root/.hermes/.env`, modo `0600`.

```bash
printf '\nTELEGRAM_BOT_TOKEN=<private-token>\n' >> /root/.hermes/.env
chmod 600 /root/.hermes/.env
hermes gateway setup
systemctl --user restart hermes-gateway
```

Teste com uma conversa privada. Não publique Telegram ou compartilhe o token em issue, histórico do shell, repositório ou payload de webhook.

## HMAC webhooks

Routes are already loopback-only:

```text
http://127.0.0.1:8644/webhooks/lotuz-crm
http://127.0.0.1:8644/webhooks/lotuz-sdr
http://127.0.0.1:8644/webhooks/lotuz-wa
http://127.0.0.1:8644/webhooks/lotuz-mkt
```


## External prerequisite acceptance

Run `make prereq-check` on the VM. Warnings are expected until the external values exist; failures stop the rollout.

Acceptance criteria:

- Cloudflare Access API returns success for the account and Access policies exist for Kuma, Hermes dashboard, Cronova, Studio, and webhook ingress.
- `TELEGRAM_BOT_TOKEN` is set only in `/root/.hermes/.env`; a private-chat smoke test succeeds.
- `BACKUP_AGE_IDENTITY` exists and has an offline copy in a password manager or encrypted removable store.
- `HEALTHCHECK_URL` and `BACKUP_ALERT_URL` are private checks and receive a success ping after backup plus a failure ping from a forced test failure.
Use `hermes webhook list` to retrieve route names. Requests require `X-Hub-Signature-256: sha256=<HMAC-SHA256(secret, raw-body)>`. Each route secret is distinct and stored in `/root/.hermes/webhook_subscriptions.json` mode `0600`.

To expose a route, first enable Cloudflare Access, create an allow policy, add the hostname through the Tunnel, and verify invalid signatures still return `401` externally.
