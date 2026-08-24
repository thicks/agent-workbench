# Architecture

agent-workbench is a downloadable agentic development workflow that teaches
Claude, Cursor, and opencode to build software through a structured pipeline
of skills.

The model is skill-based. Install `install.sh`, and you get reusable skills
in each tool's native skill or rule directory. You invoke them when needed.
They produce artifacts (specs, plans, PRs) that feed the next step. Review
skills are on-demand quality gates — they do not run automatically and they
do not track workflow state.

## Repository structure

```
agent-workbench/
├── skills/                       ← Canonical skill bodies
├── references/                   ← Canonical reference docs
├── adapters/                     ← Tool-specific adapters
│   ├── claude/                   ├─ Claude Code (agents, commands, rules, settings)
│   ├── cursor/                   ├─ Cursor: .cursorrules + agents
│   └── opencode/                 ├─ opencode: AGENTS.md + instructions.md
├── lib/install-common.sh         ← Shared copy/overwrite helpers
├── install.sh                    ← Renders skills + copies adapters
├── docs/
├── CLAUDE.md
└── README.md
```

Skill bodies and references are written once at the repo root. `install.sh`
renders each `skills/<name>.md` into the tool-native shape (Claude
`SKILL.md`, Cursor `.mdc`, opencode skill markdown) and copies adapters.
File copy, overwrite prompts, and skill rendering live in
`lib/install-common.sh` so they are not duplicated across installers.

## How it works

```
User invokes        Skill produces         Next step reads
────────────────────────────────────────────────────────
/incept my-feature  → spec.md             (design doc)
/tech-discovery tsx → research.md         (reference)
/tech-incept        → design.md           (implementation)
/write-plan         → plan.md             (tasklist)
/execute-plan       → PR opened           (shipped)
```

Skip steps, run in any order, or use only the skills you need. Skills are
stateless: they read previous artifacts and write new ones. Nothing in the
installer or skill set enforces sequence.

### Tool-specific installation

| Tool | What install.sh does |
|---|---|
| **Claude Code** | Concatenates YAML frontmatter + skill body → `.claude/skills/<name>/SKILL.md`. Also copies agents, commands, rules, and settings. |
| **Cursor** | Copies `.cursorrules` and artifact-dir config. Skills become `.cursor/rules/<name>.mdc`. |
| **opencode** | Copies `AGENTS.md` and `instructions.md`. Skills become `.opencode/skills/<name>.md`. |

**Why tool-neutral bodies?** Writing skill content once avoids drift across
tools. Trigger phrases and descriptions live in the skill's own YAML
frontmatter; each adapter keeps only the fields that tool understands.

## Pipeline

1. **incept** (optional) — clarify a raw idea into a spec
2. **tech-discovery** (optional) — research an unfamiliar technology
3. **tech-incept** — produce an engineering design from requirements
4. **write-plan** — break the design into micro-tasks
5. **execute-plan** — autonomously implement and open a PR

On-demand: **spec-review**, **plan-review**, **code-review**,
**fix-failing-tests**.

## Artifact layout

All artifacts are saved to `$ARTIFACT_DIR/<scope>/<slug>/`. The `<scope>` is
derived from the workspace path or an explicit `for <customer>` phrase.

See `adapters/claude/rules/30-artifact-dir.md` or
`references/artifact-dir.md` for the full resolution rules.
