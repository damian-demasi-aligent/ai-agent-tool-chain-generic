---
name: plugin
description: Create a Magento 2 Plugin (Interceptor) for "$ARGUMENTS".
argument-hint: Target class and method (e.g., "Magento\Catalog\Model\Product::getPrice")
disable-model-invocation: true
metadata:
  capabilities: [magento]
---

Create a Magento 2 Plugin (Interceptor) for "$ARGUMENTS".

Before starting, **read CLAUDE.md** for the project's vendor namespace. Also read the project rules (`.claude/rules/magento-conventions.md`) for the plugin naming convention and PHP conventions.

## Step 1: Understand the target

1. Identify the class and method to intercept. Search `vendor/` for the target class to understand its method signatures.
2. Determine the plugin type needed: `before`, `after`, or `around`.

## Step 2: Study existing plugins

Read examples from the project:
- Look at `Plugin/` directories under the custom modules (path from CLAUDE.md) for naming and structure conventions
- Check `etc/di.xml` files for how plugins are registered (type name, plugin name, sortOrder)

## Step 3: Create the plugin

1. Determine which module this belongs in (check CLAUDE.md module inventory).
2. Create the Plugin class in that module's `Plugin/` directory:
   - Follow Magento naming: `[TargetAction]Plugin.php`
   - Use correct method signature (`before[Method]`, `after[Method]`, or `around[Method]`)
   - The first parameter is always the `$subject` (the intercepted class instance)
   - For `before` plugins: return an array of the original method's arguments
   - For `after` plugins: receive and return the `$result`
   - For `around` plugins: receive a `callable $proceed` and call it
   - Follow the PHP conventions from `.claude/rules/magento-conventions.md` (copyright header, strict_types, promoted properties)
3. Register in the module's `etc/di.xml` (or `etc/frontend/di.xml` for frontend-only):
   ```xml
   <type name="Target\Class\Name">
       <plugin name="<prefix>_descriptive_name" type="<Vendor>\<Module>\Plugin\PluginClass" sortOrder="10"/>
   </type>
   ```
   Use the plugin naming convention from `.claude/rules/magento-conventions.md`.

## Step 4: Verify

Run the project's PHP quality commands from CLAUDE.md Commands section and report any issues.
