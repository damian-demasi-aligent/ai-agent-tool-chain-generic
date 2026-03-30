---
description: Code quality tool configuration and general coding principles
---

# Code Standards

**Always read existing code before writing new code.** This codebase has established patterns for every recurring concern. Reimplementing them from scratch introduces inconsistency and bugs.

## Detected Standards

- **ESLint:** `@aligent/ts-code-standards` with React config; `@typescript-eslint/consistent-type-assertions: never`
- **Prettier:** Tailwind-aware; sorts classes in `classNames` and `clsx` calls
- **EditorConfig:** 4-space indent for TS/PHP/PHTML, 2-space for YAML/JSON/MD, LF line endings, 100-char max line length
- **PHP:** PHPCS Magento2 standard; PHPStan level 0

## Tooling

- Claude `PostToolUse` hook auto-runs `yarn eslint --fix` and `yarn eslint` for edited React source files under `app/code/CountryCareGroup/React/view/frontend/src/app/`
- Use `/preflight` before commit for React changes — it runs lint, type-check, build, and a focused a11y audit on changed components
- When creating agent/skill files, keep them project-agnostic. Project-specific context belongs in CLAUDE.md, not in reusable agent definitions
