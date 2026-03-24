---
name: react-sync-types
description: Synchronise TypeScript types with GraphQL schema definitions. Use when GraphQL schemas have changed and React types need updating.
disable-model-invocation: true
metadata:
  capabilities: [graphql, react]
---

# Sync GraphQL Schema → TypeScript Types

Before starting, **read CLAUDE.md** to identify the project's GraphQL schema files, TypeScript types file, GQL template literal directory, and provider directory. Also check whether the project uses codegen or maintains types by hand.

## Step 1: Find schema changes

If $ARGUMENTS is provided, check that specific module. Otherwise, scan all custom modules for `schema.graphqls` files (check CLAUDE.md for the module base path).

## Step 2: Compare with TypeScript

Read the project's shared TypeScript types file and the GQL template literals (locations documented in CLAUDE.md Architecture section).

For each GraphQL operation, verify:

1. The GQL template literal matches the schema (field names, types, required/optional)
2. The TypeScript types match the GQL operation's input/output shape
3. The provider method uses the correct types

## Step 3: Report mismatches

List each discrepancy as:

- **Schema field** → **TypeScript type** — what's different
- Whether it's a missing field, wrong type, or optional/required mismatch

Ask before making changes — some mismatches may be intentional (e.g. the React side only uses a subset of fields).

## Step 4: Fix and verify

After applying agreed changes, run the project's type-check command (documented in CLAUDE.md Commands section) to confirm everything compiles.
