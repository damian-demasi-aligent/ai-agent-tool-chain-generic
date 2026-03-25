---
name: implement-feature
description: Orchestrate feature implementation and code review. Spawns the feature-implementer agent in the current working directory, then runs the reviewer agent on the result. Use when you have a plan file ready and want to execute it.
argument-hint: Path to plan file (e.g., docs/plans/ABC-123-my-awesome-feature.md)
disable-model-invocation: true
---

# Implement Feature

Orchestrate the implementation workflow for "$ARGUMENTS".

You coordinate four phases — validation, implementation, code review, and reporting. Complete all phases in order.

## Phase 0: Gather context

Run these commands in parallel to establish context:

- `git branch --show-current` — extract the ticket identifier from the branch name
- `ls docs/plans/` — check available plan files
- `git status` — check for uncommitted changes that might conflict

## Phase 1: Validate the plan

1. **Locate the plan file.** If $ARGUMENTS is a file path (e.g. `docs/plans/ABC-123-my-awesome-feature.md`), read it. If it's a ticket number, look for a matching file in `docs/plans/`. If no plan exists, stop and tell the user to run `/plan-feature` first.

2. **Check for open questions.** Scan the plan for unresolved items — look for:
   - Sections titled "Open Questions", "Questions", or "Assumptions"
   - Inline markers: `TODO`, `TBD`, `?`, "confirm", "verify"
   - Unchecked items in the implementation checklist that have question marks

3. **If open questions exist**, list them and ask the user to resolve them before proceeding. Do not continue to Phase 2 until confirmed.

4. **Check for conflicting local changes.** Compare the files listed in the plan's "Impact Analysis" and "File Plan" sections against the uncommitted changes from `git status`. If any files the plan will modify have uncommitted local changes, warn the user and recommend committing or stashing them first. Do not continue until confirmed.

5. **If the plan is clean**, summarise the scope in 2-3 sentences and confirm with the user before spawning the implementer. Example:

   ```
   Plan: docs/plans/ABC-123-my-awesome-feature.md
   Scope: New Trial module with GraphQL mutation, dual emails, React multi-step form widget, and admin config.
   Checklist: 12 items

   Ready to start implementation. Proceed?
   ```

   Wait for user confirmation before continuing.

## Phase 2: Implement

After the user confirms, use the **Agent tool** to spawn the `feature-implementer` agent. Do NOT use worktree isolation — implement directly in the working directory.

```
Agent tool call:
  description: "Implement [feature name]"
  subagent_type: "feature-implementer"
  prompt: "Implement the feature described in the following plan file: [plan file path]

Read the plan file first, then follow its implementation checklist in order. The plan contains all the context you need — file paths, pattern sources, and implementation details.

IMPORTANT — Read framework integration points before writing code:
Before writing any code that hooks into the framework (plugins, observers, middleware, event handlers, etc.), read the relevant framework source code to understand the exact flow. This prevents integration bugs that cannot be caught from project code alone. For example:
- If hooking into a handler/controller: read the target method to understand parameters and side effects
- If writing an event handler/observer: read where the event is dispatched and what state exists at that point
- If calling a framework save/update method: read it to understand cascading operations
Your agent instructions have the full list of what to read — follow step 5 carefully.

After implementation, run verification checks and produce the change summary as described in your instructions."
```

The feature-implementer agent will:

- Read the plan and CLAUDE.md
- Read vendor source code for integration points (controllers, repositories, event dispatchers)
- **Verify integration points are real** — scan files the feature depends on (imports, calls into) for stubs. If stubs are found, the agent stops and returns a "Blocked — Stub Dependencies" report instead of implementing
- **Verify required environment variables** — scan for `process.env.*` references in dependency files, check `.env*` files for their values. If backend URLs or API keys are missing/empty, the agent stops and returns a "Blocked — Missing Backend Configuration" report
- Implement each checklist item in order
- Install dependencies and run codegen inline as new packages/schemas are added
- Run type-check, lint, and build verification
- Run a dev server smoke test (start the dev server, curl the app AND a data-fetching route, check for runtime and backend connectivity errors) — this catches provider ordering bugs, server/client boundary mistakes, missing imports, hydration errors, and missing backend configuration that static checks miss
- Produce a structured change summary

Wait for the agent to complete. This may take a while for large features.

**If the implementer returns a stub or configuration blocker** instead of a completed implementation, present the blocker report to the user and stop. Do not proceed to Phase 3. The user must resolve the issue (implement dependencies, configure environment variables, or confirm the current state is intentional) before re-running `/implement-feature`.

## Phase 3: Code review

After the feature-implementer agent returns, spawn the **reviewer** agent on the working directory:

```
Agent tool call:
  description: "Review [feature name] implementation"
  subagent_type: "reviewer"
  prompt: "Review the uncommitted changes implementing [feature name].

Run these commands to see the changes:

  git diff
  git diff --cached
  git status

The plan that guided the implementation is at [plan file path].

Follow your standard review process: run git diff to see the full diff, then review for correctness, patterns compliance, cross-boundary consistency, and accessibility."
```

Wait for the reviewer to complete, then proceed to Phase 4.

## Phase 4: Report results

After both agents have completed, present the combined output to the user. The output should contain:

1. **Change summary** — files created/modified, grouped by layer (from the implementer)
2. **Verification results** — type-check, lint, build, and smoke test pass/fail (from the implementer)
3. **Checklist progress** — how many items were completed vs blocked (from the implementer)
4. **Code review** — the reviewer agent's findings, presented as-is without filtering or softening
5. **Key files to understand** — the 3-5 most important files for understanding the feature (from the implementer)

Present all of this to the user, then provide next steps:

```
## Next Steps

1. **Review the changes** — `git diff` to see all changes

2. **Fix review issues** (if any) — Address findings from the code review before committing

3. **Commit the changes** — When satisfied, use `@committer` to create structured commits following the project's grouping conventions

4. **Generate documentation** — For multi-layer features, use `@documenter [ticket]` to create a feature architecture document in docs/features/
```

If the implementer reported blocked items or failures, highlight those prominently so the user knows what needs manual attention.
