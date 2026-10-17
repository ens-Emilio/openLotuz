#!/usr/bin/env bash
# Rotate CRM, workflow, and Tunnel credentials on the target VM.
# Run on the VM as root; never copy resulting values into Git.
# Requires Docker and cloudflared on the target host.
set -euo pipefail

echo "== 1) Gerando novas senhas =="
NEW_CRM_PASS=$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-20)
NEW_FLOW_PASS=$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-20)
echo "Nova senha CRM (admin@SEU_DOMINIO): $NEW_CRM_PASS"
echo "Nova senha Flow (admin):            $NEW_FLOW_PASS"
echo ">>> ANOTE ESSAS SENHAS AGORA (vão para .env fora do repo) <<<"
echo ""

read -p "Continuar e aplicar no Supabase/Cronova? (y/N) " ok
[[ "$ok" == "y" ]] || exit 0

echo ""
echo "== 2) CRM — atualiza senha no GoTrue (Supabase) =="
# Tenta via API (SERVICE_ROLE_KEY). Se falhar, faz via SQL direto.
SUPA_ENV="/opt/lotuz/crm/supabase/.env"
if [[ -f "$SUPA_ENV" ]]; then
  SERVICE_KEY=$(grep '^SERVICE_ROLE_KEY=' "$SUPA_ENV" | cut -d= -f2-)
  ANON_KEY=$(grep '^ANON_KEY=' "$SUPA_ENV" | cut -d= -f2-)
  # Busca user id do admin (exporte ADMIN_EMAIL se diferente)
  ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
  # Tenta listar usuários via GoTrue admin API
  USER_ID=$(curl -s -H "apikey: $SERVICE_KEY" -H "Authorization: Bearer $SERVICE_KEY" \
    "http://localhost:8000/auth/v1/admin/users" | python3 -c "import sys,json; d=json.load(sys.stdin); print(next((u['id'] for u in d.get('users',[]) if u.get('email')=='$ADMIN_EMAIL'), ''))" 2>/dev/null || true)
  if [[ -n "$USER_ID" ]]; then
    echo "Atualizando $ADMIN_EMAIL ($USER_ID) via API..."
    curl -s -X PUT -H "apikey: $SERVICE_KEY" -H "Authorization: Bearer $SERVICE_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"password\":\"$NEW_CRM_PASS\"}" \
      "http://localhost:8000/auth/v1/admin/users/$USER_ID" | python3 -m json.tool || true
    echo "CRM senha trocada via API."
  else
    echo "API não retornou USER_ID — tentando via SQL (auth.users)..."
    NEW_HASH=$(python3 -c "import bcrypt; print(bcrypt.hashpw(b'$NEW_CRM_PASS', bcrypt.gensalt()).decode())" 2>/dev/null || echo "")
    if [[ -n "$NEW_HASH" ]]; then
      docker exec supabase-db psql -U postgres -c "UPDATE auth.users SET encrypted_password='$NEW_HASH' WHERE email='$ADMIN_EMAIL';" 2>&1 | head
    else
      echo "Instale bcrypt: pip install bcrypt — ou use o dashboard do GoTrue para trocar a senha manualmente."
      echo "Senha desejada: $NEW_CRM_PASS"
    fi
  fi
else
  echo "AVISO: $SUPA_ENV não encontrado. Troque a senha manualmente no Supabase Studio (http://localhost:3000)."
  echo "Senha desejada: $NEW_CRM_PASS"
fi

echo ""
echo "== 3) Flow (Cronova) — atualiza /etc/cronova/cronova.yaml =="
CRONOVA_YAML="/etc/cronova/cronova.yaml"
if [[ -f "$CRONOVA_YAML" ]]; then
  cp "$CRONOVA_YAML" "${CRONOVA_YAML}.bak.$(date +%F_%H%M)"
  # Tenta substituir campo password/admin_password (genérico, sem expor valor antigo)
  if grep -qE "password:" "$CRONOVA_YAML"; then
    sed -i -E "s/(password:[[:space:]]*).*/\1$NEW_FLOW_PASS/" "$CRONOVA_YAML"
    echo "Senha Flow atualizada em $CRONOVA_YAML"
  else
    echo "Campo 'password:' não encontrado — edite manualmente:"
    grep -n "password\|admin" "$CRONOVA_YAML" || true
    echo "Troque para: $NEW_FLOW_PASS"
  fi
  systemctl restart cronova 2>/dev/null || docker restart cronova 2>/dev/null || true
  echo "Cronova reiniciado. Teste: https://flow.SEUDOMINIO (admin / nova senha)"
else
  echo "AVISO: $CRONOVA_YAML não encontrado. Ajuste onde a senha do Flow está configurada."
fi

echo ""
echo "== 4) Cloudflare Tunnel — recriar (exige cloudflared logado) =="
echo "Se você tem CFTOK/ACCOUNT_ID exportados, o script tenta via API. Senão, use 'cloudflared tunnel login'."
if command -v cloudflared >/dev/null 2>&1; then
  if [[ -f ~/.cloudflared/cert.pem || -f /etc/cloudflared/cert.pem ]]; then
    echo "Cert encontrado — listando túneis antigos..."
    cloudflared tunnel list || true
    read -p "Deletar túnel 'lotuz' e criar novo? (y/N) " del
    if [[ "$del" == "y" ]]; then
      cloudflared tunnel delete lotuz 2>&1 || true
      cloudflared tunnel create lotuz
      NEW_TUNNEL_ID=$(cloudflared tunnel list 2>&1 | grep lotuz | awk '{print $1}' | head -1)
      echo "Novo TUNNEL_ID: $NEW_TUNNEL_ID"
      echo "Atualize /etc/cloudflared/config.yaml: tunnel: $NEW_TUNNEL_ID"
      echo "E rode: cloudflared tunnel route dns $NEW_TUNNEL_ID crm.SEUDOMINIO (repita para flow,sdr,wa,mkt)"
      echo "Depois: systemctl restart cloudflared"
    fi
  else
    echo "Sem cert.pem — faça UMA das opções:"
    echo "  A) cloudflared tunnel login   (abre browser para autenticar)"
    echo "  B) Exporte CFTOK e ACCOUNT_ID e use a API:"
    echo '     CFTOK="seu_token" ACCOUNT_ID="SEU_ACCOUNT_ID"'
    echo '     curl -X POST -H "Authorization: Bearer $CFTOK" https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel -d '\''{"name":"lotuz","config_src":"cloudflare"}'\'''
    echo "Veja docs/deploy-tunnel.md sanitizado para o fluxo completo."
  fi
else
  echo "cloudflared não instalado nesta VM — instale ou faça a rotação pelo dashboard Cloudflare (Zero Trust > Networks > Tunnels)."
fi

echo ""
echo "== Resumo =="
echo "CRM:  admin@SEU_DOMINIO / $NEW_CRM_PASS"
echo "Flow: admin / $NEW_FLOW_PASS"
echo "Tunnel: recriado se você confirmou acima — atualize DNS CNAME -> <novo-id>.cfargotunnel.com"
echo "IMPORTANTE: nenhuma dessas senhas/IDs deve voltar para o git. Estão só na VM (.env / yaml)."
