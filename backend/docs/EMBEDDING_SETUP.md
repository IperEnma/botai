# Preparación para embeddings (RAG semántico)

## Configuración rápida

Dos modos, una variable:

| `BOT_EMBEDDING_PROVIDER` | Uso |
|--------------------------|-----|
| **`djl`** (default) | Local en JVM (MiniLM, **384** dims). Dev / máquina con RAM. |
| **`api`** | Cualquier API **OpenAI-compatible** por HTTPS (poco RAM). |

### OpenRouter (Render / prod)

```env
BOT_EMBEDDING_PROVIDER=api
OPENROUTER_API_KEY=sk-or-v1-...
# opcional:
# BOT_EMBEDDING_API_MODEL=openai/text-embedding-3-small
# BOT_EMBEDDING_API_BASE_URL=https://openrouter.ai/api
```

### Ollama (misma idea: es una API)

Ollama expone `/v1/embeddings`. No hace falta un proveedor aparte: usá **`api`** apuntando a Ollama:

```env
BOT_EMBEDDING_PROVIDER=api
BOT_EMBEDDING_API_BASE_URL=http://localhost:11434
BOT_EMBEDDING_API_MODEL=nomic-embed-text
# Ollama no valida la key; el default "ollama" alcanza si no definís OPENROUTER_API_KEY
```

Antes de usar el modelo: `ollama pull nomic-embed-text` (768 dims — hoy solo soportamos columnas 384 y 1536).

Con `BOT_EMBEDDING_PROVIDER=api`, el **chat** del bot también usa OpenRouter (`BOT_CHAT_API_MODEL`). En local con `djl`, el chat sigue en Ollama (`OLLAMA_BASE_URL`, `OLLAMA_MODEL`).

---

## Dimensiones en PostgreSQL (dos columnas)

`knowledge_chunk` tiene **dos columnas** de vectores (el arranque las crea si faltan):

| Columna | Uso |
|---------|-----|
| `embedding_384` | DJL local (`BOT_EMBEDDING_PROVIDER=djl`) |
| `embedding_1536` | API / OpenRouter (`BOT_EMBEDDING_PROVIDER=api`, modelo 1536-d) |

Solo se lee/escribe la columna del proveedor activo. Podés usar **la misma Neon** en Render (API) y Postgres local (DJL) sin `ALTER` que rompa el otro entorno.

Opcional en Render: `BOT_EMBEDDING_API_DIMENSIONS=1536` (default).

Si cambiás de modelo API a otra dimensión no soportada (384 o 1536), hay que extender el código; hoy solo esas dos.

---

## Base de datos (PostgreSQL + pgvector)

- Imagen con pgvector (ej. `pgvector/pgvector:pg16`).
- Flyway agenda V1 crea la extensión `vector`.
- Hibernate (`ddl-auto=update`) crea `knowledge_chunk` con `embedding_384` y `embedding_1536` según `KnowledgeChunkEntity` (BD nueva o tras borrar tablas).

## Arranque

1. **AgendaRagSourceSync** crea/actualiza chunks (vectores vía JDBC en la columna del proveedor activo).
2. **KnowledgeChunkEmbeddingSync** rellena la columna que corresponda (`embedding_384` o `embedding_1536`).

Sin modelo configurado, el RAG semántico no devuelve chunks (no hay fallback por palabras clave en producción).

## Si ves "RAG Búsqueda semántica: 0 chunks"

1. Chunks sin vector en la columna activa → revisar logs `[RAG-EMBED]` / `[EMBED-API]`.
2. Sin chunks para el `tenant_id`.
3. Dimensiones del vector ≠ modelo actual.
