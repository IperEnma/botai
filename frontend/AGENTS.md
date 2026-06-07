# Botai Frontend — AI Agent Ruleset

> **Skills:** [new-agenda-screen](../skills/new-agenda-screen/SKILL.md) · [agenda-style-check](../skills/agenda-style-check/SKILL.md)

Scoped to `frontend/`. Root rules: [AGENTS.md](../AGENTS.md).

## Available Skills

| Skill | Description | Path |
|-------|-------------|------|
| `agenda-style-check` | Auditoría rápida de consistencia visual de uno o varios archivos Flutter del módulo Agenda. Verifica tokens de col... | [SKILL.md](../skills/agenda-style-check/SKILL.md) |
| `new-agenda-screen` | Scaffolding de una nueva pantalla Flutter del módulo Agenda. Genera el archivo con los tokens de diseño correctos, ... | [SKILL.md](../skills/new-agenda-screen/SKILL.md) |


### Auto-invoke Skills

When performing these actions, ALWAYS invoke the corresponding skill FIRST:

| Action | Skill |
|--------|-------|
| Auditing Agenda screen for design tokens and responsive layout | `agenda-style-check` |
| Creating a new Agenda Flutter screen | `new-agenda-screen` |
| Registering Agenda route in go_router | `new-agenda-screen` |
| Reviewing Agenda Flutter UI against the design system | `agenda-style-check` |
| Scaffolding Flutter feature under lib/features/agenda/ | `new-agenda-screen` |

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
- **No fallbacks innecesarios en UI:** cada campo de pantalla usa su dato de API correspondiente (`categorias` → pills del banner, `logoUrl` → logo, etc.). Si falta dato, estado vacío o arreglar origen — no reutilizar otro campo (`searchTags`, dirección, etc.). Ver [AGENTS.md](../AGENTS.md) *Agent conduct*.

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
