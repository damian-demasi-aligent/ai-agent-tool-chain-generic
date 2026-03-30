---
name: preflight
description: Run code quality checks for this project and report results. Pass "react" for frontend only, "php" for backend only, or no argument for the full suite. Includes lint, types, build, accessibility audit, runtime smoke test (Playwright), and PHP quality checks.
argument-hint: Optional scope — "react" (frontend only), "php" (backend only), or omit for full suite
disable-model-invocation: true
---

# Preflight Checks

Run quality checks for "$ARGUMENTS".

Use the **Agent tool** to spawn the `preflight` agent:

```
Agent tool call:
  description: "Run preflight checks"
  subagent_type: "preflight"
  prompt: "Run preflight checks. Scope: $ARGUMENTS"
```

Wait for the agent to complete, then present its results to the user exactly as returned — do not summarise or filter the output.

The agent reads **CLAUDE.md** to determine which commands to run for this project. Depending on scope, it checks:

**Frontend** (`react` / `frontend` / full suite):
1. Lint check
2. Type check
3. Production build
4. Accessibility audit (changed components only)
5. Runtime smoke test via Playwright (when configured in CLAUDE.md)

**Backend** (`php` / `backend` / full suite):
6. Code style check
7. Static analysis

The specific tools and commands for each check come from the Commands section in CLAUDE.md.

Do NOT attempt to fix any issues. Only report them.
