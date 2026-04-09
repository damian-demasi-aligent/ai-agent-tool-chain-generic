# CLAUDE.md — Example (Next.js + React + Apollo)

> **This is an example CLAUDE.md** from a Next.js 15 App Router project with Apollo Client for GraphQL data fetching. Convention-specific rules live in `.claude/rules/`. When you run `/setup-project`, a project-specific CLAUDE.md and rules files will be generated to replace these examples.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

E-commerce storefront built with Next.js 15 (App Router) and React 19. Uses Apollo Client 4 for GraphQL data fetching from a headless CMS backend. Deployed via Vercel.

- **Monorepo:** Yarn 4 workspaces with Nx for task orchestration
- **Packages:** `apps/storefront` (Next.js app), `libs/ui` (shared components), `libs/graphql` (operations + codegen), `libs/utils` (shared utilities), `libs/config` (shared config)

## Domain Glossary

E-commerce storefront serving a multi-brand retail group with locale-aware catalogue and promotions.

- **Catalogue** — The product data hierarchy (categories → products → variants). Maps to GraphQL `Category` and `Product` types; sourced from the headless CMS.
- **Codegen** — GraphQL Code Generator (`yarn codegen`). Reads `.graphql` operation files and the remote schema, outputs typed hooks and types into `libs/graphql/src/generated/`.
- **ISR (Incremental Static Regeneration)** — Next.js re-generation strategy for product and category pages. Configured via `revalidate` in route segment config.
- **Locale** — An `{language}-{country}` pair (e.g. `en-AU`, `fr-FR`). Determines translations, currency, and which catalogue view to query. Resolved in middleware and passed via `next-intl`.
- **Operation** — A `.graphql` file in `libs/graphql/src/operations/` defining a query, mutation, or fragment. Codegen turns each into a typed Apollo hook.
- **PDP / PLP** — Product Detail Page / Product Listing Page. Route groups `(shop)/products/[slug]` and `(shop)/categories/[...path]`.
- **Provider Stack** — The nested Context providers in `app/layout.tsx` (Apollo, intl, auth, theme). Order matters — Apollo must wrap everything that uses GraphQL hooks.
- **RSC (React Server Component)** — Default component type in the App Router. Uses `apollo-rsc` for server-side data fetching. Add `'use client'` only when interactivity is needed.
- **Route Group** — Next.js `(parenthesised)` directory that applies a shared layout without affecting the URL. `(shop)` = public pages, `(account)` = authenticated pages.
- **Variant** — A purchasable SKU within a product (e.g. size/colour combination). Maps to `ProductVariant` GraphQL type.

## Commands

### Frontend (Node)

Run from the monorepo root:

```bash
yarn dev              # Next.js dev server (http://localhost:3000)
yarn build            # Production build
yarn lint             # ESLint check across all packages
yarn lint:fix         # ESLint auto-fix
yarn check-types      # TypeScript type check (no emit)
yarn codegen          # GraphQL Codegen — regenerates types from schema
```

- Node version: **v20** (see `.nvmrc`)
- Package manager: **Yarn v4** (`yarn.lock`)

### Install & Codegen

- Install command: `yarn install`
- Codegen command: `yarn codegen`

**When to run:** Run the install command immediately after adding or removing dependencies or modifying any `package.json`. Run the codegen command immediately after modifying `.graphql` files or the GraphQL schema. Do not wait until the end of implementation — run these inline as soon as the triggering change is made.

### Smoke Test

- Dev server command: `yarn dev`
- Dev server URL: `http://localhost:3000`
- Health endpoint: `/api/health`

## Architecture

### Frontend

```
apps/storefront/
  app/                  ← Next.js App Router pages and layouts
    (shop)/             ← Route group for shop pages (products, categories, cart)
    (account)/          ← Route group for authenticated account pages
    api/                ← API routes (health, webhooks, revalidation)
    layout.tsx          ← Root layout with providers
  components/           ← App-specific components
  hooks/                ← App-specific hooks
  middleware.ts         ← Auth, locale, and redirect middleware

libs/
  ui/src/               ← Shared UI component library (design system)
  graphql/src/
    operations/         ← .graphql files (queries, mutations, fragments)
    generated/          ← GraphQL Codegen output (types + typed hooks)
    client.ts           ← Apollo Client singleton configuration
  utils/src/            ← Shared utility functions
  config/src/           ← Shared configuration (env vars, feature flags)
```

**Routing:** App Router with route groups. `(shop)` contains public pages, `(account)` contains authenticated pages behind middleware.

**Data fetching:** Server Components use `apollo-rsc` for server-side queries. Client Components use generated typed hooks from `libs/graphql/generated/`.

**Styling:** Tailwind CSS v4 with the design system in `libs/ui`. Screen-reader-only text uses the `sr-only` class.

### API Layer

- **GraphQL schema** defined by the headless CMS (external)
- **Operations** in `libs/graphql/src/operations/` as `.graphql` files
- **Codegen** generates TypeScript types and typed Apollo hooks into `libs/graphql/src/generated/`
- **Client** configured in `libs/graphql/src/client.ts` — uses `HttpLink` for SSR and `BatchHttpLink` for client-side

### Key Dependencies

- **Apollo Client 4** — GraphQL data fetching with SSR support
- **Tailwind CSS v4** — Utility-first styling; `sr-only` for screen-reader text
- **Radix UI** — Accessible UI primitives (Dialog, Popover, Select, etc.)
- **Zod** — Runtime validation for forms and API responses
- **next-intl** — i18n with App Router integration
- **Nx** — Monorepo task orchestration and caching

## Documentation (`docs/`)

The `docs/` folder is an active part of the development workflow, not just a reference archive. Agents, skills, and commands read from and write to it during normal feature work.

```
docs/
  requirements/   ← Jira tickets and specs; input for feature-planner agent
  plans/          ← Implementation plans produced by feature-planner; input for feature-implementer
  features/       ← Architecture documents for completed features (Mermaid diagrams, data flows)
  manuals/        ← Workflow guides for using Claude Code tools effectively
  scripts/        ← Workflow utility scripts (Jira fetcher, etc.)
```

### How each folder is used

**`docs/requirements/`** — Jira ticket content (description, comments, mockup images) fetched via `docs/scripts/fetch-jira-ticket.sh`. The `feature-planner` agent reads these to understand scope — including attached images for UI placement. To fetch a ticket: `./docs/scripts/fetch-jira-ticket.sh <TICKET-ID>` (reads credentials from `.env.development` — see `.env.development.example`)

**`docs/plans/`** — Save `feature-planner` output here as `PROJ-XXX-feature-name.md` before implementation begins. The `feature-implementer` agent takes a plan file as its input. Plans are living documents — update them if scope changes during implementation.

**`docs/features/`** — **Mandatory for complex features.** After implementing a multi-layer feature, create an architecture document here before creating the PR. Run `/document PROJ-XXX` to generate it, then commit as the final commit on the branch. Without this document, future developers and AI agents cannot understand the feature's design without re-reading every file.

**`docs/manuals/`** — Structured AI tooling docs by intent (`getting-started/`, `workflows/`, `playbooks/`, `reference/`, `concepts/`). Start from `docs/manuals/README.md`. Do not edit these manually — they are maintained alongside the `.claude/` tool definitions.

### When to consult `docs/` before starting work

- **Picking up an existing feature** → read `docs/features/<PROJ-XXX>.md` for architecture context before touching any code
- **Starting a new feature** → check `docs/plans/` for an existing plan before asking `feature-planner` to re-plan
- **Unsure which tool to use** → read `docs/manuals/reference/ai-tools-reference.md`
- **New to the repo** → start with `docs/manuals/getting-started/onboarding.md`
