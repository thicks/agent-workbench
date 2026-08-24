# Working in this repo

This is the **agent-workbench** source repo. The Codex adapter that gets
installed into projects lives at `adapters/Codex/`. Don't confuse the two.

- Skill bodies: `skills/<name>.md` (canonical, shared by both variants)
- Reference docs: `references/<name>.md` (canonical, shared by both variants)
- Codex frontmatter: `adapters/Codex/skills/<name>.header.md`
- Codex rules / agents / commands: `adapters/Codex/{rules,agents,commands}/`
- Cursor / opencode adapters: `adapters/{cursor,opencode}/`
- ICM structural files: `icm/` (WORKFLOW.md, review/, agents/, adapters/)

## When editing a skill or reference

Edit `skills/<name>.md` or `references/<name>.md` at the repo root. These
are the single source of truth -- both variants use them. The ICM installer
assembles them into the workflow tree at install time.

Edit `adapters/Codex/skills/<name>.header.md` only when the YAML
description or trigger phrases change.

## When working in agent mode here

This repo dogfoods its own skills. Run them via `~/.Codex/skills/<name>/`
(which is synced separately).
