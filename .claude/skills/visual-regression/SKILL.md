---
name: visual-regression
description: >
  Capture screenshots of pages before and after code changes to detect unintended visual regressions.
  Use when reviewing PRs that touch CSS/layout/components, after refactoring UI code, or when
  verifying that a fix didn't break other pages. Requires Playwright MCP.
user-invocable: true
metadata:
  capabilities: [react]
---

# Visual Regression Check

Capture and compare page screenshots to detect unintended visual changes after code modifications.

## Arguments

```
/visual-regression <url1> [url2] [url3] ...
```

If no URLs provided, infer affected pages from changed files (see Step 1).

## Prerequisites

- **Playwright MCP required** — if `browser_navigate` is not available, report: "Visual regression: SKIPPED (Playwright MCP not available)"
- **Pages must be accessible** — the dev server must be running, or URLs must point to a deployed environment. If the dev server is not running, start it using the command from CLAUDE.md Smoke Test section.

## Workflow

### Step 1: Determine pages to check

If URLs were provided in $ARGUMENTS, use those directly.

Otherwise, infer affected pages from changed files:

1. Run `git diff <main-branch> --name-only` to find changed files (use the main branch from CLAUDE.md)
2. For each changed file, trace which page routes render it:
   - **React components** — check which page, route, or widget imports the component (search for `import` statements)
   - **Layout XML / .phtml templates** — check which routes use the layout handle
   - **CSS / LESS / Tailwind files** — identify pages that include the affected styles
3. Build a list of URLs to check (max 5 pages to keep the check fast)

If no pages can be inferred, ask the user for URLs.

### Step 2: Capture current state

For each URL:

1. `browser_navigate` — open the page
2. `browser_wait_for` — if the page loads dynamic content, wait for a key selector to appear (e.g., the main content area, a product grid, a form). This avoids capturing loading spinners or skeleton states.
3. `browser_take_screenshot` — capture a full-page screenshot. Note the file path.
4. `browser_snapshot` — capture the DOM/accessibility tree for structural comparison

Record the screenshot path and a summary of the DOM structure for each page.

### Step 3: Capture baseline state (optional)

A baseline allows side-by-side comparison. Capture one if possible:

- **Deployed staging/production URL** — if the same pages are accessible on a deployed environment (different base URL), navigate there and capture the same pages
- **Separate dev server on main branch** — if a worktree or separate checkout is available on the main branch with its own dev server port, capture from that

If no baseline is available (the common case for local dev), skip this step. The screenshots from Step 2 serve as a visual record for manual review and as a baseline for future comparisons.

### Step 4: Analyse

For each page:

1. **Visual review** — examine the captured screenshots for:
   - Layout shifts or broken alignment
   - Missing or misplaced elements
   - Overlapping content or broken z-index stacking
   - Broken images, icons, or media
   - Unintended style changes (colours, spacing, typography, borders)
   - Responsive issues (if viewport was set)

2. **DOM structure comparison** — if both current and baseline DOM snapshots were captured, compare the accessibility trees for structural changes:
   - Missing or added landmark elements, headings, or navigation items
   - Changed element hierarchy that affects semantics
   - Removed interactive elements (buttons, links, form fields)

3. **Cross-page consistency** — if multiple pages were checked, verify shared elements (header, footer, navigation, sidebar) look consistent across all pages

### Step 5: Report

```
## Visual Regression Report

### Pages checked
1. <URL> — OK / ISSUE FOUND
2. <URL> — OK / ISSUE FOUND

### Issues found
- **<URL>**: <description of the visual issue — what changed, where on the page, and whether it appears intentional>

### Screenshots captured
- <page name>: <screenshot file path>

### Verdict
- PASS — no unintended visual changes detected
- REVIEW NEEDED — potential issues found, screenshots attached for human review
```

### Step 6: Cleanup

Use `browser_close` to release the browser when all pages have been captured.

## Viewport options

By default, Playwright uses a standard desktop viewport. For responsive checks, use `browser_resize` before capturing:

- **Mobile**: `browser_resize` to width 375, height 812
- **Tablet**: `browser_resize` to width 768, height 1024
- **Desktop**: `browser_resize` to width 1440, height 900

If the user requests responsive checks, capture each page at multiple viewports and note the viewport in the screenshot filename/report.

## Usage by other agents

This skill can be invoked by:

- **reviewer** — when a PR touches CSS, layout, component, or template files, capture screenshots of affected pages and include findings in the review
- **feature-implementer** — capture screenshots of the implemented feature for the change summary
- **preflight** — optional visual check alongside the runtime smoke test
- **documenter** — capture feature screenshots for architecture documentation
