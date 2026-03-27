---
description: Commit message format, ticket prefix, Co-Authored-By trailer, and commit grouping order
---

# Commit Conventions

- **Main branch:** `main`

## Message format

```
PROJ-XXX: <Verb> <what changed>
```

- **Ticket prefix** — extracted from the branch name (e.g. `feature/PROJ-420-product-filters` -> `PROJ-420`)
- **Imperative mood** — "Add", "Update", "Fix", "Remove", "Wire" — not "Added" or "Adding"
- **Subject <= 72 characters**; add a body after a blank line if needed
- **Capital letter** after the colon, **no trailing period**
- Always append the `Co-Authored-By` trailer

## Commit grouping order

When committing a multi-layer feature, group files into cohesive commits in this order so each builds on the previous:

| Priority | Group                    | Typical files                                                          |
| -------- | ------------------------ | ---------------------------------------------------------------------- |
| 1        | API routes + middleware  | `app/api/`, `middleware.ts`                                            |
| 2        | GraphQL operations + types | `libs/graphql/src/operations/`, codegen output, shared types         |
| 3        | Shared libraries         | `libs/ui/`, `libs/utils/`, `libs/config/`                             |
| 4        | Components               | `components/`, `hooks/`                                                |
| 5        | Pages + layouts          | `app/(shop)/`, `app/(account)/`, `app/layout.tsx`                     |
| 6        | Configuration            | `next.config.ts`, `tailwind.config.ts`, `package.json`, env files     |

## Rules

- Never commit `.next/` build output or `libs/graphql/src/generated/` codegen output
- Keep together files that only make sense as a unit (e.g. a GraphQL operation + its generated types)
- Merge very small groups (1-2 files) with an adjacent group
- Unrelated fixes unconnected to the main feature get their own commits
