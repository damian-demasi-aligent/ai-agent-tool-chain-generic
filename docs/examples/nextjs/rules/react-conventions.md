---
description: React and Next.js component patterns, data fetching, state management, and reuse references
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.ts"
  - "**/*.js"
---

# React Conventions

- **Server Components by default** — only add `'use client'` when the component needs interactivity, browser APIs, or hooks
- Functional components only, one `.tsx` file per component
- Props interfaces defined inline in the component file, not in separate type files
- Use barrel `index.ts` exports for component directories
- Use early returns; name event handlers with `handle*` prefix
- Avoid `setTimeout`/`setInterval` without a strong reason

## Next.js App Router

- **Layouts** are Server Components — use them for shared UI and data fetching that doesn't change between navigations
- **Pages** receive route params as props — use `generateStaticParams` for static generation where possible
- **Loading/error states** use the file convention (`loading.tsx`, `error.tsx`, `not-found.tsx`) — don't build custom loading spinners at the page level
- **Server Actions** for form mutations — prefer them over API routes for form submissions from Server Components
- **Route handlers** (`app/api/`) only for webhooks, external integrations, and non-form POST endpoints

## Data Fetching

- **Server Components** use `apollo-rsc` — queries run at request time with automatic deduplication
- **Client Components** use generated typed hooks from `libs/graphql/generated/`
- Always run `yarn codegen` after modifying `.graphql` files — do not hand-write GraphQL types
- Use Zod to validate external API responses at system boundaries

## Error Handling

- GraphQL errors surface through Apollo's `error` state on hooks — check `error` before rendering data
- Use `ErrorBoundary` components for runtime errors in client components
- API routes return typed error shapes with appropriate HTTP status codes

## Reuse Before Reimplementing

Before implementing any feature, search for existing examples by technical need:

| Need                        | Where to look first                                         |
| --------------------------- | ----------------------------------------------------------- |
| Product listing page        | `app/(shop)/products/page.tsx`                              |
| Product detail page         | `app/(shop)/products/[slug]/page.tsx`                       |
| Authenticated page          | `app/(account)/orders/page.tsx` + `middleware.ts`           |
| Form with validation        | `components/ContactForm/` (Zod + Server Action)             |
| GraphQL query + types       | `libs/graphql/src/operations/products.graphql`              |
| Shared UI component         | `libs/ui/src/` (Button, Dialog, Card, etc.)                 |
| API route (webhook)         | `app/api/webhooks/cms/route.ts`                             |
