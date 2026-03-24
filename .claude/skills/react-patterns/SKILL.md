---
name: react-patterns
description: React component conventions. Use when creating or modifying React components, hooks, context providers, or widgets.
user-invocable: false
metadata:
  capabilities: [react]
---

# React Component Patterns

Follow these conventions when writing React code. Before starting, **read CLAUDE.md** for the project's React source path, GraphQL provider structure, path aliases, key dependencies, and coding conventions.

## Component Structure

- **Check CLAUDE.md** for the React source directory and path alias configuration
- Components are functional (no class components), one `.tsx` file per component
- Props/state interfaces are defined inline in the component file, not in separate type files — check CLAUDE.md to confirm this is the project convention
- Use barrel `index.ts` exports for component directories

## State & Data

- **Check CLAUDE.md Architecture section** for how GraphQL operations are structured (query/mutation files, provider classes, singleton façade, shared types file)
- Check whether the project uses GraphQL codegen or manual type definitions
- New providers must be wired into the project's main provider entry point (documented in CLAUDE.md)
- Check CLAUDE.md Conventions for the project's API return type (e.g. a discriminated union for success/error)

## DOM Integration

- **Check CLAUDE.md Architecture** for the project's component mounting convention (widget data attributes, React portals, route-based rendering, etc.)
- If the project bridges React with a server-rendered host page, use `MutationObserver` in custom hooks to synchronise external DOM state with React state
- Always clean up observers and event listeners in `useEffect` return
- Handle the case where the observed DOM element doesn't exist yet

## Styling & UI

- **Check CLAUDE.md Key Dependencies** for the project's CSS framework (Tailwind, CSS Modules, etc.) and UI primitives library
- Use `classNames` or `clsx` for conditional class composition
- Use the project's validation library (e.g. Zod) for runtime form/data validation

## Conventions

- `handle*` prefix for event handler functions
- Early returns over nested conditionals
- No `setTimeout`/`setInterval` without strong justification
- `aria-live` regions for dynamic content updates
- Check CLAUDE.md Conventions for any additional project-specific rules
