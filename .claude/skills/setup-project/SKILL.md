---
name: setup-project
description: Configure the toolchain for the detected stack. Generates CLAUDE.md, prunes inapplicable skills/hooks, and updates agent configurations. Run /detect-stack first.
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

## Phase 3: Generate CLAUDE.md

Generate a project-specific `CLAUDE.md` by reading the stack config and scanning the actual project.

### Universal sections (always generated)

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
- `### Smoke Test` — if `smokeTest` section exists in stack-config and `smokeTest.devCommand` is not null. Document each non-null field from the `smokeTest` config as a key-value list:
  ```markdown
  ### Smoke Test
  - Dev server command: `yarn dev`
  - Dev server URL: `http://localhost:3000`
  - Install command: `yarn install`
  - Codegen command: `yarn codegen`
  - Health endpoint: `/api/health`
  ```
  Omit lines where the value is null (e.g., if there's no codegen command, don't include that line). If the entire `smokeTest` section is null or `devCommand` is null, skip this subsection entirely.

#### `## Architecture`

- **Conditional subsections based on capabilities:**
  - `### Frontend` — if `react` or `nextjs`. Describe source path, build output, entry points, component structure
  - `### Backend Modules` — if `magento`. List custom modules found in `modulePath`, describe standard structure
  - `### Theme` — if `magento-theme`. Describe theme path, parent theme, CSS preprocessor
  - `### React Widget Integration` — if `magento-react-bridge`. Describe mounting convention, data attributes, Block class
  - `### API Layer` — if `graphql` or `rest`. Describe schema locations, client library, provider pattern, types file
  - `### Key Dependencies` — always. List major dependencies from package.json/composer.json

#### `## Documentation (docs/)`

- Describe the `docs/` folder structure (plans, features, requirements, manuals)
- Reference the toolchain workflow

#### `## Testing`

- Scan for existing test framework (Vitest, Jest, PHPUnit)
- If none found, recommend based on stack (Vitest for Vite projects, Jest for Next.js, PHPUnit for Magento)
- Note co-location convention

#### `## Code Standards`

- Detect from config files: ESLint config, Prettier config, PHPCS config, EditorConfig
- List the detected standards and formatting rules

#### `## Commit Conventions`

- Use `mainBranch` and `commitPrefix` from stack config
- Include the message format and Co-Authored-By trailer
- Generate a **commit grouping order** appropriate to the stack:
  - **Magento + React**: registration → admin → GraphQL/backend → email → Magento frontend → React data → React UI
  - **Next.js**: API routes → data layer → components → pages → config
  - **React SPA**: API/data layer → components → pages/routes → config
  - **Pure Magento**: registration → admin → models/API → plugins/observers → email → layout/templates → LESS/JS

#### `## Conventions`

- **Conditional subsections per language/framework:**
  - `### React` — if `react`. Include component patterns, state management, error handling approach
  - `### PHP / Magento` — if `magento`. Include plugin naming, constructor style, copyright header
  - `### Next.js` — if `nextjs`. Include App Router patterns, server vs client components
  - `### Tooling` — always. Describe hook automation that's active for this stack
- **Always include `### Reuse Before Reimplementing`** as a subsection. Scan the project for reference features and build the lookup table showing "Need → Where to look first"

### Writing CLAUDE.md

1. Assemble all sections into a single CLAUDE.md document
2. Write to the project root, replacing the existing CLAUDE.md (which is the example)
3. Verify the file is well-formed markdown

## Phase 4: Dry-run presentation

**Before any destructive changes**, present a summary of everything that will be modified:

```
## Setup Summary

### CLAUDE.md
- Generated with sections: [list sections]

### Skills to DELETE (not needed for this stack):
- admin-config (requires: magento)
- plugin (requires: magento)
- ...

### Skills to KEEP:
- react-patterns (requires: react ✓)
- commit-pr (always kept)
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

- If `magento` capability: set `VENDOR_NAMESPACE`, module paths
- If `react` capability: set `REACT_SRC`, `REACT_BUILD_JS`, `REACT_BUILD_CSS`
- If `graphql` capability: set `GQL_SCHEMA_GLOB`, `GQL_TEMPLATES_GLOB`, `GQL_TYPES_FILE`
- Comment out variables for absent capabilities with explanation

The config.sh should always source cleanly — missing variables should be empty strings, not undefined.

## Phase 9: Clean docs and finalize

1. **Delete concept docs**: `rm -rf docs/manuals/05-concepts/*` (these are stack-specific examples; the project will build its own over time)
2. **Delete setup prompts**: Remove `docs/prompts/generate-claude-md-for-new-project.md` and `docs/prompts/review-claude-toolchain-for-new-project.md` (replaced by `/detect-stack` + `/setup-project`)
3. **Delete CLAUDE.md.example**: Remove the example file (if it exists) since the real CLAUDE.md has been generated
4. **Update docs/README.md**: Replace Magento-specific references with generic language appropriate to the detected stack
5. **Genericize onboarding**: Update `docs/manuals/00-getting-started/onboarding.md` to reference the actual project stack instead of Magento+React
6. **Delete stack-config.json**: Remove `.claude/stack-config.json` — it has been consumed and its values are now in CLAUDE.md and config.sh. Keeping it would create a stale second source of truth.

### Write setup log

Create `.claude/setup-log.md` documenting:

- Date and detected capabilities
- Skills deleted and kept
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
2. The generated CLAUDE.md path
3. Any manual steps needed (e.g., "verify the CLI wrapper command works")
4. Reminder: "Commit these changes to preserve the configured toolchain"
