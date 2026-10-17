# OpenLotuz — Orquestrador open source de negócios

Stack self-hosted 100% open source, servido atrás do Cloudflare (Tunnel + proxied DNS), sem IP exposto.

| Serviço | Software | Licença | URL |
|---|---|---|---|
| CRM | [Atomic CRM](https://github.com/marmelab/atomic-crm) sobre Supabase self-host | MIT | `crm.example.com` |
| Flow (automação) | Cronova | MIT | `flow.example.com` |
| SDR (agente) | AgentSDR | OSS | `sdr.example.com` |
| WhatsApp | OpenWA | MIT | `wa.example.com` |
| Marketing | Helio selfhost | OSS | `mkt.example.com` |
| Gateway IA | [Hermes Agent](https://github.com/NousResearch/hermes-agent) (MIT) | Discord/CLI | Bot `Hermes Agent` |
| Backup | Cloudflare R2 (rclone) | — | offsite |

> n8n foi excluído por licença fair-code; substituído pelo Cronova (MIT).

## Arquitetura

```
Internet → Cloudflare (DNS proxied) → cloudflared tunnel → VM
  flow.example.com  → 127.0.0.1:8090  (Cronova)
  sdr.example.com   → 127.0.0.1:3001  (AgentSDR)
  wa.example.com    → 127.0.0.1:3002  (OpenWA)
  mkt.example.com   → 127.0.0.1:3003  (Helio)
  crm.example.com   → 127.0.0.1:3000  (nginx: estático + proxy → Kong :8000)
                                                   └→ Supabase self-host (12 containers)
```

> Substitua `example.com` pelo seu domínio. Todas as URLs/domínios acima são placeholders (RFC 2606).

## Acesso rápido

| Serviço | URL | Credenciais |
|---|---|---|
| CRM | https://crm.example.com | `admin@example.com` / `SUA_SENHA_AQUI` |
| Flow | https://flow.example.com | admin / `SUA_SENHA_AQUI` |
| SDR | https://sdr.example.com | login na UI |
| WA | https://wa.example.com | escanear QR |
| Marketing | https://mkt.example.com | login na UI |
| Hermes (Discord) | DM para bot **Hermes Agent** | — |

> Nunca commite credenciais reais. Use variáveis de ambiente / `.env` (ignorado pelo `.gitignore`).

## Interface unificada (Hermes + Discord)

O **Hermes Agent** roda na VM com gateway Discord. No Discord:

1. Abra DM com o bot **Hermes Agent** (ID `SEU_BOT_ID`)
2. Use comandos naturais ou invoque skills:
   - `lotuz-crm companies` — lista empresas do CRM
   - `lotuz-crm contacts` — lista contatos
   - `lotuz-wa send 5511999999999 "Mensagem"` — envia WhatsApp
   - `lotuz-mkt campaigns` — lista campanhas
   - `lotuz-sdr sequences` — lista sequências SDR

O Hermes mantém contexto entre sessões, cria skills automaticamente, e tem scheduler nativo (cron) — substitui o Cronova para automações futuras.

## Deploy

Veja `docs/` para os guias passo a passo:

- [docs/deploy-tunnel.md](docs/deploy-tunnel.md) — Cloudflare Tunnel via API
- [docs/deploy-supabase.md](docs/deploy-supabase.md) — Supabase self-host + Atomic CRM
- [docs/deploy-backup-r2.md](docs/deploy-backup-r2.md) — Backup no R2

## Backup

```bash
# Na VM — diário via cron, dump Postgres + configs → rclone → R2
/opt/lotuz/backup-r2.sh
```

Credenciais em `/opt/lotuz/.backup.env` (fora do repo). Veja `.env.example` e `cloudflared.config.example.yaml` como templates.

## Variáveis de ambiente (não versionadas)

| Arquivo | Variáveis |
|---|---|
| `/opt/lotuz/crm/supabase/.env` | `POSTGRES_PASSWORD`, `JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY`, `VAULT_ENC_KEY` |
| `/root/.hermes/.env` | `HERMES_KODEO_KEY`, `DISCORD_BOT_TOKEN`, `DISCORD_ALLOW_ALL_USERS`, `ANON_KEY` |
| `/opt/lotuz/.backup.env` | `R2_BUCKET` |
| `/etc/cronova/cronova.yaml` | `secure_cookie: true`, credenciais admin |
| `/etc/cloudflared/config.yaml` | `tunnel`, `credentials-file`, `ingress` (ver `cloudflared.config.example.yaml`) |

> Copie `.env.example` → `.env` e `cloudflared.config.example.yaml` → `/etc/cloudflared/config.yaml`, substituindo `SEU_*` e `example.com`.

## Licença
Apache-2.0 — ver [LICENSE](LICENSE). Cada componente mantém a própria licença (MIT/OSS). Ao contribuir você concorda que sua contribuição será licenciada sob Apache-2.0.

## Contribuição

Issues e PRs bem-vindos. Para adicionar skills ao Hermes, crie pasta em `skills/lotuz/<nome>/` com `SKILL.md` + script executável.

---

**Status atual**: todos os containers healthy, serviços públicos via Tunnel, backup R2 testado, Hermes + Discord ativo.
