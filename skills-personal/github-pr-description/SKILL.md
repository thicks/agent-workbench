---
name: github-pr-description
description: "Generate and create GitHub pull requests with structured descriptions. Handles branch push, PR creation via gh, ticket linking, and description formatting."
allowed-tools: Bash(git:*), Bash(gh:*), Read, Grep
---

# GitHub PR Description Generator

Generate a clear, structured GitHub pull request description based on a code diff, commit messages, or summary. Focus on context, reasoning, and reviewer clarity—not just listing changes.

**Always deliver the description in copy-pasteable markdown** (see Response format below).

---

## Input

- `summary` (optional): High-level explanation of the change
- `diff` (optional): Git diff or changed files
- `commits` (optional): Commit messages
- `context` (optional): Ticket, feature, or bug context
- `ticket` (optional): Ticket identifier (e.g. PSS-123). Include as a link at the bottom of the PR body when provided.

---

## Steps

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

## Branch Naming

Default format: `<ticket-number>/<short-description>`

Example: `PSS-123/add-better-auth-support`

If the user says "prepend with th" or similar, use: `th/<ticket-number>/<short-description>`

## Rules

- Do NOT append "Made with Cursor", "Made with Claude", or any AI attribution footer to the PR description.
- Do NOT push to a branch whose PR has already been merged or closed. Create a new branch instead.

---

## Response format (mandatory)

When this skill is used standalone (not via `execute-plan`), the **entire assistant reply** for the PR description must be **only** a single fenced code block tagged `markdown`. The user copies the **inner** content (not the fence lines) into the GitHub PR description field.

**Do:**

- Put the full PR body inside ` ```markdown ` … ` ``` `
- Use GitHub-flavored markdown headings: `## Summary`, `## Changes`, `## How to Test`, etc.
- Keep prose outside the fence to zero—or at most one short line before the fence if the user asked a clarifying question first

**Do not:**

- Render the PR description as normal chat markdown (headings in the UI) without the fence
- Split the description across multiple code blocks
- Wrap only part of the sections in a fence
- Add a long preamble ("Here's your PR description…") before the fence

**Example shape of the reply:**

````markdown
```markdown
## Summary

...

## Changes

...

## How to Test

...

## Automated Tests

...

## Screenshots / Demo

...

## Impact

...

[PSS-123](https://linear.app/tango-group/issue/PSS-123)
```
````

(The example above shows the pattern; your actual response uses one `markdown` fence containing the real PR text.)

---

## PR body structure (inside the fence)

Use these sections in order.

### ## Summary

What this PR does, why it exists, and what problem it solves.

### ## Changes

Bullet list of important changes. Focus on intent, not raw diff noise. Use `###` subheadings when the PR spans multiple areas.

### ## How to Test

Numbered steps for manual validation. Include commands in bash fences **inside** the outer markdown fence (nested fences are fine).

### ## Automated Tests

Commands to run the automated test suite and any relevant subset commands. Example:

```
pnpm test
pnpm lint
pnpm typecheck
```

If specific test files were added or changed, call them out explicitly.

### ## Screenshots / Demo

Omit this section entirely for backend-only or non-UI changes. Include the heading with screenshots or a placeholder only when UI changed.

### ## Impact

Risks, blast radius, things to watch in production, rollback considerations, or follow-up work. If the change is low-risk and self-contained, a single line like "Low risk — scoped to new endpoint, no existing behavior changed." is fine. Do not omit this section.

### Ticket link (optional, at bottom)

If a ticket number was provided, include a plain link as the last line of the body:

`[PSS-123](https://linear.app/tango-group/issue/PSS-123)`

If no ticket number was provided, omit the line entirely.

---

## Skill prompt

You are an experienced software engineer writing a high-quality GitHub pull request description.

Your goal is to clearly communicate:

- What changed
- Why it changed
- How to review and test it
- What could go wrong

Avoid vague or generic language. Be concise but informative.

**Output rule:** Return **only** one ` ```markdown ` code block containing the complete PR description. No duplicate content outside the block.

Inside the block, use this structure:

## Summary

Explain the purpose of the PR and the problem it solves.

## Changes

List the most important changes. Focus on intent, not raw diff noise.

## How to Test

Provide clear, step-by-step instructions to validate the changes manually.

## Automated Tests

List the commands to run the automated test suite. Call out specific test files if they were added or changed.

## Screenshots / Demo

Include only when UI changed. Omit entirely for backend-only changes.

## Impact

Risks, blast radius, things to watch in production, rollback considerations, or follow-up work.

---

INPUT:

Summary:
{{summary}}

Context:
{{context}}

Commits:
{{commits}}

Diff:
{{diff}}

Ticket:
{{ticket}}

---

If the PR lacks clarity, rewrite the summary to reflect the likely product or engineering intent.

If the branch contains unrelated changes, call that out under **Impact** or **Summary**.

Now generate the PR description in the mandatory copy-pasteable markdown fence format.

---

## Trigger prompts

- Generate a PR description for this branch
- Create a clean GitHub PR description using the current diff and commits
- PR description in markdown format
- Copy and pasteable PR description

## Commands

```bash
git status
git log --oneline main..HEAD
git diff --stat main...HEAD
git push -u origin HEAD
gh pr create --title "..." --body "..."
```
