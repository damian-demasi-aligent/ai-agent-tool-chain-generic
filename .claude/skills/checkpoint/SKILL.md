---
name: checkpoint
description: Save critical session state to disk before running /compact. Captures branch, ticket, workflow phase, plan status, modified files, and verification results so context can be restored after compaction.
disable-model-invocation: true
---

# Checkpoint

Save all critical session state so `/compact` can run without losing important context.

## Step 1: Gather identity

Run these commands in parallel:

- `git branch --show-current` — extract the ticket identifier and branch name
- `git status --short` — list modified, staged, and untracked files
- `git diff --name-only` — unstaged changes
- `git diff --cached --name-only` — staged changes
- `git log --oneline -5` — recent commits for context

Extract the ticket identifier from the branch name using the project's commit conventions (`.claude/rules/commit-conventions.md`). If no ticket can be extracted, use a kebab-case slug derived from the branch name.

## Step 2: Gather workflow state

Determine the current workflow state by checking what exists on disk and in conversation context:

### Plan status

- Check `docs/plans/` for a plan file matching the ticket. If found, read it and note:
  - Plan file path
  - Checklist progress: count `- [x]` (done) vs `- [ ]` (remaining)
  - Open questions: scan for sections titled "Open Questions", inline `TODO`, `TBD`, `?` markers
- If no plan file exists, note "No plan file found"

### Interview status

- Check `docs/requirements/<TICKET or camel-case-feature-name>/interview-supplement.md`. If it exists, note "Interview supplement exists at [path]"
- If not, note "No interview supplement"

### Existing session state

- Check `docs/requirements/<TICKET or camel-case-feature-name>/session-state.md`. If it exists, read it and note the previous workflow and phase — this may have been written by an orchestrator milestone save

### Infer current workflow phase

Based on the evidence collected, determine the most likely current phase:

| Evidence                                                 | Inferred phase                                |
| -------------------------------------------------------- | --------------------------------------------- |
| No plan file exists                                      | Pre-planning (or direct implementation)       |
| Plan file exists, no code changes on branch              | Planning complete, implementation not started |
| Plan file exists, uncommitted code changes               | Implementation in progress                    |
| Plan file exists, committed code changes, no uncommitted | Implementation complete, review/commit phase  |
| Feature doc exists in `docs/features/`                   | Documentation complete                        |

## Step 3: Gather implementation context

If there are uncommitted or recently committed code changes, capture verification state from the conversation context:

- **Verification results**: If type-check, lint, build, or smoke test results are available from the current conversation, record them (pass/fail with details)
- **Review findings**: If a code review was run in this session, record its key findings
- **Blockers**: Any unresolved issues, failed checks, or items needing user attention

If none of this is available in the conversation (e.g., the user is checkpointing before starting work), note "No verification results in current session."

## Step 4: Write session state file

Create the directory if needed (`mkdir -p docs/requirements/<TICKET>/` or `mkdir -p docs/requirements/<camel-case-feature-name>/`), then write to `docs/requirements/<TICKET or camel-case-feature-name>/session-state.md`:

```markdown
# Session State — <TICKET>

> Saved by `/checkpoint` on <YYYY-MM-DD HH:MM>. After running `/compact`, read this file to restore context.

| Field                | Value               |
| -------------------- | ------------------- |
| Ticket               | <TICKET>            |
| Branch               | <branch name>       |
| Inferred phase       | <phase from Step 2> |
| Plan file            | <path or "none">    |
| Interview supplement | <path or "none">    |
| Saved at             | <ISO timestamp>     |

## Plan Status

<If a plan file exists:>
- Path: `<plan file path>`
- Checklist: <X of Y items completed>
- Open questions: <count, or "none">
- <List any specific open questions or blockers>

<If no plan file:>
No plan file found for this ticket.

## Modified Files

### Uncommitted changes

<list from git status, or "Working tree clean">

### Staged for commit

<list from git diff --cached, or "Nothing staged">

### Recent commits on this branch

<last 5 commits from git log>

## Verification Results

<If available from conversation context:>
- Type-check: <PASSED / FAILED (details)>
- Lint: <PASSED / FAILED (details)>
- Build: <PASSED / FAILED (details)>
- Smoke test: <PASSED / FAILED / SKIPPED (details)>

<If not available:>
No verification results in current session.

## Review Findings

<If a review was run, paste key findings>
<If not:>
No review findings in current session.

## Key Context

<Any other important context from the conversation that would be lost on compaction:

- Decisions made during this session
- User preferences or corrections expressed
- Approach chosen for ambiguous requirements
- Anything the user explicitly asked to be preserved>

---

## Recovery Instructions

After running `/compact`, restore context by:

1. Read this file: `docs/requirements/<TICKET or camel-case-feature-name>/session-state.md`
2. Read the plan file (if it exists): `<plan file path>`
3. Run `git status` and `git diff --stat` to see current code state
4. Continue from the **inferred phase** noted above
```

## Step 5: Report to user

After writing the file, report:

```
Checkpoint saved to docs/requirements/<TICKET or camel-case-feature-name>/session-state.md

Captured:
- Branch: <branch name>
- Phase: <inferred phase>
- Plan: <path or "none"> (<X/Y checklist items done>)
- Modified files: <count>
- Verification: <available / not available>

You can now run /compact safely. After compacting, start with:
  "Read docs/requirements/<TICKET or camel-case-feature-name>/session-state.md and restore context."
```
