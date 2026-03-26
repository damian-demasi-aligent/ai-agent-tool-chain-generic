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

## Step 2: Live verification with Playwright

If Playwright MCP tools are available (`browser_navigate`, `browser_snapshot`, etc.) and the page is accessible (dev server or deployed environment), verify the integration chain in the live browser. This catches issues that static file analysis alone cannot — runtime import failures, missing data attributes, hydration errors, and timing issues.

**If Playwright MCP is not available or the page is not accessible**, skip to Step 3.

### 2a. Navigate to the page

Use `browser_navigate` to open the Magento page where the widget should render. The URL should correspond to the route/page identified in Step 1 (e.g., a product page, category page, or CMS page).

### 2b. Check mount point exists

Use `browser_snapshot` and search the DOM tree for the mount `<div>` identified in Step 1 (e.g., `id="widget-name-root"`).

- **Mount point found** — the Magento template is rendering correctly. Proceed to check if React initialised.
- **Mount point missing** — the layout XML or template is not being applied to this route. Check for layout handle mismatches, block removal in theme overrides, or conditional rendering logic in the template.

### 2c. Check if React mounted

After the mount point is found, check whether React populated it with content:

1. `browser_snapshot` — look at the contents of the mount `<div>`:
   - **Has child elements with React component structure** — React mounted successfully
   - **Empty or contains only a loading spinner that never resolves** — React failed to initialise or is stuck. Check console messages.
   - **Contains server-rendered HTML but no interactive behaviour** — hydration may have failed

2. `browser_console_messages` — check for:
   - `Error` or `Uncaught` messages indicating mount failure
   - `Module not found` or `Cannot find module` — missing dependency in the build
   - `TypeError: Cannot read properties of null` — the mount element ID doesn't match between React and the template
   - React hydration warnings or errors
   - `ChunkLoadError` — the JS bundle failed to load (check network too)

3. `browser_network_requests` — check for:
   - Failed requests for the widget's JS bundle (404, 500)
   - Failed GraphQL or API requests that the widget depends on
   - CORS errors on API calls

### 2d. Check data attributes

If the widget receives data from Magento via `data-*` attributes on the mount `<div>` (identified in Step 1):

1. Use `browser_evaluate` to read the attributes:
   ```javascript
   document.getElementById('widget-name-root')?.dataset
   ```
2. Verify:
   - **Attributes are present** — the `.phtml` template is passing data correctly
   - **Attributes have valid values** — not empty strings, `undefined`, or malformed JSON
   - **Attribute names match** what the React component expects (check the component's props or `useEffect` that reads them)

### 2e. Take a screenshot

Use `browser_take_screenshot` to capture the visual state of the widget area. This provides evidence for the report:
- **Widget renders correctly** — screenshot shows the expected UI
- **Widget is broken** — screenshot shows the failure state (empty area, error message, partial render)
- **Widget is missing** — screenshot shows the page without the widget

## Step 3: Report

Summarise findings as:

- **Mount point:** Where the widget attaches to the DOM (and whether it exists in the live page)
- **Data flow:** How data reaches the widget (GraphQL, DOM observation, props from Magento data attributes)
- **Live status** (if Playwright was used): Mounted / Failed to mount / Missing mount point — with console errors and screenshot
- **Likely failure point:** Which link in the chain is broken and why
- **Suggested fix:** Concrete code change with file paths
