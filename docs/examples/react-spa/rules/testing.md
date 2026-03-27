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
- **Co-location:** Test files live next to source (`OrderTable.test.tsx` alongside `OrderTable.tsx`)

Key testing priorities by layer:

- **API hooks** — mock TanStack Query's `queryClient`, test loading/error/success states, test cache invalidation after mutations
- **Form components** — test Zod validation (valid/invalid), field interactions, submit behaviour
- **Page components** — test route params handling, data display, empty/loading states
- **Stores** — test Zustand actions and derived state in isolation
- **API client** — test interceptor behaviour (auth token injection, error transformation)
