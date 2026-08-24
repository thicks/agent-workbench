# Working in this repo

This is the **agent-workbench** source repo. Adapters that get installed into
projects live under `adapters/{claude,cursor,opencode}/`. Don't confuse those
with this source tree.

- Skill bodies: `skills/<name>.md` — canonical markdown including YAML frontmatter
- Reference docs: `references/<name>.md`
- Claude: `adapters/claude/{rules,agents,commands,settings.json}`
- Cursor / opencode: `adapters/{cursor,opencode}/`

There is no `adapters/Codex/` tree and no per-skill `*.header.md` files.

## When editing a skill or reference

Edit `skills/<name>.md` or `references/<name>.md` at the repo root.
`install.sh` renders them into each tool's native skill/rule layout.

## When working in agent mode here

This repo dogfoods its own skills via the tool's installed skill directory
(synced separately from this source).
