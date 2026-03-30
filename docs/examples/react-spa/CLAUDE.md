# CLAUDE.md — Example (React SPA + Vite + REST)

> **This is an example CLAUDE.md** from a React single-page application built with Vite and consuming a REST API. Convention-specific rules live in `.claude/rules/`. When you run `/setup-project`, a project-specific CLAUDE.md and rules files will be generated to replace these examples.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Internal operations dashboard for warehouse management. React 19 SPA built with Vite, consuming a REST API backend. Uses React Router for client-side routing and TanStack Query for server state management.

## Commands

### Frontend (Node)

```bash
npm run dev           # Vite dev server (http://localhost:5173)
npm run build         # Production build → dist/
npm run lint          # ESLint check
npm run lint:fix      # ESLint auto-fix
npm run check-types   # TypeScript type check (no emit)
npm run preview       # Preview production build locally
```

- Node version: **v20** (see `.nvmrc`)
- Package manager: **npm** (`package-lock.json`)

### Install & Codegen

- Install command: `npm install`

**When to run:** Run the install command immediately after adding or removing dependencies or modifying `package.json`. Do not wait until the end of implementation — run it inline as soon as the triggering change is made.

### Smoke Test

- Dev server command: `npm run dev`
- Dev server URL: `http://localhost:5173`

## Architecture

### Frontend

```
src/
  pages/              ← Route-level page components (one per route)
  components/         ← Shared components
    ui/               ← Design system primitives (Button, Dialog, Table, etc.)
    forms/            ← Reusable form components with validation
    layout/           ← Shell, Sidebar, Header, etc.
  hooks/              ← Custom hooks
  api/                ← REST API client layer
    client.ts         ← Axios instance with interceptors (auth, error handling)
    endpoints/        ← One file per resource (orders.ts, inventory.ts, users.ts)
    types/            ← Request/response TypeScript types per resource
  stores/             ← Zustand stores for client-only state (UI, filters, preferences)
  utils/              ← Utility functions
  constants/          ← Shared constants and enum-like objects
  routes.tsx          ← React Router route definitions
  main.tsx            ← App entry point (providers, router)
```

**Routing:** React Router v7 with lazy-loaded page components. Auth-gated routes use a `<ProtectedRoute>` wrapper that checks the auth store.

**Server state:** TanStack Query manages all REST API data — caching, refetching, optimistic updates. Direct `fetch`/`axios` calls should not be used in components; always go through the hooks in `api/endpoints/`.

**Client state:** Zustand for UI-only state (sidebar open/closed, filter selections, user preferences). Do not put server data in Zustand — that belongs in TanStack Query's cache.

**Styling:** Tailwind CSS v4. Screen-reader-only text uses the `sr-only` class.

### API Layer

- **Base URL** configured via `VITE_API_BASE_URL` environment variable
- **Client** in `api/client.ts` — Axios instance with auth token injection and error interceptor
- **Endpoints** in `api/endpoints/` — each file exports TanStack Query hooks (`useOrders`, `useCreateOrder`, etc.)
- **Types** in `api/types/` — request/response shapes per resource, validated with Zod at the boundary

### Key Dependencies

- **TanStack Query v5** — Server state management (REST API caching, mutations, optimistic updates)
- **React Router v7** — Client-side routing with lazy loading
- **Zustand** — Lightweight client state (UI state only, not server data)
- **Tailwind CSS v4** — Utility-first styling; `sr-only` for screen-reader text
- **Radix UI** — Accessible UI primitives
- **Zod** — Runtime validation for API responses and form inputs
- **Axios** — HTTP client with interceptors

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

**`docs/plans/`** — Save `feature-planner` output here as `WMS-XXX-feature-name.md` before implementation begins. The `feature-implementer` agent takes a plan file as its input. Plans are living documents — update them if scope changes during implementation.

**`docs/features/`** — **Mandatory for complex features.** After implementing a multi-layer feature, create an architecture document here before creating the PR. Run `/document WMS-XXX` to generate it, then commit as the final commit on the branch. Without this document, future developers and AI agents cannot understand the feature's design without re-reading every file.

**`docs/manuals/`** — Structured AI tooling docs by intent (`getting-started/`, `workflows/`, `playbooks/`, `reference/`, `concepts/`). Start from `docs/manuals/README.md`. Do not edit these manually — they are maintained alongside the `.claude/` tool definitions.

### When to consult `docs/` before starting work

- **Picking up an existing feature** → read `docs/features/<WMS-XXX>.md` for architecture context before touching any code
- **Starting a new feature** → check `docs/plans/` for an existing plan before asking `feature-planner` to re-plan
- **Unsure which tool to use** → read `docs/manuals/reference/ai-tools-reference.md`
- **New to the repo** → start with `docs/manuals/getting-started/onboarding.md`
