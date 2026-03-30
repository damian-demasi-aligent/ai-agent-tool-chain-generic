---
name: commit
description: Divide all uncommitted branch changes into logical, layered commits following the project's commit conventions. Spawns the committer agent to analyse and propose a plan, presents it for user approval, then executes.
disable-model-invocation: true
---

# Commit Changes

Orchestrate the commit workflow in two phases — **propose**, then **execute** — with a user approval gate in between.

## Phase 1: Analyse and propose

Spawn the `committer` agent to analyse all uncommitted changes and produce a proposed commit plan.

```
Agent tool call:
  description: "Analyse changes and propose commits"
  subagent_type: "committer"
  prompt: "Analyse the uncommitted changes on the current branch and propose a commit plan. Return ONLY the proposed plan — do not create any commits. $ARGUMENTS"
```

The agent will:

1. Read `CLAUDE.md` for the main branch name, build artifact paths, and architecture
2. Read `.claude/rules/commit-conventions.md` for message format and grouping order
3. Discover all uncommitted changes and extract the ticket identifier from the branch name
4. Read changed files to understand their purpose and layer membership
5. Run the project's type-check command — if errors exist, it stops and reports them instead of proposing a plan
6. Group changes into logical commits following the project's grouping conventions
7. Return a structured commit plan listing every proposed commit with its message and files

**Present the agent's proposed plan to the user exactly as returned.** The plan includes numbered commits, each with a commit message and the files it contains. Do not summarise, reformat, or filter the output — the user needs to see the full plan to make an informed approval decision.

After presenting the plan, prompt the user:

```
Review the proposed commits above. You can:
  • Reply "go" to proceed with all commits
  • Reply "merge 2 3" to combine commits 2 and 3
  • Reply "split 4" to discuss splitting a commit further
  • Edit the plan directly in your reply
```

**Wait for the user's reply before proceeding to Phase 2. Do not execute any commits without explicit user approval.**

## Phase 2: Execute the approved plan

After the user approves (with "go", "yes", or a modified plan), spawn the `committer` agent again to execute:

```
Agent tool call:
  description: "Execute approved commit plan"
  subagent_type: "committer"
  prompt: "Execute the following approved commit plan. Create each commit in order.

User response: <paste the user's reply>

Original proposed plan:
<paste the plan from Phase 1>"
```

The agent will:

1. Create each commit by staging only the listed files, verifying the staged set, and committing with the approved message
2. Stop immediately if a pre-commit hook fails — it will not bypass with `--no-verify`
3. After all commits succeed, check whether `CLAUDE.md` or `.claude/rules/` need updating and propose specific additions
4. Remind the user to run `/document <TICKET>` if a feature documentation workflow exists and no document has been created yet

**Present the agent's execution results to the user.** Include the list of commits created (with short hashes) and any proposed CLAUDE.md/rules updates.

## If the type-check gate fails

If Phase 1 returns type-check errors instead of a commit plan, present the errors to the user and stop. Do not proceed to Phase 2. The user must fix the errors and re-run `/commit`.
