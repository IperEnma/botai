---
name: skill-creator
description: >
  Create or update botai Agent Skills under skills/.
  Trigger: When adding a new skill, changing skill metadata (scope/auto_invoke), or documenting skill conventions.
metadata:
  author: botai
  version: "1.0"
  scope: [root]
  auto_invoke:
    - "Creating new skills"
    - "After creating/modifying a skill"
---

# Skill creator (botai)

## Layout

```
skills/<skill-name>/SKILL.md
```

Required frontmatter:

```yaml
---
name: kebab-case-name
description: One line for discovery + Trigger: when to use
metadata:
  author: botai
  version: "1.0"
  scope: [backend]   # root | backend | frontend
  auto_invoke: "Short action label for AGENTS.md table"
---
```

## Checklist

1. Create `skills/<name>/SKILL.md` (imperative steps, examples, boundaries).
2. Set `metadata.scope` and `metadata.auto_invoke`.
3. Run `./skills/skill-sync/assets/sync.sh` (regenerates **Available Skills** and **Action | Skill** tables in all `AGENTS.md` — Prowler-style).
4. Run `./skills/setup.ps1 -Claude` (Windows) or `./skills/setup.sh --claude` if symlinks are missing.

## Scope guide

| Skill type | scope |
|------------|-------|
| Flyway, JPA, use cases | `backend` |
| Flutter screens, Riverpod | `frontend` |
| Boundaries, PR, monorepo | `root` |
| Cross-cutting | `[root, backend]` or `[root, frontend]` |

## Do not

- Store skills only under `.claude/skills/` (that directory is generated via symlink).
