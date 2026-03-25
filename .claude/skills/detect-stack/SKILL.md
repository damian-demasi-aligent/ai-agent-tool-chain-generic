---
name: detect-stack
description: Auto-detect the project's technology stack and generate a stack configuration file. Run this before /setup-project when adopting the toolchain into a new project.
disable-model-invocation: true
---

# Detect Stack

Auto-detect the technology stack for this project and write `.claude/stack-config.json`.

This skill uses a **two-layer detection strategy**: fast file-based heuristics first, then deep analysis via `@codebase-qa` subagents for details that can't be derived from file presence alone.

---

## Layer 1: File-based heuristics

Scan the project root and immediate subdirectories for framework indicators. Use Glob and Grep — do NOT run find or ls.

### Detection rules

Run these checks **in parallel** (multiple Glob/Grep calls in one message):

| Indicator | Check | Capability |
|---|---|---|
| Magento backend | `composer.json` contains `magento/framework` | `magento` |
| Magento theme | `app/design/frontend/` directory exists with layout XML or LESS files | `magento-theme` |
| Magento-React bridge | PHTML files containing `data-react-widget` | `magento-react-bridge` |
| Next.js | `package.json` contains `"next"` as dependency | `nextjs` + `react` |
| React (non-Next) | `package.json` contains `"react"` but NOT `"next"` | `react` |
| Vite | `vite.config.ts` or `vite.config.js` exists | bundler = vite |
| Webpack | `webpack.config.*` exists or `package.json` has webpack dependency | bundler = webpack |
| GraphQL schemas | `*.graphqls` files exist OR `schema.graphql` files exist | `graphql` |
| BigCommerce | `package.json` contains BigCommerce SDK references (`@bigcommerce/`) | `bigcommerce` |
| TypeScript | `tsconfig.json` exists | language = typescript |
| Tailwind | `tailwind.config.*` exists or `package.json` has tailwindcss | cssFramework = tailwind |
| LESS | `.less` files in theme directories | cssFramework = less |

### Derive initial capabilities list

Based on the heuristic results, build a preliminary list of capabilities from: `magento`, `magento-theme`, `magento-react-bridge`, `react`, `graphql`, `nextjs`, `bigcommerce`.

**Implied capabilities:**
- `magento-react-bridge` implies both `magento` and `react`
- `magento-theme` implies `magento`
- `nextjs` implies `react`

---

## Layer 2: Deep analysis via @codebase-qa subagents

After Layer 1 completes, spawn **up to 3 `codebase-qa` agents in parallel** to gather details that require reading and understanding code. Only spawn agents for capabilities that were detected in Layer 1.

### Agent 1: Backend structure (spawn if `magento` or `bigcommerce` detected)

```
Agent tool call:
  description: "Analyse backend structure"
  subagent_type: "codebase-qa"
  prompt: "Analyse the backend architecture of this project. Identify and report:

1. Backend framework and version (check composer.json or package.json)
2. Vendor namespace for custom modules (look at app/code/*/registration.php or src/ directories)
3. Custom module paths and list of module names
4. CLI wrapper command (bin/magento, manta, or other — check README, Makefile, docker-compose, or scripts/)
5. PHP quality tools and their commands (PHPCS, PHPStan, etc. — check composer.json scripts section)
6. Admin configuration patterns (check system.xml files for section naming)
7. Email sending patterns (check for TransportBuilder or mail service usage)
8. Plugin/observer naming conventions (check di.xml and events.xml files)

Return your findings as structured key-value pairs."
```

### Agent 2: Frontend structure (spawn if `react` or `nextjs` detected)

```
Agent tool call:
  description: "Analyse frontend structure"
  subagent_type: "codebase-qa"
  prompt: "Analyse the frontend architecture of this project. Identify and report:

1. Frontend framework and version (React, Next.js — check package.json)
2. Bundler (Vite, Webpack, Next.js built-in — check config files)
3. Source directory path (where components/pages live)
4. Build output directory path (dist/, build/, .next/, or custom)
5. Entry points pattern (how widgets/pages are discovered)
6. Component directory structure (flat, feature-grouped, atomic, etc.)
7. State management approach (Redux, Zustand, Context API, etc.)
8. CSS framework (Tailwind version, CSS modules, styled-components, LESS)
9. UI component library (@headlessui, shadcn, MUI, etc.)
10. Validation library (Zod, Yup, etc.)
11. Package manager and version (npm, yarn, pnpm — check lock files)
12. Node version (check .nvmrc, .node-version, or engines in package.json)
13. All dev/build/lint/typecheck commands from package.json scripts
14. Dev server smoke test details:
    - The command to start a dev server (from package.json `dev` script, or framework-specific: `python manage.py runserver`, `bin/rails server`, `php -S`, etc.)
    - The URL it listens on — check for custom port config in framework config files (next.config.js/mjs, vite.config.ts `server.port`, webpack `devServer.port`, manage.py `--port`, etc.) and `--port`/`-p` flags in the dev script. If no custom port, use the framework default.
    - The dependency install command (package manager install, `pip install -r requirements.txt`, `bundle install`, `composer install`, etc.)
    - Any codegen/generate command (from package.json scripts, Makefile targets, etc.)
    - A lightweight health check endpoint if one exists (e.g. `/api/health`, `/healthz`)

Return your findings as structured key-value pairs."
```

### Agent 3: Integration patterns (spawn if BOTH backend AND frontend detected)

```
Agent tool call:
  description: "Analyse integration patterns"
  subagent_type: "codebase-qa"
  prompt: "Analyse how frontend and backend communicate in this project. Identify and report:

1. API type: GraphQL, REST, or both
2. GraphQL schema locations (*.graphqls files, schema.graphql, etc.)
3. GraphQL client library (Apollo, urql, fetch-based, etc.)
4. GraphQL operations directory (where query/mutation template literals live)
5. TypeScript types file for API responses (where frontend types mirror backend schema)
6. REST endpoint patterns (if any — check webapi.xml or API route files)
7. Widget mounting convention (data attributes, DOM selectors, React portals, etc.)
8. Data attribute patterns (how backend passes data to frontend components)
9. Provider/singleton pattern for API access (how components call the API layer)

Return your findings as structured key-value pairs."
```

---

## Layer 3: Assemble and confirm

After all agents complete, merge their findings into a `.claude/stack-config.json` file with this structure:

```json
{
  "projectName": "<detected from package.json name or composer.json name>",
  "capabilities": ["<list of detected capabilities>"],
  "stack": {
    "backend": {
      "framework": "magento2 | bigcommerce | none",
      "version": "<detected version>",
      "language": "php | javascript | typescript",
      "vendorNamespace": "<detected namespace>",
      "modulePath": "<detected path>",
      "cliWrapper": "<detected CLI command>",
      "qualityCommands": {
        "codeStyle": "<detected command>",
        "staticAnalysis": "<detected command>",
        "codeStyleFix": "<detected command>"
      }
    },
    "frontend": {
      "framework": "react | nextjs",
      "bundler": "vite | webpack | nextjs-built-in",
      "language": "typescript | javascript",
      "nodeVersion": "<detected>",
      "packageManager": "yarn | npm | pnpm",
      "packageManagerVersion": "<detected>",
      "sourcePath": "<detected source directory>",
      "buildOutputPaths": ["<detected build output directories>"],
      "commands": {
        "dev": "<detected>",
        "build": "<detected>",
        "lint": "<detected>",
        "lintFix": "<detected>",
        "typeCheck": "<detected>"
      },
      "cssFramework": "tailwind | less | css-modules | styled-components",
      "uiLibrary": "<detected or null>",
      "validationLibrary": "<detected or null>"
    },
    "api": {
      "type": "graphql | rest | both",
      "schemaPath": "<detected schema location>",
      "clientLibrary": "apollo | urql | fetch",
      "gqlTemplatePath": "<detected GQL operations directory>",
      "typesFile": "<detected types file>"
    },
    "theme": {
      "type": "magento-luma | magento-hyva | none",
      "path": "<detected theme path>",
      "cssPreprocessor": "less | sass | none"
    }
  },
  "mainBranch": "<detected from git>",
  "commitPrefix": "<detected from branch naming or null>",
  "smokeTest": {
    "devCommand": "<command to start the dev server, e.g. 'yarn dev', 'python manage.py runserver', 'bin/rails server', 'go run .', or null if no dev server>",
    "devUrl": "<URL the dev server listens on, e.g. 'http://localhost:3000' — derived from framework config, CLI flags, or framework defaults>",
    "installCommand": "<command to install dependencies, e.g. 'yarn install', 'pip install -r requirements.txt', 'composer install', 'bundle install', or null>",
    "codegenCommand": "<command to run code generation, e.g. 'yarn codegen', 'yarn generate', or null if not applicable>",
    "healthEndpoint": "<lightweight endpoint to check, e.g. '/api/health', '/', or null — prefer an API health endpoint over a full page render when available>"
  },
  "docs": {
    "plans": "docs/plans",
    "features": "docs/features",
    "requirements": "docs/requirements",
    "manuals": "docs/manuals"
  }
}
```

**Rules for assembling:**
- Set sections to `null` when the capability is not detected (e.g., `"backend": null` for a pure React SPA)
- Use actual values discovered by agents, not generic defaults
- For `mainBranch`: run `git remote show origin | grep 'HEAD branch'` or check for `main`/`master`/`production` branches
- For `commitPrefix`: check recent git log for patterns like `ABC-123:` or `[ABC-123]`

### Present findings for confirmation

After writing the initial `stack-config.json`, present the findings to the developer:

1. Show the detected capabilities list
2. Show the key stack details (backend, frontend, API type, theme)
3. Highlight any values that could not be auto-detected (marked as `null` or `"unknown"`)
4. Use **AskUserQuestion** to ask the developer to confirm or correct:
   - "Is this stack configuration correct?"
   - Options: "Yes, looks correct" / "I need to make corrections"

If corrections are needed, ask follow-up questions for the specific values, then update `stack-config.json`.

### Final output

After confirmation, report:
- The saved config file path: `.claude/stack-config.json`
- The detected capabilities
- Next step: "Run `/setup-project` to generate CLAUDE.md and configure the toolchain for your project."
