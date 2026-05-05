---
name: new-agenda-entity
description: Crea una entidad nueva del módulo AGENDA y sus piezas mínimas — domain POJO + JPA entity con prefijo agenda_ + Spring Data repo + port + adapter + migración Flyway. No crea casos de uso ni controllers. Úsese cuando se necesita persistir un concepto nuevo pero la lógica de negocio la vas a implementar después.
---

# new-agenda-entity

Crea la entidad más sus repositorios (port + adapter + Spring Data) y la migración Flyway. Sin caso de uso ni controller — eso queda para después.

## Cuándo usar

- "Agregá la entidad Coupon al dominio de AGENDA"
- "Necesitamos persistir NotificationTemplate"

No usar si:
- La feature ya involucra controllers o lógica de negocio (usá `new-agenda-feature`).
- Solo querés modificar una entidad existente (usá Edit directamente).

## Pasos

### 1. Confirmar alcance
Preguntar al usuario (si no está claro):
- Nombre de la entidad en singular (`Coupon`).
- Multi-tenant (lleva `tenant_id`) o global.
- Soft delete sí/no.
- Si reemplaza o extiende algo ya existente.

### 2. Migración Flyway
Crear `backend/src/main/resources/db/migration/agenda/V<N>__agenda_<nombre_plural>.sql`.

Template:
```sql
CREATE TABLE agenda_<nombre_plural> (
    id          UUID PRIMARY KEY,
    tenant_id   VARCHAR(64) NOT NULL,       -- omitir si es catálogo global
    -- campos de negocio
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP NULL               -- omitir si no hay soft delete
);

CREATE INDEX idx_agenda_<nombre_plural>_tenant ON agenda_<nombre_plural> (tenant_id);
```

### 3. JPA Entity
`com.botai.agenda.infrastructure.persistence.entity.FooEntity`

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
    // getters / setters
}
```

### 4. Spring Data repo
`com.botai.agenda.infrastructure.persistence.jpa.FooJpaRepository`

```java
public interface FooJpaRepository extends JpaRepository<FooEntity, UUID> {
    Optional<FooEntity> findByIdAndTenantIdAndDeletedAtIsNull(UUID id, String tenantId);
}
```

### 5. Domain POJO
`com.botai.agenda.domain.model.Foo` — record o clase inmutable. Sin anotaciones JPA ni Spring.

### 6. Port
`com.botai.agenda.domain.repository.FooRepository` — interface en términos del dominio.

### 7. Adapter
`com.botai.agenda.infrastructure.persistence.jpa.JpaFooRepository` — `@Component`, implementa el port, convierte entity↔domain.

### 8. Test mínimo
`com.botai.agenda.infrastructure.persistence.jpa.JpaFooRepositoryIT` — `@SpringBootTest` + Testcontainers, valida save + find.

### 9. Verificación
```bash
cd backend && mvn compile
cd backend && mvn test -Dtest='*Foo*'
```

## Reglas

- Nombre de tabla **siempre** con prefijo `agenda_`.
- IDs `UUID` siempre.
- Auditoría `@CreatedDate` y `@LastModifiedDate` obligatorias.
- `tenant_id` obligatorio salvo catálogo global (como `agenda_categories`).
- Nunca importar desde `com.botai.chatbot`.
