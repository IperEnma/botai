# Botai — Repository Guidelines

## How to Use This Guide

- Start here for cross-project norms. Botai is a monorepo: **backend** (Spring) + **frontend** (Flutter).
- Each component has its own `AGENTS.md` with scoped rules:
  - [backend/AGENTS.md](backend/AGENTS.md) — Java, Agenda hexagonal, Flyway
  - [frontend/AGENTS.md](frontend/AGENTS.md) — Flutter Agenda UI
- [CLAUDE.md](CLAUDE.md) has monorepo rules (Agenda + Chatbot, package isolation).
- Component docs override this file when guidance conflicts.

## AI Skills (optional setup)

**Cursor and most agents already read `AGENTS.md` (and `backend/AGENTS.md`, `frontend/AGENTS.md`) from the repo.** You do **not** need `.claude/` or `setup` for day-to-day work.

Committed sources of truth:

- [AGENTS.md](AGENTS.md) — monorepo rules + skill index
- [CLAUDE.md](CLAUDE.md) — detailed guide
- [skills/](skills/) — full skill procedures

**Optional** local symlinks (only if skills do not show up in your IDE): [Prowler-style](https://github.com/prowler-cloud/prowler) `skills/setup.sh` for Git Bash / Mac / Linux.

| OS | Command (not `./skills/setup.sh` in PowerShell — it does nothing there) |
|----|------------------------------------------------------------------------|
| Windows | `.\skills\setup.ps1` or `skills\setup.cmd` |
| Git Bash | `./skills/setup.sh` |

Regenerate **Available Skills** and **Action | Skill** tables after editing skill metadata: `.\skills\skill-sync\assets\sync.ps1` (Windows) or `./skills/skill-sync/assets/sync.sh` (Git Bash).

Details: [skills/README.md](skills/README.md).

## Available Skills

| Skill | Description | Path |
|-------|-------------|------|
| `agenda-boundary-check` | Chequeo pre-commit de aislamiento entre paquetes agenda y chatbot (sin imports cruzados) y convenciones Agenda (prefi... | [SKILL.md](skills/agenda-boundary-check/SKILL.md) |
| `agenda-style-check` | Auditoría rápida de consistencia visual de uno o varios archivos Flutter del módulo Agenda. Verifica tokens de col... | [SKILL.md](skills/agenda-style-check/SKILL.md) |
| `botai` | Project overview and navigation for the botai monorepo (Agenda + Chatbot). | [SKILL.md](skills/botai/SKILL.md) |
| `new-agenda-entity` | Crea una entidad nueva del módulo AGENDA y sus piezas mínimas — domain POJO + JPA entity con prefijo agenda_ + Sp... | [SKILL.md](skills/new-agenda-entity/SKILL.md) |
| `new-agenda-feature` | Scaffolding end-to-end de una feature nueva del módulo AGENDA. Crea domain model + port + adapter JPA + use case + c... | [SKILL.md](skills/new-agenda-feature/SKILL.md) |
| `new-agenda-migration` | Crea una migración Flyway nueva bajo backend/src/main/resources/db/migration/agenda/ siguiendo la convención V<N>__... | [SKILL.md](skills/new-agenda-migration/SKILL.md) |
| `new-agenda-screen` | Scaffolding de una nueva pantalla Flutter del módulo Agenda. Genera el archivo con los tokens de diseño correctos, ... | [SKILL.md](skills/new-agenda-screen/SKILL.md) |
| `skill-creator` | Create or update botai Agent Skills under skills/. | [SKILL.md](skills/skill-creator/SKILL.md) |
| `skill-sync` | Syncs skill metadata to AGENTS.md Auto-invoke sections. | [SKILL.md](skills/skill-sync/SKILL.md) |


## Available Subagents (Cursor)

Committed under [`agents/`](agents/). After `setup.sh`, available as `.claude/agents/`.

| Agent | When to use |
|-------|-------------|
| `agenda-architect` | Design before non-trivial Agenda features |
| `agenda-implementer` | Implement Agenda backend end-to-end |
| `agenda-reviewer` | Review Agenda backend changes |
| `agenda-boundary-guard` | Fast package-isolation check for Agenda changes |
| `agenda-frontend-implementer` | Flutter Agenda screens |
| `agenda-frontend-reviewer` | Flutter Agenda UI review |

### Auto-invoke Skills

When performing these actions, ALWAYS invoke the corresponding skill FIRST:

| Action | Skill |
|--------|-------|
| After creating/modifying a skill | `skill-creator` |
| After creating/modifying a skill | `skill-sync` |
| Before committing Agenda changes | `agenda-boundary-check` |
| Creating new skills | `skill-creator` |
| General botai development questions | `botai` |
| Navigating botai monorepo (backend + frontend) | `botai` |
| Regenerate AGENTS.md Auto-invoke tables (sync.sh) | `skill-sync` |
| Troubleshoot why a skill is missing from AGENTS.md auto-invoke | `skill-sync` |
| Understanding Agenda vs Chatbot package boundaries | `botai` |
| Verifying agenda/chatbot package isolation (no cross-imports) | `agenda-boundary-check` |

---

## Agent conduct (mandatory)

**Do not invent alternate paths for the same user flow without explicit user approval.**

Forbidden unless the user asked for it:

- Dev-only fallbacks that change production behavior (e.g. returning secrets in JSON when an external integration fails).
- Feature flags or “shortcuts” that create a second way to complete the same step (OTP bypass, echo codes, optional auth paths) without a prior agreed design.
- “Helpful” extras (extra endpoints, dual modes, silent retries with different semantics) not in the task scope.

When an integration fails (WhatsApp, payment, etc.), return a **single clear error** to the user. Fix infrastructure or ask the user how to handle dev/test — do not add a parallel code path on your own.

If you believe a fallback is necessary, **stop and ask first**.

---

## Modules (Agenda + Chatbot)

Both domains live in one backend and are **editable**. Keep **technical** separation:

| Rule | Detail |
|------|--------|
| No cross-imports | `com.botai.*.agenda` must not import `com.botai.*.chatbot` and vice versa |
| Agenda schema | Greenfield: `@Entity` → Hibernate; Flyway **solo V1–V7** (ver tabla abajo). **No** `V8+` para tablas JPA. |
| Chatbot schema | Bot tables (`bot`, `conversation`, `faq`, …) — change only when the task requires it |
| Integration | REST, actions, shared infra — not domain-to-domain imports |

Details: [CLAUDE.md](CLAUDE.md). Pre-commit for Agenda: `agenda-boundary-check`.

### Política greenfield — schema Agenda (obligatorio para agentes)

**Asunción:** BD vacía o recreada (`docker-compose down -v` local; Neon/Render: nueva base). **No** parches `ALTER TABLE` ni `V8+` “de creación” en prod.

| Qué cambia | Dónde |
|------------|--------|
| Tabla/columna con `@Entity` | Entidad JPA + Hibernate (`ddl-auto: update`) — **sin** Flyway `CREATE TABLE` / `ADD COLUMN` |
| CHECK, UNIQUE parcial, EXCLUDE GiST, índice GIN, tabla sin entidad, seeds | Flyway V1–V7 (archivo según responsabilidad) |
| Schema local viejo | Recrear Postgres — **no** acumular migraciones |

**Orden:** Hibernate crea `agenda_*` al arrancar → `ApplicationReadyEvent` → Flyway V1–V7.

| Versión | Archivo | Responsabilidad |
|---------|---------|-----------------|
| **V1** | `V1__agenda_extensions.sql` | Extensiones PG (`vector`, `pgcrypto`, `unaccent`, `btree_gist`) |
| **V2** | `V2__agenda_initial_data.sql` | Seed categorías (`INSERT` en tablas ya creadas por Hibernate) |
| **V3** | `V3__agenda_check_constraints.sql` | CHECK (rating 1–5, enums string, etc.) |
| **V4** | `V4__agenda_unique_constraints.sql` | UNIQUE parciales (slug, email tenant nullable, teléfono usuario) |
| **V5** | `V5__agenda_exclusion_constraints.sql` | EXCLUDE GiST anti doble-reserva |
| **V6** | `V6__agenda_tables_without_entities.sql` | Tablas **sin** `@Entity` (p. ej. `agenda_idempotency_keys`) |
| **V7** | `V7__agenda_indexes.sql` | Índices GIN / parciales / expresión (Hibernate no los genera) |

**Secuencia termina en V7.** Ejemplos **sin** Flyway: `agenda_reviews`, `agenda_uploaded_files` (`UploadedFileEntity` — imágenes en Postgres). **No** crear `V8__agenda_uploaded_files` ni similares.

Carpeta: `backend/src/main/resources/db/migration/agenda/`. Detalle extendido: [backend/docs/AGENDA_FLYWAY_MIGRATIONS.md](backend/docs/AGENDA_FLYWAY_MIGRATIONS.md).

---

## Project Overview

| Component | Location | Tech |
|-----------|----------|------|
| Backend | `backend/` | Java 17, Spring Boot 3.2, PostgreSQL, Flyway |
| Frontend | `frontend/` | Flutter, Riverpod, go_router |
| Plan | `PLAN_AGENDA.md` | Product/technical source of truth for Agenda |

## Commands

```bash
cd backend && mvn compile
cd backend && mvn test -Dtest='com.botai.application.agenda.**,com.botai.domain.agenda.**,com.botai.infrastructure.agenda.**'
cd frontend && flutter analyze
docker-compose up -d postgres
```
