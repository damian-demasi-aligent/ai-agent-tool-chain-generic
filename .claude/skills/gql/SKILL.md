---
name: gql
description: Scaffold a GraphQL operation for "$ARGUMENTS". Creates the React data layer (GQL template, provider method, TypeScript types). If the PHP schema and resolver are also needed, scaffolds those too.
argument-hint: Name or description of the GraphQL operation (e.g., "productAvailability query", "submitTrialEnquiry mutation")
disable-model-invocation: true
metadata:
  capabilities: [graphql]
---

Scaffold a GraphQL operation for "$ARGUMENTS".

Before starting, **read CLAUDE.md** for the project's vendor namespace, module paths, frontend Architecture (GQL directory, providers, types file, main provider entry point), and conventions.

## Step 1: Determine scope

Check whether the PHP schema already defines the operation described in $ARGUMENTS:

1. Search `etc/schema.graphqls` files in the custom modules (path from CLAUDE.md) for the operation name or a closely matching type.
2. **If the schema already exists** → skip to Step 3 (React side only).
3. **If the schema does not exist** → proceed with Step 2 (full-stack: PHP + React).

If you cannot determine this from the codebase, ask the user: "Does the GraphQL schema and resolver already exist, or do you need me to create those too?"

## Step 2: PHP side (only when schema does not exist)

Determine which module this belongs to (check CLAUDE.md module inventory). Then:

1. Add the operation to `etc/schema.graphqls` following the existing pattern (Query or Mutation type, input/output types with `@resolver` directive).
2. Create a Resolver class in `Model/Resolver/` implementing `\Magento\Framework\GraphQL\Query\ResolverInterface`.
3. If new input validation is needed, add validation rules following existing patterns.

**Show me the proposed schema.graphqls changes and resolver signature before writing files.**

## Step 3: React side

Using the paths from CLAUDE.md Architecture section:

1. Study the existing patterns in the GQL directory — these use `gql` tagged template literals from the project's GraphQL client. Read an existing operation for reference.
2. Create the query/mutation file in the GQL directory following those patterns.
3. Add a typed provider method in the matching providers file (or create a new provider if this is a new domain).
4. Add TypeScript types to the shared types file matching the GraphQL input/output shape. Follow the project's API return type convention from CLAUDE.md Conventions.
5. Export from the GQL barrel index if needed.
6. Wire the provider into the main provider entry point if it's a new provider.

## Step 4: Verify

Run the project's type-check command from CLAUDE.md Commands section to validate all types align.
