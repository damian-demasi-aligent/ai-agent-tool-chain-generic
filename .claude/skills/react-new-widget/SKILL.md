---
name: react-new-widget
description: Create a new React widget named "$ARGUMENTS".
argument-hint: Widget name (e.g., "trial", "product-comparison")
disable-model-invocation: true
metadata:
  capabilities: [magento-react-bridge]
---

Create a new React widget named "$ARGUMENTS".

Before starting, **read CLAUDE.md** for the project's frontend source paths (Architecture section), widget mounting convention, existing widgets list, and React conventions.

Follow these steps:

1. Create the Vite entry point in the widgets directory (from CLAUDE.md Architecture) as `$ARGUMENTS-widget.tsx`. Follow the mounting convention from CLAUDE.md (e.g. `data-react-widget` attribute lookup with `createRoot`). Read an existing widget for reference.

2. Create the main component in a new directory under the components directory (from CLAUDE.md Architecture), following established component patterns (GraphQL client for data, project CSS framework for styling, proper TypeScript types).

3. Show me what Magento-side integration is needed (PHTML template with the mount `<div>`, layout XML referencing it) but do NOT create those files without asking — confirm the module and page where this widget should appear.

4. Run the project's build, lint, and type-check commands from CLAUDE.md Commands section to verify the widget compiles.
