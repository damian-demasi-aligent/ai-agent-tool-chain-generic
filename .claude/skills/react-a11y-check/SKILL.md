---
name: react-a11y-check
description: Accessibility conventions for React components. Use when creating or modifying React components that render interactive UI, forms, modals, drawers, dynamic content, or error states.
user-invocable: false
metadata:
  capabilities: [react]
---

# React Accessibility Patterns

Apply these when writing or reviewing UI code. Before starting, **read CLAUDE.md** for the project's UI library choices (dialog/modal primitives), CSS framework (Tailwind, CSS Modules, etc.), and any project-specific a11y conventions (focus management patterns, error styling constants).

## Dialogs and Drawers

- Use the project's dialog/modal library (check CLAUDE.md Key Dependencies) — well-designed primitives handle focus trapping and Escape key automatically
- Close buttons must have screen-reader-only text (e.g. `<span className="sr-only">Close</span>`) with the icon wrapped in `aria-hidden="true"`

## Forms

- Every input must have a `<label>` with `htmlFor` matching the input's `id`
- Use `ariaInvalid` prop on inputs when validation fails
- Link error messages to inputs with `aria-describedby` pointing to the error element's `id`
- Use `inputMode="numeric"` and `pattern` attributes for postcode/number-only fields
- Do NOT use `autofocus` without explicit justification — if justified, add `eslint-disable-next-line jsx-a11y/no-autofocus` with a comment explaining why

## Focus Management

- **Check CLAUDE.md** for the project's focus management convention (e.g. declarative boolean flags vs imperative `.focus()` calls)
- Reset focus state when drawers/modals close:
  ```tsx
  useEffect(() => {
    if (!isOpen) {
      setShouldFocusInput(false);
    }
  }, [isOpen]);
  ```

## Dynamic Content

- Wrap content that updates asynchronously (stock status, API results, error messages) in `aria-live` regions
- Use `aria-live="polite"` for non-urgent updates, `aria-live="assertive"` for errors
- Screen-reader-only text uses the project's SR utility class (e.g. Tailwind's `sr-only`) — not `display: none` or `visibility: hidden`, which hide from assistive tech entirely

## Error Display

- Error components must render with both a visual icon and text — do not rely on colour alone
- **Check CLAUDE.md** for any project-specific error styling constants or components to reuse

## Runtime Accessibility Testing (Playwright)

When Playwright MCP tools are available, supplement the static checks above with live browser verification. These tests catch issues that source-code analysis alone cannot — incorrect tab order caused by CSS, focus traps that don't work at runtime, dynamic content that fails to announce, and missing accessibility tree entries.

### When to run

- During **preflight** (step 4b — after static a11y analysis of changed components)
- During **code review** when changes touch interactive components (forms, modals, drawers, navigation)
- When explicitly requested by the user

### Prerequisites

A dev server must be running with the pages accessible. Use CLAUDE.md Smoke Test section for the dev server command and URL. If no dev server is available, skip runtime checks and note "Runtime a11y: SKIPPED (no dev server)".

### Keyboard navigation check

1. `browser_navigate` to the page containing the changed component
2. `browser_press_key` with `Tab` repeatedly (10-20 times) and use `browser_snapshot` after each tab to observe focus movement
3. Verify:
   - **Every interactive element is reachable** — buttons, links, inputs, selects, and custom controls must all receive focus via Tab
   - **Focus order is logical** — follows visual reading order (top-to-bottom, left-to-right for LTR layouts). CSS `order`, `position: absolute`, or `flexbox` reordering can cause tab order to diverge from visual order
   - **Focus is visible** — each focused element should show a visible focus indicator (outline, ring, or highlight). Use `browser_snapshot` to check which element has focus
   - **No focus traps** (except intentional ones in modals) — Tab should not get stuck on a single element. If it does, flag it

### Modal / drawer focus management

If the changed code includes a modal, drawer, or dialog:

1. `browser_click` the trigger element to open the modal
2. `browser_snapshot` — verify focus moved inside the modal (the focused element should be within the modal's DOM subtree)
3. `browser_press_key` with `Tab` several times — verify focus stays trapped within the modal (does not escape to background content)
4. `browser_press_key` with `Escape` — verify the modal closes
5. `browser_snapshot` — verify focus returned to the trigger element

### Live accessibility tree inspection

1. `browser_snapshot` captures the page's accessibility tree — use it to verify:
   - **Heading hierarchy** — `h1` through `h6` levels do not skip (e.g., no `h2` → `h4` jump)
   - **Landmark roles** — the page has `banner`, `navigation`, `main`, `contentinfo` landmarks
   - **Form labels** — every input in the tree has an accessible name (shown as the element label in the snapshot)
   - **Button labels** — icon-only buttons have accessible names (via `aria-label` or sr-only text)
   - **Image alt text** — images show meaningful alt text, not "image" or filenames; decorative images show empty alt

### Dynamic content announcements

If the changed code updates content asynchronously (loading states, success/error messages, live data):

1. Trigger the async action (e.g., `browser_click` a submit button, `browser_fill_form` and submit)
2. `browser_snapshot` after the content updates
3. Verify the updated content is inside an element with `aria-live` (visible in the snapshot as `alert`, `status`, or `log` role, or explicit `aria-live` attribute)

### Report format

Append runtime findings to the static a11y report:

```
Runtime accessibility (Playwright):
  <page URL>:
    ⛔ BLOCKER: Focus trapped on element X — Tab key does not advance past it
    ⚠️  WARNING: Modal close does not return focus to trigger button
    ⚠️  WARNING: Success message not inside aria-live region
    ✅ Keyboard navigation: all interactive elements reachable in logical order
    ✅ Heading hierarchy: correct (h1 → h2 → h3)
    ✅ Landmarks: banner, navigation, main, contentinfo present
```
