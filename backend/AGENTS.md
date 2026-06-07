# Botai Backend — AI Agent Ruleset

> **Skills:** [new-agenda-feature](../skills/new-agenda-feature/SKILL.md) · [new-agenda-entity](../skills/new-agenda-entity/SKILL.md) · [new-agenda-migration](../skills/new-agenda-migration/SKILL.md) · [agenda-boundary-check](../skills/agenda-boundary-check/SKILL.md)

Scoped to `backend/`. Root rules: [AGENTS.md](../AGENTS.md). Full guide: [CLAUDE.md](../CLAUDE.md).

## Available Skills

| Skill | Description | Path |
|-------|-------------|------|
| `agenda-boundary-check` | Chequeo pre-commit de aislamiento entre paquetes agenda y chatbot (sin imports cruzados) y convenciones Agenda (prefi... | [SKILL.md](../skills/agenda-boundary-check/SKILL.md) |
| `new-agenda-entity` | Crea una entidad nueva del módulo AGENDA y sus piezas mínimas — domain POJO + JPA entity con prefijo agenda_ + Sp... | [SKILL.md](../skills/new-agenda-entity/SKILL.md) |
| `new-agenda-feature` | Scaffolding end-to-end de una feature nueva del módulo AGENDA. Crea domain model + port + adapter JPA + use case + c... | [SKILL.md](../skills/new-agenda-feature/SKILL.md) |
| `new-agenda-migration` | Crea una migración Flyway nueva bajo backend/src/main/resources/db/migration/agenda/ siguiendo la convención V<N>__... | [SKILL.md](../skills/new-agenda-migration/SKILL.md) |


### Auto-invoke Skills

When performing these actions, ALWAYS invoke the corresponding skill FIRST:

| Action | Skill |
|--------|-------|
| Adding a full Agenda feature across layers | `new-agenda-feature` |
| Adding Flyway script under db/migration/agenda/ | `new-agenda-migration` |
| Adding JPA entity with agenda_ table prefix | `new-agenda-entity` |
| Adding new Agenda API endpoint under /api/agenda/ | `new-agenda-feature` |
| Before committing Agenda changes | `agenda-boundary-check` |
| Creating a new Agenda entity and persistence layer | `new-agenda-entity` |
| Creating Agenda use case and REST controller | `new-agenda-feature` |
| Creating domain port and Jpa adapter for Agenda | `new-agenda-entity` |
| Creating or updating Agenda Flyway migrations | `new-agenda-migration` |
| Schema change for Agenda tables (agenda_* prefix) | `new-agenda-migration` |
| Verifying agenda/chatbot package isolation (no cross-imports) | `agenda-boundary-check` |

---

## Modules

| Package roots | Purpose |
|---------------|---------|
| `com.botai.application.agenda` · `domain.agenda` · `infrastructure.agenda` | Scheduling SaaS (hexagonal) |
| `com.botai.application.chatbot` · `domain.chatbot` · `infrastructure.chatbot` | WhatsApp / web bot, RAG, actions |
| `com.botai.infrastructure.security`, etc. | Shared infra (JWT, tenant context) |

**Isolation:** no direct imports between `agenda` and `chatbot` packages. Integrate via infrastructure (e.g. bot actions calling Agenda use cases wired in config), HTTP, or events — not domain imports.

### Agent conduct

Same rule as [AGENTS.md](../AGENTS.md): **no alternate flow paths or dev fallbacks** (echo codes, bypass modes, extra flags) unless the user explicitly requested them. One failure mode, one user-facing path.

### Agenda conventions

- New tables: prefix `agenda_`.
- **Greenfield (obligatorio):** sección completa abajo — **no** depender solo de links externos.
- REST under `/api/agenda/...` (see table below).

### Política greenfield — schema Agenda

**Asunción:** BD vacía o recreada. Schema desactualizado → `docker-compose down -v`, **no** `V8+` ni parches en prod.

| Qué cambia | Dónde |
|------------|--------|
| Tabla/columna con `@Entity` | `@Entity` + Hibernate (`ddl-auto: update`) — **sin** Flyway `CREATE TABLE` / `ADD COLUMN` |
| Suplemento PG (CHECK, UNIQUE parcial, EXCLUDE, GIN, tabla sin entidad, seeds) | Flyway V1–V7 |
| Índice simple | `@Table(indexes=...)` en la entidad (Hibernate) |

**Orden:** Hibernate al arrancar → Flyway V1–V7 en `ApplicationReadyEvent` (`AgendaFlywayConfig`).

| Versión | Archivo | Responsabilidad |
|---------|---------|-----------------|
| **V1** | `V1__agenda_extensions.sql` | Extensiones PostgreSQL |
| **V2** | `V2__agenda_initial_data.sql` | Seed `agenda_categories` |
| **V3** | `V3__agenda_check_constraints.sql` | CHECK constraints |
| **V4** | `V4__agenda_unique_constraints.sql` | UNIQUE parciales |
| **V5** | `V5__agenda_exclusion_constraints.sql` | EXCLUDE GiST (anti solapamiento reservas) |
| **V6** | `V6__agenda_tables_without_entities.sql` | Tablas sin `@Entity` (`agenda_idempotency_keys`) |
| **V7** | `V7__agenda_indexes.sql` | Índices GIN / parciales / expresión |

**Prohibido:** `CREATE TABLE agenda_*` en Flyway si existe `@Entity`; `ALTER TABLE ADD COLUMN`; `V8+` para tablas JPA (ej. `UploadedFileEntity` → `agenda_uploaded_files`).

Skills: `new-agenda-entity` (JPA), `new-agenda-migration` (solo suplemento V3–V7).

### Chatbot conventions

- Bot tables and `BotEntity` / `BotFeatures` — change when the feature requires it.
- Channels: WhatsApp, web, Telegram adapters under `infrastructure.chatbot`.
- See `backend/docs/BOT_AGENDA_INTENTS.md` for bot ↔ Agenda flows.

## Architecture

```
com.botai
├── ChatbotEngineApplication.java
├── application/{agenda,chatbot}/
├── domain/{agenda,chatbot}/
└── infrastructure/{agenda,chatbot,security,...}
```

| Layer | Convention | Example |
|-------|------------|---------|
| Domain POJO | Noun | `Booking` |
| Port | `*Repository` | `BookingRepository` |
| JPA adapter | `Jpa*Repository` | `JpaBookingRepository` |
| Entity | `*Entity` + `@Table(agenda_*)` | `BookingEntity` |
| Use case | Verb + `UseCase` | `CreateBookingUseCase` |
| Controller | `*Controller` | `BookingController` |

## REST prefixes (Agenda)

| Scope | Prefix |
|-------|--------|
| Public | `/api/agenda/public/**` |
| Platform admin | `/api/agenda/platform/**` |
| Tenant admin | `/api/agenda/tenants/{tenantId}/**` |
| End user | `/api/agenda/me/**` |

Feature guard: `AgendaFeatureGuard` on tenant/me routes when `AGENDA_ENABLED` is off → uniform 404.

## Commands

```bash
cd backend && mvn compile
cd backend && mvn spring-boot:run
cd backend && mvn test -Dtest='com.botai.application.agenda.**,com.botai.domain.agenda.**,com.botai.infrastructure.agenda.**'
# Chatbot tests (when touched):
cd backend && mvn test -Dtest='com.botai.application.chatbot.**,com.botai.domain.chatbot.**,com.botai.infrastructure.chatbot.**'
cd backend && mvn flyway:migrate -Dflyway.configFiles=flyway-agenda.conf
```

## QA checklist

- [ ] `mvn compile` passes
- [ ] Agenda tests added/updated
- [ ] Schema: `@Entity` (Hibernate) o suplemento V1–V7 según tabla arriba — **never** `V8+` / `CREATE TABLE` para entidades JPA
- [ ] OpenAPI on new endpoints
- [ ] `agenda-boundary-check` clean
