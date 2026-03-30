---
description: Code quality tool configuration and general coding principles
---

# Code Standards

**Always read existing code before writing new code.** This codebase has established patterns for every recurring concern. Reimplementing them from scratch introduces inconsistency and bugs.

## Detected Standards

- **ESLint:** `@next/eslint-plugin-next` + `@typescript-eslint`; strict mode enabled
- **Prettier:** Tailwind-aware plugin; sorts classes in `className` and `clsx` calls
- **EditorConfig:** 2-space indent for TS/TSX/JSON/YAML/MD, LF line endings, 100-char max line length

## Tooling

- Claude `PostToolUse` hook auto-runs `yarn eslint --fix` and `yarn eslint` for edited source files under `apps/` and `libs/`
- Use `/preflight` before commit — it runs lint, type-check, build, and a focused a11y audit on changed components
- When creating agent/skill files, keep them project-agnostic. Project-specific context belongs in CLAUDE.md, not in reusable agent definitions
