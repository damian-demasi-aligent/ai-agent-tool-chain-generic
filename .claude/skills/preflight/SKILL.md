---
name: preflight
description: Run code quality checks for this project and report results. Pass "react" for frontend only, "php" for backend only, or no argument for both. This is a pre-commit/pre-push validation.
argument-hint: Optional scope — "react" (frontend only), "php" (backend only), or omit for both
disable-model-invocation: true
---

Run code quality checks for "$ARGUMENTS" and report results. This is a pre-commit/pre-push validation.

**Read CLAUDE.md Commands section** for the project's quality commands.

## Determine scope

- If $ARGUMENTS is `react` or `frontend` → run **React checks only** (see below)
- If $ARGUMENTS is `php` or `backend` → run **PHP checks only** (see below)
- If $ARGUMENTS is empty or `all` → run **both** in sequence (React first, then PHP)

## React checks

Run these in order using the frontend commands from CLAUDE.md:

1. Lint check
2. Type check
3. Production build

## PHP checks

Run these in order using the PHP quality commands from CLAUDE.md:

1. Code style check (e.g. PHPCS)
2. Static analysis (e.g. PHPStan)

If either PHP command fails to execute (e.g. the CLI wrapper is not available), inform the user and suggest running the underlying composer scripts directly.

## Report

Summarise the results concisely. If there are failures, suggest fixes but do NOT auto-fix without asking.
