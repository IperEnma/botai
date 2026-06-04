# Botai AI Skills

Skills are structured instructions for AI coding assistants ([agentskills.io](https://agentskills.io) standard), following the same layout as [Prowler](https://github.com/prowler-cloud/prowler).

## Do you need setup?

**Usually no.** If you use **Cursor** (or similar) with project rules, `AGENTS.md` at the repo root is enough. The agent reads it automatically; `skills/` stays in Git for reference and `@skills/...` mentions.

Run setup **only** if your tool expects skills under `.cursor/skills` or `.claude/skills` and does not pick them up from `skills/`.

## Setup (optional)

| OS | Command |
|----|---------|
| **Windows PowerShell** | `.\skills\setup.ps1` or `skills\setup.cmd` |
| **Git Bash / Mac / Linux** | `./skills/setup.sh` |

**Do not run** `./skills/setup.sh` **inside PowerShell** — it will not execute (no output). That is normal.

Interactive menu (no flags) or flags: `--claude`, `--all`, `--help` (bash script).

Then restart the IDE if you created symlinks.

### Windows notes

- Use **`.\skills\setup.ps1`** or **`skills\setup.cmd`** — not `./skills/setup.sh` in PowerShell (the `.sh` script does not run there).
- Folder links use **junctions** (`mklink /J`) and work without Administrator mode.
- **File** symlinks (`CLAUDE.md` at repo root) are **not** overwritten: botai keeps a committed `CLAUDE.md` separate from `AGENTS.md`. Cursor reads `AGENTS.md` directly.
- If setup stopped with *"Carece de privilegios"*, re-run after this fix; your `.cursor\skills` junction may already be fine.

## What gets linked

| Tool | Symlink / file |
|------|----------------|
| Claude Code | `.claude/skills` → `skills/` |
| Cursor IDE | `.cursor/skills` → `skills/` |
| Cursor subagents | `.claude/agents` → `agents/` |
| Codex | `.codex/skills` → `skills/` |
| Gemini CLI | `.gemini/skills` → `skills/` |
| GitHub Copilot | `.github/copilot-instructions.md` (copy of root `AGENTS.md`) |

`CLAUDE.md` at the repo root stays the monorepo guide in Git; it is not replaced by setup.

Source of truth is always **`skills/`** (committed). Tool dirs are local and listed in `.gitignore`.

## Layout

```
skills/
├── <skill-name>/SKILL.md
├── setup.sh
├── setup.ps1
└── skill-sync/assets/sync.sh

agents/                     # Cursor subagent definitions
AGENTS.md                   # Repo-wide guide
backend/AGENTS.md
frontend/AGENTS.md
```

## Skill metadata (Prowler-style sync)

Like [Prowler](https://github.com/prowler-cloud/prowler), each `SKILL.md` drives two tables in `AGENTS.md`:

| Table | Source |
|-------|--------|
| **Available Skills** | `name`, `description`, `metadata.scope` |
| **Action \| Skill** (Auto-invoke) | `metadata.auto_invoke` (string or list) |

```yaml
metadata:
  author: botai
  version: "1.0"
  scope: [backend]          # root | backend | frontend (can be multiple)
  auto_invoke:
    - "Short action label for the agent"
    - "Another trigger phrase"
```

After editing metadata, regenerate tables (do not edit tables by hand):

```bash
./skills/skill-sync/assets/sync.sh
./skills/skill-sync/assets/sync.sh --dry-run
./skills/skill-sync/assets/sync.sh --scope backend
```

Windows: `.\skills\skill-sync\assets\sync.ps1`

Root `AGENTS.md` has fewer Action rows than Prowler only because botai has fewer skills today — the mechanism is the same.

## Scopes

| Scope | AGENTS.md |
|-------|-----------|
| `root` | `AGENTS.md` |
| `backend` | `backend/AGENTS.md` |
| `frontend` | `frontend/AGENTS.md` |

Component docs override the root `AGENTS.md` when guidance conflicts.
