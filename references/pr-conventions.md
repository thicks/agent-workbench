# PR Conventions

## Branch Naming

Default format: `<ticket-number>/<short-description>`

Example: `PSS-123/add-better-auth-support`

If the user says "prepend with th" or similar, use: `th/<ticket-number>/<short-description>`

## Creating a PR

1. Confirm current branch is not `main` or `master`.
2. Check for an existing PR on this branch: `gh pr view HEAD --json state,url 2>/dev/null`.
   - If a PR exists and is **open**: push new commits and report the existing URL. Do not create a duplicate.
   - If a PR exists and is **merged or closed**: do NOT push to this branch. Create a new branch from `main` with the unpushed changes, then continue from step 3.
   - If no PR exists: continue.
3. Inspect branch status and commit range against base branch.
4. Summarize all commits included in the PR.
5. Push branch with `git push -u origin HEAD` if needed.
6. Ask the user: "Is there a ticket number for this PR? (e.g. PSS-123, leave blank to skip)"
7. Generate the PR description following the structure below.
8. Create PR using `gh pr create` with the generated description.

## Rules

- Do NOT append "Made with Cursor", "Made with Claude", or any AI attribution.
- Do NOT push to a branch whose PR has already been merged or closed.

## PR Body Structure

### Summary

What this PR does, why it exists, and what problem it solves.

### Changes

Bullet list of important changes. Focus on intent, not raw diff noise.

### How to Test

Numbered steps for manual validation.

### Automated Tests

Commands to run the automated test suite. Example:

```
pnpm test
pnpm lint
pnpm typecheck
```

### Screenshots / Demo

Omit for backend-only or non-UI changes.

### Impact

Risks, blast radius, things to watch in production, rollback considerations.
Do not omit this section — even low-risk changes should say so.

### Ticket Link (optional)

If a ticket number was provided, include as the last line:
`[PSS-123](https://linear.app/tango-group/issue/PSS-123)`
