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

- New tables: prefix `agenda_`, Flyway `db/migration/agenda/`.
- Hibernate `ddl-auto: validate` for Agenda entities.
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
- [ ] Flyway migration if schema changed
- [ ] OpenAPI on new endpoints
- [ ] `agenda-boundary-check` clean
