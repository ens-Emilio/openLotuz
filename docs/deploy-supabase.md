# Deploy do Supabase self-host + Atomic CRM

Veja a arquitetura completa no [site de documentação](index.md).

## Pré-requisitos

- Docker + docker compose
- ~4 GB RAM livre
- Porta 8000 livre (Kong API gateway do Supabase)
- Banco PostgreSQL limpo (o compose cria o volume)

## Passo a passo

### 1. Baixar o compose oficial

```bash
mkdir -p /opt/lotuz/crm/supabase && cd /opt/lotuz/crm/supabase
curl -L -o docker-compose.yml "https://raw.githubusercontent.com/supabase/supabase/master/docker/docker-compose.yml"
curl -L -o .env.example "https://raw.githubusercontent.com/supabase/supabase/master/docker/.env.example"
```

### 2. Criar .env com segredos

```bash
cp .env.example .env
# Gerar senhas aleatórias (32 chars cada)
POSTGRES_PASSWORD=$(head -c 32 /dev/urandom | base64 | tr -d '+/' | cut -c1-32)
JWT_SECRET=$(head -c 32 /dev/urandom | base64 | tr -d '+/' | cut -c1-32)
ANON_KEY=$(head -c 32 /dev/urandom | base64 | tr -d '+/' | cut -c1-32)
SERVICE_ROLE_KEY=$(head -c 32 /dev/urandom | base64 | tr -d '+/' | cut-c1-32)

sed -i "
    s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|
    s|^JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|
    s|^ANON_KEY=.*|ANON_KEY=$ANON_KEY|
    s|^SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY|
" .env
```

### 3. Iniciar os serviços

```bash
docker compose up -d
```

Aguarde 2-3 min até que todos os 12 containers fiquem healthy:
```bash
docker compose ps --format "{{.Names}} {{.Status}}"
```

### 4. Executar migrations + seed do Atomic CRM

```bash
# Acessar o container do Postgres
docker exec -it supabase-db psql -U postgres -d postgres <<'SQL'
-- Habilitar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
-- Criar tabelas do Atomic CRM (marmelab/atomic-crm)
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name TEXT,
    last_name TEXT,
    email TEXT UNIQUE,
    company_id UUID REFERENCES companies(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS deals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    stage TEXT DEFAULT 'prospect',
    value DECIMAL(10,2),
    company_id UUID REFERENCES companies(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
-- Inserir dados de exemplo (seed)
INSERT INTO companies (name) VALUES
  ('Acme Corp'),
  ('Globex Inc'),
  ('Initech LLC')
ON CONFLICT DO NOTHING;
INSERT INTO contacts (first_name, last_name, email, company_id)
SELECT
  'John', 'Doe', 'john.doe@acme.com', id
FROM companies WHERE name='Acme Corp'
UNION ALL
SELECT
  'Jane', 'Smith', 'jane.smith@globex.com', id
FROM companies WHERE name='Globex Inc'
ON CONFLICT DO NOTHING;
SQL
```

### 5. Verificar APIs

```bash
# Listar empresas (deve retornar 3 linhas)
curl -s -H "apikey: $(grep '^ANON_KEY=' .env | cut -d= -f2)" \
  "http://localhost:8000/rest/v1/companies?select=id,name"

# Criar usuário admin no GoTrue (para login no CRM)
curl -s -X POST -H "apikey: $(grep '^SERVICE_ROLE_KEY=' .env | cut -d= -f2)" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SUA_SENHA_AQUI",
    "email_confirm": true
  }' "http://localhost:8000/auth/v1/signup"
```

> Substitua `admin@example.com` / `SUA_SENHA_AQUI` pelas suas credenciais reais (nunca commite).

### 6. Proxy via nginx (opcional, já configurado)

O arquivo `/etc/nginx/sites-available/crm` já encaminha `/rest/*`, `/auth/*`, etc. para `http://127.0.0.1:8000`.

Acesse:
- CRM: https://crm.example.com
- Supabase Studio (local): http://localhost:3000 (porta mapeada no compose — ver arquivo)

> Substitua `crm.example.com` pelo seu domínio.

## Segredo

Nunca commit o `.env`. Ele contém:
- `POSTGRES_PASSWORD`
- `JWT_SECRET`
- `ANON_KEY`
- `SERVICE_ROLE_KEY`

Use o `.env.example` como template no repositório.
