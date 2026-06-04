---
name: skill-sync
description: >
  Syncs skill metadata to AGENTS.md Auto-invoke sections.
  Trigger: After updating metadata.scope or metadata.auto_invoke, or running sync.sh.
metadata:
  author: botai
  version: "1.0"
  scope: [root]
  auto_invoke:
    - "After creating/modifying a skill"
    - "Regenerate AGENTS.md Auto-invoke tables (sync.sh)"
    - "Troubleshoot why a skill is missing from AGENTS.md auto-invoke"
---

# skill-sync

Keeps `### Auto-invoke Skills` sections in each `AGENTS.md` aligned with skill frontmatter.

## Commands

```bash
./skills/skill-sync/assets/sync.sh
./skills/skill-sync/assets/sync.sh --dry-run
./skills/skill-sync/assets/sync.sh --scope backend
```

## Required metadata

See [skills/README.md](../README.md).
