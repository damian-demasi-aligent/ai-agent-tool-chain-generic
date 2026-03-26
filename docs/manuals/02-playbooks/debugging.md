# Debugging Workflows

> Something is broken. How to diagnose and fix it systematically using the available AI tooling.

For canonical command syntax and inventory, use [`../reference/ai-tools-reference.md`](../reference/ai-tools-reference.md).

---

## Runtime debugging with log evidence

When you need runtime evidence to diagnose a bug — values are wrong, state is stale, conditional branches are unexpected, or async timing is off:

```
/debug-frontend
```

This skill replaces the manual "add console.log → reproduce → copy-paste from DevTools" cycle. It:

1. Starts a local log server (port 8787) that captures logs server-side
2. Guides you through generating testable hypotheses
3. Instruments the code with tagged `debugLog()` calls (wrapped in `#region debug` for easy cleanup)
4. **Automates bug reproduction via Playwright** (when available) — navigates pages, clicks elements, fills forms, and triggers the buggy interaction programmatically. Falls back to manual reproduction if Playwright MCP is not available.
5. Captures additional evidence via Playwright: browser console errors, network request failures, DOM snapshots, and screenshots
6. Reads logs directly from the log file — no user copy-paste needed
7. Evaluates each hypothesis as CONFIRMED / REJECTED / INCONCLUSIVE
8. Removes all instrumentation after the fix is verified

**When to use this instead of `/react-debug-widget`:**
- `/react-debug-widget` traces the static integration chain (mount points, layout XML, build output) and optionally verifies in the live browser via Playwright — use it when the widget doesn't render at all
- `/debug-frontend` captures runtime behaviour — use it when the widget renders but behaves incorrectly (wrong values, broken interactions, race conditions)

---

## React widget not rendering or behaving incorrectly

```
/react-debug-widget <widget-name>
```

Replace `<widget-name>` with the name of the broken widget. Check CLAUDE.md → Architecture for the list of existing widgets.

Traces the full integration chain for the named widget and finds the broken link:

1. **React side** — widget entry point, mount element ID, component tree, DOM bridge hooks
2. **Magento side** — PHTML template with the mount div, layout XML that includes it, theme overrides that might remove the block
3. **Build** — whether the compiled bundle exists in `web/js/` and whether it's loaded by layout XML

When the Playwright MCP is available, also verifies the integration chain in the live browser: checks that the mount `<div>` exists in the actual DOM, whether React mounted successfully, captures console errors and network failures, and reads data attributes passed from Magento templates.

Returns: mount point, data flow, live status (if Playwright was used), likely failure point, and a suggested fix with file paths.

---

## TypeScript or ESLint errors

```
/react-preflight
— or —
@preflight
```

Both run the same three checks in sequence (using commands from CLAUDE.md → Commands):
1. Lint check — ESLint
2. Type check — TypeScript
3. Production build — Vite

The difference: `/react-preflight` runs in the current conversation and can suggest fixes. The `preflight` agent runs independently and only reports — it never modifies files. Use `preflight` when you want a clean read without any auto-suggestions.

If `check-types` fails after a GraphQL schema change, run `/react-sync-types` first — the types and schema may have drifted.

---

## GraphQL type mismatch

Symptoms: TypeScript errors on response fields, Apollo returning `undefined` for fields that should exist, runtime `__typename` issues.

```
/react-sync-types
```

Scans all `schema.graphqls` files and compares against the project's TypeScript types file and GQL template literals (paths from CLAUDE.md → Architecture). Reports each mismatch and proposes corrections.

---

## "What changed to cause this?"

```
@impact-analyser [the file or type you suspect]
```

Traces all files that depend on the target. If a shared file changed (e.g. the GraphQL provider singleton, a GraphQL type), the impact analyser identifies every consumer that might now be broken.

Pair with `git log` or `git diff production...HEAD` to narrow down what changed on the current branch.

---

## PHP / Magento errors

For PHP issues, the first step is almost always `@codebase-qa`:

```
@codebase-qa Why does the [Module] resolver fall back to the general contact email?
@codebase-qa How does [Class] get the branch email in the [Module] module?
```

Replace the bracketed placeholders with your project's actual module and class names (see CLAUDE.md → Custom Magento Modules). The agent reads the PHP source and traces the call chain. This is faster than manually grepping through vendor code.

For understanding whether a change to a PHP class will break other things:

```
@impact-analyser <VendorNamespace>\<Module>\Model\<ClassName>
```

---

## Pre-commit hook failures

The project's CLI wrapper (see CLAUDE.md → Commands → Magento CLI) runs PHPCS and PHPStan on staged `.php` and `.phtml` files before every commit.

If a hook fails:
1. Read the error output carefully — PHPCS messages identify the exact line and rule
2. Run the project's style fix command (see CLAUDE.md → Commands → PHP) — it auto-fixes most style issues
3. PHPStan failures require manual fixes — they indicate type or logic problems
4. Never use `--no-verify` to bypass hooks — fix the underlying issue

---

## Build artifacts out of sync

If the page shows stale React behaviour after a source change:

1. Run `yarn build` to recompile
2. Check that `web/js/<widget-name>.js` has a newer timestamp than the source file
3. Do **not** commit the build output — it is generated by the deployment pipeline

---

## Visual regressions (CSS/layout broke something)

If a page looks wrong after a code change — broken layout, missing elements, overlapping content, or unintended style changes:

```
/visual-regression http://localhost:3000/affected-page
```

Captures screenshots via Playwright and analyses for visual issues. If the `@feature-implementer` captured before/after screenshots during implementation (in `docs/requirements/<TICKET>/tmp/`), the skill uses those for comparison.

For performance regressions (page loads slower after a change):

```
/lighthouse-audit http://localhost:3000/affected-page
```

Reports performance scores, core web vitals, and actionable failed audits. Compare against a baseline run on the main branch to identify regressions.

---

## Layout or template issues (Magento-rendered UI)

If a Magento-rendered element is missing, mispositioned, or showing wrong content:

```
/layout-diff Magento_Catalog
```

Compares the theme override against the Magento vendor original and explains what was changed. Identifies full-file overrides that may conflict with Magento upgrades or third-party module layout handles.

To create a corrected override:
```
/create-theme-override Magento_Catalog/catalog/product/view.phtml
```

---

## Testing a specific component or hook

If you need to write a test to reproduce or verify a bug fix:

```
/react-add-tests MyComponent
/react-add-tests useConfigurableOptions
```

If no testing infrastructure exists yet:
```
/react-add-tests setup
```

Bootstraps Vitest with `@testing-library/react`, co-located test files, and project-specific patterns for hooks, provider methods, and form components.
