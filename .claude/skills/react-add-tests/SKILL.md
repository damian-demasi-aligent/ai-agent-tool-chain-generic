---
name: react-add-tests
description: Add tests to the React codebase. Use this skill to bootstrap testing infrastructure or write tests for specific components, hooks, or providers.
disable-model-invocation: true
metadata:
  capabilities: [react]
---

# Add React Tests

Target: $ARGUMENTS (a component name, hook, provider method, or "setup" to bootstrap test infrastructure).

Before starting, **read CLAUDE.md** for the project's current testing status, testing priorities by layer, and any existing test conventions.

## If $ARGUMENTS is "setup"

Check CLAUDE.md to confirm whether a testing framework is already installed. If not, bootstrap it:

1. Install Vitest and Testing Library (aligns with Vite toolchain):

   ```
   yarn add -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
   ```

2. Add a `vitest.config.ts` at the repo root. If a `vite.config` already exists, extend it:

   ```typescript
   import { defineConfig, mergeConfig } from 'vitest/config';
   import viteConfig from './vite.config';

   export default mergeConfig(
     viteConfig({ command: 'build', mode: 'test' }),
     defineConfig({
       test: {
         environment: 'jsdom',
         globals: true,
         setupFiles: ['./vitest.setup.ts'],
       },
     })
   );
   ```

3. Add test scripts to `package.json`: `"test": "vitest"` and `"test:run": "vitest run"`

4. Create a minimal `vitest.setup.ts` with `@testing-library/jest-dom` import

5. Verify with `yarn test:run`

**Ask before proceeding** — confirm the user wants to add these dev dependencies.

## If $ARGUMENTS is a specific target

Read the target's source code first, then write tests following the testing priorities documented in CLAUDE.md. General guidance by component type:

### For Hooks

- Mock any DOM APIs the hook depends on (MutationObserver, IntersectionObserver, specific elements)
- Test observer/listener cleanup on unmount
- Test handling of missing DOM elements (the null case)

### For Provider / data-layer methods

- Mock the GraphQL client (Apollo, urql, etc.)
- Test both success and error return paths
- Verify error messages match any project constants

### For Form components

- Test schema validation: valid input passes, invalid input produces correct error map
- Test multi-step navigation (onNext called with correct data)
- Test error display renders with icon and text

### For Widget entry points

- Mock `document.querySelectorAll` and verify `createRoot` is called for each matched element
- Test data attribute reading and parsing

### Conventions

- Co-locate test files next to source: `MyComponent.test.tsx` alongside `MyComponent.tsx`
- Use `describe` blocks matching component/hook name
- Use `@testing-library/user-event` over `fireEvent` for interactions
- Check CLAUDE.md for any additional test conventions specific to this project
