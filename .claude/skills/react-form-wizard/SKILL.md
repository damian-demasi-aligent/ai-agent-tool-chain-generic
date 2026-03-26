---
name: react-form-wizard
description: Create a new multi-step form wizard for "$ARGUMENTS".
argument-hint: Name of the form (e.g., "TrialForm", "ContactForm")
disable-model-invocation: true
metadata:
  capabilities: [react]
---

Create a new multi-step form wizard for "$ARGUMENTS".

Before starting, **read CLAUDE.md** for the project's frontend source paths (Architecture section) and existing widgets list. Also read the project rules (`.claude/rules/`) for React conventions and the Reuse Before Reimplementing table (especially multi-step React form and widget entry point entries).

## Step 1: Study existing patterns

Read the existing multi-step form implementations and shared wizard infrastructure from the paths listed in the Reuse Before Reimplementing table in `.claude/rules/`. Also read:
- The shared `FormWizard` component (search the components directory from CLAUDE.md Architecture)
- The types file (from CLAUDE.md Architecture) — how form input/response types are defined
- An existing form's GQL mutation file — how form submissions map to GraphQL mutations

## Step 2: Create the form

1. Create a component directory under the components path (from CLAUDE.md Architecture) with:
   - Main form component that uses `FormWizard`
   - Individual step components (ask me how many steps and what fields)
   - Proper TypeScript interfaces for form state at each step

2. Add form input/response types to the project's shared types file (from CLAUDE.md Architecture) following the existing form input/response patterns.

3. If this form submits via GraphQL, scaffold the GQL mutation and provider method (check CLAUDE.md Architecture for the GQL and providers directories).

## Step 3: Wire up

- Ask me which widget this form should mount in (existing or new widget).
- Integrate with GoogleRecaptcha if the form submits user data (follow existing recaptcha patterns).

## Step 4: Verify

Run the project's type-check and lint commands from CLAUDE.md Commands section.
