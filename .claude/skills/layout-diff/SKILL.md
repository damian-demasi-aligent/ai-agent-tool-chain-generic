---
name: layout-diff
description: Analyze the theme layout override for "$ARGUMENTS" and explain what it changes.
argument-hint: Layout handle or module name (e.g., "catalog_product_view", "Magento_Catalog")
disable-model-invocation: true
metadata:
  capabilities: [magento-theme]
---

Analyze the theme layout override for "$ARGUMENTS" and explain what it changes.

Before starting, **read CLAUDE.md** for the project's theme path.

1. Find the theme override file under the project's theme directory (from CLAUDE.md) that matches "$ARGUMENTS" (it could be a module name like "Magento_Catalog" or a specific layout handle like "catalog_product_view").

2. Find the corresponding original layout XML in `vendor/magento/` (or the relevant vendor module).

3. Compare them and explain:
   - What blocks/containers are added, removed, or moved
   - What template overrides are applied
   - Whether the override is minimal (surgical referenceBlock changes) or a full file replacement
   - Any potential conflicts with other layout handles or third-party modules

4. If the override is a full file copy rather than surgical changes, suggest how it could be refactored to use `referenceBlock`/`referenceContainer` for better maintainability during Magento upgrades.
