# Development Workflow Rules

- Start by clarifying request scope and expected output.
- Core build pipeline: `tech-incept` → `write-plan` → `execute-plan`.
- Optional steps:
  - `tech-discovery`: independent research, use when the technology is unfamiliar.
  - `incept`: idea-to-spec, use only when no requirements exist yet.
- Use slug-based artifact names for each phase:
  - `<slug>-discovery.md`
  - `<slug>-inception.md`
  - `<slug>-spec.md`
  - `<slug>-design.md`
  - `<slug>-plan.md`
- Save planning artifacts to `$ARTIFACT_DIR/<scope>/<slug>/` per `30-artifact-dir.md`.
- Before `execute-plan`, ensure plan approval exists or ask for approval.
- During execution, validate changed areas and summarize files, checks, and risks.
- Before pushing, always check `gh pr view HEAD --json state` to verify the branch's PR is not already merged or closed. Never push to a branch whose PR has been merged — create a new branch instead.
