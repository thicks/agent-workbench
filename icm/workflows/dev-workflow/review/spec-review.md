# Spec Review

Review an existing spec for gaps before handing it to engineering. Acts as the
quality gate between [incept](../skills/incept.md) and [tech-incept](../skills/tech-incept.md).

## Inputs Accepted

- **Repo path** — "review the spec at `~/dev/.../feature.md`"
- **Pasted content** — paste the spec directly into chat
- **File upload** — drag the spec file in

## Behavior

1. **Read the spec** — fetch from path, read upload, or accept pasted content.
2. **Score on 5 dimensions** (see below).
3. **Produce a gap report** — short, specific, actionable. For each gap, include the exact suggested fix.
4. **Offer to rewrite weak sections.** Ask: "Want me to fix sections X and Y now?" before doing so.
5. If all 5 dimensions score well, say: "This spec looks solid — ready to hand to engineering."

## Scoring Dimensions

Score each 1–3 (1 = weak, 2 = adequate, 3 = strong):

| Dimension | What to check |
|---|---|
| **Clarity** | Is the Problem Statement specific and user-facing? Would a new engineer understand without extra context? |
| **Completeness** | Are Goals, Non-Goals, Constraints, and Success Criteria all present and non-vague? |
| **Constraint coverage** | Does the spec name the stack, what must not break, and any perf/SLA requirements? |
| **Task granularity** | Are Phase tasks atomic? No task should span more than one file or concept. |
| **Testability** | Are Success Criteria specific and verifiable? ("Users can log in" vs "Auth works") |

## Output Format

```
## Spec Review: [Feature Name]

### Scores
- Clarity: X/3
- Completeness: X/3
- Constraint coverage: X/3
- Task granularity: X/3
- Testability: X/3
**Overall: X/15**

### Gaps
1. [Section] — [what's missing or vague] → [specific suggested fix]

### Verdict
[Ready to proceed / Needs fixes before coding]
```

## Do Not

- Rewrite sections without asking first
- Give a passing verdict if any dimension scores 1
- Add tasks or change scope — only review what's there
