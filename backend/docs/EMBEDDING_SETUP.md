# Preparación para embeddings (RAG semántico)

Para que la búsqueda por vectores funcione, hace falta lo siguiente.

## 1. Base de datos (PostgreSQL + pgvector)

- **Imagen/contenedor:** usar una imagen con la extensión pgvector (ej. `pgvector/pgvector:pg16`).
- **Extensión:** en el primer arranque se ejecuta `schema.sql`, que incluye:
  - `CREATE EXTENSION IF NOT EXISTS vector;`
  - tabla `knowledge_chunk` con columna `embedding vector(768)`
  - `ALTER TABLE knowledge_chunk ADD COLUMN IF NOT EXISTS embedding vector(768)` por si la tabla fue creada antes por Hibernate sin esa columna.

Si la base ya existía sin pgvector, crear la extensión manualmente:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
ALTER TABLE knowledge_chunk ADD COLUMN IF NOT EXISTS embedding vector(768);
```

## 2. Ollama y modelo de embeddings

- **Ollama** en marcha y accesible (por defecto `http://localhost:11434`; configurable con `OLLAMA_BASE_URL`).
- **Modelo de embeddings** descargado. Por defecto se usa `nomic-embed-text` (768 dimensiones, coincide con `vector(768)`):

```bash
ollama pull nomic-embed-text
```

Para otro modelo (ej. multilingüe), configurar en `.env`:

```env
OLLAMA_EMBEDDING_MODEL=paraphrase-multilingual-MiniLM-L12-v2
```

y hacer `ollama pull <nombre>` según el modelo elegido. Si el modelo usa otras dimensiones (ej. 384), hay que cambiar en BD el tamaño del vector (ej. `vector(384)`).

## 3. Arranque de la aplicación

Al arrancar el backend:

1. **RagSourceSync** crea/actualiza los chunks sintéticos de horario y servicios por tenant (con `embedding = NULL`).
2. **KnowledgeChunkEmbeddingSync** (si existe `EmbeddingModel`) rellena `embedding` para todos los chunks con `embedding IS NULL`.

Si Ollama no está disponible o no hay modelo de embeddings, el bean `EmbeddingModel` no se crea y no se generan vectores; el RAG sigue funcionando con búsqueda por palabras clave.

## Si en logs ves "RAG Búsqueda semántica: 0 chunks"

Significa que la búsqueda por vectores no devolvió ningún fragmento. Suele deberse a:

1. **Chunks con `embedding` NULL**  
   La búsqueda solo usa filas con `embedding IS NOT NULL`. Si Ollama no estaba disponible en el arranque o el sync falló, los chunks quedan sin vector. **Solución:** tener Ollama + modelo de embeddings levantados y reiniciar el backend para que `KnowledgeChunkEmbeddingSync` rellene los vectores al arranque.

2. **Ningún chunk para ese tenant**  
   Comprueba en BD que existan filas en `knowledge_chunk` (o los sintéticos de horario/servicios) para el `tenant_id` del bot.

3. **Dimensiones distintas**  
   El modelo de embeddings debe usar 768 dimensiones (ej. `nomic-embed-text`); la columna es `vector(768)`. Si cambias de modelo, revisa las dimensiones.

Mientras no haya vectores, el RAG sigue funcionando con **búsqueda por palabras clave** y las secciones fijas de horario y servicios en el prompt, por eso preguntas como "¿qué horarios tienen?" pueden responderse bien igualmente.

## Resumen

| Requisito              | Acción |
|------------------------|--------|
| PostgreSQL             | Usar imagen con pgvector (ej. `pgvector/pgvector:pg16`). |
| Columna `embedding`    | Asegurada con `schema.sql` o el `ALTER TABLE` anterior. |
| Ollama en ejecución    | `ollama serve` o equivalente. |
| Modelo de embeddings   | `ollama pull nomic-embed-text` (o el configurado). |
