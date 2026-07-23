---
name: system-issue-analysis
description: >-
  Investigate a potential system issue, bug, or unusual behavior in the Gloo
  Forge platform and produce a structured, evidence-based diagnostic report
  (symptom, failing layer, root cause, blast radius, recommended fix) saved as
  a markdown artifact, with each distinct issue assigned a stable ID plus its
  endpoints/code areas/technologies/subissues and an appendix debugging prompt,
  so a later fix-oriented deep dive can target one issue by number with minimal
  context. Analysis only — no code changes. Use when asked to
  analyze, investigate, diagnose, or triage a system issue, an incident, a
  failing workflow run, a misbehaving agent dispatch, a governance/Trust Fabric
  block, a Convex error, or any unexpected platform behavior in Gloo Forge.
---

# System Issue Analysis (Gloo Forge)

Investigate a suspected issue in the Gloo Forge platform and deliver a written
diagnosis. This is a **read-only investigation** — you gather evidence, localize
the failing layer, identify the root cause, assess blast radius, and recommend a
fix. You do **not** implement the fix.

## The boundary (read this first)

```
ANALYSIS ONLY. NO CODE CHANGES.
Do not edit source, run mutations, or apply fixes.
The single deliverable is a diagnostic report artifact.
```

Read-only shell commands (logs, git, grep, Convex read queries) and read-only
Convex dashboard/queries are in scope. Anything that mutates state is out of
scope — recommend it in the report instead.

**Core principle:** no root cause claim without evidence. A symptom restated is
not a diagnosis. Every conclusion in the report must point at a specific file,
log line, table row, event, or diff.

## Numbered issues (why this matters)

An investigation often surfaces more than one issue. **Give every distinct issue
a stable ID** so a later, fix-oriented deep dive (a different skill) can reference
exactly one — e.g. "fix `<SLUG>-02`" — and stay focused.

- ID format: `<SLUG>-NN` (zero-padded, sequential): `<slug>-01`, `<slug>-02`, …
- One ID = one independently-fixable root cause. Don't merge unrelated problems
  under one ID; don't split one root cause into several.
- IDs are **stable**: never renumber an existing issue on a later edit. New issues
  get the next number; resolved/dismissed issues keep their ID with an updated
  `status`.
- The **Issues index** table (top of the report) is the menu the fix skill picks
  from. Keep each issue block self-contained so it can be actioned in isolation.

## Workflow

Copy this checklist and track progress:

```
Analysis progress:
- [ ] Phase 0 — Frame the issue (symptom, expected vs actual, slug/scope)
- [ ] Phase 1 — Gather evidence (Forge entry points below)
- [ ] Phase 2 — Localize the failing layer
- [ ] Phase 3 — Root cause (hypothesis → confirm with evidence)
- [ ] Phase 4 — Blast radius & impact
- [ ] Phase 5 — Package for handoff (recommended fix + references & scope + diagrams + debug prompt)
- [ ] Phase 6 — Confirm save path (prompt if it exists), then save the report
```

### Phase 0 — Frame the issue

State in one or two sentences: **what was observed**, **what was expected**, and
**when/where** it happened (which run, factory, channel, agent, route, env). Note
what's known vs assumed. Derive a kebab-case `<slug>` for the overall
investigation (e.g. `workflow-node-stuck-running`, `chat-agent-governance-block`).
If the invocation is vague, ask one focused question before digging.

As distinct issues emerge during the investigation, assign each the next
`<slug>-NN` ID (see "Numbered issues" above) and carry that ID through every
phase for that issue.

### Phase 1 — Gather evidence

Pull real evidence from the actual system before theorizing. Use the Forge entry
points in the next section. Prefer primary sources (logs, table rows, events,
git history) over recall. If the issue spans layers (orchestrator → agent →
sandbox), capture data at each boundary to see *where* it breaks.

### Phase 2 — Localize the failing layer

Map the symptom onto the Forge execution model and narrow to one layer before
going deep. See "Architecture map" below.

### Phase 3 — Root cause

State one hypothesis at a time: "The root cause is X because Y." Confirm or kill
it with evidence. Trace bad values backward to their origin — fix at the source,
not the symptom. If evidence points to environmental / timing / external causes,
say so and record what was ruled out. Do not stack speculation.

### Phase 4 — Blast radius & impact

Who/what is affected: one run or all runs of a graph, one factory or the tenant,
one agent or every dispatch site? Note severity, whether it's ongoing or
one-off, retryable or terminal, and any data-integrity or governance/audit
implications.

### Phase 5 — Package for handoff

For each numbered issue, prepare everything the fix-oriented deep dive needs:

1. **References & scope** — the endpoints/functions used, areas of code impacted
   (with paths), technologies involved, and any potential subissues (one sentence
   each). These come straight from your Phase 1–2 evidence; record them per issue.
2. **Recommended fix** — target file(s), the change, and why it addresses the root
   cause (not the symptom). Flag schema changes as widen-migrate-narrow, note
   validator implications, and call out any `[CHECKPOINT]` need. Include
   verification steps and alternatives if useful. **Do not implement.**
3. **Diagrams** — when they clarify the failure, add per-issue architecture and/or
   sequence diagrams, collocated in the issue block so a prompt referencing the ID
   carries them.
4. **Debugging prompt** — write the per-issue appendix prompt that points
   `systematic-debugging` at this analysis file, the issue ID, and only the places
   in "References & scope" to look — so the debug session starts with a small,
   focused context.

### Phase 6 — Save the report

1. Resolve the target path per "Save conventions" below:
   `$ARTIFACT_DIR/<scope>/<slug>/<slug>-issue-analysis.md`.
2. **Infer a save path per the artifact-dir rules, then ALWAYS prompt the user with
   your proposed path before writing. Do not write without explicit confirmation —
   even if the request appears to specify a folder or filename.** Show the fully
   resolved absolute path and the derived `<scope>`/`<slug>` and ask for explicit
   confirmation.
3. **If a file already exists at that exact path, prompt to overwrite** (overwrite /
   save as `-v2` / choose a different location). Never silently overwrite.
4. Only after the user gives explicit approval, write the report from the template,
   then confirm with `Saved: <path>`.

## Forge investigation entry points

Concrete places to look, by evidence type. Use only what's relevant.

**Convex logs & runtime**
- `pnpm convex:logs` (tails `convex.log`) or the Convex dashboard Logs view.
- `_scheduled_functions` queue — stuck/failed scheduled work (orchestrator steps,
  seeders, migrations). A non-empty, non-draining queue is a classic "stuck" cause.
- Convex dashboard → run a read `query` against a table to inspect live rows.

**Workflow runs** (the most common issue class)
- `convex/workflowV2/orchestrator.ts` — durable DAG state machine.
- `convex/workflowV2/agentExecution.ts` — per-node dispatch (thread-per-node).
- `convex/workflowV2/capabilityResolution.ts` — skill+tool intersection at node time.
- Tables: `workflowGraphDefinitions`, `workflowGraphNodes`, `workflowGraphEdges`,
  `stepResults` (per-node status: completed/failed/running — check for a node
  stuck `running` or a `markFailed` vs `markCompleted` mismatch).
- Node types: `agent`, `router`, `join`, `human`, `publish`.

**Ops / diagnostics (built-in)**
- `convex/ops/diagnosticTimeline.ts` — correlated per-run timeline (run events +
  platform events like deploys/config changes) from the `platformEvents` table.
  Powers `/ops/run/[runId]`. Start here for "what changed around the failure."
- `convex/ops/performanceReport.ts`, `convex/ops/attentionItems.ts`,
  `convex/lib/failureTaxonomy.ts` — `classifyError` buckets failures into
  `infrastructure | timeout | budget | logic | approval | agent | policy |
  unknown` with severity `critical | warning | info`, plus `isRetryable` and
  `blastRadius`. Use these labels in the report.

**Agent dispatch**
- `convex/lib/agentComposition.ts` — `composeAgentConfig` (universal resolver;
  prompt + skills + tools + model). Does NOT run governance.
- Dispatch sites: `convex/chat/agentDispatchExec.ts`, `convex/agents/factoryWorkerExec.ts`.
- `executionModel` must be `"native"` — `"managed"`/`"cloud"` throw at dispatch.

**Trust Fabric (governance) — for blocked/held operations**
- `convex/trust_fabric/engine.ts` + numbered gates in `convex/trust_fabric/gates/`
  (gate1Preflight → … → gate9Guardrails → gateChatResponse). A `GovernanceDecision`
  disposition of `block`/`hold` is often the "unexpected" behavior. Identify which
  gate fired and why (budget, scope, autonomy, policy, safety).

**Vercel Sandbox (code execution)**
- `convex/agents/vercelSandbox.ts` — `runInSandbox`. Look for build/test failures,
  runtime/credential issues, snapshot continuity problems.

**Capabilities**
- `convex/lib/capabilities/registry.ts` (`resolveCapability`) +
  `convex/lib/capabilities/types.ts` (`CAPABILITY_DOMAINS`). Provider resolution,
  fallback chains, health snapshots — relevant for inference/secrets/sandbox failures.

**Forge Console (UI symptoms)**
- Next.js App Router under `apps/console/src/app/`. Reactive `useQuery`/`useMutation`.
  Distinguish a data problem (Convex) from a render/hydration problem (Console).
- Observe section: `/observe/logs`, `/observe/traces`, `/observe/run-history`.

**Change correlation**
- `git log`, `git diff`, recent PRs, deploy/config-change events in `platformEvents`.
  "What changed right before this started?" is often the fastest path.

## Architecture map (localize fast)

```
Trigger (manual / API / cron)
  → workflowV2/orchestrator.ts (DAG walk, ready nodes)
    → Trust Fabric gates (allow / block / hold)        ← governance blocks live here
      → composeAgentConfig (prompt+skills+tools+model)  ← wrong tools/skills/model
        → @convex-dev/agent turn (Convex action)        ← agent/LLM behavior
          → runInSandbox (optional, Vercel VM)           ← code exec failures
        → output validation → stepResults               ← validator/ReturnsValidationError
    → orchestrator advances edges                        ← stuck node / bad edge
Forge Console (useQuery/useMutation) renders reactively  ← UI vs data problem
```

Match the symptom to a layer, then use that layer's entry points above.

## Report template

Save exactly this shape. The document holds one or more numbered issues: an
**Issues index** table up top, then one **self-contained block per issue**.

```markdown
---
title: <Human-readable investigation subject>
tags:
  - analysis
  - system-issue
  - <slug>
  - <1–3 domain tags>
keywords:
  - <3–8 search terms>
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: <analysis-complete | needs-more-data>
---

# <Subject> — Analysis

## Summary
One paragraph on the investigation: what was looked at, how many distinct issues
were found, and the headline finding. Written so an engineer and a lead both
understand it.

## Issues index
The menu for a fix-oriented deep dive — reference issues by ID.

| ID          | Title                        | Severity  | Failure class   | Status              |
| ----------- | ---------------------------- | --------- | --------------- | ------------------- |
| `<slug>-01` | <short title>                | critical  | logic           | analysis-complete   |
| `<slug>-02` | <short title>                | warning   | timeout         | needs-more-data     |

Status ∈ `analysis-complete | needs-more-data | dismissed | fixed`.
Severity ∈ `critical | warning | info`.
Failure class ∈ `infrastructure | timeout | budget | logic | approval | agent | policy | unknown`.

---

## `<slug>-01` — <short title>

- **Severity:** <critical | warning | info>
- **Failure class:** <one of the classes above>
- **Status:** <analysis-complete | needs-more-data | dismissed | fixed>

### Symptom
- Observed: <what happened>
- Expected: <what should have happened>
- Context: <run/factory/agent/route/env, timestamp>
- Reproducible: <yes/no/unknown — steps if yes>

### Evidence
Primary evidence with pointers (file:line, table row, log excerpt, event,
commit). Quote the smallest relevant snippet. Note evidence that ruled out
alternatives.

### Root cause
The confirmed cause and the mechanism. Trace bad values to their origin. If
unconfirmed, state the leading hypothesis and what evidence would confirm it.

### Diagrams
Collocated with THIS issue (not a shared section after the issues) so a follow-up
prompt that references `<slug>-NN` carries them. Use mermaid — or draw.io if that
tooling is available. Include only diagrams that clarify this issue; omit if they
add nothing.
- **Architecture:** the components involved and where the failure sits.
- **Sequence:** the interaction/flow that triggers it, marking the failing step.

### Blast radius & impact
Scope (one run vs all / one tenant vs platform), severity, ongoing vs one-off,
retryable vs terminal, any data-integrity / governance / audit implications.

### References & scope
Tells the fix-oriented deep dive exactly where to look (keeps its context small).
- **Endpoints used:** <Convex functions, HTTP/platform API routes, Console routes involved — name them>
- **Areas of code impacted:** <files / dirs / modules, with paths>
- **Technologies:** <e.g. Convex, @convex-dev/workflow, @convex-dev/agent, @vercel/sandbox, Next.js/React, Trust Fabric, WorkOS>
- **Potential subissues:**
  - <one sentence per plausible related/hidden problem>
  - <one sentence — omit the bullet list if none>

### Recommended fix (for the fix-oriented deep dive)
Target file(s) and the change, and why it fixes the root cause. Note schema /
validator / `[CHECKPOINT]` implications. Verification steps. Alternatives if any.
(Describe only — not implemented in this analysis.)

### Open questions / follow-ups
What's still unknown and what to check next for this issue.

---

## `<slug>-02` — <short title>
<repeat the per-issue block above>

---

## References
Files, dashboards, PRs, docs consulted across the investigation (clickable where
possible).

## Appendix — Debugging prompts
One copy-paste prompt per issue for the `systematic-debugging` skill. Each names
the analysis file + issue ID and the minimal set of places to look (drawn from
that issue's "References & scope"), so the debug skill loads little context.

### Prompt for `<slug>-01`
    Debug issue `<slug>-01` using the analysis report at
    `$ARTIFACT_DIR/<scope>/<slug>/<slug>-issue-analysis.md` as the starting hypothesis.
    Look here FIRST and ignore unrelated layers to keep context small:
    - Code: <Areas of code impacted for <slug>-01>
    - Endpoints/functions: <Endpoints used for <slug>-01>
    - Technologies/tools: <Technologies for <slug>-01>
    - Watch for these subissues: <Potential subissues for <slug>-01>
    Confirm the root cause against the recommended fix, then implement and verify.

### Prompt for `<slug>-02`
    <repeat the prompt shape above for each issue>
```

If exactly one issue is found, still assign it `<slug>-01` and keep the index
table (with one row) — the fix skill and future edits rely on stable IDs.

## Save conventions

- Resolve `$ARTIFACT_DIR` and `<scope>` (project override for the cwd → else
  `for <customer>` → else cwd derivation).
- **Infer a save path per the artifact-dir rules, then ALWAYS prompt the user with
  your proposed path before writing. Do not write without explicit confirmation —
  even if the request appears to specify a folder or filename.** Show the fully
  resolved absolute path and the derived `<scope>`/`<slug>` and ask for explicit
  confirmation.
- If a file already exists at that exact path, prompt the user to choose:
  overwrite / save as `-v2` / different location. Never silently overwrite.
- Path: `$ARTIFACT_DIR/<scope>/<slug>/<slug>-issue-analysis.md`.
- If the `<slug>` directory already exists from a prior discovery/plan/analysis,
  save alongside — same project.
- Never hardcode a vault path; never write to `.cursor/plans/` or `./artifacts`.
- Set `created`/`updated` to today; bump `updated` on later edits and update the
  file in place (no changelog appendices).

## Self-improvement (save location)

Deriving `<scope>` from the cwd is the most error-prone step. Get better at it
over time:

- **Treat a user correction as authoritative** for this run, and learn from it.
- **Persist recognized project mappings.** When a correction (or confirmation)
  applies to a stable project root (the cwd), offer to add/update that path →
  `<scope>` in `~/.cursor/artifact-dir.json` under `projectScopes`, so future runs
  resolve it automatically. Ask before editing the config and show the exact entry.
- **Prefer a `projectScopes` match** over re-deriving from the cwd — per the
  artifact-dir rule it's the highest-priority signal.
- **When unsure, ask once** with the 1–2 most likely scopes rather than guessing;
  a wrong guess scatters artifacts across the vault.

## Guardrails

- **No fixes.** If you find yourself editing source or running a mutation, stop —
  that belongs in a follow-up, not this analysis.
- **Evidence before conclusions.** Don't restate the symptom as a root cause.
- **One hypothesis at a time.** Confirm or kill each with evidence.
- **Localize before deep-diving.** Use the architecture map; don't read the whole
  orchestrator when a `stepResults` row already names the failing node.
- **Distinguish data vs UI.** A blank Console screen may be a Convex query error,
  not a React bug — check both sides of the reactive boundary.
- **Ask if blocked.** If required context (run id, env, repro) is missing, ask one
  focused question rather than guessing.
- **Number every issue with a stable ID.** One `<slug>-NN` per independently-
  fixable root cause; keep each block self-contained; never renumber on edits.
  This document is the reference the fix-oriented deep dive targets by ID.
- **Scope every issue for cheap handoff.** Fill "References & scope" (endpoints,
  code areas, technologies, subissues) and write the appendix debugging prompt so
  `systematic-debugging` can start with a minimal, focused context window.
