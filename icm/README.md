# Agent Workbench -- ICM Variant

This is the **Interpretable Context Methodology** (ICM) variant of the
agent-workbench dev-workflow.

> **Looking for the standard variant?** Use `install.sh` at the repo root.
> It installs short procedural skills directly into each tool's native
> skill system (Claude Code, Cursor, opencode).

## What is ICM?

ICM is a way to structure AI agent workflows so that every piece of context
is explicit, layered, and auditable. Instead of giving an agent a bag of
independent skills and hoping it picks the right one, ICM organizes them
into a **workflow tree** with clear routing, stage contracts, and shared
conventions.

The approach is described in
[Interpretable Context Methodology](https://arxiv.org/abs/2603.16021).

Core assumptions:

- **Plain text is the interface** -- skills are markdown, artifacts are
  markdown, conventions are markdown. Everything is human-readable and
  version-controllable.
- **Layered context** -- a routing document (`WORKFLOW.md`) points to
  skills. Skills reference shared conventions in `references/`. Review
  checklists live in `review/`. Each layer has a clear purpose.
- **Stage contracts** -- each skill defines its inputs, outputs, and the
  next skill it hands off to. Artifacts are the interface between stages.
- **Self-contained workflow** -- the installed workflow lives in one
  directory and can be vendored into any project.

## How ICM differs from a native skill set

In Claude Code, Cursor, or opencode, skills are standalone procedures that
the agent discovers and invokes independently. There is no defined order,
no shared convention layer, and no routing -- the agent decides what to
call based on its own judgment.

ICM changes this:

| Aspect | Native skills | ICM workflow |
|--------|--------------|--------------|
| Entry point | Agent picks a skill from its inventory | Agent reads `WORKFLOW.md`, which routes to the right skill |
| Skill relationships | Independent, unordered | Pipeline with explicit handoffs (incept -> tech-incept -> write-plan -> execute-plan) |
| Shared conventions | Repeated in each skill or missing entirely | Extracted into `references/` and linked from skills |
| Artifacts | Ad hoc | Named, slugged, saved to `$ARTIFACT_DIR/<scope>/<slug>/` by convention |
| Review gates | Not built in | `review/` directory with on-demand quality checklists |
| Auditability | Scattered across tool config | One directory tree you can read top-to-bottom |

The workflow itself becomes a first-class artifact -- something you read,
audit, refactor, and version like code.

## Repo layout

Skills and references are **not** duplicated inside `icm/`. They live at
the repo root as the single source of truth. The ICM directory contains
only the structural files that give the workflow its shape:

```
agent-workbench/
├── skills/                        # Canonical skill bodies (shared by both variants)
├── references/                    # Canonical reference docs (shared by both variants)
├── icm/
│   ├── workflows/
│   │   └── dev-workflow/
│   │       ├── WORKFLOW.md        # Routing table and pipeline overview
│   │       ├── review/            # Quality gate checklists
│   │       └── agents/            # Subagent definitions (task-executor)
│   ├── adapters/
│   │   ├── claude/                # CLAUDE.md + agents/ (thin pointers to WORKFLOW.md)
│   │   ├── cursor/                # .cursorrules (thin pointer to WORKFLOW.md)
│   │   └── opencode/              # instructions.md (thin pointer to WORKFLOW.md)
│   └── README.md                  # This file
├── install-icm.sh                 # Assembles and installs the ICM variant
└── ...
```

## Install

From the agent-workbench repo root:

```bash
./install-icm.sh
```

The script prompts for:

1. **Target project path** -- the repo where the workflow will be installed.
2. **Tools** -- Claude Code, Cursor, opencode, or all.

### What the installer does

The installer **assembles** the complete workflow tree at install time:

1. Copies `icm/workflows/` into `$TARGET/workflows/` (the structural
   skeleton: `WORKFLOW.md`, `review/`, `agents/`).
2. Copies top-level `skills/*.md` into
   `$TARGET/workflows/dev-workflow/skills/` -- populating the workflow
   with the canonical skill bodies.
3. Copies top-level `references/*.md` into
   `$TARGET/workflows/dev-workflow/references/` -- populating the shared
   conventions.
4. Writes the per-tool adapter files (`CLAUDE.md`, `.cursorrules`,
   `.opencode/instructions.md`) that point the agent to
   `workflows/dev-workflow/WORKFLOW.md`.

The installed result is a **fully self-contained** workflow tree. All
relative links in `WORKFLOW.md` (like `skills/incept.md` and
`references/artifact-dir.md`) resolve correctly. The target project has
no dependency on the agent-workbench repo after install.

### Installed layout (in target project)

```
your-project/
├── workflows/
│   └── dev-workflow/
│       ├── WORKFLOW.md
│       ├── skills/           # Assembled from repo root skills/
│       ├── references/       # Assembled from repo root references/
│       ├── review/
│       └── agents/
├── CLAUDE.md                 # (if Claude Code selected)
├── .cursorrules              # (if Cursor selected)
└── .opencode/instructions.md # (if opencode selected)
```

## Pipeline

```
incept -> tech-incept -> write-plan -> execute-plan
             ^
             |
       tech-discovery (optional, can inform any stage)
```

Each skill produces a single artifact under
`$ARTIFACT_DIR/<scope>/<slug>/<slug>-*.md`. See
`references/artifact-dir.md` for scope resolution rules.

| Phase | Artifact |
|-------|----------|
| Incept | `<slug>-inception.md`, `<slug>-spec.md` |
| Tech Discovery | `<slug>-discovery.md` |
| Tech Incept | `<slug>-design.md` |
| Write Plan | `<slug>-plan.md` |
| Execute Plan | Code commits + pull request |

## Why ICM vs standard?

| Concern | Standard variant | ICM variant |
|---------|------------------|-------------|
| Skill body | Short procedural markdown | Full workflow with templates and stage contracts |
| References | Inlined into adapter rules or skills | Separate `references/` directory, linked from skills |
| Tool coupling | Per-tool adapter renders frontmatter at install | Workflow is tool-neutral; adapters are one-line pointers |
| Cross-skill links | Implicit (skill name in prose) | Explicit relative-path links in installed tree |
| Installed shape | Skills scattered across tool-specific locations | One `workflows/` directory tree |
| Best for | Quick install, light dev-loop | Long-form workflows with auditing, review, retros |

## Working on the ICM variant

**Skills and references** are edited at the repo root (`skills/` and
`references/`), not inside `icm/`. Both variants share these canonical
sources. Changes propagate to ICM installs the next time
`install-icm.sh` runs.

**Structural files** -- `WORKFLOW.md`, `review/`, `agents/`, and the
adapter pointers -- are ICM-specific and live under `icm/`. Edit them
there.

To propagate changes to an already-installed project, re-run
`install-icm.sh` against the target path.
