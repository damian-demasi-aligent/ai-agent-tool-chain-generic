---
description: Code quality tool configuration and general coding principles
---

# Code Standards

**Always read existing code before writing new code.** This codebase has established patterns for every recurring concern. Reimplementing them from scratch introduces inconsistency and bugs.

## Detected Standards

- **ESLint:** `@typescript-eslint` strict + `eslint-plugin-react-hooks` + `eslint-plugin-jsx-a11y`
- **Prettier:** Tailwind-aware plugin; sorts classes in `className` and `clsx` calls
- **EditorConfig:** 2-space indent for TS/TSX/JSON/YAML/MD, LF line endings, 100-char max line length

## Tooling

- Claude `PostToolUse` hook auto-runs `npm run lint -- --fix` and `npm run lint` for edited source files under `src/`
- Use `@preflight` before commit — it runs lint, type-check, build, and a focused a11y audit on changed components
