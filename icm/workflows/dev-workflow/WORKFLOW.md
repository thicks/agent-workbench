# Development Workflow

This workflow takes you from an idea or requirement to shipped code. Read
top-to-bottom to understand the pipeline, or jump to a specific skill.

```
  ┌─────────────────────────────────────────────────────┐
  │  "I have an idea"  ──▶  incept  ──▶  spec           │
  │  "What is this tech?" ──▶  tech-discovery  ──▶ notes │  Optional
  └─────────────────────────────────────────────────────┘
                            │
                            ▼
  ┌─────────────────────────────────────────────────────┐
  │  requirements  ──▶  tech-incept  ──▶  design         │
  │  design        ──▶  write-plan   ──▶  plan           │  Core Pipeline
  │  plan (approved) ──▶  execute-plan ──▶  code + PR    │
  └─────────────────────────────────────────────────────┘
```

---

## Where to Start

| You have... | Start with... |
|---|---|
| A raw idea, no written requirements | [incept](skills/incept.md) |
| A ticket, spec, user story, or PDF | [tech-incept](skills/tech-incept.md) |
| An unfamiliar technology to research | [tech-discovery](skills/tech-discovery.md) |
| An approved plan ready to build | [execute-plan](skills/execute-plan.md) |

---

## Core Pipeline

These three skills run in order. Each produces an artifact that feeds the next.

### 1. Tech Incept — "How do we build this?"

Takes any requirements source and produces an engineering design.

- **Input:** Spec, ticket, user story, or any markdown/PDF
- **Output:** `<slug>-design.md`
- **Details:** [tech-incept](skills/tech-incept.md)

### 2. Write Plan — "Break it into tasks"

Converts the design into micro-tasks with exact code and verification steps.

- **Input:** `<slug>-design.md`
- **Output:** `<slug>-plan.md`
- **Details:** [write-plan](skills/write-plan.md)

### 3. Execute Plan — "Build it"

Autonomously executes the approved plan: code, commits, PR.

- **Input:** `<slug>-plan.md` (approved)
- **Output:** Code commits + pull request
- **Details:** [execute-plan](skills/execute-plan.md)

> **Approval gate:** The plan must be reviewed before execution. Use
> [plan-review](review/plan-review.md) for a second opinion.

---

## Optional Steps

Use these when the situation calls for them. They are not required.

### Incept — "I have an idea, help me think it through"

A product-thinking step for when you have no written requirements. Produces
a spec that feeds into the core pipeline.

- **Output:** `<slug>-inception.md` + `<slug>-spec.md`
- **Details:** [incept](skills/incept.md)
- **Skip when:** A ticket, spec, or requirements doc already exists.

### Tech Discovery — "What is this technology?"

Independent research into a technology, architecture, or codebase. Can be
used at any point — before, during, or outside the build pipeline.

- **Output:** `<slug>-discovery.md`
- **Details:** [tech-discovery](skills/tech-discovery.md)

---

## Review Tools

On-demand quality gates. Use these anytime — they are not automatic steps.

| Tool | Purpose |
|---|---|
| [plan-review](review/plan-review.md) | "Is this plan detailed enough for a junior engineer?" |
| [spec-review](review/spec-review.md) | "Is this spec ready for engineering?" |
| [code-review](review/code-review.md) | "Review these changes for correctness, security, and style" |
| [fix-failing-tests](review/fix-failing-tests.md) | "Tests are broken — diagnose and fix" |

---

## Artifacts

Every skill produces named markdown artifacts using a slug. Artifacts are
saved to `$ARTIFACT_DIR/<scope>/<slug>/` (defaults to `./artifacts/<slug>/` if
the environment variable is not set).

Within `$ARTIFACT_DIR`, artifacts are further organized by `<scope>` — typically
`<customer>/<workspace>` derived from the current cwd, or an explicit
`for <customer>` phrase in the invocation. See
[artifact-dir](references/artifact-dir.md) for the full rule.

| Phase | Artifact |
|---|---|
| Incept | `<slug>-inception.md`, `<slug>-spec.md` |
| Tech Discovery | `<slug>-discovery.md` |
| Tech Incept | `<slug>-design.md` |
| Write Plan | `<slug>-plan.md` |
| Execute Plan | Code commits + PR |

To configure your artifact directory, set `ARTIFACT_DIR` in your tool's
local config. See [Configuration](#configuration) below.

---

## References

Stable conventions and standards that apply across the workflow:

- [coding-standards](references/coding-standards.md) — writing style for skills and code
- [pr-conventions](references/pr-conventions.md) — PR format, branch naming, ticket linking
- [git-workflow](references/git-workflow.md) — branch rules, push safety, artifact naming
- [artifact-dir](references/artifact-dir.md) — `$ARTIFACT_DIR` resolution and slug paths
- [save-plan](references/save-plan.md) — persisting design/plan artifacts to Obsidian

---

## Configuration

### Artifact directory

Set `ARTIFACT_DIR` to control where planning artifacts are saved. If not set,
artifacts default to `./artifacts/<scope>/<slug>/` in the project root.

| Tool | Where to set it |
|---|---|
| Claude Code | `.claude/settings.local.json` — add `"env": {"ARTIFACT_DIR": "/your/path"}` |
| Cursor | Project `.env` file — add `ARTIFACT_DIR=/your/path` |
| Shell | `export ARTIFACT_DIR=/your/path` before running your tool |

### Workspace scope strip list

`ARTIFACT_DIR_STRIP_SEGMENTS` controls which leading path segments are dropped
when deriving `<customer>/<workspace>` from cwd (default `dev`,
comma-separated to add more like `dev,work,projects`). See
[artifact-dir](references/artifact-dir.md) for the full scope rule.

| Tool | Where to set it |
|---|---|
| Claude Code | `.claude/settings.local.json` — add to the `env` block alongside `ARTIFACT_DIR` |
| Cursor | Project `.env` file — add `ARTIFACT_DIR_STRIP_SEGMENTS=dev,work` |
| Shell | `export ARTIFACT_DIR_STRIP_SEGMENTS=dev,work` |

For Claude Code, copy the included example and edit the path:
```bash
cp .claude/settings.local.json.example .claude/settings.local.json
```

The `.local.json` file is gitignored — your personal paths stay out of the repo.

---

## Escalation

Stop and ask the user when:

- Requirements are ambiguous
- Approval is needed to move from planning to execution
- A new dependency seems necessary
- Validation failures suggest unrelated repo instability
