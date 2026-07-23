# Working in this repo

This is the **agent-workbench** source repo. The Claude adapter that gets
installed into projects lives at `adapters/claude/`. Don't confuse the two.

- Skill bodies: `skills/<name>.md` (canonical, shared by both variants)
- Reference docs: `references/<name>.md` (canonical, shared by both variants)
- Claude frontmatter: `adapters/claude/skills/<name>.header.md`
- Claude rules / agents / commands: `adapters/claude/{rules,agents,commands}/`
- Cursor / opencode adapters: `adapters/{cursor,opencode}/`
- ICM structural files: `icm/` (WORKFLOW.md, review/, agents/, adapters/)

## When editing a skill or reference

Edit `skills/<name>.md` or `references/<name>.md` at the repo root. These
are the single source of truth -- both variants use them. The ICM installer
assembles them into the workflow tree at install time.

Edit `adapters/claude/skills/<name>.header.md` only when the YAML
description or trigger phrases change.

## When working in agent mode here

This repo dogfoods its own skills. Run them via `~/.claude/skills/<name>/`
(which is synced separately).
