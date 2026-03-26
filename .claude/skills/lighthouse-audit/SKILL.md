---
name: lighthouse-audit
description: >
  Run a Lighthouse performance and quality audit on one or more URLs.
  Reports scores for performance, accessibility, best practices, and SEO,
  plus core web vitals and actionable failed audits. Use to catch regressions
  or verify page quality after changes.
user-invocable: true
metadata:
  capabilities: [react]
---

# Lighthouse Audit

Run Google Lighthouse audits and report performance, accessibility, best practices, and SEO scores.

## Arguments

```
/lighthouse-audit <url1> [url2] [url3] ...
```

If no URLs provided, use the dev server URL from CLAUDE.md Smoke Test section.

## Prerequisites

- `npx lighthouse` must be available (included in most Node.js projects via dev dependency, or installed globally)
- Target pages must be accessible (dev server running or deployed environment)
- Chrome/Chromium must be installed (Lighthouse launches its own headless instance)

## Workflow

### Step 1: Verify Lighthouse is available

```bash
npx lighthouse --version 2>/dev/null || echo "NOT_AVAILABLE"
```

If not available, report: "Lighthouse audit: SKIPPED (lighthouse CLI not available — install with `npm install -g lighthouse` or add as a dev dependency)".

### Step 2: Determine URLs

If URLs were provided in $ARGUMENTS, use those.

Otherwise:
1. Read CLAUDE.md for the Smoke Test dev server URL
2. Use the dev server root as the primary URL
3. Also include one data-fetching route (e.g., a category page, product page) if identifiable from CLAUDE.md Architecture

If no URLs can be determined, ask the user.

### Step 3: Run Lighthouse

For each URL, run Lighthouse with JSON output:

```bash
npx lighthouse "<URL>" \
  --output=json \
  --output-path=/tmp/lighthouse-<page-name>.json \
  --chrome-flags="--headless --no-sandbox" \
  --only-categories=performance,accessibility,best-practices,seo \
  2>&1 | tail -5
```

**Naming**: slugify the URL path for the filename (e.g., `/women.html` → `lighthouse-women.json`, `/` → `lighthouse-home.json`).

**Timeout**: Lighthouse takes 30-90 seconds per URL. Use a 120-second timeout for the Bash command.

### Step 4: Parse results

For each report, extract scores, core web vitals, and failed audits:

```bash
python3 -c "
import json, sys

with open('/tmp/lighthouse-<page-name>.json') as f:
    r = json.load(f)

# Category scores
cats = r['categories']
for key in ['performance','accessibility','best-practices','seo']:
    c = cats[key]
    score = int(c['score'] * 100)
    print(f\"{c['title']}: {score}/100\")

print()

# Core Web Vitals
audits = r['audits']
metrics = ['first-contentful-paint','largest-contentful-paint','total-blocking-time',
           'cumulative-layout-shift','speed-index','interactive']
for m in metrics:
    if m in audits:
        a = audits[m]
        s = int(a['score']*100) if a['score'] is not None else 'N/A'
        print(f\"  {a['title']}: {a.get('displayValue','N/A')} (score: {s})\")

print()
print('Failed/Warning Audits:')
for key, a in audits.items():
    if a.get('score') is not None and a['score'] < 0.9 and \\
       a.get('scoreDisplayMode') not in ('informative','notApplicable','manual'):
        score = int(a['score']*100)
        print(f\"  [{score}] {a['title']}: {a.get('displayValue','')}\")
"
```

### Step 5: Report

```
## Lighthouse Audit Report

### Scores

| Page | Performance | Accessibility | Best Practices | SEO |
|------|-------------|---------------|----------------|-----|
| <URL> | XX/100 | XX/100 | XX/100 | XX/100 |

### Core Web Vitals — <URL>

| Metric | Value | Score |
|--------|-------|-------|
| First Contentful Paint | X.Xs | XX |
| Largest Contentful Paint | X.Xs | XX |
| Total Blocking Time | Xms | XX |
| Cumulative Layout Shift | X.XXX | XX |
| Speed Index | X.Xs | XX |
| Time to Interactive | X.Xs | XX |

### Key failed audits — <URL>
- [score] Audit name: details
- [score] Audit name: details

### Verdict
- PASS — all category scores above threshold
- WARNING — scores below threshold: <list categories and scores>
```

**Dev mode caveat**: Always include this note when auditing a local dev server:

> Dev mode results are inflated compared to production (unminified bundles, no CDN, no caching headers, source maps included). Performance and best-practices scores should be interpreted as relative baselines, not absolute targets. Accessibility and SEO scores are typically accurate regardless of environment.

## Thresholds

Default score thresholds for flagging warnings:

| Category | Threshold | Rationale |
|----------|-----------|-----------|
| Performance | 50 | Lenient — dev mode inflates bundle sizes and blocking time |
| Accessibility | 90 | Accessibility issues are real regardless of environment |
| Best Practices | 85 | Some dev-mode warnings are expected (source maps, HTTP) |
| SEO | 80 | Most SEO signals are accurate in dev mode |

Flag any category below its threshold. If the user provides custom thresholds in $ARGUMENTS (e.g., `--perf=70 --a11y=95`), use those instead.

## Storing reports

If a ticket number is identifiable (from branch name or context), copy the JSON report for reference:

```bash
TICKET="<ticket number>"
mkdir -p docs/requirements/$TICKET/tmp
cp /tmp/lighthouse-<page-name>.json docs/requirements/$TICKET/tmp/
```

Otherwise, the `/tmp/` copy is sufficient for the current session.

## Before/after comparison

When running Lighthouse to measure the impact of code changes:

1. **Before**: Run the audit on the main branch or current deployed version and save the report
2. **After**: Run the audit on the feature branch
3. **Compare**: Report the delta for each category score and flag any regressions:

```
### Score comparison (before → after)

| Category | Before | After | Delta |
|----------|--------|-------|-------|
| Performance | 65 | 58 | -7 ⚠️ |
| Accessibility | 95 | 97 | +2 ✅ |
| Best Practices | 92 | 92 | 0 |
| SEO | 85 | 85 | 0 |
```

Flag any category where the score dropped by 5+ points as a regression warning.

## Usage by other agents

- **preflight** — optional quality gate after the runtime smoke test
- **feature-implementer** — run before/after implementation to detect performance regressions
- **reviewer** — run on pages affected by a PR to flag performance or accessibility regressions
