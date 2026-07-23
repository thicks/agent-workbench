# Save Plan — Persist Design Artifacts

Standing instruction for when the user says **save plan** or when a workflow
skill finishes a design/plan artifact that should be persisted.

This is not a separate pipeline stage — it describes **where** workflow outputs
are written. Skills (write-plan, tech-incept, etc.) already save to
`$ARTIFACT_DIR`; this reference covers the **save plan** user command and
editor integration conventions.

See [artifact-dir](artifact-dir.md) for `$ARTIFACT_DIR` resolution.

## What to save

Full **design / architecture plan** content:

- Problem / context, diagrams, call placement, caching, auth
- Files to add/change (plan intent, not "what shipped")
- Out of scope, verification steps

## What NOT to save

- Post-implementation recaps ("what shipped")
- Cursor plan frontmatter (`todos`, `overview`, `isProject`)
- Files under `.cursor/plans/`

## Default path

```
$ARTIFACT_DIR/<scope>/<slug>/<slug>-plan.md
```

Other artifact types use the same directory — see [artifact-dir](artifact-dir.md).

## Project overrides

Overrides are now derived automatically from cwd — see
[artifact-dir](artifact-dir.md). No explicit per-repo overrides are needed.

## Steps

1. Resolve `$ARTIFACT_DIR`, `<scope>`, and `<slug>`
2. Write full markdown to `$ARTIFACT_DIR/<scope>/<slug>/<slug>-plan.md`
3. Add `*Created: YYYY-MM-DD*` under the title
4. Use `-v2` suffix if file already exists
5. Confirm: `Saved: $ARTIFACT_DIR/<scope>/<slug>/<slug>-plan.md`
6. Open in editor/vault if integration is configured

## Hard rules

- Never truncate
- Never write deliverables to `.cursor/plans/`
- Always use slug-prefixed filenames
