# Git Workflow

## Branch Rules

- Never commit directly to `main` or `master`.
- Create feature branches for all work: `feat/<slug>` or `<TICKET-ID>/<slug>`.
- Push only to feature branches — pushes to `main`/`master` are blocked.
- Force pushes are blocked.

## Push Safety

Before pushing, always check `gh pr view HEAD --json state` to verify the
branch's PR is not already merged or closed. Never push to a branch whose PR
has been merged — create a new branch instead.

## Artifact Naming

Use slug-based artifact names for each phase:

- `<slug>-discovery.md`
- `<slug>-inception.md`
- `<slug>-spec.md`
- `<slug>-design.md`
- `<slug>-plan.md`

Save planning artifacts to `$ARTIFACT_DIR/<scope>/<slug>/` (defaults to `./artifacts/<scope>/<slug>/`).

See [artifact-dir](artifact-dir.md) for resolution order, slug lookup, scope derivation, and Obsidian open.

## Workflow Rules

- Start by clarifying request scope and expected output.
- Before `execute-plan`, ensure plan approval exists or ask for approval.
- During execution, validate changed areas and summarize files, checks, and risks.
