---
description: Testing frameworks, conventions, and layer-specific testing priorities
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/*.test.js"
  - "**/*.test.jsx"
  - "**/__tests__/**"
  - "**/tests/**"
  - "**/playwright.config.*"
  - "**/*.stories.tsx"
---

# Testing

No testing framework is currently installed. When bootstrapping tests, use Vitest (aligns with the existing Vite toolchain) with `@testing-library/react` and `jsdom`. Co-locate test files next to source (`MyComponent.test.tsx` alongside `MyComponent.tsx`).

Key testing priorities by layer:

- **Hooks** — mock DOM APIs (MutationObserver, elements), test cleanup on unmount, test null/missing element cases
- **Provider methods** — mock Apollo Client, test both success and error paths of the `ActionResult<T>` return type
- **Form components** — test Zod validation (valid/invalid), multi-step navigation, error display
- **Widget entry points** — mock `document.querySelectorAll`, verify `createRoot` is called for each matched element, test data attribute reading
