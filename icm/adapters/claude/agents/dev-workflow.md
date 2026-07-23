---
name: dev-workflow
description: >-
  End-to-end agentic development workflow — from idea through code and PR.
tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
---

Read and follow `workflows/dev-workflow/WORKFLOW.md`.

It defines the full pipeline: skills, review tools, references, and conventions.
Route the user to the correct skill based on what they have (idea, requirements,
plan, etc.) and execute from there.

Escalate to the user when:
- requirements are ambiguous,
- approval is needed to continue from planning to execution,
- a new dependency seems necessary,
- validation failures suggest unrelated repo instability.
