---
name: react-debug-widget
description: Diagnose issues with a React widget not rendering or behaving incorrectly on a Magento page.
disable-model-invocation: true
metadata:
  capabilities: [magento-react-bridge]
---

# Debug React Widget

Diagnose why the widget "$ARGUMENTS" is not working correctly.

Before starting, **read CLAUDE.md** to identify the project's widget directory, theme path, build output path, and any DOM bridge hooks.

## Step 1: Trace the full integration chain

React widgets mounted in Magento pages have multiple failure points across two systems. Check each in order:

### React side

1. Find the widget entry point — search the widgets directory documented in CLAUDE.md for a file matching `$ARGUMENTS`
2. Check what DOM element ID it mounts to (e.g. `document.getElementById('...-root')`)
3. Trace the component tree it renders — look for missing props, broken context providers, or GraphQL client issues
4. Check if it depends on DOM bridge hooks that observe Magento-rendered DOM elements (search for `MutationObserver` or `querySelector` usage in custom hooks)

### Magento side

5. Search for the mount `<div>` with the matching ID in `.phtml` templates — check both custom module templates and theme template overrides (paths from CLAUDE.md)
6. Find the layout XML that references that template — check if the block is properly declared and assigned to the correct container
7. Check if there are layout XML overrides in the theme that might remove or reposition the block

### Build

8. Verify the widget appears in the build output directory (documented in CLAUDE.md) after running the build command
9. Check that the widget's JS bundle is properly loaded on the page — look at layout XML or RequireJS config for the script reference

## Step 2: Report

Summarise findings as:

- **Mount point:** Where the widget attaches to the DOM
- **Data flow:** How data reaches the widget (GraphQL, DOM observation, props from Magento data attributes)
- **Likely failure point:** Which link in the chain is broken and why
- **Suggested fix:** Concrete code change with file paths
