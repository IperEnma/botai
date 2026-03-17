# Estrategia actual: IA y flujo de agendar

## Stack que usamos (no LangChain)

- **Backend:** Java 17 + Spring Boot 3.2
- **IA/LLM:** **Spring AI** (spring-ai-starter-model-ollama) → Ollama local
- **RAG:** propio (RagAiContextBuilder + KnowledgeService con pgvector)
- **Orquestación:** propia (IntentRouter, IntentClassifierService, ScopeGuard, BookAppointmentAction)

No usamos LangChain. Spring AI ya ofrece integración con modelos (Ollama, OpenAI, etc.), embeddings y en versiones recientes **function calling / tools**. Si más adelante quieres “tools” tipo LangChain, se puede hacer con Spring AI sin cambiar de stack.

---

## Flujo cuando el usuario escribe "quiero agendar una cita"

1. **Router** recibe el mensaje.
2. **Clasificador** (IntentClassifierService):
   - Si `bot.classifier.use-llm: true`: primero llama al **LLM** para clasificar (SALUDO | ACCION_CRM | PREGUNTA_GENERAL | MALA_INTENCION).
   - Si el LLM falla, hace timeout o devuelve algo no parseable → **fallback a keywords** ("agendar", "ver citas", etc.).
   - Si el LLM responde bien → se usa esa clasificación.
3. Si la clasificación es **ACCION_CRM book_appointment** y acciones están activas:
   - Se llama a **ActionDispatcher.startFromMenuOption** → **BookAppointmentAction.execute**.
   - La respuesta es la del flujo de agendar (servicios, fecha, hora, etc.).
4. Si la clasificación es **PREGUNTA_GENERAL** (o la acción devuelve `null`):
   - El mensaje sigue por FAQ/menú y, si no hay match, llega a **HybridAiService** (IA con RAG).
   - Se construye contexto (horario, servicios, knowledge) y se llama al **LLM**.
   - Si **el LLM falla** (Ollama caído, timeout, error) → se responde: **"Estamos procesando tu consulta. Por favor, intenta de nuevo en un momento."** y ahí se queda.

---

## Por qué a veces ves "Estamos procesando" y se queda ahí

Ese mensaje solo sale cuando **ya se está usando la IA** (HybridAiService) y **Ollama falla** (no responde, timeout o excepción). Eso puede pasar en dos casos:

1. **El clasificador mandó “agendar” a la IA:**  
   El LLM del clasificador devolvió PREGUNTA_GENERAL en vez de ACCION_CRM (o falló y el fallback por keywords no matcheó). Entonces el mensaje se trata como pregunta general y termina en la IA. Si además Ollama falla → "Estamos procesando".

2. **La acción de agendar devolvió `null`:**  
   Se detectó bien book_appointment pero BookAppointmentAction devolvió `null` en algún paso. El router no tiene respuesta de la acción y sigue; al final llega a la IA, y si Ollama falla → "Estamos procesando".

Además, si **Ollama no está levantado** o no es accesible (URL en `.env`), cualquier llamada al LLM (clasificador o respuesta) puede fallar; si esa llamada es la de la IA de respuesta, verás "Estamos procesando".

---

## Qué hacer para que "agendar una cita" no se quede en "procesando"

1. **Priorizar keywords para acciones conocidas**  
   Que frases con "agendar" (y otras acciones CRM) no dependan del LLM del clasificador: si el texto contiene la keyword, clasificar como ACCION_CRM aunque el LLM no se use o falle. Así "quiero agendar una cita" siempre entra al flujo de agendar.

2. **Comprobar Ollama**  
   - Backend y Ollama en la misma máquina/docker: que Ollama esté en marcha (`ollama serve` o el contenedor que uses).  
   - Revisar en `.env` / `application.yml`: `OLLAMA_BASE_URL` (ej. `http://localhost:11434`).

3. **Reducir dependencia del clasificador LLM para agendar**  
   Si quieres que agendar no dependa del LLM, pon en `application.yml`:
   ```yaml
   bot:
     classifier:
       use-llm: false
   ```
   Así el clasificador usa solo keywords y "agendar una cita" siempre dará ACCION_CRM book_appointment.

---

## Recomendación de framework

- **Seguir con Spring AI** (Ollama, y otros proveedores si los añades).
- **No hace falta LangChain** para este flujo; la orquestación (router, clasificador, acciones, RAG) ya la tenéis en Java.
- Si más adelante quieres **tools / function calling** (que el LLM decida llamar a “agendar_cita”, “ver_horario”, etc.), Spring AI tiene soporte para eso; se puede integrar en el mismo flujo sin pasar a LangChain.
