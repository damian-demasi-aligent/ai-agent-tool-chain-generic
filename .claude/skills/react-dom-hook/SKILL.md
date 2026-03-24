---
name: react-dom-hook
description: Create a custom React hook that bridges Magento's server-rendered DOM with React state for "$ARGUMENTS".
argument-hint: Name or description of the DOM bridge (e.g., "ConfigurablePrice", "product swatch selection")
disable-model-invocation: true
metadata:
  capabilities: [magento-react-bridge]
---

Create a custom React hook that bridges Magento's server-rendered DOM with React state for "$ARGUMENTS".

Before starting, **read CLAUDE.md** for the project's frontend source paths (Architecture section) and React conventions.

## Context

This project mounts React widgets into Magento pages. Magento renders product pages, checkout, etc. with server-side PHP, and React widgets need to observe and react to DOM changes made by Magento's vanilla JS (e.g., configurable product swatches updating the SKU, price changes, option selections).

## Step 1: Study existing DOM bridge hooks

Search the project's hooks directory (from CLAUDE.md Architecture) for existing DOM bridge hooks that use `MutationObserver` or `querySelector`. Read them to understand the established patterns:

Key conventions:
- Use MutationObserver for watching Magento DOM changes
- Clean up observers in useEffect return
- Return typed state objects (not raw DOM values)
- Handle the case where the observed element doesn't exist yet

## Step 2: Create the hook

1. Create the hook in the hooks directory following the naming convention `use[FeatureName].ts`
2. Ask me which DOM element(s) to observe and what data to extract
3. Return a properly typed state object
4. Include cleanup logic in the useEffect teardown

## Step 3: Verify

Run the project's type-check and lint commands from CLAUDE.md Commands section.
