# Análisis: uso de Spring AI Tools en el chatbot

## Qué son los Tools en Spring AI

Los **tools** (function calling) permiten que el **modelo decida** cuándo llamar a una función Java y con qué argumentos. Spring AI:

1. Registra funciones como beans (p. ej. `get_horario`, `listar_servicios`, `agendar_cita`).
2. Genera el JSON schema de cada función y se lo envía al modelo en el prompt.
3. Cuando el modelo responde con "llamar a la función X con argumentos Y", Spring ejecuta esa función en Java.
4. El resultado se devuelve al modelo, que lo usa para generar la respuesta final al usuario.

**Requisitos con Ollama:** Ollama 0.2.8+ y un modelo con soporte de tools (p. ej. Llama 3.1, Mistral, en la [sección Tools de ollama.com](https://ollama.com/search?c=tools)).

---

## Flujo actual (sin tools)

```
Usuario: "quiero agendar una cita"
    → Clasificador (keyword o LLM): ACCION_CRM book_appointment
    → Router: ActionDispatcher.startFromMenuOption(book_appointment)
    → BookAppointmentAction.execute(): flujo multi-paso (servicio → fecha → hora → nombre → doc → confirmar)
    → Respuesta: "¿Qué servicio deseas y para qué fecha? Servicios: X, Y."
```

Para preguntas generales:

```
Usuario: "¿qué horarios tienen?"
    → Clasificador: PREGUNTA_GENERAL
    → Router: llega a RagLlmChatService (turno generativo completo)
    → RagAiContextBuilder construye contexto (horario, servicios, knowledge) en texto
    → Una llamada al LLM con ese contexto
    → Respuesta generada por el modelo
```

**Ventajas del flujo actual:** predecible, keywords primero (agendar no se pierde), flujos CRM con estado claro (paso a paso), un solo tipo de llamada al LLM (chat con contexto).

---

## Oportunidad de usar Tools

### Escenario A: Tools solo para “lectura” (recomendado como primer paso)

Exponer herramientas que **solo consultan** datos y dejar que el modelo las use cuando haga falta:

| Tool              | Descripción                         | Uso típico                          |
|-------------------|-------------------------------------|-------------------------------------|
| `get_horario`     | Devuelve horario del tenant         | "¿qué horarios tienen?"             |
| `listar_servicios`| Devuelve servicios activos          | "¿qué servicios ofrecen?"           |
| `buscar_conocimiento` | Búsqueda RAG por pregunta       | Preguntas que no son horario/servicios |

**Flujo:** Una sola llamada al LLM con (system prompt + historial + mensaje del usuario + tools). El modelo puede:

- Llamar `get_horario()` y responder con ese texto.
- Llamar `listar_servicios()` y listar los servicios.
- Llamar `buscar_conocimiento(pregunta)` y responder con el fragmento relevante.

**Ventajas:** El modelo elige qué dato necesita; no hace falta inyectar horario/servicios/knowledge a mano en el prompt (RagAiContextBuilder se simplifica o se complementa). Respuestas más alineadas con la pregunta.

**Desventajas:** Hay que usar un modelo con soporte de tools en Ollama; si el modelo no llama a la tool, la respuesta puede ser genérica o inventada.

### Escenario B: Tools también para “agendar” (más ambicioso)

Exponer algo como `agendar_cita(servicio, fecha, hora)` o herramientas por paso (`solicitar_agendar`, `confirmar_datos_cita`, etc.).

**Problema:** El agendar actual es **multi-turn y con estado** (servicio → fecha → hora → nombre → documento → confirmar). Un solo tool call no cubre todo. Opciones:

1. **Un tool por paso:** `set_booking_service(serviceName)`, `set_booking_date(date)`, `set_booking_time(time)`, … El modelo iría llamando tools según lo que el usuario vaya diciendo. Habría que mantener estado de “booking en curso” (p. ej. en conversación) y que el backend lo asocie al mismo flujo.
2. **Un solo tool “agendar” con todos los parámetros opcionales:** `agendar_cita(servicio?, fecha?, hora?, nombre?, documento?)`. Cuando el modelo tenga suficiente información, llama con todo; si falta algo, el modelo pide al usuario. El backend crea la cita cuando lleguen todos los datos obligatorios.

**Ventajas:** Un único camino “IA + tools” para todo; el modelo orquesta pregunta + acciones.

**Desventajas:** Más complejidad (estado, timeouts, mensajes a medio completar); dependencia fuerte de que el modelo llame bien las tools; depuración más difícil que el flujo actual paso a paso.

---

## Cómo lo veo: recomendación

### 1. Sí hay oportunidad de usar Tools de Spring AI

Encajan sobre todo para:

- **Consultas:** horario, servicios, conocimiento. El modelo decide si llama `get_horario`, `listar_servicios` o `buscar_conocimiento` y responde con eso.
- **Unificar “qué datos usar”:** en lugar de (o además de) construir un bloque de texto con horario/servicios en RagAiContextBuilder, el modelo pide los datos vía tools cuando los necesite.

### 2. Enfoque híbrido (recomendado)

- **Mantener** el router actual y el clasificador con **keywords primero** para acciones CRM (agendar, ver citas). Así “quiero agendar una cita” sigue siendo robusto aunque el modelo falle o no tenga tools.
- **Añadir** un camino “IA con tools” para **preguntas generales** cuando la IA esté activa:
  - Si clasificador → PREGUNTA_GENERAL (o saludo que quieras responder con datos), ir a **RagLlmChatService** (ChatClient con tools).
  - En esa llamada al LLM: system prompt (rol, instrucciones) + historial + mensaje del usuario + tools `get_horario`, `listar_servicios`, `buscar_conocimiento`.
  - El modelo opcionalmente llama tools y genera la respuesta; vosotros seguís validando (p. ej. no inventar) con la salida del modelo.

Así no sustituyes de golpe el flujo de agendar por tools; solo enriqueces la rama de “preguntas” con tools.

### 3. Agendar: mantener flujo actual de acciones

Para **agendar** (y en general flujos multi-paso con estado), mantendría el diseño actual:

- Clasificador (keyword) → `BookAppointmentAction` con pasos bien definidos.
- Opcional más adelante: que el **primer** mensaje de agendar (“quiero X para mañana”) pueda rellenar servicio/fecha por parsing (como ya hacéis) y, si os interesa, que una tool “solo consulta” devuelva servicios/horario para que el modelo sugiera opciones; pero el flujo de “guardar cita” seguiría en `BookAppointmentAction`.

### 4. Resumen

| Área              | ¿Usar Tools? | Comentario |
|-------------------|--------------|------------|
| Horario / servicios / knowledge | **Sí (opcional)** | Tools de lectura; el modelo elige qué consultar. |
| Agendar / ver citas             | **No por ahora**  | Mantener router + acciones; posible tool de “consulta” más adelante. |
| Clasificador (saludo, CRM, pregunta) | **No**      | Dejar keywords + LLM actual; tools no reemplazan esto. |

Implementación técnica: Spring AI expone esto vía `ChatClient` con `.functions("getHorario", "listarServicios")` o registrando beans `Function<Request, Response>` con `@Description`. Tu `SpringAiLanguageModel` hoy usa `ChatModel.call(prompt)`; para tools necesitarías usar la API que permita pasar funciones (p. ej. `ChatClient` o el builder de prompt con tools del modelo que use Spring AI para Ollama). Conviene revisar la versión exacta de Spring AI que usáis (1.0.x) y la doc de [Ollama Chat](https://docs.spring.io/spring-ai/reference/api/chat/ollama-chat.html) y [Ollama Tool Support](https://spring.io/blog/2024/07/26/spring-ai-with-ollama-tool-support) para el código concreto.

---

## Próximos pasos concretos

1. **Probar un modelo con tools en Ollama** (p. ej. `ollama run mistral` o el que indique la doc).
2. **Definir 1–2 tools de solo lectura** (p. ej. `get_horario(tenantId)`, `listar_servicios(tenantId)`) como beans `Function<..., ...>` con `@Description`.
3. **Crear un camino “IA con tools”** opcional (feature flag o tenant): en vez de `RagAiContextBuilder` + una sola llamada sin tools, hacer una llamada al LLM con esas tools y system prompt mínimo; el modelo llama las tools y responde.
4. **Mantener** el flujo actual de agendar (router + clasificador + `BookAppointmentAction`) como está.

Si quieres, el siguiente paso puede ser esbozar en código cómo quedaría un `get_horario(tenantId)` como tool y cómo enlazarlo a `RagLlmChatService` (tools ya soportados vía ChatClient).

---

## Validar Ollama por comando (sin código)

Desde la terminal, contra la URL que uses (por defecto `http://localhost:11434`):

**¿Está Ollama en marcha y qué modelos hay?**

```bash
curl http://localhost:11434/api/tags
```

**¿Responde el modelo de chat?** (sustituye `llama3` por tu `OLLAMA_MODEL`)

```bash
curl http://localhost:11434/api/generate -d "{\"model\":\"llama3\",\"prompt\":\"Hola\",\"stream\":false}"
```

Si `OLLAMA_BASE_URL` es otra (ej. en otro host/puerto), cambia la URL en los comandos.
