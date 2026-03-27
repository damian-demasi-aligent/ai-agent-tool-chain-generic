---
description: React component patterns, state management, data fetching, and reuse references
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.ts"
  - "**/*.js"
---

# React Conventions

- Functional components only, one `.tsx` file per component
- Props interfaces defined inline in the component file, not in separate type files
- Use barrel `index.ts` exports for component directories
- Use early returns; name event handlers with `handle*` prefix
- Avoid `setTimeout`/`setInterval` without a strong reason

## Data Fetching

- **All server data goes through TanStack Query** — never store API data in Zustand or `useState`
- API hooks live in `api/endpoints/` — one file per resource, exporting `useXxx` query hooks and `useCreateXxx`/`useUpdateXxx` mutation hooks
- Mutations must invalidate relevant query keys after success — use `queryClient.invalidateQueries`
- Validate API responses with Zod at the boundary (in the endpoint file), not in components
- Optimistic updates for user-facing mutations (e.g. toggling a status) — use TanStack Query's `onMutate`/`onError`/`onSettled` pattern

## Client State

- **Zustand for UI state only** — sidebar open/closed, selected filters, user preferences
- Do not duplicate server state in Zustand — if it comes from the API, it belongs in TanStack Query's cache
- Keep stores small and focused — one store per concern (`useFilterStore`, `usePreferencesStore`), not one god store

## Error Handling

- API errors are transformed in the Axios interceptor (`api/client.ts`) into a typed `ApiError` shape
- Components consume errors via TanStack Query's `error` state — never use try/catch around hooks
- Use the `ErrorAlert` component for displaying API errors — it handles the `ApiError` shape consistently
- Toast notifications for mutation errors; inline alerts for query errors

## Routing

- Pages are lazy-loaded via `React.lazy` in `routes.tsx`
- Auth-gated routes wrap pages in `<ProtectedRoute>` — do not add auth checks inside page components
- Route params are read with `useParams()` — validate them with Zod before using as API arguments

## Reuse Before Reimplementing

Before implementing any feature, search for existing examples by technical need:

| Need                        | Where to look first                                         |
| --------------------------- | ----------------------------------------------------------- |
| Data table with pagination  | `components/OrderTable/`                                    |
| Form with validation        | `components/forms/CreateOrderForm/` (Zod + mutation hook)   |
| Filter panel + URL sync     | `components/FilterPanel/` + `stores/useFilterStore.ts`      |
| API endpoint + types        | `api/endpoints/orders.ts` + `api/types/orders.ts`           |
| Auth-gated page             | `pages/OrdersPage.tsx` + `routes.tsx` ProtectedRoute usage  |
| Modal/dialog pattern        | `components/ui/ConfirmDialog/` (Radix Dialog)               |
| Detail page with tabs       | `pages/OrderDetailPage.tsx`                                 |
