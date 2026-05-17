# Despliegue en Render (Neon + chat/embeddings)

Prueba rápida sin Oracle: backend en **Render**, Postgres en **Neon**. Por defecto en `render.yaml`: **chat gratis** en OpenRouter + **embeddings DJL** en la JVM (sin cargos de API por vectores).

```
Internet → Render (HTTPS) → Spring Boot
                              ↓
                         Neon (pgvector)
```

Render da HTTPS; no hace falta Caddy ni `docker-compose.prod.yml`.

---

## 1. Neon (si aún no está)

1. [neon.tech](https://neon.tech) → proyecto → activar **pgvector** en el proyecto (o en SQL Editor: `CREATE EXTENSION IF NOT EXISTS vector;`).
2. Desde el **Connection string** de Neon, definí en Render tres variables: `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD` (ver `backend/.env.render.example`).

Al **primer deploy**, el backend crea tablas del bot y agenda con **Hibernate** y aplica **Flyway** (V1–V4). No hace falta ejecutar `schema.sql` manual.

### Embeddings (dos columnas en BD)

El backend usa **`embedding_384`** (DJL, local) y **`embedding_1536`** (API/OpenRouter en Render). Al arrancar crea las columnas si faltan; **no hace falta** `ALTER` manual en Neon.

Render (recomendado $0): `BOT_EMBEDDING_PROVIDER=djl` + `BOT_CHAT_PROVIDER=api` + `BOT_CHAT_API_MODEL=openrouter/free` → columna **`embedding_384`**. Ver `backend/docs/EMBEDDING_SETUP.md`.

Si antes usaste `api` + `text-embedding-3-small`, los chunks pueden tener solo `embedding_1536`; al pasar a DJL el arranque rellena `embedding_384` (logs `[RAG-EMBED]` / `[DJL-EMBED]`).

---

## 2. OpenRouter y costos

1. [openrouter.ai](https://openrouter.ai) → API key (sigue haciendo falta para el chat aunque el modelo sea free).
2. **Evitar** en Environment de Render:
   - `BOT_CHAT_API_MODEL=meta-llama/llama-3.3-70b-instruct` (70B, de pago)
   - `BOT_EMBEDDING_PROVIDER=api` + `openai/text-embedding-3-small` si no querés pagar embeddings

### Config sin cargos OpenRouter (plan Free Render)

| Variable | Valor |
|----------|--------|
| `BOT_EMBEDDING_PROVIDER` | `djl` |
| `BOT_CHAT_PROVIDER` | `api` |
| `BOT_CHAT_API_MODEL` | `openrouter/free` |
| `BOT_API_BASE_URL` | `https://openrouter.ai/api` |
| `OPENROUTER_API_KEY` | tu key |

No definas `BOT_EMBEDDING_API_MODEL` con DJL. El RAG usa `embedding_384`.

**RAM:** DJL + Spring en 512 MB puede fallar; si el servicio no arranca, subí a **Starter** o dejá `BOT_EMBEDDING_PROVIDER=api` solo para embeddings (chat sigue con `openrouter/free`).

### Solo chat de pago (embeddings baratos)

```env
BOT_EMBEDDING_PROVIDER=api
BOT_EMBEDDING_API_MODEL=openai/text-embedding-3-small
BOT_CHAT_API_MODEL=openrouter/free
```

---

## 3. Crear el servicio en Render

### Opción A — Blueprint (`render.yaml` en la raíz)

1. [dashboard.render.com](https://dashboard.render.com) → **New** → **Blueprint**.
2. Conectá el repo `botai`.
3. Completá las variables marcadas como secretas (`SPRING_DATASOURCE_*`, `OPENROUTER_API_KEY`, `GOOGLE_*`, etc.).
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
| `BOT_EMBEDDING_PROVIDER` | `djl` (o `api` si preferís embeddings de pago) |
| `BOT_CHAT_PROVIDER` | `api` (con `djl`; obligatorio en Render sin Ollama) |
| `BOT_CHAT_API_MODEL` | `openrouter/free` |
| `OPENROUTER_API_KEY` | tu key |
| `BOT_API_BASE_URL` | `https://openrouter.ai/api` |
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://HOST:5432/neondb?sslmode=require` (sin usuario en la URL) |
| `SPRING_DATASOURCE_USERNAME` | usuario Neon |
| `SPRING_DATASOURCE_PASSWORD` | contraseña Neon |
| `AGENDA_PUBLIC_BASE_URL` | URL del front en Vercel (ej. `https://tu-app.vercel.app`) — ver [VERCEL.md](./VERCEL.md) |
| `AGENDA_UPLOADS_BASE_URL` | `https://TU-SERVICIO.onrender.com/uploads` |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | OAuth |

WhatsApp: credenciales en el panel del bot (`bot.whatsapp_*` en BD), no variables de entorno.

### Chat (OpenRouter)

Con `BOT_CHAT_PROVIDER=api` (o `BOT_EMBEDDING_PROVIDER=api`), el chat va por **OpenRouter**. Usá `openrouter/free` para no generar cargos por tokens de chat.

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
| RAM | 512 MB — DJL + Spring es justo; si OOM, plan Starter o embeddings `api` |
| Sleep | ~15 min sin tráfico → cold start lento |
| Disco | Efímero — uploads en `/app/uploads` se pierden al redeploy |
| OpenRouter | Modelos sin `:free` / distintos de `openrouter/free` generan cargo en el dashboard |

---

## 7. Google OAuth / CORS

En Google Cloud Console, autorizá el origen del front y, si aplica, la URL del API Render.

---

## Volver a DJL (Oracle)

Cuando tengas **A1.Flex** con cupo:

- `BOT_EMBEDDING_PROVIDER=djl`
- `vector(384)` en Neon (o regenerar tras volver a MiniLM)
- `docker-compose.prod.yml` + `deploy/ORACLE.md`
