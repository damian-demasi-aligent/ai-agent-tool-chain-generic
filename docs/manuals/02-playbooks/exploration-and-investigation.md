# Exploration and Investigation

> How to understand unfamiliar parts of the codebase and assess the impact of changes before making them.

For canonical command syntax and inventory, use [`../reference/ai-tools-reference.md`](../reference/ai-tools-reference.md).

---

## Understanding how something works

### "How does X work?"

Use the `codebase-qa` agent for any question that requires reading multiple files to answer. It traces full chains — from React component through GraphQL to PHP resolver — and cites file paths and line numbers.

```
@codebase-qa How does [feature] work in the [Module] form?
@codebase-qa Where is the [ClassName] ViewModel used and what does it provide?
@codebase-qa How does the [widget-name] widget get product data?
```

Replace bracketed placeholders with your project's actual module and class names (see CLAUDE.md → Custom Magento Modules and Architecture).

> `codebase-qa` reads the actual source — it never guesses. If something isn't clear from the code, it says so.

### "What does this module do?"

```
/module-overview <VendorNamespace>_<ModuleName>
```

Check CLAUDE.md → Architecture → Custom Magento Modules for the full list of available modules.

Returns a structured summary: files present, what the module does, how it integrates with other modules, any GraphQL schema extensions. Useful as a first pass before diving deeper.

### "What does this layout override actually change?"

```
/layout-diff Magento_Catalog
/layout-diff catalog_product_view
```

Finds the theme override in the project's theme directory (from CLAUDE.md → Architecture → Magento Theme), locates the original in `vendor/`, and explains what changed: added/removed/moved blocks, template swaps, and any maintainability concerns (e.g. full-file copies instead of surgical `referenceBlock` changes).

---

## Assessing the impact of a change

### Before modifying a type, schema, or shared file

```
@impact-analyser app/code/<VendorNamespace>/<Module>/etc/schema.graphqls
@impact-analyser <ProviderSingleton>.ts
@impact-analyser <InterfaceName>
```

The impact analyser traces the full dependency graph:
- For GraphQL schema changes: resolver → GQL template literal → provider method → TypeScript types → component usage
- For React components: imports, widget entry point, PHTML mount, context providers
- For PHP classes: `di.xml` references, layout XML, templates, constructor injection

Reports **direct dependencies** (must change) and **indirect dependencies** (may need updating), plus a risk assessment.

> Run this before any change to shared infrastructure like the GraphQL provider singleton, TypeScript types file, or a GraphQL schema type used by multiple resolvers (see CLAUDE.md → Architecture for these file locations).

### Checking GraphQL ↔ TypeScript alignment

```
/react-sync-types
/react-sync-types <VendorNamespace>_<Module>
```

Scans all `schema.graphqls` files (or a specific module) and compares them against the hand-maintained TypeScript types file and GQL template literals (paths from CLAUDE.md → Architecture). Reports mismatches — missing fields, wrong types, optional/required differences — before proposing fixes.

Use this after:
- Merging a branch that changed GraphQL schema
- Pulling from `production` when you're unsure if types are still in sync
- Before starting a feature that extends an existing GraphQL operation

---

## Exploring the React ↔ Magento boundary

The integration between PHP and React is a common source of confusion. The full chain for any widget is:

```
Layout XML handle
  → declares Block class → references .phtml template
    → .phtml renders <div data-react-widget="name" data-config-attr="...">
      → Vite bundle: widgets/name-widget.tsx finds the div via querySelectorAll
        → mounts React component tree
          → component reads data attributes for config
            → calls the GraphQL provider singleton for dynamic data
              → Apollo Client → POST /graphql → PHP resolver
```

To trace this chain for a specific widget:
1. Find the widget entry point: `Glob src/app/widgets/*`
2. Find its mount element: search for `data-react-widget="name"` in `.phtml` files
3. Find the layout XML that renders that template
4. Read the `@codebase-qa` agent for a guided walkthrough

---

## Reading feature documentation

The `docs/features/` folder contains architecture documents for implemented features. Each document includes:
- Architecture overview with Mermaid diagrams
- Data flow sequences for key operations
- Admin configuration paths
- Deployment steps

These are the fastest way to understand a feature before reading the code. Start here when assigned to maintain or extend an existing feature.

---

## Exploring admin configuration

Most feature toggles and content are configured in the admin under a shared section (see CLAUDE.md → Conventions → PHP / Magento for the admin config section name and convention).

To understand what admin config a feature uses, read its `etc/adminhtml/system.xml` and look for `ScopeConfigInterface::getValue()` calls in the model.

```
/module-overview <VendorNamespace>_<Module>
```

...then read `etc/adminhtml/system.xml` directly to see all available config fields.
