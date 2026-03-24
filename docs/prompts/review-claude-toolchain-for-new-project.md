# Prompt: Review and Adapt .claude/ Toolchain for a New Project

Run this prompt **after** generating `CLAUDE.md` with the companion prompt (`generate-claude-md-for-new-project.md`). It reviews the entire `.claude/` toolchain against the newly generated CLAUDE.md and updates anything that needs adapting.

## Why this is needed

The `.claude/` toolchain (agents, commands, skills, hooks) is designed to be portable — agents and skills reference `CLAUDE.md` dynamically rather than hardcoding project-specific values. However, two things still need project-specific adaptation:

1. **`hooks/config.sh`** — shell environment variables that hooks source at runtime (vendor namespace, React paths, GraphQL sync paths)
2. **Hook assumptions** — some hooks assume specific directory structures or files exist (e.g. `docs/manuals/`)

Additionally, a mismatch between what CLAUDE.md documents and what the tools expect will cause silent failures, so the review validates compatibility end-to-end.

---

## Copy/Paste Prompt

```md
You are an expert Claude Code tooling engineer. The `.claude/` directory in this repository contains a portable toolchain (agents, commands, skills, hooks) that was designed for Magento 2 + React projects. A project-specific `CLAUDE.md` has just been generated.

Your task is to review the entire `.claude/` toolchain against the new CLAUDE.md and update anything that needs adapting so every tool works correctly in this project.

## Overview of what you're reviewing

The toolchain has this structure:

```
.claude/
  settings.json           ← Hook registration (PreToolUse, PostToolUse)
  hooks/
    config.sh             ← CRITICAL: centralised project-specific variables
    core-vendor-guard.sh  ← Blocks edits to vendor/core files
    clean-build-output.sh ← Removes Vite build output before commits
    graphql-sync-check.sh ← Ensures GraphQL layers stay in sync on commit
    react-lint-on-edit.sh ← Auto-runs ESLint on React file edits
    sync-manuals-check.sh ← Prompts docs updates when tooling files change
  agents/*.md             ← AI agent definitions (generic, reference CLAUDE.md)
  commands/*.md           ← Slash command definitions (generic, reference CLAUDE.md)
  skills/*/SKILL.md       ← Skill definitions (generic, reference CLAUDE.md)
```

**Design principle:** All project-specific configuration is centralised in two places:
- `CLAUDE.md` (for AI tools — agents, commands, skills)
- `.claude/hooks/config.sh` (for shell hooks)

Agents, commands, and skills are fully generic — they resolve project-specific data by reading CLAUDE.md at runtime.

## Phase 1: Update hooks/config.sh (MANDATORY)

This is the **only file that requires direct editing** in most cases. Read both `CLAUDE.md` and `.claude/hooks/config.sh`, then update these variables:

### Variable reference

| Variable | What it controls | Where to find the correct value |
|---|---|---|
| `VENDOR_NAMESPACE` | Custom module namespace under `app/code/` | CLAUDE.md → Project Overview → Vendor namespace |
| `REACT_SRC` | Path to React source root | CLAUDE.md → Architecture → React + Vite Integration → directory tree |
| `REACT_BUILD_JS` | Vite JS build output directory | CLAUDE.md → Architecture → React + Vite Integration → build output |
| `REACT_BUILD_CSS` | Vite CSS build output directory | CLAUDE.md → Architecture → React + Vite Integration → build output |
| `GQL_SCHEMA_GLOB` | Glob for GraphQL schema files | CLAUDE.md → Architecture → Custom Magento Modules (all modules with GraphQL) |
| `GQL_TEMPLATES_GLOB` | Glob for frontend GQL template literals | CLAUDE.md → Architecture → React + Vite Integration → GraphQL layer path |
| `GQL_TYPES_FILE` | Path to the TypeScript types file for GQL responses | CLAUDE.md → Architecture → React + Vite Integration → types directory |

### Rules for updating

1. Read the current `config.sh` to understand the variable structure
2. Read CLAUDE.md to find the correct values for this project
3. Update each variable to match the new project's paths and namespace
4. Ensure `REACT_SRC` and derived paths (`GQL_TEMPLATES_GLOB`, `GQL_TYPES_FILE`) are consistent
5. If this project does NOT use React + Vite, set `REACT_SRC=""` and comment out the React/GQL variables with a note explaining why

### Special cases

- **Different React module name:** If the React source lives in a module other than `React` (e.g. `Frontend`, `PWA`), update all paths accordingly
- **Different GQL types file name:** If the project's TypeScript types file for GraphQL responses has a different name than `ccgProvider.ts`, update `GQL_TYPES_FILE`
- **No GraphQL layer:** If the project doesn't use a custom GraphQL provider pattern, comment out the `GQL_*` variables
- **Multiple vendor namespaces:** If custom modules live under different namespaces, update `GQL_SCHEMA_GLOB` to cover all of them (e.g. `app/code/{Acme,AcmeExtras}/*/etc/schema.graphqls`)

## Phase 2: Update hardcoded comments in hook scripts

Some hook scripts have project-specific content in their **comments** (not functional code). While comments don't affect functionality, they should be accurate for maintainability.

1. Read `.claude/hooks/graphql-sync-check.sh`
   - Lines 10-11 describe the three GraphQL layers with example paths
   - Update the paths in these comments to match the new project's actual paths from `config.sh`
   - The functional code already uses `$VENDOR_NAMESPACE`, `$REACT_SRC`, and `$GQL_TYPES_FILE` from config.sh, so no code changes needed

2. Read all other hook scripts — check for any comments that reference the old project name or paths and update them

## Phase 3: Validate hook assumptions

Each hook makes structural assumptions about the project. Verify each one:

### core-vendor-guard.sh
- **Assumes:** `vendor/` and `app/code/Magento/` directories exist
- **Check:** These are standard Magento paths — should be fine for any Magento project
- **Action:** No changes needed unless the project uses a non-standard directory layout

### clean-build-output.sh
- **Assumes:** Vite build outputs to `REACT_BUILD_JS` and `REACT_BUILD_CSS` directories
- **Check:** Verify these directories match where `yarn build` (or equivalent) actually outputs
- **Action if no React/Vite:** This hook will silently do nothing (the directories won't exist). Either remove it from `settings.json` or leave it — it's harmless.

### graphql-sync-check.sh
- **Assumes:** Three-layer GraphQL sync pattern (PHP schema, GQL templates, TypeScript types)
- **Check:** Does this project use the same three-layer pattern? Read the React source to verify.
- **Action if different:** If the project has a different GraphQL integration (e.g. codegen, no custom provider), either update the sync check logic or disable it in `settings.json`

### react-lint-on-edit.sh
- **Assumes:** `yarn eslint` command is available and React source is under `REACT_SRC`
- **Check:** Verify the lint command from CLAUDE.md Commands section. Some projects use `npx eslint`, `npm run lint`, or a different path.
- **Action:** If the lint command differs, update lines 44 and 50 in the script to use the correct command

### sync-manuals-check.sh
- **Assumes:** `docs/manuals/` directory exists with `reference/ai-tools-reference.md`
- **Check:** Does this project have a `docs/manuals/` directory? Was it copied along with `.claude/`?
- **Action if missing:** Either:
  - (a) Create the `docs/manuals/` structure (recommended if using the full toolchain), or
  - (b) Remove this hook from `settings.json` → delete the PostToolUse entry for `sync-manuals-check.sh`, or
  - (c) Leave it — the hook exits silently for non-tooling files and will only produce output when `.claude/` files are edited (output will reference missing docs but won't break anything)

## Phase 4: Validate CLAUDE.md ↔ tool compatibility

The agents, commands, and skills don't need editing — but they need CLAUDE.md to have the right sections. Verify this compatibility by running these checks:

### 4a. Section existence check

Read CLAUDE.md and verify ALL of these exact section headings exist (the tools reference them by name):

```
## Project Overview
## Commands
### React / Frontend (Node)        ← or equivalent frontend heading
### Magento CLI
### PHP / Magento (Composer)
## Architecture
### React + Vite Integration        ← or equivalent frontend architecture heading
### Magento Theme
### Custom Magento Modules
### Key Dependencies
## Documentation (`docs/`)
## Testing
## Code Standards
## Commit Conventions
### Commit grouping order
## Conventions
### React
### PHP / Magento
### Tooling
## Reuse Before Reimplementing
```

For each missing section, report it with the list of tools that will be affected (see the dependency map in Phase 6).

### 4b. Critical data point check

Verify CLAUDE.md contains these specific data points that tools actively parse:

| Data point | Where tools expect it | Example tools that use it |
|---|---|---|
| Vendor namespace | Project Overview | `magento-module`, `plugin`, `email-template` |
| Main branch name | Commit Conventions | `committer`, `preflight`, `review-pr` |
| Frontend build command | Commands → Frontend | `preflight`, `feature-implementer` |
| Frontend lint command | Commands → Frontend | `preflight`, `react-lint-on-edit` hook |
| Frontend type-check command | Commands → Frontend | `preflight`, `committer`, `feature-implementer` |
| PHP quality commands | Commands → PHP | `php-preflight`, `plugin`, `observer` |
| Widget directory path | Architecture → Frontend | `react-new-widget`, `react-debug-widget` |
| Components directory path | Architecture → Frontend | `react-new-widget`, `react-form-wizard` |
| GraphQL layer paths | Architecture → Frontend | `react-gql`, `gql-fullstack`, `react-sync-types` |
| Theme path | Architecture → Magento Theme | `less-theme`, `create-theme-override`, `layout-diff` |
| Module inventory table | Architecture → Custom Modules | `feature-planner`, `module-overview`, `email-template` |
| Plugin naming convention | Architecture → Custom Modules | `plugin`, `magento-module` |
| Reference features list | Reuse Before Reimplementing | `feature-planner`, `feature-implementer` |
| Reuse lookup table | Reuse Before Reimplementing | `email-template`, `gql-fullstack`, `react-form-wizard` |
| docs/ folder structure | Documentation | `feature-planner`, `committer`, `documenter` |
| Commit message format | Commit Conventions | `committer`, `commit-pr` |

For each missing data point, report it and explain which tools will malfunction.

### 4c. Command cross-reference

For each command in CLAUDE.md's Commands section, verify the command actually works:

1. Read `package.json` — confirm every frontend command listed in CLAUDE.md has a matching script
2. Read `composer.json` — confirm every PHP command listed in CLAUDE.md has a matching script
3. Check if the CLI wrapper mentioned in CLAUDE.md (e.g. `manta`, `warden`) is referenced consistently

### 4d. Path validation

For each file path or directory mentioned in CLAUDE.md, verify it exists:

1. Vendor namespace directory: `app/code/<Namespace>/` exists
2. React source root from Architecture section exists
3. Theme directory from Architecture section exists
4. Each module in the Custom Magento Modules table has a `registration.php`
5. Each widget listed in Architecture section exists in the widgets directory
6. Reference feature files in Reuse Before Reimplementing actually exist

## Phase 5: Validate skills against project capabilities

Skills are generic, but some assume capabilities that a project might not have. Read each skill and flag incompatibilities:

### Skills that assume React + Vite exists
- `react-patterns`
- `react-widget-wiring`
- `react-error-handling`
- `react-a11y-check`
- `react-add-tests`
- `react-debug-widget`
- `react-sync-types`

**If this project has no React layer:** These skills will produce irrelevant guidance. Options:
- (a) Remove them from agent frontmatter `skills:` lists and from `settings.json`
- (b) Leave them — they'll be loaded but the agents will find no matching architecture in CLAUDE.md and skip React guidance

### Skills that assume LESS theming
- `less-theme`

**If this project uses SCSS, Tailwind, or Hyvä:** Update or replace this skill.

### Skills that assume transactional email patterns
- `email-patterns`

**If this project has no custom transactional emails yet:** The skill is still useful as a guide for future work. No changes needed.

### Skills that assume REST API endpoints
- `rest-api-patterns`

**If this project has no custom REST endpoints:** Same as above — keep for future use.

## Phase 6: Generate compatibility report

After completing all phases, produce a structured report:

```
# .claude/ Toolchain Compatibility Report

## config.sh updates
- [ ] VENDOR_NAMESPACE: <old> → <new>
- [ ] REACT_SRC: <old> → <new>
- [ ] REACT_BUILD_JS: <old> → <new>
- [ ] REACT_BUILD_CSS: <old> → <new>
- [ ] GQL_SCHEMA_GLOB: <old> → <new>
- [ ] GQL_TEMPLATES_GLOB: <old> → <new>
- [ ] GQL_TYPES_FILE: <old> → <new>

## Hook comment updates
- [ ] graphql-sync-check.sh lines 10-11: updated path examples
- [ ] (any other comment-only changes)

## Hook structural issues
- (list any hooks whose assumptions don't hold for this project)

## CLAUDE.md missing sections
- (list any missing sections with affected tools)

## CLAUDE.md missing data points
- (list any missing data with affected tools)

## Command mismatches
- (list any commands in CLAUDE.md that don't match package.json/composer.json)

## Path validation failures
- (list any paths in CLAUDE.md that don't exist on disk)

## Skill incompatibilities
- (list any skills that assume capabilities this project lacks)

## Recommendations
- (prioritised list of follow-up actions)
```

## Execution order

1. Read CLAUDE.md thoroughly first
2. Read and update `hooks/config.sh` (Phase 1)
3. Update hook comments (Phase 2)
4. Validate hook assumptions (Phase 3)
5. Run all compatibility checks (Phase 4)
6. Check skill compatibility (Phase 5)
7. Produce the report (Phase 6)

Do NOT skip phases. Do NOT make changes beyond what this prompt specifies — agents, commands, and skills should NOT be edited unless a Phase 5 incompatibility requires removing a skill reference from an agent's frontmatter.
```

---

## Usage notes

- Run this prompt in the target repository **after** the `.claude/` directory has been copied and `CLAUDE.md` has been generated
- The prompt is read-heavy by design — it validates before changing, so changes are minimal and targeted
- In most cases, the only file that actually changes is `hooks/config.sh` (and possibly a few comments)
- The compatibility report at the end gives you confidence that the toolchain is correctly adapted
- If the report surfaces missing CLAUDE.md sections, go back and update CLAUDE.md before using the tools

## Relationship to other prompts

| Order | Prompt | Purpose |
|---|---|---|
| 1 | `generate-claude-md-for-new-project.md` | Generates the project-specific CLAUDE.md |
| 2 | **This prompt** | Reviews and adapts `.claude/` toolchain to work with the new CLAUDE.md |
