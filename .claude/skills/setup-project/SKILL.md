---
name: setup-project
description: Configure the toolchain for the detected stack. Generates CLAUDE.md and .claude/rules/ files, prunes inapplicable skills/hooks/rules, and updates agent configurations. Run /detect-stack first.
disable-model-invocation: true
---

# Setup Project

Configure the Claude Code toolchain for this project based on the detected stack configuration.

**Prerequisite:** `.claude/stack-config.json` must exist. If it doesn't, tell the user to run `/detect-stack` first.

---

## Phase 1: Validate inputs

1. Read `.claude/stack-config.json`
2. Read `.claude/stack-capabilities.json` (the capability mapping for skills and hooks)
3. Validate capability consistency:
   - `magento-react-bridge` requires both `magento` and `react` — error if one is missing
   - `magento-theme` requires `magento` — error if missing
   - `nextjs` implies `react` — add `react` if missing
4. If validation fails, report the inconsistency and stop

## Phase 2: Safety backup

Before any destructive changes, create a filesystem backup of the toolchain directories. This avoids polluting git history with snapshot commits while still providing a rollback path.

1. Run `git status` to check for uncommitted changes
2. If there are uncommitted changes, warn the user and ask if they want to proceed (their changes will be mixed with toolchain modifications)
3. Ensure `tmp/` is gitignored (add it to `.gitignore` if not already present) so the backup is never committed
4. Create a timestamped backup of the toolchain directories inside the project:
   ```bash
   BACKUP_DIR="tmp/.claude-toolchain-backup-$(date +%s)"
   mkdir -p "$BACKUP_DIR"
   cp -r .claude/ "$BACKUP_DIR/claude"
   cp -r docs/ "$BACKUP_DIR/docs"
   [ -f CLAUDE.md ] && cp CLAUDE.md "$BACKUP_DIR/CLAUDE.md"
   [ -f CLAUDE.md.example ] && cp CLAUDE.md.example "$BACKUP_DIR/CLAUDE.md.example"
   ```
5. Report the backup location to the user so they know where to find it if needed:

   ```
   Toolchain backup saved to: <BACKUP_DIR>
   ```

   This backup covers only the `.claude/` and `docs/` toolchain files — not your project source code or working changes. It will be automatically deleted after you approve the final setup results.

   To restore manually if needed: `cp -r <BACKUP_DIR>/claude/ .claude/ && cp -r <BACKUP_DIR>/docs/ docs/`

## Phase 3: Generate CLAUDE.md and rules files

Generate a slim project-specific `CLAUDE.md` plus convention-specific `.claude/rules/*.md` files. The split keeps CLAUDE.md under 200 lines while scoping conventions to the file types they apply to.

### Part A: Slim CLAUDE.md

Generate these sections in order. For each, scan the project to populate with real content — never use placeholder text.

#### `## Project Overview`

- Read `stack-config.json` for project name, backend framework, frontend framework
- Summarize the tech stack in 2-3 sentences
- Note the vendor namespace (if Magento) or project structure

#### `## Commands`

- **Always include a subsection for each detected layer:**
  - `### Frontend (Node)` — if `react` or `nextjs` capability. List commands from `stack.frontend.commands`
  - `### Backend CLI` — if `magento` capability. List CLI commands using the detected `cliWrapper`
  - `### Backend Quality` — if `magento` capability. List quality commands from `stack.backend.qualityCommands`
- Include the package manager, Node version, and any wrapper commands
- `### Install & Codegen` — always include this subsection when `smokeTest.installCommand` or `smokeTest.codegenCommand` is non-null. Document the commands as a key-value list and describe when each must be run:
  ```markdown
  ### Install & Codegen
  - Install command: `yarn install`
  - Codegen command: `yarn codegen`

  **When to run:** Run the install command immediately after creating a new package/module, adding or removing dependencies, or modifying any dependency manifest (package.json, composer.json, requirements.txt, Gemfile, go.mod, etc.). Run the codegen command immediately after creating or modifying schema files (GraphQL schemas, OpenAPI specs, Protobuf definitions, etc.). Do not wait until the end of implementation — run these inline as soon as the triggering change is made.
  ```
  Omit lines where the value is null. If both are null, skip this subsection.
- `### Smoke Test` — if `smokeTest` section exists in stack-config and `smokeTest.devCommand` is not null. Document the dev server fields only:
  ```markdown
  ### Smoke Test
  - Dev server command: `yarn dev`
  - Dev server URL: `http://localhost:3000`
  - Health endpoint: `/api/health`
  ```
  Omit lines where the value is null. If the entire `smokeTest` section is null or `devCommand` is null, skip this subsection entirely.

#### `## Architecture`

- **Conditional subsections based on capabilities:**
  - `### Frontend` — if `react` or `nextjs`. Describe source path, build output, entry points, component structure
  - `### Backend Modules` — if `magento`. List custom modules found in `modulePath`, describe standard structure
  - `### Theme` — if `magento-theme`. Describe theme path, parent theme, CSS preprocessor (structural description only — LESS conventions go in `.claude/rules/theme-conventions.md`)
  - `### React Widget Integration` — if `magento-react-bridge`. Describe mounting convention, data attributes, Block class
  - `### API Layer` — if `graphql` or `rest`. Describe schema locations, client library, provider pattern, types file
  - `### Key Dependencies` — always. List major dependencies from package.json/composer.json

#### `## Documentation (docs/)`

- Describe the `docs/` folder structure (plans, features, requirements, manuals)
- Reference the toolchain workflow

Add this note at the top of CLAUDE.md, right after the `## Project Overview` section heading:

> Convention-specific rules (code standards, commit format, testing, language conventions) live in `.claude/rules/`. They load automatically based on the files being edited.

### Part B: Rules files (`.claude/rules/`)

Create the `.claude/rules/` directory and generate the following files. Each file uses YAML frontmatter. Files without a `paths:` field load unconditionally; files with `paths:` load only when Claude works with matching files.

#### `.claude/rules/code-standards.md`

**Frontmatter:** no `paths:` (always loaded)

```yaml
---
description: Code quality tool configuration and general coding principles
---
```

**Content:**
- General rule: "Always read existing code before writing new code" (from old `### General Code` convention)
- Detected standards: ESLint config, Prettier config, PHPCS config, EditorConfig
- List the detected standards and formatting rules
- Tooling notes: describe which hooks are active for this stack (e.g. PostToolUse ESLint auto-fix, /preflight usage)

#### `.claude/rules/commit-conventions.md`

**Frontmatter:** no `paths:` (always loaded)

```yaml
---
description: Commit message format, ticket prefix, Co-Authored-By trailer, and commit grouping order
---
```

**Content:**
- `mainBranch` and `commitPrefix` from stack config
- Message format and Co-Authored-By trailer
- Commit grouping order appropriate to the stack:
  - **Magento + React**: registration → admin → GraphQL/backend → email → Magento frontend → React data → React UI
  - **Next.js**: API routes → data layer → components → pages → config
  - **React SPA**: API/data layer → components → pages/routes → config
  - **Pure Magento**: registration → admin → models/API → plugins/observers → email → layout/templates → LESS/JS
- Rules about build artifacts, layer separation, small group merging

#### `.claude/rules/testing.md`

**Frontmatter:** path-scoped to test files

```yaml
---
description: Testing frameworks, conventions, and layer-specific testing priorities
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/*.test.js"
  - "**/*.test.jsx"
  - "**/__tests__/**"
  - "**/tests/**"
  - "**/playwright.config.*"
  - "**/*.stories.tsx"
---
```

**Content:**
- Detected test framework (or recommendation if none found)
- Co-location convention
- Testing priorities by layer (hooks, providers, form components, widget entry points, etc.)

#### `.claude/rules/react-conventions.md` (if `react` or `nextjs` capability)

**Frontmatter:** path-scoped to frontend source files

```yaml
---
description: React and Next.js component patterns, state management, error handling, and reuse references
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.ts"
  - "**/*.js"
---
```

**Content:**
- `### React` conventions: component patterns, state management, error handling approach
- `### Next.js` conventions (if `nextjs`): App Router patterns, server vs client components
- `### Reuse Before Reimplementing` — React/frontend rows from the lookup table (multi-step form, widget entry point, React components, etc.)
- For mixed Magento+React projects, include only the React-side rows; for React-only/Next.js projects, include the full table

#### `.claude/rules/magento-conventions.md` (if `magento` capability)

**Frontmatter:** path-scoped to PHP/XML files

```yaml
---
description: PHP and Magento 2 module patterns, plugin naming, email conventions, and reuse references
paths:
  - "**/*.php"
  - "**/*.xml"
  - "**/*.phtml"
---
```

**Content:**
- `### PHP / Magento` conventions: copyright header, strict_types, constructor style, plugin naming, admin config section convention, template overrides, stale asset debugging
- `### Reuse Before Reimplementing` — PHP/Magento rows from the lookup table (transactional email, GraphQL mutation+resolver, admin config, plugin, data patch, DB schema, etc.)
- Specific rules: dual emails, branch email routing, BCC lists, enquiry code generation, template variables, React data attributes escaping, REST vs GraphQL boundary, REST conventions

#### `.claude/rules/theme-conventions.md` (if `magento-theme` capability)

**Frontmatter:** path-scoped to LESS and theme files

```yaml
---
description: LESS styling, theme colour variables, custom mixins, and Magento theme override patterns
paths:
  - "**/*.less"
  - "**/app/design/**"
---
```

**Content:**
- Theme colour variable conventions (prefix pattern, available variables)
- Custom mixin locations and usage
- Responsive style file conventions (dedicated media-query files, not inline)
- Module-specific override convention (`_extend.less`)

### Writing CLAUDE.md and rules files

1. Assemble the slim sections (Project Overview, Commands, Architecture, Documentation) into CLAUDE.md
2. Write CLAUDE.md to the project root, replacing the existing CLAUDE.md (which is the example)
3. Create `.claude/rules/` directory if it doesn't exist
4. Write each applicable rules file with the appropriate frontmatter
5. Skip rules files whose capability gates are not met (e.g., skip `react-conventions.md` if no `react` capability, skip `magento-conventions.md` if no `magento` capability, skip `theme-conventions.md` if no `magento-theme` capability)
6. Verify all files are well-formed markdown

## Phase 4: Dry-run presentation

**Before any destructive changes**, present a summary of everything that will be modified:

```
## Setup Summary

### CLAUDE.md (slim)
- Generated with sections: [list sections]
- Estimated line count: ~[N] lines

### Rules files (.claude/rules/)
- code-standards.md — always loaded
- commit-conventions.md — always loaded
- testing.md — path-scoped: test files
- react-conventions.md — path-scoped: tsx/jsx/ts/js [if react or nextjs capability]
- magento-conventions.md — path-scoped: php/xml/phtml [if magento capability]
- theme-conventions.md — path-scoped: less/theme files [if magento-theme capability]

### Skills to DELETE (not needed for this stack):
- admin-config (requires: magento)
- plugin (requires: magento)
- ...

### Skills to KEEP:
- react-patterns (requires: react ✓)
- commit (always kept)
- ...

### Hooks to DELETE:
- core-vendor-guard.sh (requires: magento)
- ...

### Hooks to KEEP:
- react-lint-on-edit.sh (requires: react ✓)
- sync-manuals-check.sh (always kept)
- ...

### Agent updates:
- feature-implementer.md: remove skills [list]
- reviewer.md: remove skills [list]
- ...

### Other changes:
- config.sh: rewrite with project-specific paths
- settings.json: remove deleted hook references
- docs/manuals/05-concepts/: delete all concept docs (start fresh)
- CLAUDE.md.example: delete (replaced by generated CLAUDE.md)
- .claude/rules/*.md.example: delete (replaced by generated rules files)
- docs/examples/: delete (stack reference examples no longer needed)
```

Use **AskUserQuestion** to confirm: "Proceed with these changes?" with options "Yes, apply changes" / "No, let me adjust stack-config.json first".

Include this note in the confirmation prompt: "Approving will apply all changes and delete the toolchain backup from Phase 2. The backup only contains `.claude/` and `docs/` toolchain files — your project source code and working changes are not affected."

**Wait for confirmation before proceeding to Phase 5.**

## Phase 5: Prune skills

Read `.claude/stack-capabilities.json` to determine which skills to delete.

For each skill in the `skills` mapping:

1. Check if ALL of its required capabilities are in the project's capabilities list
2. If not, delete the entire skill directory: `rm -rf .claude/skills/<skill-name>/`
3. Record what was deleted

### Prune inapplicable rules files

Read the `rules` mapping from `.claude/stack-capabilities.json`. For each rules file listed:

1. Check if ALL of its required capabilities are in the project's capabilities list
2. If not, delete the file: `rm .claude/rules/<rule-name>`
3. Record what was deleted

Rules files listed in `$rules-always-kept` are never pruned.

## Phase 6: Update agent skill references

For each agent file in `.claude/agents/`:

1. Read the file
2. Find the `allowed_tools:` line in frontmatter (this lists skill names)
3. Remove any skill names that were deleted in Phase 5
4. Write the updated file

**Important:** Some agents reference skills by description text in the body, not just frontmatter. Search for deleted skill names in agent body text and remove or genericize those references.

## Phase 7: Prune hooks and update settings.json

### Delete inapplicable hooks

For each hook in the `hooks` mapping in `stack-capabilities.json`:

1. Check if ALL required capabilities are present
2. If not, delete the hook file: `rm .claude/hooks/<hook-name>`

### Update settings.json

1. Read `.claude/settings.json`
2. Remove any hook references that point to deleted hook files
3. Write the updated settings.json

## Phase 8: Rewrite config.sh

Rewrite `.claude/hooks/config.sh` with values from `stack-config.json`:

- Always set `COMMIT_PREFIX_PATTERN` from `stack-config.json` `commitPrefix` (e.g., `"PROJ-[0-9]+"`)
- If `magento` capability: set `VENDOR_NAMESPACE`, module paths
- If `react` capability: set `REACT_SRC`, `REACT_BUILD_JS`, `REACT_BUILD_CSS`
- If `graphql` capability: set `GQL_SCHEMA_GLOB`, `GQL_TEMPLATES_GLOB`, `GQL_TYPES_FILE`
- Comment out variables for absent capabilities with explanation

The config.sh should always source cleanly — missing variables should be empty strings, not undefined.

## Phase 9: Clean docs and finalize

1. **Delete concept docs**: `rm -rf docs/manuals/05-concepts/*` (these are stack-specific examples; the project will build its own over time)
2. **Delete example files**: Remove `CLAUDE.md.example` and all `.claude/rules/*.md.example` files (if they exist) since the real CLAUDE.md and rules files have been generated
3. **Delete stack examples**: `rm -rf docs/examples/` (these are reference examples for different stacks; no longer needed once the toolchain is configured for this project)
4. **Update docs/README.md**: Replace Magento-specific references with generic language appropriate to the detected stack
5. **Genericize onboarding**: Update `docs/manuals/00-getting-started/onboarding.md` to reference the actual project stack instead of Magento+React
6. **Delete stack-config.json**: Remove `.claude/stack-config.json` — it has been consumed and its values are now in CLAUDE.md, `.claude/rules/`, and config.sh. Keeping it would create a stale second source of truth.

### Write setup log

Create `.claude/setup-log.md` documenting:

- Date and detected capabilities
- Skills deleted and kept
- Rules files created, deleted, and kept
- Hooks deleted and kept
- Agent modifications made
- Any warnings or manual steps needed

### Clean up backup

Delete the filesystem backup created in Phase 2:

```bash
rm -rf "$BACKUP_DIR"
```

Report that the backup has been cleaned up.

### Final report

Present to the user:

1. Summary of what was configured
2. The generated CLAUDE.md path and list of `.claude/rules/` files created
3. Any manual steps needed (e.g., "verify the CLI wrapper command works")
4. Reminder: "Commit these changes to preserve the configured toolchain"
