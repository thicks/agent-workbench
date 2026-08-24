# Coding Standards

- Use concise, explicit Markdown instructions.
- Keep skills task-focused and deterministic.
- Prefer checklist-based workflows for repeatability.
- Keep comments and prose grammatically correct.

## Shell

- `set -euo pipefail`. No bare `((x++))` under `set -e` when the counter may be 0.
- Declare `local` separately from command substitution (SC2155).
- Quote paths. Use `nullglob` for `dir/*` loops. Do not swallow `cp` failures with `|| true`.

## TypeScript

- Prefer one shared primitive over copied polling loops.
- Clear timers on completion. Named constants instead of repeated literals.
