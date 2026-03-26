---
name: observer
description: Create a Magento 2 Observer for "$ARGUMENTS".
argument-hint: Event name and description (e.g., "sales_order_place_after — update custom attribute on order")
disable-model-invocation: true
metadata:
  capabilities: [magento]
---

Create a Magento 2 Observer for "$ARGUMENTS".

Before starting, **read CLAUDE.md** for the project's vendor namespace, module inventory, and PHP quality commands. Also read the project rules (`.claude/rules/magento-conventions.md`) for PHP conventions and the plugin naming convention (observers follow a similar prefix pattern).

## Step 1: Understand the event

1. Parse the event name and intent from $ARGUMENTS. Examples:
   - `sales_order_place_after — update custom attribute on order` → event `sales_order_place_after`, purpose: update attribute
   - `checkout_cart_add_product_complete — log cart additions` → event `checkout_cart_add_product_complete`
   - Just a description like `hide stock status when product has hide_price attribute` → search vendor for the right event
2. If only a description was given (no event name), search `vendor/magento/` for relevant events:
   ```bash
   grep -r "eventManager->dispatch" vendor/magento/module-* --include="*.php" -l
   ```
   Then read the matched files to find the event that provides the data the observer needs.
3. Read the event dispatch call in vendor to understand:
   - What data is passed to the observer (the `$observer->getEvent()->getData()` keys)
   - What scope it fires in (global, frontend, adminhtml)

## Step 2: Determine scope

Choose the correct `events.xml` location based on where the observer should fire:

| Scope | File path |
|---|---|
| All areas (global) | `etc/events.xml` |
| Frontend only | `etc/frontend/events.xml` |
| Admin only | `etc/adminhtml/events.xml` |

Prefer the narrowest scope that satisfies the requirement. Only use global if the observer must run in both frontend and admin.

## Step 3: Study existing observers

Search for existing observers in the project's custom modules (`Observer/` directories). Read examples to follow established conventions:

Key conventions:
- Observers implement `ObserverInterface` with a single `execute(Observer $observer): void` method
- Follow the PHP conventions from `.claude/rules/magento-conventions.md` (copyright header, strict_types, promoted readonly properties)
- Namespace: `<Vendor>\<Module>\Observer\<ObserverName>`
- Observer names in `events.xml` use `snake_case` descriptive names — check existing `events.xml` files for the naming prefix convention
- Use early returns for guard clauses

## Step 4: Create the observer

1. Determine which module this belongs in (check CLAUDE.md module inventory — choose based on the domain).
2. Create the Observer class in that module's `Observer/` directory:
   - File name: `<DescriptiveAction>Observer.php` (or just `<DescriptiveAction>.php` — match the naming style of existing observers in the same module)
   - Implement `Magento\Framework\Event\ObserverInterface`
   - Inject dependencies via constructor with promoted readonly properties
   - Access event data via `$observer->getEvent()->getData('key')` — use the keys identified in Step 1
   - Use early returns for guard clauses
3. Register in the module's `events.xml` (at the correct scope from Step 2):
   ```xml
   <?xml version="1.0"?>
   <config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xsi:noNamespaceSchemaLocation="urn:magento:framework:Event/etc/events.xsd">
       <event name="the_event_name">
           <observer name="<prefix>_descriptive_observer_name"
                     instance="<Vendor>\<Module>\Observer\ObserverClass"/>
       </event>
   </config>
   ```
   If the `events.xml` file already exists, add the new `<event>` entry — do not overwrite existing observers.

## Step 5: Verify

Run the project's PHP quality commands from CLAUDE.md Commands section on the new files. Report any issues found. If the commands are not available in this environment, list what manual checks should be run before committing.
