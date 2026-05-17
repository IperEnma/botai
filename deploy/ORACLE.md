# Despliegue: Oracle (backend) + Neon (Postgres)

Arquitectura:

```
Internet → Caddy (HTTPS) → backend (Docker en Oracle VM)
                              ↓
                         Neon Postgres (pgvector, free tier)
```

**Ventaja:** la VM usa menos RAM (sin Postgres local). Encaja mejor en **2 OCPU + 12 GB** Always Free.

---

## Parte A — Neon (base de datos)

### A1. Crear proyecto en Neon

1. [neon.tech](https://neon.tech) → cuenta gratis (sin tarjeta en el plan free).
2. **New project** → nombre `botai` → región cercana a tu VM (ej. AWS São Paulo si Vinhedo).
3. Crear base **PostgreSQL 16** (Neon lo hace solo).

### A2. Activar pgvector

En el proyecto Neon → **SQL Editor** (o consola):

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### A3. Esquema (automático al arrancar)

No ejecutes `schema.sql` manual. Con `SPRING_DATASOURCE_*` apuntando a Neon, el primer arranque del backend:

1. Aplica extensiones PG (Flyway V1 + `AgendaPostgresExtensions`).
2. Crea/actualiza tablas del **bot** y **agenda** con Hibernate (`ddl-auto=update`).
3. Corre Flyway V2–V4 (semilla agenda, índices, constraints).

### A4. Anotar variables para `.env.prod`

En Neon → **Connection details** → copiá el **connection string** completo:

| Variable | Valor |
|----------|--------|
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://HOST:5432/neondb?sslmode=require` |
| `SPRING_DATASOURCE_USERNAME` | usuario Neon |
| `SPRING_DATASOURCE_PASSWORD` | contraseña Neon |

---

## Parte B — Oracle Cloud (solo backend)

### Límites Always Free

| Recurso | Límite | Qué hacemos |
|---------|--------|-------------|
| VMs Ampere | 4 OCPU / 24 GB RAM total | **1 VM**: 2 OCPU, 12 GB |
| Block storage | 200 GB total | Boot **50 GB** |
| No crear | 2ª VM, Autonomous DB, LB de pago | — |

**Budget alert $1** en Billing (recomendado).

### B1. Crear la VM

1. [oracle.com/cloud/free](https://www.oracle.com/cloud/free/) → región home (ej. São Paulo / Vinhedo).
2. **Compute → Instances → Create instance**:
   - Name: `botai`
   - Image: **Ubuntu 22.04** (aarch64)
   - Shape: **Ampere** `VM.Standard.A1.Flex` — **2 OCPU, 12 GB**
   - Boot: **50 GB**
   - **Assign public IPv4**
   - Tu **SSH public key**
3. Create → esperá **Running** → anotá **IP pública**.

Si falla por capacidad: otra **Availability Domain** en la misma región.

### B2. Firewall (Security List)

Ingress en la VCN:

| Puerto | Origen |
|--------|--------|
| 22 | Tu IP (`tu.ip/32`) |
| 80, 443 | `0.0.0.0/0` |

No abras **8080** al exterior.

### B3. SSH y Docker

```bash
ssh ubuntu@TU_IP
```

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose-plugin git iptables-persistent
sudo usermod -aG docker $USER
```

Salí y volvé a entrar por SSH.

```bash
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save
```

### B4. Clonar repo y configurar

```bash
cd ~
git clone https://github.com/TU_USUARIO/botai.git
cd botai
cp backend/.env.prod.example backend/.env.prod
nano backend/.env.prod
```

Completá al menos:

- `DB_*` → valores de Neon (Parte A4)
- `CADDY_DOMAIN` → ej. `api.tudominio.com`
- `AGENDA_PUBLIC_BASE_URL` → URL del front
- `GOOGLE_*`, `WHATSAPP_*`
- `OPENROUTER_API_KEY` si `BOT_EMBEDDING_PROVIDER=api`

**Importante:** la VM debe poder salir a internet hacia el host de Neon (puerto 5432). Neon free permite conexiones desde cualquier IP si SSL está activo (por defecto sí).

### B5. Build y arranque

```bash
cd ~/botai
docker compose -f docker-compose.prod.yml --env-file backend/.env.prod build
docker compose -f docker-compose.prod.yml --env-file backend/.env.prod up -d
docker compose -f docker-compose.prod.yml logs -f backend
```

Esperá:

- Flyway aplicando migraciones `agenda_*`
- Sin error de conexión a Neon
- Si usás `api` embeddings: no hace falta `[DJL-EMBED]` (usa OpenRouter)

Health:

```bash
curl -s http://localhost:8080/actuator/health
```

Con DNS apuntando a la VM:

```bash
curl -s https://api.tudominio.com/actuator/health
```

### B6. DNS y post-deploy

| Qué | Dónde |
|-----|--------|
| Registro **A** | `api.tudominio.com` → IP de la VM |
| Front | `API_BASE_URL=https://api.tudominio.com/api` |
| WhatsApp webhook | `https://api.tudominio.com/api/v1/webhook/whatsapp` |
| Google OAuth | orígenes del dominio del front |

Actualizar:

```bash
cd ~/botai && git pull
docker compose -f docker-compose.prod.yml --env-file backend/.env.prod build backend
docker compose -f docker-compose.prod.yml --env-file backend/.env.prod up -d
```

---

## Embeddings en prod (recomendado con 12 GB VM)

```env
BOT_EMBEDDING_PROVIDER=api
OPENROUTER_API_KEY=sk-or-v1-...
```

Tras cambiar de `djl` a `api`, en Neon conviene **regenerar embeddings** (columna `embedding` en `knowledge_chunk`) o vaciarla y reiniciar el backend para que el sync los rellene vía API.

---

## Checklist “sigo en free”

- [ ] Solo **1** VM `VM.Standard.A1.Flex` (2 OCPU, 12 GB)
- [ ] Neon en plan **Free** (0.5 GB, suficiente para empezar)
- [ ] Sin Autonomous DB / LB de pago en Oracle
- [ ] Budget alert en Oracle

---

## Problemas frecuentes

| Síntoma | Solución |
|---------|----------|
| Backend no conecta a Neon | Revisá `SPRING_DATASOURCE_*`, SSL (`sslmode=require`), password |
| `vector` extension missing | Activar pgvector en Neon o `CREATE EXTENSION vector` |
| RAG sin chunks | Revisar logs `[RAG-EMBED]`; tabla `knowledge_chunk` la crea Hibernate al arrancar |
| OOM en VM | `BOT_EMBEDDING_PROVIDER=api` y bajar `mem_limit` del backend en compose |
| Flyway checksum | Solo dev: `FLYWAY_REPAIR_ON_MIGRATE=true`; en prod migraciones inmutables |
