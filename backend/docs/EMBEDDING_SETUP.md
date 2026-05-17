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

Antes de usar el modelo: `ollama pull nomic-embed-text` (768 dims → alinear columna `knowledge_chunk.embedding`).

Con `BOT_EMBEDDING_PROVIDER=api`, el **chat** del bot también usa OpenRouter (`BOT_CHAT_API_MODEL`). En local con `djl`, el chat sigue en Ollama (`OLLAMA_BASE_URL`, `OLLAMA_MODEL`).

---

## Dimensiones en PostgreSQL

Si cambiás de proveedor o modelo, la columna `embedding` debe tener las **mismas dimensiones** que el modelo. Tras cambiar: vaciar/regenerar vectores (`embedding IS NULL` y reiniciar el backend).

| Modelo típico | Dimensiones |
|---------------|-------------|
| DJL MiniLM (default) | 384 |
| Ollama `nomic-embed-text` | 768 |
| OpenAI `text-embedding-3-small` | 1536 |

---

## Base de datos (PostgreSQL + pgvector)

- Imagen con pgvector (ej. `pgvector/pgvector:pg16`).
- Hibernate crea `knowledge_chunk.embedding` como `vector(384)` por defecto (DJL MiniLM).

Si la base ya existía sin pgvector:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
ALTER TABLE knowledge_chunk ADD COLUMN IF NOT EXISTS embedding vector(384);
```

## Arranque

1. **RagSourceSync** crea/actualiza chunks sintéticos (`embedding = NULL`).
2. **KnowledgeChunkEmbeddingSync** rellena vectores si hay `EmbeddingModel`.

Sin modelo configurado, el RAG semántico no devuelve chunks (no hay fallback por palabras clave en producción).

## Si ves "RAG Búsqueda semántica: 0 chunks"

1. Chunks con `embedding IS NULL` → revisar logs `[RAG-EMBED]` / `[EMBED-API]`.
2. Sin chunks para el `tenant_id`.
3. Dimensiones del vector ≠ modelo actual.
