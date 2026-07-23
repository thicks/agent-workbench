# Architecture

agent-workbench is a downloadable agentic development workflow that teaches Claude, Cursor, and opencode to build software through a structured pipeline of skills.

The **standard model** is the core: a set of reusable skills that work together to guide development from idea to shipped code. You invoke them when needed, and they produce artifacts (specs, plans, PRs) that feed into the next step.

There's also an **ICM variant** (optional) for teams who want workflow routing, gates, and orchestration baked in—useful when the pipeline itself needs to be auditable and versioned.

Both variants share the same skills and produce the same artifacts. The difference is how they're packaged and invoked.

## Repository structure: Dual-variant layout

The agent-workbench repo holds both the standard and ICM variants because they share the same skill and reference bodies. Only the packaging differs.

```
agent-workbench/
├── skills/                       ← Canonical skill bodies (shared by both variants)
├── references/                   ← Canonical reference docs (shared by both variants)
│
├── adapters/                     ← Standard variant: tool-specific adapters
│   ├── claude/                   ├─ Claude Code adapter (agents, commands, rules, settings)
│   │   ├── skills/               ├─ Skill headers (*.header.md) to render with bodies
│   │   ├── agents/, commands/
│   │   ├── rules/, settings.json
│   ├── cursor/                   ├─ Cursor: .cursorrules + config
│   └── opencode/                 ├─ opencode: AGENTS.md + instructions.md
│
├── icm/                          ← ICM variant: workflow orchestration (optional)
│   ├── workflows/dev-workflow/   ├─ Routing, gates, and agent definitions
│   │   ├── WORKFLOW.md           ├─ Router entry point
│   │   ├── review/               ├─ Quality gates (code-review, plan-review, spec-review)
│   │   └── agents/               ├─ Subagent definitions (task-executor)
│   └── adapters/                 ├─ Tool-specific pointers to workflow
│
├── install.sh                    ← Standard installer: renders & copies to adapters
├── install-icm.sh                ← ICM installer: assembles skills/references into workflows
├── docs/
├── CLAUDE.md
└── README.md
```

### Why both variants in one repo?

**Single source of truth for content**: Skills and references are written once. When you update a skill body, both variants get the update automatically.

**Install-time assembly**: Each installer takes the shared sources and assembles them differently:
- `install.sh` → Renders skills with tool-specific headers and copies adapters (standard)
- `install-icm.sh` → Embeds skills/references into the workflow tree (ICM)

**No duplication, no drift**: Because skills are canonical at the repo root, a bug fix or improvement in one skill fixes it for both variants.

## Comparison: Standard vs ICM

| Aspect | Standard | ICM |
|--------|----------|-----|
| **Entry point** | Individual slash commands (`/incept`, `/write-plan`, etc.) | Single `WORKFLOW.md` routing entry point |
| **Sequencing** | User decides order and which steps to run | Workflow enforces sequence and gates |
| **Quality gates** | None built-in (user manually validates) | Integrated review steps with automated feedback loops |
| **State tracking** | None (each skill is independent) | Workflow state machine tracks progression |
| **When to use** | Flexible ad-hoc workflows, reusable skills across projects | End-to-end development pipeline with guardrails |
| **Readability** | Skills are isolated, easy to understand individually | Workflow logic is visible and auditable in WORKFLOW.md |
| **Extension** | Add new skills without touching routing logic | Modify WORKFLOW.md to change pipeline behavior |

## Standard variant: The core model

The standard model is skill-based. Install `install.sh`, and you get a set of reusable skills that live in your tool's skill directory. Invoke them with slash commands whenever you need them.

### What happens when you install (standard)

```bash
./install.sh
# Select tool(s): Claude Code, Cursor, opencode, or all
# Target project path: ./
```

Installation:
1. **Copies `skills/` to target** — canonical skill bodies (tool-neutral markdown)
2. **Renders skills per-tool** — concatenates frontmatter headers + skill bodies
3. **Installs adapters** — tool-specific config (agents, commands, rules, settings)

Result: Each tool gets a populated `skills/` directory with trigger-ready skills.

### How the standard model works

Users invoke skills directly when needed. Each skill reads artifact files left by previous steps and produces new artifacts that feed downstream.

```
User invokes        Skill produces         Next step reads
────────────────────────────────────────────────────────
/incept my-feature  → spec.md             (design doc)
/tech-discovery tsx → research.md         (reference)
/tech-incept        → design.md           (implementation)
/write-plan         → plan.md             (tasklist)
/execute-plan       → PR opened           (shipped)
```

**Flexibility**: Skip steps, run in any order, or use only the skills you need. Great for ad-hoc development and integrating into existing tool setups.

### Repository structure for standard

```
agent-workbench/
├── skills/                       ← Canonical skill bodies (written once)
├── references/                   ← Canonical reference docs (written once)
├── adapters/                     ← Tool-specific frontmatter and config
│   ├── claude/
│   │   ├── skills/               ├─ Frontmatter headers (*.header.md)
│   │   ├── agents/, commands/    ├─ Claude-specific extensions
│   │   ├── rules/, settings.json └─ Config
│   ├── cursor/                   ← Cursor config and rules
│   └── opencode/                 ← opencode config
├── install.sh                    ← Standard installer
└── CLAUDE.md                     ← Repo dev guide
```

**How it flows in practice**: User types `/incept` to clarify an idea. The incept skill runs a PM interview and writes `spec.md`. Next, the user types `/tech-discovery` (if needed), which reads `spec.md`, researches the topic, and writes `research.md`. Then `/tech-incept` reads both, designs a solution, writes `design.md`. Then `/write-plan` breaks it into tasks, writes `plan.md`. Finally, `/execute-plan` reads the plan and builds it.

**Key observations**:
- User stays in control—they decide when to invoke each step
- Each skill reads context from previous artifacts
- Skills are stateless—they don't need to know about each other
- Artifacts live in `$ARTIFACT_DIR` and are version-controlled (checked into git)
- No orchestration overhead—just invoke what you need

### Tool-specific installation details

Skill bodies live at `skills/<name>.md` — plain markdown, tool-neutral, no frontmatter. When you run `install.sh`, each tool gets what it needs:

| Tool | What install.sh does |
|---|---|
| **Claude Code** | Concatenates `<name>.header.md` (YAML frontmatter with trigger phrases) + `skills/<name>.md` → `.claude/skills/<name>/SKILL.md`. Also copies agents, commands, rules, and settings. |
| **Cursor** | Copies `.cursorrules` and artifact-dir config. Skills are installed to `skills/`. |
| **opencode** | Copies `AGENTS.md` and `instructions.md`. Skills are installed to `skills/`. |

**Why tool-neutral bodies?** Writing skill content once avoids drift across tools. Tool-specific metadata (trigger phrases, descriptions) lives in `.header.md` files, so you can update skill logic without touching tool configuration.

## ICM variant (optional): Workflow orchestration

**For most users: use the standard model.** The ICM variant is optional, designed for teams that want the workflow itself to be a first-class artifact with routing, gates, and orchestration.

### What is ICM?

ICM (Interpretable Context Methodology) wraps the same skills in a routing layer (`WORKFLOW.md`) that:
- **Routes** through stages with conditional logic ("Do we need research?")
- **Gates** each stage with validation steps (spec review, plan review, code review)
- **Orchestrates** the full pipeline—user invokes once, workflow manages sequencing
- **Tracks state**—workflow knows where you are and what comes next

### When to use ICM instead of standard

Pick ICM if:
- **Workflow is an artifact**: You want to audit, version, and refactor the pipeline itself
- **Gates matter**: Quality checks are mandatory, not optional
- **Control is strict**: Sequence must be enforced (can't skip to execution without a plan)
- **Transparency required**: Stakeholders need to review the entire pipeline logic

Use standard if you prefer flexibility, lightweight installation, and loose skill coupling.

### ICM repository structure

The ICM directory contains **only** the structural/routing layer. Skills and references are shared from the repo root.

```
icm/
├── workflows/dev-workflow/       ← Self-contained workflow tree (no skills or references here)
│   ├── WORKFLOW.md               ← Router: entry point that orchestrates the pipeline
│   │                                Decides routing (incept needed?), gates (design ready?),
│   │                                and sequencing (can't execute without a plan)
│   │
│   ├── review/                   ← Quality gates (automated validation steps)
│   │   ├── code-review.md        ├─ Validates code correctness, test coverage
│   │   ├── plan-review.md        ├─ Validates plan completeness before execution
│   │   └── spec-review.md        └─ Validates spec before design work
│   │
│   └── agents/                   ← Subagent definitions
│       └── task-executor.md      └─ Long-running agent for autonomous implementation
│
└── adapters/                     ← Tool-specific configuration (thin pointers)
    ├── claude/                   ├─ Points Claude Code to workflows/dev-workflow/WORKFLOW.md
    ├── cursor/
    └── opencode/
```

When `install-icm.sh` runs, it assembles the full workflow tree:
1. Copies `icm/workflows/` to target
2. Copies `skills/` (from repo root) → `workflows/dev-workflow/skills/`
3. Copies `references/` (from repo root) → `workflows/dev-workflow/references/`
4. Installs tool-specific adapters that reference the workflow

Result: Target project has a complete, auditable workflow with embedded content and routing logic.

### Installing ICM

```bash
./install-icm.sh
# Select tool(s): Claude Code, Cursor, opencode, or all
# Target project path: ./

# Result: Fully self-contained workflow tree with embedded skills/references
```


## Pipeline

Both variants share the same five-stage pipeline:

1. **incept** (optional) — clarify a raw idea into a spec
2. **tech-discovery** (optional) — research an unfamiliar technology
3. **tech-incept** — produce an engineering design from requirements
4. **write-plan** — break the design into micro-tasks
5. **execute-plan** — autonomously implement and open a PR

## Artifact layout

All artifacts are saved to `$ARTIFACT_DIR/<scope>/<slug>/`. The `<scope>` is
derived from the workspace path or an explicit `for <customer>` phrase.

See `adapters/claude/rules/30-artifact-dir.md` (standard) or
`references/artifact-dir.md` for the full resolution rules.
