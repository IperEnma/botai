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

Regenerate Auto-invoke tables after editing skill metadata: `./skills/skill-sync/assets/sync.sh` (Git Bash) or `.\skills\skill-sync\assets\sync.ps1`.

Details: [skills/README.md](skills/README.md).

## Available Skills

| Skill | Description | Path |
|-------|-------------|------|
| `botai` | Monorepo overview and navigation | [SKILL.md](skills/botai/SKILL.md) |
| `new-agenda-feature` | End-to-end Agenda feature scaffolding | [SKILL.md](skills/new-agenda-feature/SKILL.md) |
| `new-agenda-entity` | Entity + JPA + port + adapter + migration | [SKILL.md](skills/new-agenda-entity/SKILL.md) |
| `new-agenda-migration` | Flyway migration only | [SKILL.md](skills/new-agenda-migration/SKILL.md) |
| `agenda-boundary-check` | Package isolation + Agenda conventions (no cross-imports) | [SKILL.md](skills/agenda-boundary-check/SKILL.md) |
| `new-agenda-screen` | New Flutter Agenda screen | [SKILL.md](skills/new-agenda-screen/SKILL.md) |
| `agenda-style-check` | Flutter design system audit | [SKILL.md](skills/agenda-style-check/SKILL.md) |
| `skill-creator` | Author new skills | [SKILL.md](skills/skill-creator/SKILL.md) |
| `skill-sync` | Regenerate Auto-invoke tables | [SKILL.md](skills/skill-sync/SKILL.md) |

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
| After creating/modifying a skill | `skill-sync` |
| Before committing Agenda changes | `agenda-boundary-check` |
| Creating new skills | `skill-creator` |
| General botai development questions | `botai` |
| Regenerate AGENTS.md Auto-invoke tables (sync.sh) | `skill-sync` |
| Troubleshoot why a skill is missing from AGENTS.md auto-invoke | `skill-sync` |
| Verifying agenda/chatbot package isolation (no cross-imports) | `agenda-boundary-check` |

---

## Modules (Agenda + Chatbot)

Both domains live in one backend and are **editable**. Keep **technical** separation:

| Rule | Detail |
|------|--------|
| No cross-imports | `com.botai.*.agenda` must not import `com.botai.*.chatbot` and vice versa |
| Agenda schema | New tables: `agenda_*`; Hibernate for `@Entity`; Flyway V1–V7 supplement only — [backend/docs/AGENDA_FLYWAY_MIGRATIONS.md](backend/docs/AGENDA_FLYWAY_MIGRATIONS.md) |
| Chatbot schema | Bot tables (`bot`, `conversation`, `faq`, …) — change only when the task requires it |
| Integration | REST, actions, shared infra — not domain-to-domain imports |

Details: [CLAUDE.md](CLAUDE.md). Pre-commit for Agenda: `agenda-boundary-check`.

### Política greenfield (schema)

- **Asunción:** BD vacía o recreada; no migraciones incrementales en prod.
- **Agenda:** Hibernate crea tablas/columnas desde `@Entity`; Flyway aplica **V1–V7** (extensiones PG, seeds, CHECK, UNIQUE parciales, EXCLUDE GiST, tablas sin entidad, índices GIN). **No** `ALTER TABLE ADD COLUMN` en Flyway; **no** `CREATE TABLE` si ya hay entidad JPA (ej. `agenda_uploaded_files` → `UploadedFileEntity`, sin V8).
- **Local desactualizado:** `docker-compose down -v` y volver a levantar.
- **Prod (Render/Neon):** recrear la base si el schema no coincide — ver [deploy/RENDER.md](deploy/RENDER.md).
- **Referencia agentes:** [backend/docs/AGENDA_FLYWAY_MIGRATIONS.md](backend/docs/AGENDA_FLYWAY_MIGRATIONS.md).

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
