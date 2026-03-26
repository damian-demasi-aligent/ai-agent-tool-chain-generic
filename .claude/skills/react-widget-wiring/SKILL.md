---
name: react-widget-wiring
description: Magento-to-React widget integration patterns. Use when creating widget entry points, writing .phtml templates that mount React widgets, or passing data from Magento PHP to React components via data attributes.
user-invocable: false
metadata:
  capabilities: [magento-react-bridge]
---

# Magento–React Widget Wiring

React widgets mount into Magento-rendered pages through a specific integration chain. Before starting, **read CLAUDE.md** for the project's mounting convention, script loading mechanism, and GraphQL access pattern, and the project rules (`.claude/rules/magento-conventions.md`) for data attribute escaping rules.

## Mounting Convention

Check CLAUDE.md for how widgets discover their mount points. A common pattern is attribute-based lookup to support multiple widget instances per page:

```tsx
// widgets/my-widget.tsx
const widgetName = 'my-widget';
const targetElements = document.querySelectorAll(`[data-react-widget="${widgetName}"]`);

targetElements.forEach(targetElement => {
  const someConfig = targetElement.getAttribute('data-some-config');
  ReactDOM.createRoot(targetElement).render(<MyComponent config={someConfig} />);
});
```

## Magento → React Data Flow

All configuration passes through **HTML data attributes** on the mount element. Avoid `window.*` globals or inline JSON scripts.

```phtml
<!-- Template: view/frontend/templates/my-widget.phtml -->
<div data-react-widget="my-widget"
     data-product-label="<?= $escaper->escapeHtmlAttr($block->getProductLabel()) ?>"
     data-some-options="<?= $escaper->escapeHtmlAttr(json_encode($block->getOptions())) ?>">
</div>
```

**Always use `$escaper->escapeHtmlAttr()`** for data attributes. Use `json_encode()` for arrays/objects. Check the project rules (`.claude/rules/magento-conventions.md`) for any additional escaping rules.

## Reading Config Inside Components

If a nested component needs data attributes from the mount element, traverse up with `closest()`:

```tsx
const parentWithAttr = ref.current?.closest('[data-some-config]');
const value = parentWithAttr?.getAttribute('data-some-config');
```

Prefer reading attributes at the widget entry point and passing as props.

## Script Loading

**Check CLAUDE.md** for the project's script loading mechanism. Typically a shared Block class handles:

- **Dev mode:** `<script type="module">` pointing to the Vite dev server
- **Production:** `<script type="module">` pointing to the compiled asset

React widgets are typically **ES modules** — they do NOT use RequireJS.

## GraphQL Access

**Check CLAUDE.md** for how widgets access GraphQL. Common patterns include:

- A module-level singleton (instantiated at import time) rather than React Context
- Environment variables to build the GraphQL endpoint URL

Read the project's existing widget entry points to see the exact import and usage pattern.
