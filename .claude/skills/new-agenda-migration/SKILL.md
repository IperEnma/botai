---
name: new-agenda-migration
description: Crea una migración Flyway nueva bajo backend/src/main/resources/db/migration/agenda/ siguiendo la convención V<N>__agenda_<descripcion>.sql. Valida que el nombre tenga prefijo agenda_, que no toque tablas del bot, y que el número de versión sea correlativo. Úsese cuando hay un cambio de schema aislado.
---

# new-agenda-migration

Crea una migración Flyway aislada para el módulo AGENDA.

## Cuándo usar

- "Agregá un índice a agenda_bookings"
- "Necesitamos una columna notes en agenda_businesses" → **no** migración `ALTER`; actualizar `BusinessEntity` y recrear BD.
- "Seed de categorías iniciales"

No usar si:
- Es parte de una feature completa (usá `new-agenda-feature`, que ya incluye la migración).
- Tocarías tablas del bot (`bot`, `appointment`, `conversation`, etc.) → **NO procedas**, escalá al usuario.

## Pasos

### 1. Validar alcance
Confirmar que:
- La migración toca **solo** tablas con prefijo `agenda_`.
- Si hay DROP o ALTER de una tabla que no existe aún, no es una migración correctiva; es un error → preguntar.

### 2. Calcular próxima versión
Solo si el cambio **no** es una columna nueva en una tabla ya modelada por JPA: en greenfield el schema va en `@Entity` + recrear BD (ver `CLAUDE.md` → *Política greenfield*). Flyway en este repo es para índices, constraints, seeds y tablas sin entidad — **no** `ALTER TABLE ... ADD COLUMN`.

```bash
ls backend/src/main/resources/db/migration/agenda/ 2>/dev/null | grep -oP '^V\d+' | sort -V | tail -1
```
Si no existe la carpeta, `V1`. Si la última es `V7`, la próxima es `V8`.

### 3. Elegir nombre
Formato: `V<N>__agenda_<snake_case_descripcion>.sql`

Ejemplos:
- `V3__agenda_add_notes_to_businesses.sql`
- `V5__agenda_seed_default_categories.sql`
- `V9__agenda_index_bookings_by_business_date.sql`

### 4. Escribir la migración
Buenas prácticas:
- **Greenfield:** columnas nuevas → `@Column` en la entidad JPA; BD vieja → recrear Postgres, no `ALTER`.
- **Idempotente cuando sea posible:** `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`.
- **Sin destrucción de datos sin pedir:** un `DROP COLUMN` requiere confirmación explícita del usuario.
- **No mezclar DDL de AGENDA con DDL del bot.**

Template (solo índices / tablas sin entidad):
```sql
-- <motivo en una línea>

CREATE INDEX IF NOT EXISTS idx_agenda_<tabla>_<col> ON agenda_<tabla> (<col>);
```

### 5. Validaciones antes de cerrar
Ejecutar:
```bash
# 1. El archivo es el próximo en la secuencia
ls backend/src/main/resources/db/migration/agenda/

# 2. No menciona tablas del bot
grep -niE "\s(bot|appointment|conversation|faq|knowledge_chunk|lead|menu|menu_option|message|business_hours|service|feature_config|menu_trigger)\b" backend/src/main/resources/db/migration/agenda/V*.sql

# 3. Todas las tablas mencionadas tienen prefijo agenda_
grep -oP "\b(agenda_\w+|\w+)\b" backend/src/main/resources/db/migration/agenda/V<N>__*.sql | grep -v '^agenda_' | grep -E '^(businesses|bookings|services|plans|users|categories)$' && echo "ALERTA: hay tablas sin prefijo"
```

### 6. Ajustar JPA entities
Si la migración cambia columnas, actualizar la entity correspondiente bajo `com.botai.agenda.infrastructure.persistence.entity`.

### 7. Probar
```bash
cd backend && mvn compile
# Si hay test de integración que corra Flyway:
cd backend && mvn test -Dtest='*IT' -Dspring.profiles.active=test
```

## Reglas

- **Nunca** tocar tablas del bot en una migración bajo `db/migration/agenda/`.
- Si Flyway está configurado también para el bot, usar carpeta **separada** (`db/migration/bot/` o `db/migration/agenda/`) con `flyway.locations` distintos.
- Mensajes y comentarios en español si son para el usuario final.
- Nunca incluir datos sensibles hardcodeados.
