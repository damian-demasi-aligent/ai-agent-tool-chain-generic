---
description: Testing frameworks, conventions, and layer-specific testing priorities
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/__tests__/**"
  - "**/playwright.config.*"
  - "**/*.stories.tsx"
---

# Testing

- **Unit/integration:** Vitest + `@testing-library/react` + `jsdom`
- **E2E:** Playwright (configured in `playwright.config.ts`)
- **Co-location:** Test files live next to source (`MyComponent.test.tsx` alongside `MyComponent.tsx`)

Key testing priorities by layer:

- **Server Components** — test data fetching logic in isolation, mock Apollo RSC client
- **Client Components** — test user interaction, form validation, loading/error states
- **GraphQL hooks** — mock Apollo Client, test both success and error paths
- **API routes** — test request handling, validation, and response shapes
- **Middleware** — test redirect rules, auth gating, locale detection
