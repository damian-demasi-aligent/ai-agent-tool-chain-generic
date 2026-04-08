---
name: restore
description: Restore session context from a checkpoint file after running /compact. Reads session-state.md, the plan file, and current git state to rebuild working context.
disable-model-invocation: true
---

# Restore

Reload session context from a checkpoint saved by `/checkpoint` or an orchestrator milestone save.

## Step 1: Find the session state file

Run `git branch --show-current` to extract the ticket identifier from the branch name.

Look for the session state file at:
- `docs/requirements/<TICKET>/session-state.md`

If `$ARGUMENTS` is provided (e.g. `/restore ABC-123` or `/restore my-feature`), use that as the ticket/slug instead of inferring from the branch.

If the file does not exist, report: "No checkpoint found. Run `/checkpoint` to save session state before compacting." and stop.

## Step 2: Read the checkpoint

Read `docs/requirements/<TICKET or camel-case-feature-name>/session-state.md` in full. Extract:

- Ticket and branch
- Inferred phase at time of checkpoint
- Plan file path
- Interview supplement path
- Verification results (if captured)
- Review findings (if captured)
- Key context (decisions, preferences, approach choices)

## Step 3: Rebuild context from disk

Run these in parallel to get the current state (which may have changed since the checkpoint):

- `git status --short` — current working tree
- `git diff --stat` — scope of uncommitted changes
- `git log --oneline -5` — recent commits

Then read the referenced files:

1. **Plan file** — if the checkpoint references a plan file path, read it. Note checklist progress (count `- [x]` vs `- [ ]`), open questions, and the current implementation order.
2. **Interview supplement** — if the checkpoint references one, read it for requirements context.

## Step 4: Present restored context

Report to the user:

```
Context restored from docs/requirements/<TICKET>/session-state.md

## Session Identity
- Ticket: <TICKET>
- Branch: <branch>
- Checkpoint saved: <timestamp from file>

## Where You Left Off
- Phase: <inferred phase>
- Plan: <path> — <X of Y checklist items done>
- Open questions: <count or "none">

## Current Code State
- Uncommitted changes: <count of files, or "clean">
- Staged: <count or "nothing">
- Recent commits: <last 3 one-liners>

## Verification Results
<from checkpoint, or "Not captured">

## Review Findings
<from checkpoint, or "Not captured">

## Key Context
<decisions, preferences, approach choices from checkpoint>

## Suggested Next Step
<Based on the inferred phase, suggest what to do next:
  - Pre-planning → "Run /plan-feature to start planning"
  - Planning complete → "Run /implement-feature <plan path> to begin implementation"
  - Implementation in progress → "Continue implementation or run /preflight to check current state"
  - Implementation complete → "Run /commit to create commits, or /preflight first"
  - Documentation complete → "Ready for PR">
```
