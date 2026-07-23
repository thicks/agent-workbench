# Fix Failing Tests

Diagnose and fix failing tests with minimal, scoped changes.

## Workflow

1. **Reproduce** — run the failing test(s) and capture output.
2. **Isolate** — identify the specific assertion(s) and file(s) that fail.
3. **Diagnose** — determine root cause:
   - Is the test wrong (stale snapshot, outdated assertion, bad mock)?
   - Is the code wrong (regression, missing edge case, broken contract)?
   - Is the environment wrong (missing fixture, dependency mismatch, timing)?
4. **Fix** — apply the minimal change that resolves the failure.
   - If the test is wrong: update the test to match correct behavior.
   - If the code is wrong: fix the code, not the test.
   - If both changed: fix whichever diverged from the approved spec or intent.
5. **Verify** — re-run the failing test(s) and the broader suite to confirm no regressions.
6. **Report** — summarize root cause, what changed, and verification results.

## Rules

- Do not delete or skip tests to make the suite pass.
- Do not refactor unrelated code or tests.
- If the root cause is ambiguous, report findings and ask before changing code.
- If fixing requires a dependency update or environment change, flag it rather than applying silently.
