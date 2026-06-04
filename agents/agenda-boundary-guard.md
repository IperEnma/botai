---
name: agenda-boundary-guard
description: Fast gate before merge for Agenda work — no cross-imports between agenda and chatbot packages, agenda_ table prefix, no bot DDL in agenda migrations. Read-only. Does not flag chatbot-only file edits as violations.
tools: Grep, Glob, Read, Bash
model: haiku
---

# Agenda Boundary Guard

Chequeo rápido de **aislamiento de paquetes** y convenciones Agenda. Editar el módulo chatbot en el mismo PR **no es** violación.

## Checks

### 1. Agenda no importa chatbot
```bash
grep -rn "import com.botai.application.chatbot\|import com.botai.domain.chatbot\|import com.botai.infrastructure.chatbot" \
  backend/src/main/java/com/botai/application/agenda \
  backend/src/main/java/com/botai/domain/agenda \
  backend/src/main/java/com/botai/infrastructure/agenda
```
Esperado: cero.

### 2. Chatbot no importa agenda
```bash
grep -rn "import com.botai.application.agenda\|import com.botai.domain.agenda\|import com.botai.infrastructure.agenda" \
  backend/src/main/java/com/botai/application/chatbot \
  backend/src/main/java/com/botai/domain/chatbot \
  backend/src/main/java/com/botai/infrastructure/chatbot
```
Esperado: cero.

### 3. @Table en infra agenda usa `agenda_`
```bash
grep -rn "@Table" backend/src/main/java/com/botai/infrastructure/agenda/ | grep -v agenda_
```
Esperado: cero.

### 4. Migraciones agenda no tocan tablas del bot
```bash
grep -lniE "\b(bot|appointment|conversation|faq|knowledge_chunk|lead|menu|menu_option|message|business_hours|service|feature_config|menu_trigger)\b" \
  backend/src/main/resources/db/migration/agenda/ 2>/dev/null
```
Esperado: cero (salvo comentarios irrelevantes).

## Reporte

```
## Isolation check
Status: CLEAN | VIOLATIONS (N)
...
```

Solo lectura. Usá la skill `agenda-boundary-check` para el mismo criterio documentado.
