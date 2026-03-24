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
