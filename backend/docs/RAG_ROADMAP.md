# Roadmap RAG — botai

Evolución del asistente (un solo flujo: clasificador → recuperación → LLM + tools → auto-revisión). Referencia de patrones: [25 tipos de RAG](https://medium.com/@rupeshit/mastering-the-25-types-of-rag-architectures-when-and-how-to-use-each-one-2ca0e4b944d7). Ver pipeline en [BOT_AGENDA_INTENTS.md](./BOT_AGENDA_INTENTS.md).

## Flujo actual (implementado)

| Pieza | Código |
|-------|--------|
| Embeddings + pgvector + fallback texto | `KnowledgeService`, `JpaKnowledgeRepository` |
| Query con historial de sesión | `RagQueryExpander`, `MessageHistoryService` |
| Filtro por topic (Agenda) | `RagTopicHintService` |
| Gate CRAG (similitud baja → sin fragmentos, usar tools) | `KnowledgeService.retrieveForTurn` |
| Contexto en prompt | `RagAiContextBuilder` |
| Sync chunks desde Agenda | `AgendaRagSourceSync` |
| Tools en vivo | `ConsultaTools`, `getHorario`, etc. |
| Auto-revisión | `bot.rag.self-review-enabled` |

### Configuración (`bot.rag` en `application.yml`)

```yaml
bot:
  rag:
    max-chunks: 3
    min-similarity: 0.0
    self-review-enabled: true
    history-turns-for-query: 2
    crag-min-avg-similarity: 0.52
    crag-min-chunk-similarity: 0.40
    retrieval-prefetch-multiplier: 2
```

Todo vive bajo **`bot.rag`**; no hay sub-bloques ni flags de “fases” distintas.

---

## Pendiente (mismo flujo, sin nuevos namespaces)

| Mejora | Beneficio |
|--------|-----------|
| Self-review con extracto de tool calls en FACTS | Coherencia con `getHorario` |
| Re-ranking post-retrieval | Mejor top-k |
| Métricas (0-chunk, CRAG reject) | Afinar umbrales en prod |
| Feedback 👍👎 por conversación | Ajustar chunks / `min-similarity` |

---

## Fuera de alcance

- Múltiples “arquitecturas RAG” conmutables.
- RAG para “mis citas” (SQL + teléfono canónico).
- Prefetch especulativo, aprendizaje agéntico sin evaluación, RAG de imágenes.
