---
name: correct-course
description: Amend an implementation plan mid-feature when assumptions prove wrong, requirements change, or the reviewer flags a fundamental issue. Compares the plan to current state, proposes targeted amendments, and updates the plan file.
argument-hint: 'Path to plan file, optionally followed by a reason (e.g., docs/plans/ABC-123-feature.md "API doesn''t support batch mutations")'
---

# Correct Course

Amend the implementation plan for "$ARGUMENTS" based on a deviation discovered during implementation.

You coordinate four phases — assess current state, understand the deviation, propose amendments, and update the plan. Complete all phases in order.

## Phase 1: Assess current state

Run these commands in parallel:

- `git branch --show-current` — extract the ticket identifier
- `git diff <main-branch>...HEAD --stat` — see what files have been implemented (use the main branch from CLAUDE.md)
- `git diff <main-branch>...HEAD --name-only` — list of changed files
- `git log <main-branch>..HEAD --oneline` — commit history on this branch

After extracting the ticket identifier, check for `docs/requirements/<TICKET>/session-state.md`. If it exists and its `Workflow` field is `correct-course` and it contains a `## Amendment Proposal` section, present the saved proposal to the user: "Found a saved amendment proposal from a previous session. Would you like to review and approve it, or start fresh?" If the user wants to use the saved proposal, skip to Phase 4. Otherwise, continue normally.

Then:

1. **Locate the plan file.** If $ARGUMENTS starts with a file path (e.g. `docs/plans/ABC-123-feature.md`), read it. If it's a ticket number, look for a matching file in `docs/plans/`. If no plan exists, stop and tell the user there's nothing to correct.

2. **Parse the plan's checklist.** Identify:
   - Checked items (done) — these represent completed work
   - Unchecked items (remaining) — these are what might need to change
   - The file plan and layer ordering

3. **Cross-reference with the diff.** Compare the files listed in the plan against the files actually changed on the branch. Note:
   - Files in the plan that exist in the diff (implemented)
   - Files in the plan that don't exist in the diff (not started)
   - Files in the diff that aren't in the plan (unplanned additions — may indicate the deviation already started)

4. **Scan git log for course-correction signals.** Look for:
   - Revert commits
   - Fixup or amendment commits
   - Commit messages with "fix approach", "actually use", "switch to", "revert" — these hint at problems already encountered

Present a brief status summary:

> **Plan status for PROJ-123:**
>
> - Checklist: X/Y items completed
> - Files implemented: N of M planned
> - Unplanned files: [list if any]
> - Correction signals in git log: [list if any]

## Phase 2: Understand the deviation

1. **Extract the reason from $ARGUMENTS.** If the user provided a reason after the plan path (e.g. `docs/plans/ABC-123.md "the API doesn't support batch mutations"`), use it.

2. **If no reason was provided**, use **AskUserQuestion** to ask:

   > What needs to change and why? Examples:
   >
   > - "The GraphQL API doesn't support batch mutations — need individual calls"
   > - "Requirements changed: client now wants email confirmation too"
   > - "The reviewer flagged that the data model won't scale"

3. **Research the constraint if needed.** If the deviation involves a technical question (e.g. "does this API support X?"), spawn a `codebase-qa` agent to verify:

   ```
   Agent tool call:
     description: "Research constraint"
     subagent_type: "codebase-qa"
     prompt: "[question about the constraint]"
   ```

   Only spawn a research agent if the deviation involves a factual question about the codebase. Skip for requirement changes or design decisions.

## Phase 3: Propose amendments

Analyse the impact of the deviation on the remaining plan. For each unchecked item, determine whether it:

- **Stays unchanged** — the deviation doesn't affect it
- **Needs modification** — the approach changes but the goal is the same
- **Should be removed** — no longer needed
- **Is new** — the deviation introduces work that wasn't in the original plan

Present the proposed amendments in this format:

> **Course correction for PROJ-123:**
>
> **Reason:** [the deviation, in one sentence]
>
> **Completed work (unaffected):**
>
> - [list checked items that don't need rework]
>
> **Completed work (needs rework):**
>
> - [list checked items that must be revisited, with what changes]
>
> **Remaining work — unchanged:**
>
> - [list unchecked items that stay as-is]
>
> **Remaining work — modified:**
>
> - ~~Original step~~ → **New step** (reason for change)
> - [repeat for each modified item]
>
> **Removed:**
>
> - [items no longer needed, with reason]
>
> **Added:**
>
> - **New step:** [description] (why this is now needed)
>
> **Risk assessment:** [one sentence on what could go wrong with the new approach]
>
> **Estimated impact:** +N new files, ~M files modified, -R files removed compared to original plan

### Milestone: Save state before approval

Before asking the user to approve, save the amendment proposal to disk so it survives context compaction while waiting for user input. Create the directory if needed (`mkdir -p docs/requirements/<TICKET>/`), then write to `docs/requirements/<TICKET>/session-state.md`:

```markdown
# Session State — <TICKET>

| Field | Value |
|-------|-------|
| Workflow | correct-course |
| Last completed phase | 3 |
| Ticket | <TICKET> |
| Branch | <branch name from Phase 1> |
| Plan file | <plan file path> |
| Saved at | <ISO timestamp> |

## Plan Status

- Checklist: <X/Y items completed>
- Files implemented: <N of M planned>
- Unplanned files: <list or "none">

## Deviation

<the reason, in one sentence>

## Amendment Proposal

<paste the full formatted proposal as presented above>

## Approval Status

Pending — waiting for user approval
```

Use **AskUserQuestion** to ask the user to approve, modify, or reject the proposed amendments.

If the user modifies the proposal, incorporate their feedback. If they reject it entirely, stop — do not update the plan.

## Phase 4: Update the plan

After the user approves the amendments:

1. **Update the checklist.** Using the `Edit` tool:
   - Uncheck any completed items that need rework
   - Modify descriptions of changed items
   - Remove items that are no longer needed
   - Add new items in the appropriate position (following the commit grouping order from the project's commit conventions)
   - Preserve all checked items that don't need rework

2. **Update the file plan** (if the plan has one). Add, remove, or modify file entries to match the new approach.

3. **Append a Course Corrections log entry** at the end of the plan file (create the section if it doesn't exist):

   ```markdown
   ## Course Corrections

   ### CC-1 — YYYY-MM-DD

   **Reason:** [the deviation]
   **Impact:** [one-sentence summary of what changed in the plan]
   **Items affected:** [list of checklist items added, removed, or modified]
   ```

   If the section already exists (from a previous correction), increment the number (CC-2, CC-3, etc.).

4. **Flag lessons learned candidates.** If the deviation reveals something non-obvious that would help future implementations (e.g. "this API doesn't support X despite the docs suggesting it does"), note it at the end of the Course Corrections entry:

   ```markdown
   **Lesson candidate:** [description — the documenter agent will propose codifying this into .claude/rules/ at the end of the feature]
   ```

## Output

Report back with:

1. The updated plan file path
2. Summary: how many items were modified, added, removed, and unchanged
3. Whether any completed work needs rework
4. Any lesson candidates flagged for the documenter
5. Reminder: "Resume implementation from the updated plan. The checklist reflects the current state."
