# Botai AI Skills

Skills are structured instructions for AI coding assistants ([agentskills.io](https://agentskills.io) standard).

## Quick start

```bash
# Bash (Git Bash / WSL / macOS / Linux)
./skills/setup.sh --claude

# Windows PowerShell
./skills/setup.ps1 -Claude
```

Then restart your AI assistant.

On Windows, if symlinks fail, enable **Developer Mode** (Settings → System → For developers) or run PowerShell as Administrator. `setup.ps1` tries directory junctions (`mklink /J`) first.

## Layout

```
skills/
├── <skill-name>/SKILL.md   # Source of truth (committed)
├── setup.sh                # Symlinks for Claude / Codex / Copilot / Gemini
├── setup.ps1               # Same on Windows
└── skill-sync/assets/sync.sh   # Regenerates Auto-invoke tables in AGENTS.md

agents/                     # Cursor subagent definitions (optional)
backend/AGENTS.md           # Scope: Java / Spring / Agenda backend
frontend/AGENTS.md          # Scope: Flutter Agenda UI
AGENTS.md                   # Repo-wide index + auto-invoke (root scope)
```

## Skill metadata (for sync)

Add to `SKILL.md` frontmatter when a skill should appear in `AGENTS.md`:

```yaml
metadata:
  author: botai
  version: "1.0"
  scope: [backend]          # root | backend | frontend (multiple allowed)
  auto_invoke: "Creating a new Agenda entity"
  # or list:
  # auto_invoke:
  #   - "Action A"
  #   - "Action B"
```

Regenerate tables after editing metadata:

```bash
./skills/skill-sync/assets/sync.sh
./skills/skill-sync/assets/sync.sh --dry-run
./skills/skill-sync/assets/sync.sh --scope backend
```

Windows PowerShell:

```powershell
.\skills\skill-sync\assets\sync.ps1
.\skills\skill-sync\assets\sync.ps1 -DryRun -Scope backend
```

## Scopes

| Scope      | AGENTS.md file        | Use for                          |
|------------|-----------------------|----------------------------------|
| `root`     | `AGENTS.md`           | Monorepo rules, boundaries, PRs  |
| `backend`  | `backend/AGENTS.md`   | Java 17, Spring, Flyway, Agenda  |
| `frontend` | `frontend/AGENTS.md`  | Flutter, Riverpod, Agenda UI     |

Component docs override the root `AGENTS.md` when guidance conflicts.
