# Stack Examples

These directories show what the toolchain's generated output looks like for different technology stacks. Each contains a sample `CLAUDE.md` and `.claude/rules/` files that `/setup-project` would produce for that stack.

The root-level `CLAUDE.md.example` and `.claude/rules/*.md.example` files demonstrate a Magento 2 + React/Vite project (same content as the `magento-react/` directory here). These examples cover the main supported stacks:

| Directory | Stack | Key characteristics |
|---|---|---|
| `magento-react/` | Magento 2 + React/Vite | PHP backend, Luma theme with LESS, React widgets via Vite, GraphQL API, dual-email patterns |
| `nextjs/` | Next.js + React + Apollo | App Router, monorepo, GraphQL API, Tailwind, codegen |
| `react-spa/` | React SPA + Vite + REST | Single-page app, REST API, TanStack Query, Zustand, React Router |

These files are **reference only** — they are not consumed by the toolchain and do not need to be deleted during setup.
