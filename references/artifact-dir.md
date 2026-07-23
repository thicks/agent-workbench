# Artifact Directory (`ARTIFACT_DIR`)

All workflow skills save slug-based markdown artifacts under `$ARTIFACT_DIR/<scope>/<slug>/`,
where `<scope>` is derived from cwd or an explicit `for <customer>` phrase
(see [Destination subpath](#destination-subpath) below).

## Resolution order

1. `ARTIFACT_DIR` environment variable
2. Project `.env` — `ARTIFACT_DIR=...` (Cursor)
3. `.claude/settings.local.json` — `"env": {"ARTIFACT_DIR": "..."}` (Claude Code)
4. Default: `./artifacts` in the current project root

Expand `~` to the user's home directory before use.

## Destination subpath

Every artifact path is `$ARTIFACT_DIR/<scope>/<slug>/<slug>-*.md`. `<scope>` is
derived once per session from the trigger sentence and the current working
directory.

### Trigger phrase parsing

If the user's invocation contains `for <customer>` (case-insensitive, where
`<customer>` is a single token), capture `<customer>` as the explicit customer
segment. Examples that match: "incept an idea for Acme", "plan for myorg",
"write plan for billing-service". Ambiguous phrasings (e.g. "plan for next
week") — ask once.

### Path derivation from cwd

Take cwd relative to `$HOME`. Drop any leading segment matching the strip-list
(default `dev`; override via `ARTIFACT_DIR_STRIP_SEGMENTS` — comma-separated,
e.g. `dev,work,projects`). Use the first two remaining segments as
`<customer-from-path>/<workspace>`. One remaining segment → workspace only.
Zero remaining → flat fallback.

### Scope assembly

| Signals | `<scope>` |
|---|---|
| Explicit `for <customer>` + workspace under strip-list root | `<customer>/<workspace>` (workspace from cwd) |
| Explicit `for <customer>` only | `<customer>` |
| Workspace cwd only (under strip-list root) | `<customer-from-path>/<workspace>` |
| Neither | `""` (flat `$ARTIFACT_DIR/<slug>/`, back-compat) |

### Slug-collapse rule

If `<slug>` equals the last path segment of `<scope>` (case-insensitive),
skip the nested `<slug>/` subdirectory — write artifacts directly into
`$ARTIFACT_DIR/<scope>/` instead of `$ARTIFACT_DIR/<scope>/<slug>/`. This
avoids a redundant directory name repeating itself (e.g. avoid
`.../agent-workbench/agent-workbench/`). Applies to every skill that
resolves `<scope>` and `<slug>` — check this before the "Create directory"
step.

### Case rule

Lowercase-kebab a fresh customer segment. If `$ARTIFACT_DIR/` already contains
a case-insensitive sibling (e.g. user says "for acme" but `Acme/` exists),
reuse the existing directory's casing. Workspace segments derived from cwd
preserve on-disk casing.

### Examples

- cwd `~/dev/myorg/webapp`, no phrase → `$ARTIFACT_DIR/myorg/webapp/<slug>/`
- cwd `~/dev/Acme/billing`, no phrase → `$ARTIFACT_DIR/Acme/billing/<slug>/`
- cwd `~/dev/myorg/webapp` + "for Acme" → `$ARTIFACT_DIR/Acme/webapp/<slug>/`
- No matching cwd + "for myorg" → `$ARTIFACT_DIR/myorg/<slug>/`
- Nothing matched → `$ARTIFACT_DIR/<slug>/`

## Paths

```
$ARTIFACT_DIR/<scope>/<slug>/<slug>-inception.md
$ARTIFACT_DIR/<scope>/<slug>/<slug>-spec.md
$ARTIFACT_DIR/<scope>/<slug>/<slug>-discovery.md
$ARTIFACT_DIR/<scope>/<slug>/<slug>-design.md
$ARTIFACT_DIR/<scope>/<slug>/<slug>-plan.md
```

Unless the slug-collapse rule applies (see above), in which case drop the
`<slug>/` segment: `$ARTIFACT_DIR/<scope>/<slug>-*.md`.

## Slug lookup (idea name → file)

When the user gives an idea name (no path), derive kebab-case `<slug>` and read:

| Need | Path |
|------|------|
| Spec (after incept) | `$ARTIFACT_DIR/<scope>/<slug>/<slug>-spec.md` |
| Inception (in progress) | `$ARTIFACT_DIR/<scope>/<slug>/<slug>-inception.md` |
| Design (after tech-incept) | `$ARTIFACT_DIR/<scope>/<slug>/<slug>-design.md` |
| Plan (after write-plan) | `$ARTIFACT_DIR/<scope>/<slug>/<slug>-plan.md` |
| Discovery | `$ARTIFACT_DIR/<scope>/<slug>/<slug>-discovery.md` |

To list recent plans: find `*-plan.md` under `$ARTIFACT_DIR/**/<slug>/` (walk
up to three levels deep to cover `<customer>/<workspace>/<slug>/`, plain
`<scope>/<slug>/`, and flat `<slug>/` layouts) modified in the last 7 days.

## Editor integration (optional)

If `$ARTIFACT_DIR` lives inside a note-taking app vault (e.g. Obsidian), open
artifacts after write using the appropriate URI scheme:

```bash
open "obsidian://open?vault=<vault>&file=<vault-relative-path-without-.md>"
```

If `$ARTIFACT_DIR` is outside a vault, skip the URI and confirm the absolute
path only.

## Project overrides

Overrides are now derived automatically from cwd via the Destination subpath
rule above. Explicit per-repo overrides are no longer needed and should not
be added.

## Hard rules

- Never hardcode `1-Projects/plans/` or other vault paths.
- Never write deliverables to `.cursor/plans/`.
- Always use slug-prefixed filenames (`<slug>-plan.md`, not `plan.md`).
