---
name: less-theme
description: LESS and CSS theming conventions for a Magento 2 theme. Use when modifying .less files in the theme directory or when working on Magento template styling (not Tailwind in React components).
user-invocable: false
metadata:
  capabilities: [magento-theme]
---

# Magento 2 Theme LESS Patterns

Magento templates use LESS for styling. If the project also uses a JS framework (React, Vue, etc.) with its own styling system (Tailwind, CSS Modules, etc.), those are a separate concern. Do not mix LESS theme styles with JS component styles.

Before starting, **read CLAUDE.md** for the project's theme path and parent theme. Also read the project rules (`.claude/rules/`) for colour variables, custom mixins, and file organisation conventions.

## File Organisation

Magento themes organise LESS under the theme's `web/css/source/` directory. Common file patterns:

| File | Purpose |
|------|---------|
| `_extend.less` | Main entry point — imports other files |
| `_variables.less` | Theme variable overrides |
| `_mixins.less` | Shared mixins |
| `_media-query-*.less` | Responsive breakpoint styles |
| `lib/*.less` | Project-specific mixin libraries |

**Check CLAUDE.md and the actual theme directory** for the project's specific file listing — projects vary significantly in how they organise their LESS.

Module-specific overrides use `_extend.less` or `_module.less` in the module's `web/css/source/` directory under the theme (e.g. `Magento_Catalog/web/css/source/_extend.less`).

## Theme Variables

**Always use the project's theme colour variables** — do not hardcode hex values. Check the project rules (`.claude/rules/`) for the variable naming convention and prefix (e.g. `@theme__color__primary`). If unsure, search the theme's LESS files for `@.*color` definitions.

## Breakpoints

Use Magento's standard breakpoint variables with the `.media-width()` mixin:

- `@screen__s` (640px)
- `@screen__m` (768px)
- `@screen__l` (1024px)
- `@screen__xl` (1440px)

The project may define additional custom breakpoints — check the theme's variables file.

## Mixins

Check the project rules (`.claude/rules/`) for project-specific mixins (page titles, modals, buttons, icon injection, etc.). Before writing new styles, search the theme's mixin files to see if a reusable mixin already exists.

## Rules

- New module-level styles go in `<ModuleName>/web/css/source/_extend.less` under the theme directory
- General theme styles go in the matching file in `web/css/source/`
- Responsive styles go in the appropriate `_media-query-*.less` file, NOT inline in component LESS — check the project rules (`.claude/rules/`) for the project's responsive file convention
- Read existing LESS files in the theme before writing new styles to match naming patterns and structure
