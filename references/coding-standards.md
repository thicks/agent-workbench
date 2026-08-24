# Coding Standards

## Skill authoring

- Use concise, explicit Markdown instructions.
- Keep skills task-focused and deterministic.
- Prefer checklist-based workflows for repeatability.
- Keep comments and prose grammatically correct.

## Shell

- Start scripts with `set -euo pipefail`.
- Do not use bare `((x++))` under `set -e` when `x` may be 0; GNU bash
  treats that as failure. Prefer `x=$((x + 1))` or drop unused counters.
- `local var="$(cmd)"` masks `cmd`'s exit status (SC2155). Declare, then assign.
- Quote expansions. Enable `nullglob` (and restore it) before `for f in dir/*`.
- Distinguish skip from error: do not `|| true` over real `cp` failures.
- Name timeouts, intervals, and other literals (`POLL_INTERVAL_MS`), do not repeat magic numbers.

## TypeScript

- One primitive over three copies of the same loop.
- Clear timers / listeners on resolve and reject.
- Examples in this repo must typecheck without private path aliases.

## Git

- Never commit to `main`. Never `git push` with no refspec on a main checkout.
- Force-push policy lives on GitHub branch protection, not only in `settings.json`.
