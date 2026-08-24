# Working in this repo

This is the **agent-workbench** source repo. The Claude adapter that gets
installed into projects lives at `adapters/claude/`. Don't confuse the two.

- Skill bodies: `skills/<name>.md` — canonical markdown **including** YAML
  frontmatter (`name`, `description`, `allowed-tools`). There is no
  `adapters/claude/skills/` directory and no `*.header.md` files.
- Reference docs: `references/<name>.md`
- Claude rules / agents / commands: `adapters/claude/{rules,agents,commands}/`
- Cursor / opencode adapters: `adapters/{cursor,opencode}/`
- Shared install helpers: `lib/install-common.sh`

## When editing a skill or reference

Edit `skills/<name>.md` or `references/<name>.md` at the repo root. Change
trigger phrases in that skill's YAML frontmatter. `install.sh` parses those
fields and re-emits tool-native frontmatter.

## When working in agent mode here

This repo dogfoods its own skills. Run them via `~/.claude/skills/<name>/`
(which is synced separately).
