# Artifact directory (`ARTIFACT_DIR` + `<scope>`)

Every artifact path produced by the dev-workflow skills (`incept`,
`tech-incept`, `tech-discovery`, `write-plan`, `execute-plan`, `plan-review`)
is `$ARTIFACT_DIR/<scope>/<slug>/<slug>-*.md`.

Resolve `$ARTIFACT_DIR` and `<scope>` once per session, before scaffolding any
artifact. Never hardcode vault paths.

## `ARTIFACT_DIR`

- Read from environment. Set in `.claude/settings.local.json` under `env`
  (see `.claude/settings.local.json.example` for the shape).
- Fallback: `./artifacts/` relative to cwd (already in `.gitignore`).

## `<scope>` resolution

Build `<scope>` from two inputs, in order:

1. **Explicit `for <customer>`** in the invocation
   (`"incept an idea for Gloo"`, `"plan for Thickideas"`).
2. **Workspace path** derived from cwd.

### Workspace from cwd

- Strip the user's home prefix (`$HOME`) and any leading segments named in
  `ARTIFACT_DIR_STRIP_SEGMENTS` (comma-separated env var, defaults to `dev`).
- Take the next two segments as `<customer>/<workspace>`.
- Examples:
  - cwd `~/dev/myorg/agent-workbench` → workspace `myorg/agent-workbench`
  - cwd `~/dev/Gloo/mission-control` → workspace `Gloo/mission-control`

### Scope assembly

| Inputs | `<scope>` |
|--------|-----------|
| Explicit `for <customer>` + workspace `<customer>/<project>` (same `<customer>`) | `<customer>/<project>` |
| Explicit `for <customer>` only (no matching workspace) | `<customer>` |
| Workspace only, no explicit phrase | `<customer>/<project>` |
| Neither | (empty — artifacts go directly under `$ARTIFACT_DIR/<slug>/`) |

### Case rule

If a directory matching the desired scope segment **already exists** under
`$ARTIFACT_DIR`, reuse its casing (e.g. user has `Gloo/` — keep `Gloo`, not
`gloo`). Otherwise prefer the casing the user typed (Title-case for proper
nouns); default to lowercase-kebab for product/repo names.

### Slug-collapse rule

If `<slug>` equals the last segment of `<scope>` (case-insensitive), skip the
nested `<slug>/` subdirectory — write artifacts directly into
`$ARTIFACT_DIR/<scope>/` instead of `$ARTIFACT_DIR/<scope>/<slug>/`. This
avoids a redundant repeated directory name (e.g. avoid
`.../agent-workbench/agent-workbench/`). Check this before creating the
artifact directory.

## Examples

| Invocation | cwd | `<scope>` | Final path |
|------------|-----|-----------|------------|
| `incept an idea for Gloo` | `~/dev/Gloo/mission-control` | `Gloo/mission-control` | `$ARTIFACT_DIR/Gloo/mission-control/<slug>/` |
| `plan an idea for myorg` | any | `myorg` | `$ARTIFACT_DIR/myorg/<slug>/` |
| `incept loyalty rewards` | `~/dev/myorg/agent-workbench` | `myorg/agent-workbench` | `$ARTIFACT_DIR/myorg/agent-workbench/<slug>/` |
| `write a plan` | `~/Projects/personal-app` | (no scope — `Projects` not under strip list) | `$ARTIFACT_DIR/Projects/personal-app/<slug>/` |
| `incept loyalty rewards` (no cwd context) | `~/` | (none) | `$ARTIFACT_DIR/<slug>/` |
| `incept agent-workbench` | `~/dev/myorg/agent-workbench` | `myorg/agent-workbench` | `$ARTIFACT_DIR/myorg/agent-workbench/` (slug collapses — matches last scope segment) |

## Hard rules

- **Always** resolve `$ARTIFACT_DIR` from env — never hardcode vault paths.
- **Always** use slug-prefixed filenames: `<slug>-inception.md`, `<slug>-spec.md`,
  `<slug>-design.md`, `<slug>-discovery.md`, `<slug>-plan.md`.
- **Confirm** the final path to the user before writing the first artifact
  in a new scope.
