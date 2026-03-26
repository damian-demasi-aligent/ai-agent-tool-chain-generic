# AI Tools Reference

> A complete reference of all available agents and skills. Use this as a quick lookup — the workflow guides in the other manuals explain how to combine them.

---

## Agents

Agents are autonomous subprocesses invoked with `@agent-name`. They run independently, read files, and return a single result to the conversation.

| Agent | Invoke | Purpose |
|---|---|---|
| `codebase-qa` | `@codebase-qa [question]` | Answer "how does X work" questions by reading the actual source. Returns file paths and line references. |
| `committer` | `@committer` | Analyse uncommitted changes, propose a logical commit breakdown, and execute after approval. [Two-phase workflow.](#committer) |
| `documenter` | `@documenter [TICKET-XXX]` | Generate a feature architecture document (`docs/features/`) from the code on the current branch. Includes Mermaid diagrams, data flows, deployment steps, and feature screenshots (via Playwright when available). |
| `feature-implementer` | `@feature-implementer [plan or task]` | Write code across all project layers following project conventions. Captures before/after screenshots (via Playwright) for visual comparison, runs static checks and browser verification, and produces a change summary with verification results. Best used via `/implement-feature` which also orchestrates the code review. |
| `feature-planner` | `@feature-planner [feature description]` | Produce a file-by-file implementation plan from requirements and optional pre-researched findings. Best used via `/plan-feature` which provides research automatically. |
| `impact-analyser` | `@impact-analyser [file, type, or description]` | Trace all dependencies of a target and report what else will need to change. |
| `preflight` | `@preflight` | Run full preflight quality checks including runtime smoke test via Playwright (see CLAUDE.md Commands for the specific checks). Report results only — never modifies files. |
| `reviewer` | `@reviewer` | Review the current branch diff against the main branch (from CLAUDE.md). Includes visual diff with screenshots when CSS/layout/component files changed (via Playwright). Returns per-file issues with severity and a merge verdict. |
| `test-runner` | `@test-runner [scope?]` | Run the Vitest test suite and report results. Accepts a component name, file path, or `changed` to run only tests for changed files. Guides setup if test infrastructure is missing. |

### `committer` — two-phase workflow

Phase 1 (default — invoke with no arguments):
```
@committer
```
Returns a proposed commit plan. Does not create any commits.

Phase 2 (execute the approved plan):
After reviewing the plan in the conversation, reply `"go"` — the main Claude will invoke the committer again to execute.

---

## Skills

Skills are invoked with `/skill-name` in the conversation. They run in the current context and can ask clarifying questions mid-execution. Some skills are also loaded automatically by agents as context modules.

### User-invocable skills

#### Exploration

| Skill | Purpose |
|---|---|
| `/module-overview [ModuleName]` | Concise summary of a custom Magento module: files, purpose, integrations, GraphQL extensions. |
| `/layout-diff [handle or module]` | Compare a theme layout override against the vendor original. Explains what changed and flags maintainability risks. |

#### Feature planning

| Skill | Purpose |
|---|---|
| `/plan-feature [requirements file, ticket, or description]` | Orchestrate the full planning workflow: spawn `codebase-qa` sub-agents for research + `impact-analyser` sub-agents for ripple effects, then delegate to `@feature-planner` with findings. Returns a file-by-file implementation plan. |
| `/implement-feature [plan file path]` | Orchestrate the full implementation workflow: validate the plan, spawn `@feature-implementer` in the working directory, then spawn `@reviewer` to review the result. Returns a combined report with change summary, verification results, and code review findings. The review feedback is informational output for the user — it does not trigger automated fixes. |

#### Feature scaffolding

| Skill | Purpose |
|---|---|
| `/react-new-widget [name]` | Create a new Vite widget entry point and component directory. Confirms Magento integration before creating PHP files. |
| `/react-form-wizard [name]` | Scaffold a multi-step form wizard following the project's existing form patterns (see CLAUDE.md Reuse table). |
| `/gql [name]` | Scaffold a GraphQL operation. Auto-detects whether the PHP schema exists — if not, creates schema + resolver + React data layer; if so, creates React data layer only. |
| `/plugin [ClassName::method]` | Create a Magento 2 plugin (interceptor). Reads vendor class, determines correct plugin type. |
| `/observer [event_name — description]` | Create a Magento 2 observer. Finds the event dispatch in vendor, determines scope, creates Observer class + `events.xml` registration. |
| `/create-theme-override [Module/path]` | Copy a vendor template or layout file to the project's theme override directory (from CLAUDE.md). Shows original before modifying. |
| `/react-dom-hook [name]` | Create a MutationObserver hook for bridging Magento's vanilla JS DOM changes into React state. |
| `/admin-config [description]` | Scaffold admin configuration: `system.xml` fields, `config.xml` defaults, source models, dynamic row blocks, and ACL resources. Shows plan before writing. |
| `/data-patch [description]` | Create declarative schema (`db_schema.xml`) or data patches (EAV attributes, DB operations). Supports product/customer attributes, table columns, and new tables. |
| `/email-template [description]` | Scaffold transactional email: `email_templates.xml`, HTML templates (customer + internal), PHP sender methods, and branch routing. |

#### Quality

| Skill | Purpose |
|---|---|
| `/preflight [react\|php]` | Run quality checks — `react` for frontend (ESLint + TypeScript + Vite build), `php` for backend (PHPCS + PHPStan), or omit for both. |
| `/react-add-tests [target or "setup"]` | Write Vitest tests for a component, hook, or provider. Use `"setup"` to bootstrap test infrastructure. |
| `/react-sync-types [module?]` | Compare `schema.graphqls` definitions against the project's TypeScript types file and GQL template literals (paths from CLAUDE.md). Reports mismatches. |
| `/react-debug-widget [name]` | Trace the full integration chain for a React widget and identify the broken link. When Playwright MCP is available, also verifies mount points, React initialisation, and data attributes in the live browser. |
| `/debug-frontend [project path?]` | Debug frontend bugs with runtime evidence. Starts a local log server, instruments code with hypotheses-tagged logging, and captures logs server-side. When Playwright MCP is available, automates bug reproduction and verification — no manual browser interaction needed. |
| `/visual-regression [url1] [url2]` | Capture screenshots of pages and compare for unintended visual changes. Infers affected pages from `git diff` if no URLs provided. Requires Playwright MCP. |
| `/lighthouse-audit [url1] [url2]` | Run Lighthouse performance, accessibility, best practices, and SEO audits. Reports scores, core web vitals, and failed audits with thresholds. |

#### Git

| Skill | Purpose |
|---|---|
| `/commit-pr` | Interactive commit workflow: analyse changes, propose plan, wait for approval, execute commits. |
| `/review-pr [PR#/branch]` | Review a PR or branch diff with project-specific checklist (conventions from CLAUDE.md). |

### Agent context skills (not user-invocable)

These are loaded automatically into agents that declare them. They inject project conventions and patterns into the agent's context.

| Skill | Loaded by | Purpose |
|---|---|---|
| `less-theme` | `feature-implementer` | LESS and CSS theming conventions for the Magento theme (reads paths from CLAUDE.md). |
| `magento-module` | `feature-implementer`, `feature-planner`, `committer`, `reviewer`, `documenter` | Magento 2 module structure and PHP conventions. |
| `react-a11y-check` | `feature-implementer`, `reviewer`, `preflight` | Accessibility patterns: forms, dialogs, dynamic content, error states. Includes runtime Playwright checks (keyboard nav, focus traps, live regions). |
| `visual-regression` | `reviewer` | Screenshot capture and comparison for detecting unintended visual changes. Used automatically when CSS/layout/component files are in the diff. |
| `react-error-handling` | `feature-implementer`, `feature-planner`, `reviewer` | `ActionResult<T>` pattern, Zod `safeParse`, error display. |
| `react-patterns` | `feature-implementer`, `feature-planner`, `committer`, `reviewer`, `documenter`, `test-runner` | React component conventions, state, DOM integration, styling. |
| `react-widget-wiring` | `feature-implementer`, `feature-planner`, `reviewer`, `documenter` | `data-react-widget` mounting, data attributes, script loading. |
| `email-patterns` | `feature-implementer`, `feature-planner`, `reviewer` | TransportBuilder patterns, email_templates.xml, HTML template directives, branch routing. |
| `rest-api-patterns` | `feature-implementer`, `feature-planner`, `reviewer` | `webapi.xml` routes, service contract interfaces, Data DTOs, di.xml preferences, REST vs GraphQL decision guide. |

---

## Choosing the right tool

| Situation | Tool |
|---|---|
| I want to understand how X works | `@codebase-qa` |
| I want a summary of a module | `/module-overview` |
| I want to know what a layout change does | `/layout-diff` |
| I want to know what will break if I change X | `@impact-analyser` |
| I'm starting a large feature | `/plan-feature` → `/implement-feature` |
| I'm adding a new React widget | `/react-new-widget` |
| I'm adding a form | `/react-form-wizard` |
| I'm adding a GraphQL operation | `/gql` (auto-detects whether PHP side is needed) |
| I need to intercept a Magento method | `/plugin` |
| I need to react to a Magento event | `/observer` |
| I need to override a template | `/create-theme-override` |
| I need to bridge Magento JS events to React | `/react-dom-hook` |
| I need admin-configurable settings | `/admin-config` |
| I need a new DB column, table, or EAV attribute | `/data-patch` |
| I need transactional emails for a feature | `/email-template` |
| My React widget isn't rendering | `/react-debug-widget` |
| I need runtime evidence to debug a frontend bug | `/debug-frontend` — instruments code, captures logs server-side, no DevTools copy-paste needed |
| My GraphQL types are out of sync | `/react-sync-types` |
| I want to check for visual regressions after CSS/layout changes | `/visual-regression` — captures screenshots via Playwright and flags unintended changes |
| I want to run a Lighthouse performance/a11y audit | `/lighthouse-audit` — reports scores, core web vitals, and failed audits |
| I want to run quality checks (React + PHP) | `@preflight` — now includes runtime smoke test via Playwright when available |
| I want to run quality checks for one stack only | `/preflight react` or `/preflight php` |
| I want to add tests | `/react-add-tests` |
| I want to run existing tests | `@test-runner` or `@test-runner changed` |
| I want to review before committing | `@reviewer` — run this **before** `@committer` to catch bugs while code is still uncommitted |
| I'm ready to commit | `@committer` — run this **after** `@reviewer` and any fixes are applied |
| I need to document a completed feature | `@documenter TICKET-XXX` — generates `docs/features/` architecture doc with Mermaid diagrams |
| I'm debugging a broken widget or PHP error | See [debugging.md](../02-playbooks/debugging.md) for guided workflows |
| I'm exploring unfamiliar code or tracing dependencies | See [exploration-and-investigation.md](../02-playbooks/exploration-and-investigation.md) for investigation patterns |

---

## Claude Hooks Automation

Hooks are configured in `.claude/settings.json` and run automatically before or after certain tool calls.

### Shared configuration

Project-specific paths (vendor namespace, React source root, build output directories, GraphQL layer paths) are centralised in **`.claude/hooks/config.sh`**. Each hook that needs project-specific paths sources this file automatically — no manual setup required. When reusing this `.claude/` directory in another project, edit `config.sh` to match the new project's directory structure.

### Hook inventory

| Hook | Trigger | Behavior |
|---|---|---|
| `config.sh` | Sourced by other hooks | Exports project-specific path variables (`VENDOR_NAMESPACE`, `REACT_SRC`, `REACT_BUILD_JS`, etc.). Not a hook itself — it is a shared config file. |
| `core-vendor-guard.sh` | `PreToolUse` on `Write or Edit` | Blocks edits to Magento core and vendor files and instructs extension-safe alternatives. |
| `clean-build-output.sh` | `PreToolUse` on `Bash` (`git commit`) | Removes and unstages React build output (`web/js`, `web/css`) before commit. Uses paths from `config.sh`. |
| `graphql-sync-check.sh` | `PreToolUse` on `Bash` (`git commit`) | Blocks commit when GraphQL schema, GQL templates, and TS types are not staged consistently. Uses paths from `config.sh`. |
| `sync-manuals-check.sh` | `PostToolUse` on `Write or Edit` | Prompts manual updates when `.claude/*` tooling files or `CLAUDE.md` change. |
| `react-lint-on-edit.sh` | `PostToolUse` on `Write or Edit` | For edited React source files, runs `yarn eslint --fix` then `yarn eslint` on the edited file. Uses paths from `config.sh`. |
