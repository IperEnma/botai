# Roadmap RAG — botai

Referencia de evolución del asistente (Spring AI + `knowledge_chunk` + tools). Inspirado en patrones del artículo [25 tipos de RAG](https://medium.com/@rupeshit/mastering-the-25-types-of-rag-architectures-when-and-how-to-use-each-one-2ca0e4b944d7), priorizando lo aplicable a un chatbot multi-tenant de negocios (Agenda + WhatsApp).

**Estado actual (baseline):** RAG semántico (pgvector) + fallback textual, sync `AgendaRagSourceSync`, tools en vivo (`getHorario`, etc.), clasificador de intención, memoria de sesión, auto-revisión opcional (`bot.rag.self-review-enabled`). Ver también [BOT_AGENDA_INTENTS.md](./BOT_AGENDA_INTENTS.md).

---

## Fase 1 — Calidad de retrieval ✅ (implementada)

| Pieza | Descripción | Config |
|-------|-------------|--------|
| **Query expansion** | Consulta de embedding = mensaje actual + hasta 2 turnos previos de la sesión (`MessageHistoryService`). | `bot.rag.phase1.history-turns-for-query` (default `2`) |
| **Filtro por topic** | Heurísticas en español priorizan prefijos de topic (`Agenda: Horarios`, `Agenda: Servicios`, etc.) en SQL y en fallback textual. | `bot.rag.phase1.enabled` |
| **CRAG gate** | Tras recuperar con distancia coseno: descarta chunks por debajo de umbral; si no queda ninguno o la similitud media es baja → turno sin fragmentos (solo tools + reglas). | `bot.rag.phase1.min-chunk-similarity`, `bot.rag.phase1.min-avg-similarity` |

**Código:** `RagQueryExpander`, `RagTopicHintService`, `KnowledgeService.retrieveForTurn`, `RagAiContextBuilder`.

**Desactivar Fase 1:** `bot.rag.phase1.enabled: false` → comportamiento anterior (`findRelevant` directo sobre el mensaje del usuario).

---

## Fase 2 — Coherencia de respuesta (pendiente)

| Idea | Beneficio |
|------|-----------|
| Self-review con extracto de **tool calls** del turno en FACTS | El revisor no contradice horarios devueltos por `getHorario` |
| Re-ranking ligero o reglas post-retrieval | Mejor top-k cuando hay muchos chunks por tenant |
| Prioridad explícita horarios → tool en prompt si CRAG rechazó chunks de horario | Menos respuestas con horarios desactualizados en RAG |

---

## Fase 3 — Producto y observabilidad (pendiente)

| Idea | Beneficio |
|------|-----------|
| Métricas: tasa 0-chunk, CRAG reject, tool vs RAG | Afinar umbrales en prod |
| Feedback tenant (👍/👎) ligado a conversación | Ajustar `min-similarity` / chunks malos |
| Citas / XAI light en logs (`topic` usado) | Confianza del dueño del bot |

---

## Qué no está en el roadmap

- 25 “arquitecturas” conmutables (mantenimiento inviable).
- RAG para “mis citas” (SQL + teléfono canónico es correcto).
- Speculative prefetch, Agenetic/Self-RAG sin pipeline de evaluación, Attention U-Net (visión), ECO/Cost-Constrained como producto.

---

## Referencia rápida: qué ya teníamos antes de Fase 1

| Patrón | En botai |
|--------|----------|
| Naive / hybrid RAG | `KnowledgeService` + pgvector + fallback texto |
| Corrective (parcial) | Self-review + `ResponseValidator` |
| Tools / Replug | `ConsultaTools`, `AgendarTools`, `AgendaHorarioTextService` |
| Memo / conversacional | `ChatMemory`, `MessageHistoryService` |
| Rule-based | `IntentClassifierService`, `JailbreakInputFilter`, routing CRM |
| Auto sync | `AgendaRagSourceSync`, `AgendaKnowledgeChunkRefresher` |
