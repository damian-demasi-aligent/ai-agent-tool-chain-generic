---
description: Commit message format, ticket prefix, Co-Authored-By trailer, and commit grouping order
---

# Commit Conventions

- **Main branch:** `main`

## Message format

```
PROJ-XXX: <Verb> <what changed>
```

- **Ticket prefix** — extracted from the branch name (e.g. `feature/PROJ-55-order-filters` -> `PROJ-55`)
- **Imperative mood** — "Add", "Update", "Fix", "Remove", "Wire" — not "Added" or "Adding"
- **Subject <= 72 characters**; add a body after a blank line if needed
- **Capital letter** after the colon, **no trailing period**
- Always append the `Co-Authored-By` trailer

## Commit grouping order

When committing a multi-layer feature, group files into cohesive commits in this order so each builds on the previous:

| Priority | Group                     | Typical files                                                |
| -------- | ------------------------- | ------------------------------------------------------------ |
| 1        | API client + types        | `api/endpoints/`, `api/types/`, `api/client.ts`              |
| 2        | Stores + hooks            | `stores/`, `hooks/`                                          |
| 3        | Components                | `components/`, `pages/`                                      |
| 4        | Routes + configuration    | `routes.tsx`, `main.tsx`, `vite.config.ts`, env files        |

## Rules

- Never commit `dist/` build output
- Keep together files that only make sense as a unit (e.g. an API endpoint file + its types file)
- Merge very small groups (1-2 files) with an adjacent group
- Unrelated fixes unconnected to the main feature get their own commits
