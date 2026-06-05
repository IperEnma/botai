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
| Auto-revisión | `RagLlmChatService` (siempre en pipeline generativo) |

### Umbrales (`bot.rag.*` en `application.yml`)

`max-chunks`, `min-similarity`, `history-turns-for-query`, `crag-min-*`, etc. Ver `BotProperties.java`.

---

## Pendiente (mismo flujo, sin nuevos namespaces)

| Mejora | Beneficio |
|--------|-----------|
| Self-review con extracto de tool calls en FACTS | Coherencia con `getHorario` |
| Re-ranking post-retrieval | Mejor top-k |
| Métricas (0-chunk, CRAG reject) | Afinar umbrales en prod |

**Implementado:** feedback al cliente al cerrar conversación, FAQ FIXED/RAG_HINT, lessons, metadata chunks, límites tools, stages LLM. Ver [BOT_IMPLEMENTATION.md](./BOT_IMPLEMENTATION.md).

---

## Fuera de alcance

- Múltiples “arquitecturas RAG” conmutables.
- RAG para “mis citas” (SQL + teléfono canónico).
- Prefetch especulativo, aprendizaje agéntico sin evaluación, RAG de imágenes.
