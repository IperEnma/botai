# Agenda — Migraciones Flyway (greenfield)

> **Fuente de verdad para agentes.** Antes de crear `V8`, `V9`, etc., leé esto.
> Carpeta: `backend/src/main/resources/db/migration/agenda/`
> Historial Flyway: tabla `agenda_flyway_schema_history`.

## Política greenfield

Este repo **no evoluciona BDs en producción con parches**. El schema vigente se obtiene así:

1. **BD vacía** (local: `docker-compose down -v`; Neon/Render: nueva base o drop schema).
2. Hibernate (`spring.jpa.hibernate.ddl-auto: update`) crea tablas y columnas de entidades `@Entity` (`agenda_*`).
3. Flyway aplica **solo** V1–V7 **después** del arranque (`AgendaFlywayConfig` → `ApplicationReadyEvent`).

**Prohibido para agentes:**

| Acción | Por qué |
|--------|---------|
| `ALTER TABLE ... ADD COLUMN` en Flyway | Columna nueva → `@Column` en la entidad + recrear BD |
| `CREATE TABLE agenda_*` si existe `@Entity` | Hibernate ya crea la tabla (`UploadedFileEntity` → `agenda_uploaded_files`, **sin V8**) |
| Nueva migración `V8+` “de creación” de tabla con entidad | Error de diseño; corregir entidad JPA, no Flyway |
| Parchear prod con SQL manual | Recrear la base (ver `deploy/RENDER.md`) |

**Cuándo sí agregar migración** (y solo entonces usar `new-agenda-migration`):

- Extensión PG, CHECK, UNIQUE parcial, EXCLUDE GiST, índice GIN/parcial que Hibernate no genera.
- Tabla **sin** entidad JPA (hoy: `agenda_idempotency_keys` en V6).
- Seeds idempotentes (V2).

Si el schema local quedó desactualizado: **recrear Postgres**, no acumular versiones Flyway.

---

## Orden de ejecución (Hibernate → Flyway)

```
Arranque Spring
  → Hibernate ddl-auto=update (tablas agenda_* desde @Entity)
  → ApplicationReadyEvent
  → Flyway migrate V1 … V7
```

---

## Responsabilidad de cada versión

| Versión | Archivo | Responsabilidad | Quién crea el DDL |
|---------|---------|-----------------|-------------------|
| **V1** | `V1__agenda_extensions.sql` | Extensiones PostgreSQL (`vector`, `pgcrypto`, `unaccent`, `btree_gist`) | Flyway |
| **V2** | `V2__agenda_initial_data.sql` | Seed de categorías iniciales (`agenda_categories`) | Flyway (INSERT; tablas ya existen vía Hibernate) |
| **V3** | `V3__agenda_check_constraints.sql` | CHECK de integridad que Hibernate no genera (rating 1–5, enums string, etc.) | Flyway (`ALTER … ADD CONSTRAINT`, idempotente) |
| **V4** | `V4__agenda_unique_constraints.sql` | UNIQUE parciales (email tenant nullable, `public_slug`, teléfono usuario, etc.) | Flyway |
| **V5** | `V5__agenda_exclusion_constraints.sql` | EXCLUDE GiST anti doble-reserva (negocio+servicio y staff) | Flyway (requiere `btree_gist` de V1) |
| **V6** | `V6__agenda_tables_without_entities.sql` | Tablas **sin** `@Entity` JPA (p. ej. `agenda_idempotency_keys`) | Flyway |
| **V7** | `V7__agenda_indexes.sql` | Índices de rendimiento GIN / parciales / expresión que Hibernate no genera | Flyway |

**La secuencia termina en V7.** No debe existir V8 salvo que se añada un suplemento nuevo de la misma naturaleza (índice GIN, tabla sin entidad, etc.) — nunca para tablas ya modeladas por JPA.

---

## Tablas con entidad JPA (NO van en Flyway)

Ejemplos: `agenda_businesses`, `agenda_reviews`, **`agenda_uploaded_files`** (`UploadedFileEntity` — storage de logo/banner/avatares en Postgres).

Definición: `@Entity` + `@Table(name = "agenda_…")` bajo `infrastructure.agenda.persistence.entity`.

Índices **simples** declarados en `@Table(indexes = …)` los crea Hibernate. Índices GIN/parciales complejos → V7 (o ampliar V7 en greenfield con recreación de BD, no `V8` duplicado).

---

## Error común: V8 `agenda_uploaded_files`

Se creó `V8__agenda_uploaded_files.sql` por error: la tabla ya está en `UploadedFileEntity`. **Eliminada.** En greenfield Hibernate crea la tabla al arrancar.

Si una BD remota ya registró V8 en `agenda_flyway_schema_history`:

1. **Preferido:** recrear la base (greenfield).
2. La tabla puede coexistir (creada por V8 o por Hibernate); lo importante es no volver a agregar migraciones de creación para entidades JPA.

---

## Referencias

- Diseño perfil público / reviews: [AGENDA_PUBLIC_PROFILE_REVIEWS.md](./AGENDA_PUBLIC_PROFILE_REVIEWS.md)
- Deploy Render: [../../deploy/RENDER.md](../../deploy/RENDER.md)
- Skill agente: [../../skills/new-agenda-migration/SKILL.md](../../skills/new-agenda-migration/SKILL.md)
