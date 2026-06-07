# Botai Backend — AI Agent Ruleset

> **Skills:** [new-agenda-feature](../skills/new-agenda-feature/SKILL.md) · [new-agenda-entity](../skills/new-agenda-entity/SKILL.md) · [new-agenda-migration](../skills/new-agenda-migration/SKILL.md) · [agenda-boundary-check](../skills/agenda-boundary-check/SKILL.md)

Scoped to `backend/`. Root rules: [AGENTS.md](../AGENTS.md). Full guide: [CLAUDE.md](../CLAUDE.md).

## Available Skills

| Skill | Path |
|-------|------|
| `new-agenda-feature` | [SKILL.md](../skills/new-agenda-feature/SKILL.md) |
| `new-agenda-entity` | [SKILL.md](../skills/new-agenda-entity/SKILL.md) |
| `new-agenda-migration` | [SKILL.md](../skills/new-agenda-migration/SKILL.md) |
| `agenda-boundary-check` | [SKILL.md](../skills/agenda-boundary-check/SKILL.md) |

### Auto-invoke Skills

When performing these actions, ALWAYS invoke the corresponding skill FIRST:

| Action | Skill |
|--------|-------|
| Adding a full Agenda feature across layers | `new-agenda-feature` |
| Before committing Agenda changes | `agenda-boundary-check` |
| Creating a new Agenda entity and persistence layer | `new-agenda-entity` |
| Creating or updating Agenda Flyway migrations | `new-agenda-migration` |
| Verifying agenda/chatbot package isolation (no cross-imports) | `agenda-boundary-check` |

---

## Modules

| Package roots | Purpose |
|---------------|---------|
| `com.botai.application.agenda` · `domain.agenda` · `infrastructure.agenda` | Scheduling SaaS (hexagonal) |
| `com.botai.application.chatbot` · `domain.chatbot` · `infrastructure.chatbot` | WhatsApp / web bot, RAG, actions |
| `com.botai.infrastructure.security`, etc. | Shared infra (JWT, tenant context) |

**Isolation:** no direct imports between `agenda` and `chatbot` packages. Integrate via infrastructure (e.g. bot actions calling Agenda use cases wired in config), HTTP, or events — not domain imports.

### Agenda conventions

- New tables: prefix `agenda_`.
- **Greenfield (obligatorio):** misma política que [AGENTS.md](AGENTS.md#política-greenfield--schema-agenda).

### Política greenfield — schema Agenda

**Asunción:** BD vacía o recreada. Schema desactualizado → `docker-compose down -v`, **no** `V8+` ni parches en prod.

| Qué cambia | Dónde |
|------------|--------|
| Tabla/columna con `@Entity` | `@Entity` + Hibernate — **sin** Flyway `CREATE TABLE` / `ADD COLUMN` |
| Suplemento PG | Flyway V1–V7 |
| Índice simple | `@Table(indexes=...)` |

| Versión | Archivo | Responsabilidad |
|---------|---------|-----------------|
| **V1** | `V1__agenda_extensions.sql` | Extensiones PostgreSQL |
| **V2** | `V2__agenda_initial_data.sql` | Seed categorías |
| **V3** | `V3__agenda_check_constraints.sql` | CHECK |
| **V4** | `V4__agenda_unique_constraints.sql` | UNIQUE parciales |
| **V5** | `V5__agenda_exclusion_constraints.sql` | EXCLUDE GiST |
| **V6** | `V6__agenda_tables_without_entities.sql` | Tablas sin `@Entity` |
| **V7** | `V7__agenda_indexes.sql` | Índices GIN / parciales |

**Prohibido:** `V8+` / `CREATE TABLE` para tablas con `@Entity` (ej. `UploadedFileEntity`).

- REST under `/api/agenda/...` (see table below).

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
- [ ] Schema: `@Entity` (Hibernate) o suplemento V1–V7 — **never** `V8+` / `CREATE TABLE` para entidades JPA
- [ ] OpenAPI on new endpoints
- [ ] `agenda-boundary-check` clean
