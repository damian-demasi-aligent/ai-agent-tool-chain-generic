---
description: Commit message format, ticket prefix, Co-Authored-By trailer, and commit grouping order
---

# Commit Conventions

- **Main branch:** `production`

## Message format

```
PROJ-XXX: <Verb> <what changed>
```

- **Ticket prefix** — extracted from the branch name (e.g. `feature/PROJ-123-add-widget` -> `PROJ-123`)
- **Imperative mood** — "Add", "Update", "Fix", "Remove", "Wire" — not "Added" or "Adding"
- **Subject <= 72 characters**; add a body after a blank line if needed
- **Capital letter** after the colon, **no trailing period**
- Always append the `Co-Authored-By` trailer

## Commit grouping order

When committing a multi-layer feature, group files into cohesive commits in this order so each builds on the previous:

| Priority | Group                          | Typical files                                                                       |
| -------- | ------------------------------ | ----------------------------------------------------------------------------------- |
| 1        | PHP module registration        | `registration.php`, `composer.json`, `etc/module.xml`                               |
| 2        | Admin configuration            | `etc/adminhtml/system.xml`, `etc/config.xml`, `Block/Adminhtml/`                    |
| 3        | GraphQL schema + backend logic | `etc/schema.graphqls`, `Api/`, `Model/`, `etc/di.xml`, `etc/email_templates.xml`    |
| 4        | Email templates                | `view/frontend/email/`                                                              |
| 5        | Magento frontend integration   | layout XML, `.phtml`, `.js`, `.less`, `requirejs-config.js` in PHP modules          |
| 6        | React data layer               | API client, GraphQL operations, providers, types                                    |
| 7        | React components + widget      | `components/`, `widgets/`, `.phtml` under the React module                          |

## Rules

- Never commit build artifacts under generated build output directories — these are created by the build command
- Never mix PHP source with React source in the same commit
- Keep together files that only make sense as a unit (e.g. a resolver + its schema type)
- Merge very small groups (1-2 files) with an adjacent group
- Unrelated fixes unconnected to the main feature get their own commits
