---
name: commit-pr
description: Divide all uncommitted branch changes into logical, layered commits following project conventions from CLAUDE.md. Presents a plan for user approval before making any commits.
disable-model-invocation: true
---

# Commit PR Changes

Divide all uncommitted changes on the current branch into logical commits and create them one by one — **only after user approval**.

Before starting, **read `CLAUDE.md`** in the project root to learn the project's commit conventions, commit grouping order, message format, main branch name, and any build artifacts that must not be committed.

## Step 1: Discover changes

Run these in parallel:

- `git status` — all untracked and modified files
- `git diff HEAD --stat` — what has changed and how much
- `git log <main-branch>...HEAD --oneline` — commits already on this branch (use the main branch name from CLAUDE.md; avoid duplicating existing commits)
- `git branch --show-current` — extract a ticket/issue identifier if the branch name contains one

Extract the ticket identifier from the branch name using the pattern described in CLAUDE.md's commit conventions (e.g. `feature/PROJ-123-description` → `PROJ-123`). If the branch name contains no recognisable identifier, note this and use a placeholder.

## Step 2: Group changes into logical commits

Analyse the changed files and group them into **cohesive, independent commits**. Each commit should represent one logical unit of work that a reviewer can understand without reading all the others.

**Use the commit grouping order from CLAUDE.md** to determine the sequencing. Commits should be ordered so each builds on the previous.

**Rules:**

- **Never commit build artifacts** — check CLAUDE.md for paths that are generated and must not be committed. If `git status` shows them as untracked or modified, exclude them from your plan.
- Follow any layer-separation rules from CLAUDE.md (e.g. do not mix backend and frontend source in the same commit if CLAUDE.md says so)
- Keep together files that only make sense as a unit (e.g. a schema definition + its resolver)
- If a group is very small (1–2 files), consider merging it with an adjacent group
- Unrelated bug fixes or minor changes unconnected to the main feature must be their own commits

## Step 3: Present the plan

Display the **full commit plan before making any changes**. Show each commit's proposed message and every file it will include:

```
Proposed commits for <TICKET>:

  1. <TICKET>: Add module skeleton
       path/to/file1
       path/to/file2

  2. <TICKET>: Add backend logic and schema
       path/to/file3
       path/to/file4

  ... (continue for all commits)

Do you approve this breakdown? You can:
  • Reply "yes" or "go" to proceed with all commits
  • Reply "merge 2 3" to combine commits 2 and 3
  • Reply "split 4" to discuss splitting a commit further
  • Edit the plan directly in your reply and I will use your version
```

**Wait for the user's reply before doing anything else.**

## Step 4: Create the commits

Once the user approves (exactly as proposed or with requested changes), create each commit in order:

1. Stage **only** the files listed for that commit:

   ```bash
   git add path/to/file1 path/to/file2 ...
   ```

   Never use `git add .` or `git add -A` — always add files by explicit path.

2. Verify the staged set matches the plan:

   ```bash
   git diff --cached --stat
   ```

3. Commit using the approved message and the commit message format from CLAUDE.md:

   ```bash
   git commit -m "$(cat <<'EOF'
   <TICKET>: Verb phrase describing the change

   Co-Authored-By: Claude Code
   EOF
   )"
   ```

4. Confirm success:

   ```bash
   git log --oneline -1
   ```

5. Proceed to the next commit without pausing (unless a step fails).

## Step 5: Update CLAUDE.md

After all commits have been created successfully, review what was added and update `CLAUDE.md` if any of the committed changes affect how Claude Code should understand or work with this project.

### What warrants a CLAUDE.md update

Read the current `CLAUDE.md`, then check the committed files against these categories:

- **New top-level module/package** — add it to any module/package inventory table
- **New entry point** (widget, CLI command, API endpoint) — add it to the relevant architecture section
- **New key dependency** (not dev tooling) — add to any dependencies section
- **New convention or pattern** introduced (e.g. a new data-passing mechanism between layers) — add a note under conventions or architecture
- **Pure implementation files** (components, resolvers, templates) — no CLAUDE.md change needed

### How to update

1. Read `CLAUDE.md` to understand the current structure
2. Draft only the specific lines or rows that need adding or changing — do not rewrite existing content
3. Show the proposed diff to the user and wait for confirmation
4. Apply the changes only after the user confirms
5. If nothing warrants an update, state that clearly and skip this step

## Step 6: Remind about feature documentation

If CLAUDE.md describes a feature documentation workflow (e.g. a `docs/features/` directory or a documenter tool), check whether a feature document exists for this branch's ticket.

If no document exists and the branch contains a complex, multi-layer feature, remind the user about the documentation workflow described in CLAUDE.md.

If a document already exists, or the changes are simple (single-file fix, config tweak), skip this step silently.

## Commit message format

Follow the commit message format specified in CLAUDE.md. The general principles are:

- **Ticket prefix** — from the branch name, always first
- **Imperative mood** — "Add", "Update", "Fix", "Remove", "Wire" — not "Added" or "Adding"
- **Subject ≤ 72 characters** — if you need more, add a body after a blank line
- **Capital letter** after the prefix separator
- **No trailing period**
- Always append the `Co-Authored-By` trailer

## Safety rules

- **Never** stage files outside the agreed plan without asking
- **Never** use `--no-verify` to skip pre-commit hooks — if a hook fails, report it and stop
- **Never** amend or force-push commits already on the remote
- **Never** commit build artifacts — check CLAUDE.md for generated file paths that must be excluded
- If `git add` would accidentally include unintended files (e.g. `.env`, lock files, generated files unrelated to the feature), flag this and exclude them from the plan
- If the working tree has both staged and unstaged changes at the start, report this and ask the user how to handle it before proceeding
