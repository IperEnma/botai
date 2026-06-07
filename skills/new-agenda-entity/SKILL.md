---
name: new-agenda-entity
description: Crea una entidad nueva del módulo AGENDA y sus piezas mínimas — domain POJO + JPA entity con prefijo agenda_ + Spring Data repo + port + adapter. Sin migración Flyway de CREATE TABLE (greenfield = Hibernate). No crea casos de uso ni controllers.
metadata:
  author: botai
  version: "1.0"
  scope: [backend]
  auto_invoke:
    - "Creating a new Agenda entity and persistence layer"
    - "Adding JPA entity with agenda_ table prefix"
    - "Creating domain port and Jpa adapter for Agenda"
---

# new-agenda-entity

Crea entidad + repos (port + adapter + Spring Data). **Sin** migración Flyway de tabla — Hibernate crea el DDL (greenfield).

## Greenfield (obligatorio)

| Acción | Correcto | Incorrecto |
|--------|----------|------------|
| Nueva tabla `agenda_*` | `@Entity` + `@Table` | `V8__agenda_*.sql` con `CREATE TABLE` |
| Nueva columna | `@Column` en entidad | `ALTER TABLE` en Flyway |
| Índice simple | `@Table(indexes=...)` | Flyway |
| Índice GIN / parcial complejo | Ampliar V7 vía `new-agenda-migration` | Flyway de creación de tabla |

Flyway V1–V7 = solo suplemento. Ver [backend/AGENTS.md](../../backend/AGENTS.md).

## Cuándo usar

- "Agregá la entidad Coupon al dominio de AGENDA"
- "Necesitamos persistir NotificationTemplate"

No usar si:
- La feature ya involucra controllers o lógica de negocio (usá `new-agenda-feature`).
- Solo querés modificar una entidad existente (usá Edit directamente).
- La tabla **no** tendrá `@Entity` (caso raro → V6 + `new-agenda-migration`, no este skill).

## Pasos

### 1. Confirmar alcance
Preguntar al usuario (si no está claro):
- Nombre de la entidad en singular (`Coupon`).
- Multi-tenant (lleva `tenant_id`) o global.
- Soft delete sí/no.
- Si reemplaza o extiende algo ya existente.

### 2. JPA Entity (schema = greenfield)
`com.botai.infrastructure.agenda.persistence.entity.FooEntity`

- `@Table(name = "agenda_foos")` — Hibernate crea/actualiza la tabla al arrancar.
- Índices **simples** → `@Table(indexes = @Index(...))`.
- Índices GIN/parciales complejos → suplemento en V7 (`new-agenda-migration`), no en la entidad sola.
- **No** crear `V8__agenda_foos.sql` con `CREATE TABLE`.

```java
@Entity
@Table(name = "agenda_foos")
@EntityListeners(AuditingEntityListener.class)
public class FooEntity {
    @Id
    private UUID id;
    @Column(name = "tenant_id", nullable = false)
    private String tenantId;
    // ... campos
    @CreatedDate
    private Instant createdAt;
    @LastModifiedDate
    private Instant updatedAt;
    private Instant deletedAt;   // si aplica
}
```

### 3. Spring Data repo
`com.botai.infrastructure.agenda.persistence.jpa.FooJpaRepository`

### 4. Domain POJO
`com.botai.domain.agenda.model.Foo`

### 5. Port
`com.botai.domain.agenda.repository.FooRepository`

### 6. Adapter
`com.botai.infrastructure.agenda.persistence.jpa.JpaFooRepository` — `@Component`

### 7. Test mínimo (opcional)
Unit/integration según convención del módulo.

### 8. Verificación
```bash
cd backend && mvn compile
cd backend && mvn test -Dtest='*Foo*'
```

Schema local viejo → `docker-compose down -v`, no Flyway parche.

## Reglas

- Nombre de tabla **siempre** con prefijo `agenda_`.
- IDs `UUID` salvo clave natural documentada (ej. `UploadedFileEntity.storageKey`).
- Sin imports desde `com.botai.*.chatbot` en paquetes agenda.
- Flyway **solo** si hace falta CHECK/UNIQUE parcial/índice GIN — no para la tabla base.
