# Prompt: Generate CLAUDE.md for a New Magento 2 Project

Use the prompt below in a new Magento 2 project repository to generate a `CLAUDE.md` file that is compatible with the portable `.claude/` toolchain (agents, commands, and skills).

## Why this matters

The `.claude/` agents and skills never hardcode project-specific paths, namespaces, or commands. Instead they reference **CLAUDE.md section names** like "read CLAUDE.md's Architecture section" or "check CLAUDE.md Commands section". If a section is missing or misnamed, the tool that depends on it will produce incorrect output or fail silently.

This prompt ensures every required section exists, is named correctly, and is populated with the new project's real data.

---

## Copy/Paste Prompt

```md
You are an expert Magento 2 and Claude Code tooling engineer. Your task is to generate a complete `CLAUDE.md` file for this repository that is compatible with a portable `.claude/` agent and skill system.

## Goal

Produce a single `CLAUDE.md` at the repo root that:
1. Accurately documents this project's architecture, commands, conventions, and dependencies
2. Uses the **exact section names and structure** listed below — agents and skills resolve their references by section name
3. Contains only real paths, commands, and conventions discovered from this repository — never copy placeholder data from another project

## Required sections (in order)

The CLAUDE.md MUST contain these sections with these exact headings. Each section description explains what the `.claude/` tools expect to find there.

### 1. `# CLAUDE.md` (top-level heading)

Opening line: `This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.`

### 2. `## Project Overview`

- Magento edition and version (check `composer.json` or `composer.lock`)
- Project name / client name
- Whether the frontend uses React + Vite, PWA Studio, Hyvä, or pure Luma
- **Vendor namespace** — the custom namespace under `app/code/` (e.g. `Acme`). State it explicitly: `**Vendor namespace:** \`<Namespace>\` — all custom modules live under \`app/code/<Namespace>/\``
- Theme path (e.g. `app/design/frontend/<Vendor>/<theme>/`)

### 3. `## Commands`

Three subsections are required. Every agent and command references "the project's X command from CLAUDE.md Commands section" — if a command is missing, the tool will not know how to run it.

#### `### React / Frontend (Node)` (or equivalent frontend heading)

List the actual commands from `package.json` scripts:
- Dev server command
- Production build command
- Lint check command
- Lint fix command
- Type-check command
- Node version (from `.nvmrc` or `engines`)
- Package manager and version (npm/yarn/pnpm — check lock files)

#### `### Magento CLI`

- The CLI wrapper used in this project (e.g. `manta`, `warden`, `bin/magento`, `docker exec ...`)
- Common commands: `setup:upgrade`, `setup:di:compile`, `cache:flush`
- **Important:** If a wrapper is used, state clearly to never use `bin/magento` directly

#### `### PHP / Magento (Composer)`

- Code style check command (PHPCS)
- Code style fix command (PHPCBF)
- Static analysis command (PHPStan)
- How pre-commit hooks run these (if applicable)

### 4. `## Architecture`

#### `### React + Vite Integration` (or equivalent frontend architecture heading)

This section is heavily referenced by `react-patterns`, `react-widget-wiring`, `react-new-widget`, `react-gql`, `feature-planner`, and `feature-implementer`. Include:

- **Full directory tree** of the React source (widgets, components, GraphQL layer, hooks, context, utils, types, constants, config)
- **Widget discovery mechanism** — how Vite finds entry points (auto-discovery from a folder, manual config, etc.)
- **Mounting convention** — how widgets attach to the DOM (data attribute lookup, ID-based, etc.)
- **Script loading** — how the Block/PHP class loads React bundles in dev vs production mode
- **GraphQL access pattern** — singleton provider, React context, direct Apollo calls, codegen, etc.
- **Existing widgets** — list all current widget entry points
- **Path alias** — e.g. `@/*` resolves to `src/app/*`
- **Build output paths** — where compiled JS/CSS goes (and note these are NOT committed)

#### `### Magento Theme`

- Theme directory tree (CSS source, JS, module overrides)
- Parent theme (Luma, Blank, Hyvä, custom)
- **LESS styling conventions** (or SCSS/Tailwind if applicable):
  - Theme colour variable naming convention
  - Custom mixin locations
  - Responsive style approach (media query files vs inline)
  - Module override pattern (e.g. `_extend.less`)

#### `### Custom Magento Modules`

A table listing every custom module under the vendor namespace:

```
| Module | Purpose |
|--------|---------|
| `ModuleName` | Brief description |
```

Also document:
- Standard module structure reminder
- **Plugin naming convention** — the prefix pattern used in `di.xml` plugin names

#### `### Key Dependencies`

List major frontend and backend dependencies with their purpose. The `feature-implementer` uses this to know what UI library, CSS framework, validation library, etc. are available.

### 5. `## Documentation (\`docs/\`)`

If the project uses a `docs/` folder for plans, requirements, and feature architecture documents, describe:
- Folder structure
- How each subfolder is used
- When to consult docs before starting work

If no `docs/` folder exists yet, include a template structure and explain that agents like `feature-planner` will write plan files here.

### 6. `## Testing`

- Test framework (Vitest, Jest, PHPUnit, etc.) — or state that none is installed yet
- Test file location convention (co-located, `__tests__/`, separate `tests/` dir)
- Key testing priorities by layer (hooks, providers, components, widgets)

### 7. `## Code Standards`

- ESLint config package/preset
- Prettier config and any plugins (e.g. Tailwind class sorting)
- EditorConfig rules (indentation, line endings, max line length)
- PHP standards (PHPCS ruleset, PHPStan level)

### 8. `## Commit Conventions`

This section is critical for the `committer` agent.

- **Main branch name** (e.g. `production`, `main`, `master`, `develop`)
- **Message format** — show the pattern with ticket prefix extraction from branch names
- Rules: imperative mood, character limit, capitalisation, no trailing period, Co-Authored-By trailer

#### `### Commit grouping order`

A priority table defining how multi-layer features should be split into commits. The `committer` agent follows this table exactly:

| Priority | Group | Typical files |
|---|---|---|
| 1 | PHP module registration | `registration.php`, `composer.json`, `etc/module.xml` |
| 2 | Admin configuration | `etc/adminhtml/system.xml`, `etc/config.xml` |
| 3 | GraphQL schema + backend logic | `etc/schema.graphqls`, `Model/`, `Api/`, `etc/di.xml` |
| 4 | Email templates | `view/frontend/email/` |
| 5 | Magento frontend integration | layout XML, `.phtml`, `.js`, `.less` |
| 6 | React data layer | GQL operations, providers, types |
| 7 | React components + widget | components, widgets, widget PHTML |

Adapt this table to match the project's actual layer boundaries.

**Rules:**
- List which build output paths should never be committed
- Rule: never mix PHP source with React source in the same commit
- Rule: keep together files that only make sense as a unit
- Rule: merge very small groups with an adjacent group

### 9. `## Conventions`

#### `### React`

Coding conventions for React/TypeScript code. Include:
- Where React code must live (single module? spread across modules?)
- Component style (functional only, class allowed, etc.)
- Props/state interface location (inline vs separate type files)
- Export pattern (barrel exports, named exports, default exports)
- GraphQL integration pattern (codegen, manual Apollo, provider pattern)
- Event handler naming (e.g. `handle*` prefix)
- Error handling pattern (e.g. `ActionResult<T>` discriminated union, try/catch, etc.)
- Error message constant structure
- Accessibility conventions (aria-live, focus management approach, sr-only utility)
- Any project-specific UI patterns (error styling constants, etc.)

#### `### PHP / Magento`

- Copyright header format
- `declare(strict_types=1)` requirement
- Constructor style (promoted properties, traditional)
- Admin config section organisation (shared section name, group convention)
- Pre-commit hook details

#### `### Tooling`

- Any Claude Code hooks (PostToolUse auto-lint, etc.)
- Preflight check usage

### 10. `## Reuse Before Reimplementing`

This is the most project-specific section. The `feature-planner`, `feature-implementer`, `email-template`, and other tools use this to find reference implementations.

- Opening statement: always read existing code before writing new code
- **Full-stack reference features** — name 2-3 modules that are the best examples of end-to-end feature implementation (registration → admin config → GraphQL → email → React form → widget → layout)
- **Lookup table** mapping technical needs to specific reference files:

| Need | Where to look first |
|---|---|
| Transactional email | `<Module>/Model/<File>.php` |
| GraphQL mutation + resolver | `<Module>/Model/Resolver/<File>.php` |
| Admin config fields | `<Module>/etc/adminhtml/system.xml` |
| Multi-step React form | `components/<FormDir>/` |
| React widget entry point | `widgets/<name>-widget.tsx` |
| Magento plugin | `Plugin/` directories |
| Data patch / EAV attribute | `<Module>/Setup/Patch/Data/` |
| DB schema | `<Module>/etc/db_schema.xml` |

- **Specific reuse rules** — document any project-specific patterns that must be followed exactly (dual emails, branch routing, BCC handling, enquiry codes, template variable structure, data attribute escaping, GraphQL type sync requirements, REST vs GraphQL boundaries, etc.)

## Discovery process

Before writing CLAUDE.md, execute these steps to gather accurate data:

1. **Read `composer.json`** — Magento version, PHP version, vendor packages
2. **Read `package.json`** — all available scripts, dependencies, devDependencies, Node version
3. **Check for `.nvmrc`**, `.node-version`, or `engines` in package.json
4. **Check lock files** — `yarn.lock` (Yarn), `package-lock.json` (npm), `pnpm-lock.yaml` (pnpm)
5. **Check `.yarnrc.yml`** for Yarn version if applicable
6. **Scan `app/code/`** — list all vendor namespaces and modules
7. **Read the React source tree** — identify the module hosting React code, its directory structure, widgets, components, provider pattern
8. **Read `vite.config.ts`** (or equivalent) — understand entry point discovery, build output, aliases
9. **Read `app/design/frontend/`** — identify theme vendor/name, parent theme, LESS/SCSS structure
10. **Read `.editorconfig`** — indentation, line length, line endings
11. **Read ESLint and Prettier configs** — `.eslintrc.*`, `eslint.config.*`, `.prettierrc.*`
12. **Read PHPCS config** — `phpcs.xml`, `phpcs.xml.dist`, or composer scripts
13. **Read PHPStan config** — `phpstan.neon`, `phpstan.neon.dist`
14. **Check `composer.json` scripts** — PHPCS, PHPCBF, PHPStan commands
15. **Check for CLI wrappers** — search for `manta`, `warden`, or Docker-based commands in `Makefile`, `composer.json` scripts, or repo docs
16. **Read 2-3 complete custom modules** — understand the project's actual patterns for GraphQL, email, plugins, admin config
17. **Check for a `docs/` directory** and its contents
18. **Check the git config** — main branch name (`git symbolic-ref refs/remotes/origin/HEAD` or check common branch names)
19. **Read recent git log** — understand commit message conventions already in use
20. **Check for test infrastructure** — Vitest config, Jest config, PHPUnit config, test directories

## Quality checks

After generating CLAUDE.md, verify:

- [ ] Every path referenced in the file actually exists in the repository
- [ ] Every command listed can be run (check that the script exists in package.json or composer.json)
- [ ] The module inventory table includes all custom modules
- [ ] The widget list matches the actual files in the widgets directory
- [ ] The dependency list matches what's actually in package.json
- [ ] The commit message format matches the style visible in `git log`
- [ ] No placeholder text or data from another project remains
- [ ] All section headings match the required names exactly

## What NOT to include

- Do not invent conventions not evidenced in the codebase
- Do not add aspirational guidance ("we should..." / "ideally...")
- Do not document third-party vendor module internals
- Do not include sensitive data (API keys, credentials, internal URLs)
- Do not add setup/installation instructions (that belongs in README)

Now scan this repository and generate the complete CLAUDE.md file.
```

---

## Usage notes

- Run this prompt in the target Magento 2 repository root
- The generated CLAUDE.md should be committed to the repo root alongside the `.claude/` directory
- After generating CLAUDE.md, use the companion prompt `rebuild-claude-skills-in-new-project.md` to adapt the skills
- If the project doesn't use React + Vite, the React-related sections can be adapted or marked as N/A — but keep the section headings so tools degrade gracefully
- Review the output carefully — the AI may miss project-specific patterns that only humans familiar with the codebase know about

## Section dependency map

This table shows which `.claude/` tools depend on which CLAUDE.md sections, so you know the impact of omitting or renaming a section:

| CLAUDE.md Section | Referenced by |
|---|---|
| Project Overview (vendor namespace) | `magento-module`, `plugin`, `email-template`, `admin-config`, `observer`, `data-patch`, `feature-implementer` |
| Commands → Frontend | `preflight`, `react-preflight`, `committer`, `feature-implementer`, `react-new-widget` |
| Commands → Magento CLI | `feature-implementer`, `module-overview` |
| Commands → PHP | `preflight`, `php-preflight`, `plugin`, `email-template`, `observer`, `data-patch`, `feature-implementer` |
| Architecture → React + Vite | `react-new-widget`, `react-gql`, `react-form-wizard`, `react-dom-hook`, `feature-planner`, `feature-implementer`, `preflight` |
| Architecture → Theme | `less-theme`, `create-theme-override`, `layout-diff` |
| Architecture → Custom Modules | `feature-planner`, `feature-implementer`, `module-overview`, `email-template`, `plugin` |
| Architecture → Key Dependencies | `react-patterns`, `react-a11y-check`, `feature-implementer`, `preflight` |
| Documentation | `feature-planner`, `committer`, `documenter` |
| Testing | `react-add-tests`, `test-runner` |
| Code Standards | `preflight`, `react-preflight`, `php-preflight` |
| Commit Conventions | `committer`, `commit-pr` |
| Commit Conventions → Grouping | `committer`, `feature-planner` |
| Conventions → React | `react-patterns`, `react-error-handling`, `react-a11y-check`, `feature-implementer` |
| Conventions → PHP | `magento-module`, `plugin`, `observer`, `email-template`, `data-patch`, `feature-implementer` |
| Conventions → Tooling | `preflight` |
| Reuse Before Reimplementing | `feature-planner`, `feature-implementer`, `email-template`, `gql-fullstack`, `react-form-wizard` |
