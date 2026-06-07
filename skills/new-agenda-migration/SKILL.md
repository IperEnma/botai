---
name: new-agenda-migration
description: Crea una migración Flyway nueva bajo backend/src/main/resources/db/migration/agenda/ siguiendo la convención V<N>__agenda_<descripcion>.sql. Valida que el nombre tenga prefijo agenda_, que no toque tablas del bot, y que el número de versión sea correlativo. Úsese cuando hay un cambio de schema aislado.
metadata:
  author: botai
  version: "1.0"
  scope: [backend]
  auto_invoke:
    - "Creating or updating Agenda Flyway migrations"
    - "Schema change for Agenda tables (agenda_* prefix)"
    - "Adding Flyway script under db/migration/agenda/"
---

# new-agenda-migration

Crea una migración Flyway **suplementaria** para el módulo AGENDA (greenfield).

**Leer primero:** [backend/docs/AGENDA_FLYWAY_MIGRATIONS.md](../../backend/docs/AGENDA_FLYWAY_MIGRATIONS.md)

## Cuándo usar

- Índice GIN / parcial / expresión que Hibernate no genera → ampliar **V7** o, si la secuencia ya está congelada en prod recreado, siguiente V8 **solo** de ese tipo.
- CHECK, UNIQUE parcial, EXCLUDE GiST → V3 / V4 / V5 según tipo.
- Tabla **sin** `@Entity` JPA → V6.
- Seed de datos → V2 (patrón existente).

## Cuándo NO usar (greenfield)

| Pedido | Hacer en su lugar |
|--------|-------------------|
| Nueva tabla con `@Entity` | Entidad JPA + recrear BD — **sin** Flyway `CREATE TABLE` |
| Nueva columna en tabla existente | `@Column` en entidad + recrear BD — **sin** `ALTER TABLE` |
| `agenda_uploaded_files` / imágenes | `UploadedFileEntity` ya existe — Hibernate |
| Schema local viejo | `docker-compose down -v`, no `V9` parche |

## Pasos

### 1. Validar alcance
Confirmar que:
- La migración toca **solo** tablas con prefijo `agenda_`.
- **No** es `CREATE TABLE` para algo que tendrá `@Entity`.
- Si hay DROP o ALTER de columna nueva, **detener** — greenfield no aplica parches.

### 2. Calcular versión
Secuencia actual **V1–V7** (ver doc). Próxima versión solo si el suplemento no cabe en el archivo de responsabilidad existente (p. ej. otro índice GIN → preferir editar V7 y recrear BD).

```bash
ls backend/src/main/resources/db/migration/agenda/ 2>/dev/null | grep -oP '^V\d+' | sort -V | tail -1
```

### 3. Elegir nombre
Formato: `V<N>__agenda_<snake_case_descripcion>.sql`

### 4. Escribir la migración
- Idempotente: `CREATE INDEX IF NOT EXISTS`, `CREATE TABLE IF NOT EXISTS` (solo tablas **sin** entidad).
- Comentario inicial: `-- Responsabilidad (VN): …` + referencia a `AGENDA_FLYWAY_MIGRATIONS.md`.
- **Sin** destrucción de datos sin confirmación del usuario.
- **No** mezclar DDL de AGENDA con DDL del bot.

### 5. Validaciones antes de cerrar
```bash
ls backend/src/main/resources/db/migration/agenda/
grep -niE "\s(bot|appointment|conversation|faq)\b" backend/src/main/resources/db/migration/agenda/V*.sql
```

### 6. Ajustar JPA entities
Si el cambio es columna nueva → **entidad**, no Flyway.

### 7. Probar
```bash
cd backend && mvn compile
```

## Reglas

- **Nunca** tocar tablas del bot en `db/migration/agenda/`.
- **Nunca** `V8+` solo porque “falta una tabla” que ya tiene `@Entity`.
- Mensajes en español si son para el usuario final.
