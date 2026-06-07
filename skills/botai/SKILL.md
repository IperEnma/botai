---
name: botai
description: >
  Project overview and navigation for the botai monorepo (Agenda + Chatbot).
  Trigger: General questions about repo structure, which module to edit, or where AGENTS.md/skills apply.
metadata:
  author: botai
  version: "1.1"
  scope: [root]
  auto_invoke:
    - "General botai development questions"
    - "Navigating botai monorepo (backend + frontend)"
    - "Understanding Agenda vs Chatbot package boundaries"
---

# Botai

Monorepo: **Agenda** (scheduling SaaS) + **Chatbot** (WhatsApp / web), shared Spring Boot backend and Flutter frontend.

## Read first

| Doc | Purpose |
|-----|---------|
| [AGENTS.md](../../AGENTS.md) | Repo-wide rules and skill index |
| [CLAUDE.md](../../CLAUDE.md) | Monorepo guide (both modules + isolation) |
| [PLAN_AGENDA.md](../../PLAN_AGENDA.md) | Product/technical plan for Agenda |
| [backend/AGENTS.md](../../backend/AGENTS.md) | Java / Spring scope |
| [frontend/AGENTS.md](../../frontend/AGENTS.md) | Flutter scope |

## Components

| Component | Path | Stack |
|-----------|------|-------|
| Backend | `backend/` | Java 17, Spring Boot 3.2, PostgreSQL, Flyway |
| Frontend | `frontend/` | Flutter, Riverpod, go_router |
| Agenda | `com.botai.*.agenda` | Hexagonal, `agenda_*` tables |
| Chatbot | `com.botai.*.chatbot` | Hexagonal, bot tables, Spring AI / RAG |

## Isolation (not a ban on editing)

- Edit **either** module per user task.
- **Do not** cross-import `agenda` ↔ `chatbot` domain packages.
- Integrate via bot actions, REST, shared infrastructure wiring.

## Agent conduct

Follow [AGENTS.md](../../AGENTS.md) (*Agent conduct*): no unnecessary fallbacks — e.g. do not show `searchTags` when the UI expects `categorias`; empty field → empty UI or fix data at source.

## Greenfield — schema Agenda (leer antes de Flyway o `@Entity`)

BD vacía o recreada. **No** parches prod.

| Qué | Dónde |
|-----|--------|
| Tabla/columna con `@Entity` | Hibernate — **sin** Flyway `CREATE TABLE` |
| CHECK / UNIQUE parcial / EXCLUDE / GIN / tabla sin entidad / seeds | Flyway **V1–V7** |

| V | Responsabilidad |
|---|-----------------|
| V1 | Extensiones PG |
| V2 | Seed categorías |
| V3 | CHECK |
| V4 | UNIQUE parciales |
| V5 | EXCLUDE GiST reservas |
| V6 | Tablas sin `@Entity` |
| V7 | Índices GIN / parciales |

**Termina en V7.** Ej.: `agenda_uploaded_files` = `UploadedFileEntity`, **no** migración Flyway.

Ver: [backend/AGENTS.md](../../backend/AGENTS.md), skill `new-agenda-migration`.

## Commands

```bash
cd backend && mvn compile
cd backend && mvn test -Dtest='com.botai.application.agenda.**,com.botai.domain.agenda.**,com.botai.infrastructure.agenda.**'
cd backend && mvn test -Dtest='com.botai.application.chatbot.**,com.botai.domain.chatbot.**,com.botai.infrastructure.chatbot.**'
cd frontend && flutter analyze
```
