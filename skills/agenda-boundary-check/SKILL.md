---
name: agenda-boundary-check
description: Chequeo pre-commit de aislamiento entre paquetes agenda y chatbot (sin imports cruzados) y convenciones Agenda (prefijo agenda_, migraciones). No bloquea edits al bot. Reporte en segundos.
metadata:
  author: botai
  version: "1.1"
  scope: [root, backend]
  auto_invoke:
    - "Before committing Agenda changes"
    - "Verifying agenda/chatbot package isolation (no cross-imports)"
---

# agenda-boundary-check

Valida **aislamiento técnico** entre dominios, no prohíbe trabajar en chatbot.

## Cuándo usar

- Commit que tocó código **Agenda**.
- Refactor que pudo introducir `import` entre `agenda` y `chatbot`.

## Checks

### 1. Agenda → Chatbot
```bash
grep -rn "import com.botai.application.chatbot\|import com.botai.domain.chatbot\|import com.botai.infrastructure.chatbot" \
  backend/src/main/java/com/botai/application/agenda \
  backend/src/main/java/com/botai/domain/agenda \
  backend/src/main/java/com/botai/infrastructure/agenda 2>/dev/null
```
Esperado: vacío.

### 2. Chatbot → Agenda
```bash
grep -rn "import com.botai.application.agenda\|import com.botai.domain.agenda\|import com.botai.infrastructure.agenda" \
  backend/src/main/java/com/botai/application/chatbot \
  backend/src/main/java/com/botai/domain/chatbot \
  backend/src/main/java/com/botai/infrastructure/chatbot 2>/dev/null
```
Esperado: vacío.

### 3. Prefijo `agenda_` en @Table (solo paquete agenda)
```bash
grep -rn "@Table" backend/src/main/java/com/botai/infrastructure/agenda/ | grep -v 'agenda_'
```
Esperado: vacío.

### 4. Tablas del bot no en migraciones Agenda
```bash
grep -liE "\b(bot|appointment|conversation|faq|knowledge_chunk|lead|menu|menu_option|message|business_hours|service|feature_config|menu_trigger)\b" \
  backend/src/main/resources/db/migration/agenda/*.sql 2>/dev/null
```
Esperado: ningún archivo listado.

## Formato del reporte

```
✅ Isolation check: CLEAN
  - agenda → chatbot:      0 imports
  - chatbot → agenda:      0 imports
  - @Table sin agenda_:    0
  - migraciones cruzadas:  0
```

Con violaciones: listar archivo:línea y fix sugerido (DTO, puerto, evento — no import de dominio).

## Acción

Solo reporta. No implica que los archivos del bot no puedan haberse modificado en el mismo PR.
