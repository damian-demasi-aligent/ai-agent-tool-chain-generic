> **[EXAMPLE - Magento 2 + React]** This concept doc is from a Magento 2 + React project. It will be deleted when you run `/setup-project`. It serves as an example of the kind of architecture knowledge you should capture for your own project.

# The GraphQL schema as a contract

The GraphQL schema (`etc/schema.graphqls`) is the single source of truth for what data can flow between React and PHP. Three layers must stay in sync:

```
schema.graphqls  →  PHP Resolver  →  GQL template literal  →  TypeScript types  →  React component
```

When these drift apart, bugs are silent and hard to trace:

- **Field in schema but not in resolver:** GraphQL returns `null` without error.
- **Field in TypeScript types but not in schema:** Apollo silently drops it from the response.
- **Field in resolver but not in schema:** The data is computed but never reachable from the frontend.
- **Field expected by PHP but not sent by frontend:** PHP reads `null` or falls back to a default — the feature appears to work but with wrong data.

**Real-world example:** A frontend once embedded `store_code` inside a JSON string rather than as a top-level GraphQL field, so the PHP resolver's `$input['store_code']` always resolved to an empty string. Branch email routing silently fell back to the general contact email — the form "worked" but emails went to the wrong place. This kind of bug is invisible at the UI level.

**Prevention:** Run `/react-sync-types` after any GraphQL schema change. The `reviewer` agent also performs cross-boundary validation. Additionally, the `graphql-sync-check` pre-commit hook blocks commits that stage changes to only some of the three layers (schema, GQL templates, TypeScript types) without the others — catching the most common drift at commit time.
