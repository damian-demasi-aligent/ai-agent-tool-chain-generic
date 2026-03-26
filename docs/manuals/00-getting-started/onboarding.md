# Onboarding — Development with Claude Code

> New to this repo? Read this first. It covers the project structure, the key mental models you need, and how to use the AI tooling to get up to speed quickly.

---

## What this project is

Read **CLAUDE.md** at the repo root for the full project overview, including the technology stack, directory structure, and key dependencies. CLAUDE.md and `.claude/rules/` are the sources of truth for project-specific details and conventions. Rules files load automatically based on the files you're working with.

---

## Repository structure

Check CLAUDE.md's **Architecture** section for the full directory tree, including:

- **Backend modules/services** — location, naming, and structure
- **Frontend source** (if applicable) — framework, source path, build output
- **Theme** (if applicable) — path, parent theme, CSS preprocessor
- **API layer** — GraphQL schemas, REST endpoints, client operations
- **docs/** — feature documentation, implementation plans, workflow scripts, and these manuals

---

## Key mental models

### 1. Understand the layer boundaries

Read CLAUDE.md's Architecture section to understand how the project's layers connect. Key questions to answer:

- Where does backend code live? Where does frontend code live?
- How does data flow from user interaction to the backend and back?
- What is the API contract between frontend and backend (GraphQL, REST, both)?
- How are frontend components mounted or routed?

### 2. The API contract

Frontend and backend communicate through a defined API layer. Check CLAUDE.md for the specific approach (GraphQL, REST, or both), where schemas are defined, and how types are synchronised between layers.

### 3. Build output is NOT committed

Compiled JS/CSS bundles are **not committed to git** — they are produced by the deployment pipeline. A pre-commit hook automatically removes any staged build artifacts. Run the build command (from CLAUDE.md → Commands) locally for development and testing only.

### 4. Pre-commit hooks run quality checks

The project may have hooks that run code quality checks (linting, static analysis) on staged files before every commit. Check CLAUDE.md → Commands and CLAUDE.md → Conventions → Tooling for what runs automatically vs. what you need to run manually.

---

## Getting oriented with AI tools

These are the tools best suited for orientation when you're new to a part of the codebase.

### Ask "how does X work?"

```
@codebase-qa How does the [feature] form submit to the backend?
```

The `codebase-qa` agent reads actual source files and traces the full chain with file paths and line references.

### Read feature documentation

The `docs/features/` folder contains architecture documents for implemented features. These include Mermaid flow diagrams showing the full frontend-backend interaction. Start here when picking up an existing feature.

### Explore a module or component

Use targeted slash commands if available for your stack (check `docs/manuals/03-reference/ai-tools-reference.md` for the full inventory):

- `/module-overview <Module>` — summarise a backend module (Magento projects)
- `/layout-diff <Module>` — compare a theme override vs. vendor original (Magento projects)

---

## Recommended first steps

1. **Read CLAUDE.md** thoroughly — it documents the project's architecture, conventions, and reference features
2. Read `docs/features/` — existing architecture documents show fully documented features with every layer described
3. Browse `docs/manuals/05-concepts/` — architectural insights about how the codebase works under the surface
4. Ask `@codebase-qa` anything you're unsure about — it reads the source and answers with file references
5. Check CLAUDE.md's **Conventions → Reuse Before Reimplementing** section for the cleanest full-stack reference examples

---

## How the AI tooling is structured

The `.claude/` directory contains agents, skills, and hooks. These are **project-portable** — they contain generic methodology and patterns, not hardcoded project details. Project-specific information lives in:

- **`CLAUDE.md`** — architecture, file paths, conventions, commands, and reuse references. All skills, agents, and hooks read from this file.
- **`.claude/hooks/config.sh`** — project-specific paths for shell hook scripts. Each hook sources this file automatically.

When adopting this toolchain in a new project, run `/detect-stack` then `/setup-project` — they configure everything automatically.

---

## Local development

Check CLAUDE.md's **Commands** section for the exact commands for this project. The typical structure is:

```bash
# Node (use nvm if .nvmrc exists)
nvm use

# Install dependencies
<package-manager> install

# Dev server
<dev-command>

# Production build
<build-command>

# Quality checks
<lint-command>       # Linting
<type-check-command> # Type checking
```

Check CLAUDE.md → Commands for backend-specific CLI commands (database migrations, cache management, etc.).
