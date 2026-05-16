# Despliegue en Render (embeddings API + Neon)

Prueba rápida sin Oracle: backend en **Render**, Postgres en **Neon**, embeddings por **OpenRouter** (`BOT_EMBEDDING_PROVIDER=api`). Sin DJL en el servidor.

```
Internet → Render (HTTPS) → Spring Boot
                              ↓
                         Neon (pgvector)
```

Render da HTTPS; no hace falta Caddy ni `docker-compose.prod.yml`.

---

## 1. Neon (si aún no está)

1. [neon.tech](https://neon.tech) → proyecto → **SQL Editor**:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

2. Ejecutá `backend/src/main/resources/schema.sql` (tablas del bot).
3. Copiá **Connection details** (host, user, password, database).

### Dimensiones de embeddings (importante)

Tu `schema.sql` usa **`vector(384)`** (DJL MiniLM).

`openai/text-embedding-3-small` en OpenRouter devuelve **1536** dimensiones. Antes del primer embed en prod, en Neon:

```sql
ALTER TABLE knowledge_chunk ALTER COLUMN embedding TYPE vector(1536);
UPDATE knowledge_chunk SET embedding = NULL;
```

Si preferís seguir con **384** dims, elegí en OpenRouter un modelo que devuelva 384 y ajustá `BOT_EMBEDDING_API_MODEL` (debe coincidir con la columna).

---

## 2. OpenRouter

1. [openrouter.ai](https://openrouter.ai) → API key.
2. Crédito free / pago según uso de embeddings + chat.

---

## 3. Crear el servicio en Render

### Opción A — Blueprint (`render.yaml` en la raíz)

1. [dashboard.render.com](https://dashboard.render.com) → **New** → **Blueprint**.
2. Conectá el repo `botai`.
3. Completá las variables marcadas como secretas (`DB_*`, `OPENROUTER_API_KEY`, `GOOGLE_*`, etc.).
4. **Apply**.

### Opción B — Manual

1. **New** → **Web Service** → repo.
2. **Root Directory:** `backend`
3. **Runtime:** Docker
4. **Plan:** Free (512 MB) o Starter si falla memoria.
5. **Health Check Path:** `/actuator/health`
6. Variables de entorno: copiá de `backend/.env.render.example`.

---

## 4. Variables obligatorias (Environment)

| Variable | Valor |
|----------|--------|
| `JAVA_OPTS` | `-Xmx384m` |
| `BOT_EMBEDDING_PROVIDER` | `api` |
| `OPENROUTER_API_KEY` | tu key |
| `BOT_EMBEDDING_API_MODEL` | `openai/text-embedding-3-small` (→ 1536 dims, ver SQL arriba) |
| `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | Neon |
| `DB_JDBC_PARAMS` | `?sslmode=require` |
| `SPRING_SQL_INIT_MODE` | `never` |
| `AGENDA_PUBLIC_BASE_URL` | URL del front Flutter/web |
| `AGENDA_UPLOADS_BASE_URL` | `https://TU-SERVICIO.onrender.com/uploads` |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | OAuth |

Opcional WhatsApp: `WHATSAPP_*`.

### Chat (Ollama)

El chat del bot usa **Ollama** (`OLLAMA_BASE_URL`). En Render **no** hay Ollama local.

- Poné una URL **pública** de Ollama, o
- Dejá la app levantada y probá solo endpoints Agenda / health hasta tener LLM.

---

## 5. Deploy y comprobación

Tras el build:

```text
https://botai-backend.onrender.com/actuator/health
```

Logs en Render → **Logs**:

- `[EMBED-API]` o arranque de embeddings API
- Flyway `agenda_*` sin error
- Sin `Connection refused` a Neon

Regenerar vectores: chunks con `embedding IS NULL` se rellenan al arrancar.

---

## 6. Límites del plan Free

| Tema | Detalle |
|------|---------|
| RAM | 512 MB — justo para Spring sin DJL |
| Sleep | ~15 min sin tráfico → cold start lento |
| Disco | Efímero — uploads en `/app/uploads` se pierden al redeploy |
| DJL | No usar en Render free; volver a Oracle cuando haya cupo A1 |

---

## 7. Google OAuth / CORS

En Google Cloud Console, autorizá el origen del front y, si aplica, la URL del API Render.

---

## Volver a DJL (Oracle)

Cuando tengas **A1.Flex** con cupo:

- `BOT_EMBEDDING_PROVIDER=djl`
- `vector(384)` en Neon (o regenerar tras volver a MiniLM)
- `docker-compose.prod.yml` + `deploy/ORACLE.md`
