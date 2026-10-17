# Deploy do Cloudflare Tunnel via API

Este túnel expõe todos os serviços locais (portas 3000, 3001, 3002, 3003, 8090) para o DNS proxied `*.example.com`.

> Substitua `example.com` pelo seu domínio. `SEU_ZONE_ID`, `SEU_ACCOUNT_ID` e `SEU_TUNNEL_ID` são placeholders — nunca commite valores reais.

## Pré-requisitos

- Conta Cloudflare com zona `example.com` (Zone ID: `SEU_ZONE_ID`)
- Token API com permissões:
  - Zone:DNS:Edit
  - Zone:DNS:Read
  - Account:Cloudflare Tunnel:Edit
- `cloudflared` instalado na VM

## 1. Criar túnel via API

```bash
CFTOK="seu_token_api"
ACCOUNT_ID="SEU_ACCOUNT_ID"

# Criar túnel (nome: lotuz)
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/cfd_tunnel" \
  -H "Authorization: Bearer ${CFTOK}" \
  -H "Content-Type: application/json" \
  -d '{"name":"lotuz","config_src":"cloudflare"}'

# Anotar o Tunnel ID (ex: SEU_TUNNEL_ID)
```

## 2. Gerar credenciais do túnel

```bash
TUNNEL_ID="SEU_TUNNEL_ID"
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/credentials" \
  -H "Authorization: Bearer ${CFTOK}" \
  -H "Content-Type: application/json" \
  -d '{}' > /etc/cloudflared/${TUNNEL_ID}.json
```

## 3. Configurar ingress (config.yaml)

`/etc/cloudflared/config.yaml`:

```yaml
tunnel: SEU_TUNNEL_ID
credentials-file: /etc/cloudflared/SEU_TUNNEL_ID.json
ingress:
  - hostname: flow.example.com
    service: http://localhost:8090
  - hostname: sdr.example.com
    service: http://localhost:3001
  - hostname: wa.example.com
    service: http://localhost:3002
  - hostname: mkt.example.com
    service: http://localhost:3003
  - hostname: crm.example.com
    service: http://localhost:3000
  - service: http_status:404
```

## 4. DNS records (via API ou dashboard)

```bash
ZONE_ID="SEU_ZONE_ID"
TUNNEL_ID="SEU_TUNNEL_ID"

for sub in flow sdr wa mkt crm; do
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CFTOK}" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\":\"CNAME\",
      \"name\":\"${sub}\",
      \"content\":\"${TUNNEL_ID}.cfargotunnel.com\",
      \"proxied\":true
    }"
done
```

## 5. Rodar como serviço

```bash
cat > /etc/systemd/system/cloudflared.service <<'EOF'
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/cloudflared tunnel --config /etc/cloudflared/config.yaml run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now cloudflared
systemctl status cloudflared
```

## 6. Verificar

```bash
# Local
curl -s http://localhost:3000/ -o /dev/null -w '%{http_code}\n'   # 200

# Público
curl -s https://crm.example.com/ -o /dev/null -w '%{http_code}\n'  # 200
```

## Observações

- O túnel **não precisa de IP público** — o `cloudflared` faz conexão outbound só.
- Se o token CF não tiver permissão de Access, o túnel ainda funciona (DNS proxied + Tunnel).
- Credenciais (`/etc/cloudflared/*.json`) não vão pro repo.
