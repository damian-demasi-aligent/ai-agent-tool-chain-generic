---
name: module-overview
description: Give me a concise overview of the Magento module "$ARGUMENTS".
argument-hint: Module name (e.g., "VendorName_ModuleName", "Magento_Catalog")
disable-model-invocation: true
metadata:
  capabilities: [magento]
---

Give me a concise overview of the Magento module "$ARGUMENTS".

Before starting, **read CLAUDE.md** for the project's vendor namespace and theme path.

Search for it in both the custom modules directory and the theme overrides directory (paths from CLAUDE.md).

For each location found, report:
- What files exist (layout XML, templates, LESS, JS, PHP classes)
- What the module does based on its code (Block classes, Models, Plugins, etc.)
- How it integrates with other modules or the frontend layer (if at all)
- Any GraphQL schema extensions

Keep the output concise and structured. Do not read every file — scan the structure and read only the key files (etc/module.xml, registration.php, main Block/Model classes, layout XML).
