---
description: PHP and Magento 2 module patterns, plugin naming, email conventions, and reuse references
paths:
  - "**/*.php"
  - "**/*.xml"
  - "**/*.phtml"
---

# PHP / Magento Conventions

- Aligent copyright header on all PHP files: `/** Aligent * Copyright (c) <YEAR> Aligent. (https://www.aligent.com.au) */`
- `declare(strict_types=1)` on all PHP files
- Constructor uses PHP 8.1 promoted `private readonly` properties
- Admin config section: all custom config lives under a shared `country_care_group` section (defined in Catalog module) with module-specific groups. Only create a new section if genuinely needed — almost all config goes into the shared one.
- Pre-commit hooks (PHPCS + PHPStan) run via `manta` wrapper — if hooks fail in your environment, check the `manta` command availability
- For Magento template overrides, always verify the correct module path (e.g., Magento_CustomerCustomAttributes vs Magento_Customer)
- When debugging frontend issues where code changes don't take effect, check for stale compiled/bundled assets early in the debugging process

## Reuse Before Reimplementing

**Full-stack reference features:** `Hire` and `Service` are the most complete examples — each covers module registration, admin config, GraphQL schema + resolver, email sending, React multi-step form, widget entry point, and Magento layout wiring. Use them as the primary analogue for any new form-to-backend feature.

Before implementing any feature, search for existing examples by technical need:

| Need                        | Where to look first                                                                |
| --------------------------- | ---------------------------------------------------------------------------------- |
| Transactional email         | `Service/Model/ServiceEnquiry.php`, `Hire/Model/HireEnquiry.php`                   |
| GraphQL mutation + resolver | `Hire/Model/Resolver/HireEnquiry.php`, `Service/Model/Resolver/ServiceEnquiry.php` |
| Admin config fields         | `Hire/etc/adminhtml/system.xml`, `Service/etc/adminhtml/system.xml`                |
| Magento plugin              | `Plugin/` directories under any `CountryCareGroup/` module                         |
| Data patch / EAV attribute  | `Catalog/Setup/Patch/Data/`, `Customer/Setup/Patch/Data/`                          |
| DB schema column            | `ShippingRateProvider/etc/db_schema.xml`, `StoreLocation/etc/db_schema.xml`        |

## Specific Rules

- **Dual emails per form submission:** Each enquiry sends two emails — a customer confirmation and an internal `[ACTION REQUIRED]` email to the relevant branch. Follow this pattern for any new form-to-email feature.
- **Branch email routing:** Always use the `InventorySource` lookup pattern from `ServiceEnquiry`/`HireEnquiry`. Do not hardcode email addresses or invent a new routing mechanism.
- **BCC lists:** Always read from `country_care_group/<module>/bcc_to` admin config and split on comma. Do not add a new config path unless the module is genuinely new.
- **Enquiry code generation:** Match the existing `bin2hex(random_bytes(3))` pattern. Do not use `uniqid()`, UUIDs, or timestamps. Each module has its own prefix (e.g. `ENQHIR`, `ENQSER`, `TRL-`) — check the existing model when adding a new enquiry type.
- **Template variables:** Always pass a single `['data' => $input]` array to `setTemplateVars()`. Do not create top-level template variables outside the `data` key.
- **React data attributes:** Always use `$escaper->escapeHtmlAttr()` for PHTML data attributes. Do not use `escapeHtml()` or raw output.
- **GraphQL types:** After any schema change, check `types/ccgProvider.ts` and the GQL template literal for the same operation — all three must stay in sync.
- **REST vs GraphQL boundary:** REST endpoints are for B2B/external integrations (Punchout, server-to-server) and Magento service extensions. React widgets always use GraphQL — do not add REST endpoints for frontend data needs.
- **REST conventions:** One method per endpoint interface. Reference implementations: `Punchout` module (authenticated POST with request body, `self` + `%cart_id%`) and `StoreLocation` module (anonymous GET with query parameters).
