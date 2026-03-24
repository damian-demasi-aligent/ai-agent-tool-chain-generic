---
name: review-pr
description: Review a pull request or the current branch's changes against the main branch with project-specific knowledge from CLAUDE.md.
disable-model-invocation: true
---

# Code Review

Review the changes in $ARGUMENTS (a PR number, branch name, or leave blank for current branch vs main).

Before starting, **read CLAUDE.md** to identify the project's main branch name, coding conventions, architecture, and any cross-layer sync rules.

## Step 1: Gather context

Get the diff (use the main branch name from CLAUDE.md):

- If a PR number: `gh pr diff $ARGUMENTS`
- If a branch: `git diff <main-branch>...$ARGUMENTS`
- If blank: `git diff <main-branch>...HEAD`

Review the changes in file order to build a complete picture before reporting.

## Step 2: Evaluate

Assess each changed file against the relevant concerns below, supplemented by project-specific conventions from CLAUDE.md.

### Functionality and correctness

- Does the code behave as intended in realistic user scenarios?
- Are edge cases handled or at least clearly constrained?
- Are loading, error, and empty states treated appropriately?
- Are assumptions about data, props, or environment safe and explicit?

### React (if TypeScript/TSX files changed)

- [ ] Hooks usage is idiomatic — no unnecessary effects, stale closures, or redundant state
- [ ] Components are small, focused, and composable — logic is at the right level (component vs hook vs util)
- [ ] New/changed GraphQL operations have matching TypeScript types (check CLAUDE.md for the types file location and sync rules)
- [ ] New components follow the project's export and file structure conventions (check CLAUDE.md)
- [ ] GraphQL provider methods are wired into the project's provider entry point (check CLAUDE.md Architecture)
- [ ] DOM bridge hooks clean up MutationObservers in useEffect teardown
- [ ] No `setTimeout`/`setInterval` without clear justification
- [ ] `aria-live` used for dynamic content that screen readers should announce
- [ ] CSS framework classes used consistently (no raw CSS unless necessary)
- [ ] `handle*` naming for event handlers
- [ ] Check CLAUDE.md Conventions for additional project-specific React rules

### Magento PHP (if .php/.phtml files changed)

- [ ] Plugins use `before`/`after` over `around` where possible
- [ ] New modules have `registration.php`, `etc/module.xml`, and `composer.json`
- [ ] GraphQL resolvers implement `ResolverInterface` correctly
- [ ] Layout XML uses `referenceBlock`/`referenceContainer` (not full file copies)
- [ ] Check CLAUDE.md for project-specific PHP conventions (plugin naming, email patterns, etc.)

### Cross-cutting

- [ ] If a GraphQL schema changed, both PHP resolver AND frontend types are updated
- [ ] Build output is consistent with source changes (not stale) — check CLAUDE.md for build artifact paths
- [ ] No hardcoded URLs, API keys, or environment-specific values
- [ ] Naming reflects intent and domain language — no hidden coupling or leaky abstractions

## Step 3: Report

Structure your output as follows:

### Per-file issues

For each issue found:

- **File:line** — what's wrong and why it matters
- Severity: **blocker** / **should fix** / **nit**

### Summary

- **High-level assessment:** What the feature does, whether it's correct and well-implemented
- **What's working well:** Good decisions or clean patterns worth calling out
- **Issues or risks:** Problems, bugs, or design risks (be specific)
- **Recommended improvements:** Actionable suggestions, ordered by impact
- **Verdict:** Whether the changes are safe to merge

Do not comment on formatting, linting, or stylistic preferences unless they affect correctness or maintainability.
