# Botai Frontend — AI Agent Ruleset

> **Skills:** [new-agenda-screen](../skills/new-agenda-screen/SKILL.md) · [agenda-style-check](../skills/agenda-style-check/SKILL.md)

Scoped to `frontend/`. Root rules: [AGENTS.md](../AGENTS.md).

## Available Skills

| Skill | Path |
|-------|------|
| `new-agenda-screen` | [SKILL.md](../skills/new-agenda-screen/SKILL.md) |
| `agenda-style-check` | [SKILL.md](../skills/agenda-style-check/SKILL.md) |

### Auto-invoke Skills

When performing these actions, ALWAYS invoke the corresponding skill FIRST:

| Action | Skill |
|--------|-------|
| Creating a new Agenda Flutter screen | `new-agenda-screen` |
| Reviewing Agenda Flutter UI against the design system | `agenda-style-check` |

---

## Scope

- Agenda UI: `lib/features/agenda/**`, `lib/providers/agenda/**`, `lib/models/agenda/**`
- Design reference: `lib/features/agenda/public/landing_screen.dart`, `public_reservar_layout.dart`
- Do not change bot admin screens unless the user asks

## Stack

Flutter · Riverpod · go_router · Google Fonts (design tokens per screen/theme)

## Conventions

- Responsive layouts (mobile-first; breakpoints consistent with existing Agenda screens)
- Navigation via `go_router` — register routes in router config when adding screens
- API access through existing Agenda providers/services, not ad-hoc HTTP in widgets
- `PublicReservarTheme.textStyle` uses `size` and `weight`, not `fontSize` / `fontWeight`

## Commands

```bash
cd frontend && flutter pub get
cd frontend && dart analyze
cd frontend && flutter test
```

## QA checklist

- [ ] `dart analyze` on touched files
- [ ] `agenda-style-check` for UI changes
- [ ] Route registered for new screens
