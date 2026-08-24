# Working in this repo

This is the **agent-workbench** source repo. The Claude adapter that gets
installed into projects lives at `adapters/claude/`. Don't confuse the two.

- Skill bodies: `skills/<name>.md` (canonical)
- Reference docs: `references/<name>.md` (canonical)
- Claude rules / agents / commands: `adapters/claude/{rules,agents,commands}/`
- Cursor / opencode adapters: `adapters/{cursor,opencode}/`

## When editing a skill or reference

Edit `skills/<name>.md` or `references/<name>.md` at the repo root. These
are the single source of truth. `install.sh` renders them into each tool's
native skill/rule layout.

## When working in agent mode here

This repo dogfoods its own skills. Run them via `~/.claude/skills/<name>/`
(which is synced separately).
