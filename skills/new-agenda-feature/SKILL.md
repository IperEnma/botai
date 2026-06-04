---
name: new-agenda-feature
description: Scaffolding end-to-end de una feature nueva del módulo AGENDA. Crea domain model + port + adapter JPA + use case + controller + migración Flyway + tests, siguiendo la arquitectura hexagonal. Úsese cuando el usuario pide "agregar X a AGENDA" y la feature toca múltiples capas. No importa paquetes chatbot desde agenda.
metadata:
  author: botai
  version: "1.0"
  scope: [backend]
  auto_invoke: "Adding a full Agenda feature across layers"
---

# new-agenda-feature

Scaffolding completo de una feature del módulo AGENDA. Toca todas las capas y deja la feature lista para extender.

## Cuándo usar esta skill

- "Agregá al módulo AGENDA el CRUD de Plan"
- "Implementá la cancelación de reservas"
- "Creá el endpoint público de búsqueda de negocios"

No usar si:
- Solo se necesita una entidad nueva sin lógica (usá `new-agenda-entity`).
- Solo es una migración SQL (usá `new-agenda-migration`).
- Se tocaría código del bot (escalar al usuario).

## Pre-requisitos que la skill confirma antes de empezar

1. Leer `CLAUDE.md` y `PLAN_AGENDA.md`.
2. Verificar que la feature esté en el plan (o confirmar con el usuario si es una extensión).
3. Si la feature integra con el bot, hacerlo sin imports de dominio chatbot en agenda (acción, API o wiring en infra).

## Pasos

### Paso 1 — Diseño rápido
Listar al usuario (en 5 líneas max) qué archivos van a crearse. Si la feature es compleja, sugerir delegar primero al subagente `agenda-architect`.

### Paso 2 — Migración Flyway
Crear `backend/src/main/resources/db/migration/agenda/V<N>__agenda_<feature>.sql` con:
- Tablas nuevas con prefijo `agenda_`.
- Columnas `created_at TIMESTAMP NOT NULL DEFAULT NOW()` y `updated_at TIMESTAMP NOT NULL DEFAULT NOW()`.
- Índices necesarios (al menos uno por `tenant_id` si aplica).
- `deleted_at TIMESTAMP NULL` si la tabla requiere soft delete.

Calcular `<N>` con:
```bash
ls backend/src/main/resources/db/migration/agenda/ | grep -oP '^V\d+' | sort -V | tail -1
```

### Paso 3 — Capa de persistencia
Crear bajo `com.botai.agenda.infrastructure.persistence`:
- `entity/FooEntity.java` — `@Entity`, `@Table(name = "agenda_foos")`, `@EntityListeners(AuditingEntityListener.class)`, campos `@CreatedDate` / `@LastModifiedDate`.
- `jpa/FooJpaRepository.java` — `extends JpaRepository<FooEntity, UUID>`, con queries custom si hacen falta.

### Paso 4 — Capa de dominio
Crear bajo `com.botai.agenda.domain`:
- `model/Foo.java` — POJO inmutable (builder o record). Sin anotaciones JPA.
- `repository/FooRepository.java` — interface con métodos en términos del dominio (`findById(UUID id, String tenantId)`, `save(Foo foo)`, etc.).

### Paso 5 — Adapter JPA
Crear `infrastructure/persistence/jpa/JpaFooRepository.java`:
- `@Component`, implementa `FooRepository`.
- Usa `FooJpaRepository` internamente.
- Métodos `toEntity(Foo)` y `toDomain(FooEntity)` para la conversión.

### Paso 6 — Caso de uso
Crear en `com.botai.agenda.application`:
- `dto/CreateFooRequest.java`, `FooResponse.java` — records con Bean Validation.
- `usecase/CreateFooUseCase.java` — `@Service`, `@Transactional`, orquesta puertos de dominio. Emite eventos si aplica.
- `mapper/FooMapper.java` — si la conversión es no trivial.

### Paso 7 — Controller
Crear `infrastructure/api/FooController.java`:
- `@RestController`, `@RequestMapping("/api/agenda/tenants/{tenantId}/foos")` (o el scope que corresponda).
- `@Operation` y `@ApiResponse` de Swagger.
- Delega 100% al use case; sin lógica.

### Paso 8 — Tests
- `domain/model/FooTest.java` — invariantes del POJO.
- `application/usecase/CreateFooUseCaseTest.java` — unit con Mockito.
- `infrastructure/api/FooControllerIT.java` — `@SpringBootTest` + Testcontainers + `MockMvc`.

### Paso 9 — Verificación
Correr:
```bash
cd backend && mvn compile
cd backend && mvn test -Dtest='com.botai.agenda.**.Foo*'
```

Invocar al subagente `agenda-boundary-guard` para confirmar que no hubo fugas de boundary.

### Paso 10 — Reporte al usuario
- Lista de archivos creados con links `computer://`.
- Comando para correr los tests.
- Próximos pasos sugeridos (documentar en OpenAPI, revisar con `agenda-reviewer`).

## Reglas que nunca se rompen

- Sin `import com.botai.*.chatbot` en código agenda.
- El prefijo `agenda_` está en toda tabla nueva.
- Cada use case tiene al menos un test.
- Ninguna `@Transactional` se pone en controllers ni en adapters.
