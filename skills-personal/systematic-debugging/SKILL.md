---
name: systematic-debugging
description: "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes. Drives one issue to a verified root-cause fix and records the session as a <slug>-debug.md artifact under $ARTIFACT_DIR; can be driven by a system-issue-analysis issue ID when one is provided."
risk: unknown
source: community
date_added: "2026-02-27"
---

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## When to Use
Use for ANY technical issue:
- Test failures
- Bugs in production
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues

**Use this ESPECIALLY when:**
- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- You've already tried multiple fixes
- Previous fix didn't work
- You don't fully understand the issue

**Don't skip when:**
- Issue seems simple (simple bugs have root causes too)
- You're in a hurry (rushing guarantees rework)
- Manager wants it fixed NOW (systematic is faster than thrashing)

## Output artifact

Record the debugging session as a durable artifact under `$ARTIFACT_DIR`.

- **Filename:** `<slug>-debug.md`
- **Path:** `$ARTIFACT_DIR/<scope>/<slug>/<slug>-debug.md`

## Save path checkpoint

Use the same save-location protocol as `system-issue-analysis`:

**Infer a save path per the artifact-dir rules, then ALWAYS prompt the user with
your proposed path before writing. Do not write without explicit confirmation — even
if the request appears to specify a folder or filename.**

1. Resolve `$ARTIFACT_DIR` and `<scope>` (project override for the cwd → else
   `for <customer>` → else cwd derivation). `<slug>` is the kebab-case bug subject.
2. Propose the fully resolved absolute path (e.g.
   `$ARTIFACT_DIR/<scope>/<slug>/<slug>-debug.md`) and ask the user for explicit
   confirmation. Show the derived `<scope>` and `<slug>` clearly.
3. If a file already exists at that exact path, prompt the user to choose:
   overwrite / save as `-v2` / pick a different location. Never silently overwrite.
4. Only after the user gives explicit approval of the path (and overwrite choice
   if applicable), proceed to write or update the file.

Do this checkpoint as soon as the slug and likely scope are known. If the investigation
later proves the slug is wrong, prompt again with the corrected path before writing.

If the `<slug>` directory already exists from a prior analysis or discovery, save
alongside — same project. Never hardcode a vault path; never write to
`.cursor/plans/` or `./artifacts`.

Frontmatter:

```yaml
---
title: <Human-readable bug>
tags:
  - debug
  - <slug>
  - <1–3 domain tags>
keywords:
  - <3–8 search terms>
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: <investigating | root-cause-found | fixed | blocked>
source_analysis: <analysis path + issue id if driven from a system-issue-analysis report, else omit>
---
```

Set `created`/`updated` to today; bump `updated` and advance `status` as you move
through the phases. Prepare the frontmatter and body content during the phases,
but write (or update) the file on disk **only after the user has confirmed the
resolved save path** (see the confirmation steps above). Under real time pressure
keep it terse — but still obtain confirmation before writing; the record is what
makes the fix reproducible and hands off cleanly.

Body sections map 1:1 to the phases:
1. **Symptom** — observed vs expected, context, reproducibility.
2. **Root cause investigation** (Phase 1) — evidence, errors, data-flow trace.
3. **Pattern analysis** (Phase 2) — working reference vs broken, differences.
4. **Hypothesis & tests** (Phase 3) — each hypothesis and its result.
5. **Fix & verification** (Phase 4) — the change made and how it was proven.
6. **Follow-ups** — regressions to watch, monitoring, architectural concerns.

## Optional: start from an analysis report

If a `system-issue-analysis` artifact and an issue ID (`<slug>-NN`) were provided,
load that issue block first and use its symptom / evidence / root-cause hypothesis
/ recommended fix as your Phase 1 starting point — then jump to Phase 3 to confirm
the hypothesis and fix. Record the source in `source_analysis`.

**The file may not be available — that's expected.** When no analysis artifact
exists, run the full Phase 1 discovery yourself. Debugging never *requires* an
analysis report; it only accelerates when one is present.

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

> If driven from a `system-issue-analysis` issue (see "Optional: start from an
> analysis report" above), begin by loading that issue block as your starting
> hypothesis, then confirm it via Phase 3 rather than repeating discovery. If no
> analysis artifact is available, run the full discovery below.

1. **Read Error Messages Carefully**
   - Don't skip past errors or warnings
   - They often contain the exact solution
   - Read stack traces completely
   - Note line numbers, file paths, error codes

2. **Reproduce Consistently**
   - Can you trigger it reliably?
   - What are the exact steps?
   - Does it happen every time?
   - If not reproducible → gather more data, don't guess

3. **Check Recent Changes**
   - What changed that could cause this?
   - Git diff, recent commits
   - New dependencies, config changes
   - Environmental differences

4. **Gather Evidence in Multi-Component Systems**

   **WHEN system has multiple components (CI → build → signing, API → service → database):**

   **BEFORE proposing fixes, add diagnostic instrumentation:**
   ```
   For EACH component boundary:
     - Log what data enters component
     - Log what data exits component
     - Verify environment/config propagation
     - Check state at each layer

   Run once to gather evidence showing WHERE it breaks
   THEN analyze evidence to identify failing component
   THEN investigate that specific component
   ```

   **Example (multi-layer system):**
   ```bash
   # Layer 1: Workflow
   echo "=== Secrets available in workflow: ==="
   echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"

   # Layer 2: Build script
   echo "=== Env vars in build script: ==="
   env | grep IDENTITY || echo "IDENTITY not in environment"

   # Layer 3: Signing script
   echo "=== Keychain state: ==="
   security list-keychains
   security find-identity -v

   # Layer 4: Actual signing
   codesign --sign "$IDENTITY" --verbose=4 "$APP"
   ```

   **This reveals:** Which layer fails (secrets → workflow ✓, workflow → build ✗)

5. **Trace Data Flow**

   **WHEN error is deep in call stack:**

   See `root-cause-tracing.md` in this directory for the complete backward tracing technique.

   **Quick version:**
   - Where does bad value originate?
   - What called this with bad value?
   - Keep tracing up until you find the source
   - Fix at source, not at symptom

### Phase 2: Pattern Analysis

**Find the pattern before fixing:**

1. **Find Working Examples**
   - Locate similar working code in same codebase
   - What works that's similar to what's broken?

2. **Compare Against References**
   - If implementing pattern, read reference implementation COMPLETELY
   - Don't skim - read every line
   - Understand the pattern fully before applying

3. **Identify Differences**
   - What's different between working and broken?
   - List every difference, however small
   - Don't assume "that can't matter"

4. **Understand Dependencies**
   - What other components does this need?
   - What settings, config, environment?
   - What assumptions does it make?

### Phase 3: Hypothesis and Testing

**Scientific method:**

1. **Form Single Hypothesis**
   - State clearly: "I think X is the root cause because Y"
   - Write it down
   - Be specific, not vague

2. **Test Minimally**
   - Make the SMALLEST possible change to test hypothesis
   - One variable at a time
   - Don't fix multiple things at once

3. **Verify Before Continuing**
   - Did it work? Yes → Phase 4
   - Didn't work? Form NEW hypothesis
   - DON'T add more fixes on top

4. **When You Don't Know**
   - Say "I don't understand X"
   - Don't pretend to know
   - Ask for help
   - Research more

### Phase 4: Implementation

**Fix the root cause, not the symptom:**

1. **Create Failing Test Case**
   - Simplest possible reproduction
   - Automated test if possible
   - One-off test script if no framework
   - MUST have before fixing
   - Use the `superpowers:test-driven-development` skill for writing proper failing tests

2. **Implement Single Fix**
   - Address the root cause identified
   - ONE change at a time
   - No "while I'm here" improvements
   - No bundled refactoring

3. **Verify Fix**
   - Test passes now?
   - No other tests broken?
   - Issue actually resolved?

4. **If Fix Doesn't Work**
   - STOP
   - Count: How many fixes have you tried?
   - If < 3: Return to Phase 1, re-analyze with new information
   - **If ≥ 3: STOP and question the architecture (step 5 below)**
   - DON'T attempt Fix #4 without architectural discussion

5. **If 3+ Fixes Failed: Question Architecture**

   **Pattern indicating architectural problem:**
   - Each fix reveals new shared state/coupling/problem in different place
   - Fixes require "massive refactoring" to implement
   - Each fix creates new symptoms elsewhere

   **STOP and question fundamentals:**
   - Is this pattern fundamentally sound?
   - Are we "sticking with it through sheer inertia"?
   - Should we refactor architecture vs. continue fixing symptoms?

   **Discuss with your human partner before attempting more fixes**

   This is NOT a failed hypothesis - this is a wrong architecture.

6. **Finalize the artifact**
   - Before writing the final version, propose the resolved path (per the same
     inference rules) and **always prompt** the user for explicit approval. If the
     file exists, prompt for overwrite / `-v2` / different location.
   - Update `<slug>-debug.md`: fill "Fix & verification", set `status: fixed`
     (or `blocked` if you stopped at Phase 4.5), bump `updated`.
   - Write the file only after the user explicitly approves the path (and
     overwrite decision if applicable), then report `Saved: <path>`.
   - If this was driven from a `system-issue-analysis` issue, note in the report
     that the source issue's fix is implemented (the analysis doc's issue `status`
     can be flipped to `fixed` in that file separately).

## Red Flags - STOP and Follow Process

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**

**ALL of these mean: STOP. Return to Phase 1.**

**If 3+ fixes failed:** Question the architecture (see Phase 4.5)

## your human partner's Signals You're Doing It Wrong

**Watch for these redirections:**
- "Is that not happening?" - You assumed without verifying
- "Will it show us...?" - You should have added evidence gathering
- "Stop guessing" - You're proposing fixes without understanding
- "Ultrathink this" - Question fundamentals, not just symptoms
- "We're stuck?" (frustrated) - Your approach isn't working

**When you see these:** STOP. Return to Phase 1.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## When Process Reveals "No Root Cause"

If systematic investigation reveals issue is truly environmental, timing-dependent, or external:

1. You've completed the process
2. Document what you investigated in `<slug>-debug.md` and set `status: blocked`
3. Implement appropriate handling (retry, timeout, error message)
4. Add monitoring/logging for future investigation

**But:** 95% of "no root cause" cases are incomplete investigation.

## Supporting Techniques

These techniques are part of systematic debugging and available in this directory:

- **`root-cause-tracing.md`** - Trace bugs backward through call stack to find original trigger
- **`defense-in-depth.md`** - Add validation at multiple layers after finding root cause
- **`condition-based-waiting.md`** - Replace arbitrary timeouts with condition polling

**Related skills:**
- **superpowers:test-driven-development** - For creating failing test case (Phase 4, Step 1)
- **superpowers:verification-before-completion** - Verify fix worked before claiming success

## Real-World Impact

From debugging sessions:
- Systematic approach: 15-30 minutes to fix
- Random fixes approach: 2-3 hours of thrashing
- First-time fix rate: 95% vs 40%
- New bugs introduced: Near zero vs common

## Limitations
- Use this skill only when the task clearly matches the scope described above.
- Do not treat the output as a substitute for environment-specific validation, testing, or expert review.
- Stop and ask for clarification if required inputs, permissions, safety boundaries, or success criteria are missing.
