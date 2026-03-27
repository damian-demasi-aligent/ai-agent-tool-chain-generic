---
description: React component patterns, state management, error handling, and reuse references
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.ts"
  - "**/*.js"
---

# React Conventions

- React widgets must live in the `React` module — do not add React code to other modules
- Functional components only (no class components), one `.tsx` file per component
- Props/state interfaces are defined inline in the component file, not in separate type files
- Use barrel `index.ts` exports for component directories
- GraphQL operations use Apollo Client directly — no codegen. New providers must be wired into `CCGProvider.ts`
- Use early returns; name event handlers with `handle*` prefix
- Avoid `setTimeout`/`setInterval` without a strong reason
- Provider methods never throw — they return `ActionResult<T>`, a discriminated union (`{ status: 'success'; payload: T } | { status: 'error'; message: string }`). Consume with status checks, not try/catch.
- Error message constants live in `constants/` as objects with `type` (`'warning'` | `'error'`) and `message` fields
- Use `aria-live` regions for dynamic content (cart, filters, notifications)
- Track focus intent with boolean state flags (e.g. `shouldFocusInput`) and reset them when drawers/modals close — do not call `.focus()` imperatively
- Use the `ERROR_TYPE_STYLES` constant for consistent error component styling across all React widgets

## Reuse Before Reimplementing

**Full-stack reference features:** `Hire` and `Service` are the most complete examples — each covers module registration, admin config, GraphQL schema + resolver, email sending, React multi-step form, widget entry point, and Magento layout wiring. Use them as the primary analogue for any new form-to-backend feature. For product-page widgets with complex state and DOM bridging, study `StockAvailability` (stock-availability-widget).

Before implementing any feature, search for existing examples by technical need:

| Need                        | Where to look first                                       |
| --------------------------- | --------------------------------------------------------- |
| Multi-step React form       | `components/HireForm/`, `components/ServiceForm/`         |
| React widget entry point    | `widgets/hire-widget.tsx`, `widgets/service-widget.tsx`    |
