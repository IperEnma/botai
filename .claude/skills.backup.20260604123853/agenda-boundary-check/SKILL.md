---
name: agenda-boundary-check
description: Chequeo rápido pre-commit de la frontera entre com.botai.agenda y com.botai.chatbot. Verifica que no haya imports cruzados, archivos del bot tocados, ni violaciones de convención de prefijo agenda_. Devuelve un reporte en 5 segundos.
---

# agenda-boundary-check

Chequeo rápido de boundaries. Corre estos 6 checks, en este orden, y devuelve un reporte.

## Cuándo usar

- Antes de cada commit que tocó código de AGENDA.
- Como último paso en cualquier flujo de implementación.
- Cuando sospechás que un refactor pudo haber cruzado la frontera.

## Checks

### 1. Agenda → Chatbot
```bash
grep -rn "import com.botai.chatbot" backend/src/main/java/com/botai/agenda/ 2>/dev/null
```
Esperado: vacío.

### 2. Chatbot → Agenda
```bash
grep -rn "import com.botai.agenda" backend/src/main/java/com/botai/chatbot/ 2>/dev/null
```
Esperado: vacío.

### 3. Archivos del bot modificados
```bash
git status --porcelain backend/src/main/java/com/botai/chatbot/
git status --porcelain backend/src/main/resources/
```
Esperado: ninguno modificado (a menos que el usuario lo haya autorizado explícitamente).

### 4. BotFeatures / BotEntity intactos
```bash
git diff HEAD -- '**/BotFeatures.java' '**/BotEntity.java'
```
Esperado: vacío.

### 5. Prefijo `agenda_` en @Table
```bash
grep -rn "@Table" backend/src/main/java/com/botai/agenda/ | grep -v 'agenda_'
```
Esperado: vacío. Cualquier línea con `@Table(name = "...")` sin `agenda_` es violación.

### 6. Tablas del bot no aparecen en migraciones de AGENDA
```bash
grep -liE "\b(bot|appointment|conversation|faq|knowledge_chunk|lead|menu|menu_option|message|business_hours|service|feature_config|menu_trigger)\b" backend/src/main/resources/db/migration/agenda/*.sql 2>/dev/null
```
Esperado: ningún archivo listado.

## Formato del reporte

Corto, visual, accionable. Ejemplo cuando todo OK:

```
✅ Boundary check: CLEAN
  - agenda → chatbot:      0 imports
  - chatbot → agenda:      0 imports
  - archivos bot:          0 modificados
  - BotFeatures/BotEntity: intactos
  - @Table sin prefijo:    0
  - migraciones cruzadas:  0
```

Ejemplo con violaciones:

```
❌ Boundary check: VIOLATIONS (2)

  1. backend/.../FooUseCase.java:14
     import com.botai.chatbot.domain.model.Lead;
     → FIX: crear un modelo equivalente en com.botai.agenda.domain.model o pasar datos vía DTO.

  2. backend/.../BarEntity.java:18
     @Table(name = "bar")
     → FIX: @Table(name = "agenda_bars").

  Status: NO APTO PARA MERGE
```

## Acción

Esta skill **no corrige**. Si hay violaciones, reportalas claramente y sugerí usar `agenda-implementer` para arreglarlas, o escalalas al usuario.
