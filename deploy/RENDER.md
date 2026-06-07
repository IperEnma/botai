# Despliegue en Render (Neon + OpenRouter free)

Backend en **Render**, Postgres en **Neon**. Sin DJL en el servidor: **chat** y **embeddings** por OpenRouter con modelos **$0** (`openrouter/free` + `nvidia/llama-nemotron-embed-vl-1b-v2:free`).

```
Internet → Render (HTTPS) → Spring Boot → OpenRouter (chat + embeddings)
                              ↓
                         Neon (pgvector)
```

---

## 1. Neon (si aún no está)

1. [neon.tech](https://neon.tech) → activar **pgvector** (`CREATE EXTENSION IF NOT EXISTS vector;`).
2. Tres variables en Render: `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD` (ver `backend/.env.render.example`).

### Embeddings en BD

| Columna | Cuándo |
|---------|--------|
| `embedding_384` | Render $0 (Nemotron free + `BOT_EMBEDDING_API_DIMENSIONS=384`) |
| `embedding_1536` | Solo si usás `openai/text-embedding-3-small` (de pago) |

Si antes tenías `text-embedding-3-small`, al cambiar a Nemotron free el sync rellena `embedding_384` (logs `[RAG-EMBED]` / `[EMBED-API]`).

### Base de datos: solo greenfield

Este proyecto **no usa `ALTER TABLE` ni parches sobre BDs ya desplegadas**. El schema vigente está en el repo (`@Entity` + Flyway V1–V7 de suplemento). Si una instancia Postgres (Neon/Render) quedó con un schema viejo, **recreá la base desde cero** — no ejecutes SQL manual en prod para “arreglar” columnas.

**Migraciones:** [backend/docs/AGENDA_FLYWAY_MIGRATIONS.md](../backend/docs/AGENDA_FLYWAY_MIGRATIONS.md) — secuencia V1–V7; tablas con entidad JPA (p. ej. `agenda_uploaded_files`) **no** tienen migración Flyway.

Si aplicaste por error `V8__agenda_uploaded_files` en Render/Neon: la tabla es válida (duplicada con Hibernate); al eliminar V8 del repo, **recreá la BD** o borrá la fila `version = '8'` de `agenda_flyway_schema_history` antes del próximo deploy.

---

## 2. OpenRouter $0 (copiar al dashboard)

| Variable | Valor |
|----------|--------|
| `BOT_EMBEDDING_PROVIDER` | `api` |
| `BOT_API_BASE_URL` | `https://openrouter.ai/api` |
| `OPENROUTER_API_KEY` | tu key |
| `BOT_EMBEDDING_API_MODEL` | `nvidia/llama-nemotron-embed-vl-1b-v2:free` |
| `BOT_EMBEDDING_API_DIMENSIONS` | `384` |
| `BOT_CHAT_API_MODEL` | `openrouter/free` |

**No usar** (generan cargo): `meta-llama/llama-3.3-70b-instruct`, `openai/text-embedding-3-small`, `BOT_EMBEDDING_PROVIDER=djl` en Render.

Nemotron free admite Matryoshka; con `384` usamos la columna `embedding_384` ya existente.

---

## 3. Crear el servicio en Render

### Opción A — Blueprint (`render.yaml`)

New → Blueprint → repo → completar secretos → Apply.

### Opción B — Manual

Root Directory: `backend`, Docker, Health: `/actuator/health`, variables desde `backend/.env.render.example`.

---

## 4. Variables obligatorias

| Variable | Valor |
|----------|--------|
| `JAVA_OPTS` | `-Xmx384m` |
| `BOT_EMBEDDING_PROVIDER` | `api` |
| `BOT_EMBEDDING_API_MODEL` | `nvidia/llama-nemotron-embed-vl-1b-v2:free` |
| `BOT_EMBEDDING_API_DIMENSIONS` | `384` |
| `BOT_CHAT_API_MODEL` | `openrouter/free` |
| `OPENROUTER_API_KEY` | tu key |
| `SPRING_DATASOURCE_*` | Neon |
| `AGENDA_PUBLIC_BASE_URL` | URL Vercel |
| `AGENDA_UPLOADS_BASE_URL` | `https://TU-SERVICIO.onrender.com/uploads` |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | OAuth |

---

## 5. Deploy y comprobación

- `https://TU-SERVICIO.onrender.com/actuator/health`
- Logs: `[EMBED-API] ... nemotron ... 384`, Flyway OK, sin errores OpenRouter.

```sql
SELECT id, topic, embedding_384 IS NOT NULL AS ok
FROM knowledge_chunk WHERE active = true LIMIT 10;
```

---

## 6. Límites plan Free

| Tema | Detalle |
|------|---------|
| RAM | 512 MB — sin DJL; solo HTTP a OpenRouter |
| Sleep | Cold start ~15 min sin tráfico |
| OpenRouter | Modelos sin `:free` / `openrouter/free` pueden cobrar |

---

## 7. Google OAuth / CORS

Origen del front + URL del API en Google Cloud Console.

---

## DJL local (Oracle / dev)

Solo si tenés RAM en el servidor (`BOT_EMBEDDING_PROVIDER=djl`). Ver `deploy/ORACLE.md`.
