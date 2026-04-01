---
description: PHP and Magento 2 module patterns, plugin naming, email conventions, and reuse references
paths:
  - "**/*.php"
  - "**/*.xml"
  - "**/*.phtml"
---

# PHP / Magento Conventions

- Copyright header on all PHP files (use your organisation's standard format)
- `declare(strict_types=1)` on all PHP files
- Constructor uses PHP 8.1 promoted `private readonly` properties
- Admin config section: prefer a shared section (defined in one central module) with module-specific groups. Only create a new section if genuinely needed.
- Pre-commit hooks (PHPCS + PHPStan) run via the CLI wrapper — if hooks fail, check wrapper command availability
- For Magento template overrides, always verify the correct module path (e.g., Magento_CustomerCustomAttributes vs Magento_Customer)
- When debugging frontend issues where code changes don't take effect, check for stale compiled/bundled assets early in the debugging process

## Reuse Before Reimplementing

Before implementing any feature, search for existing examples by technical need:

| Need                        | Where to look first                                          |
| --------------------------- | ------------------------------------------------------------ |
| Transactional email         | Existing email-sending models in your custom modules         |
| GraphQL mutation + resolver | Existing resolver classes in `Model/Resolver/`               |
| Admin config fields         | Existing `etc/adminhtml/system.xml` files                    |
| Magento plugin              | `Plugin/` directories under your custom modules              |
| Data patch / EAV attribute  | `Setup/Patch/Data/` directories in your custom modules       |
| DB schema column            | Existing `etc/db_schema.xml` files                           |

## Specific Rules

- **Dual emails per form submission:** Each enquiry sends two emails — a customer confirmation and an internal notification. Follow this pattern for any new form-to-email feature.
- **Branch email routing:** Use the existing store/branch lookup pattern for routing. Do not hardcode email addresses or invent a new routing mechanism.
- **React data attributes:** Always use `$escaper->escapeHtmlAttr()` for PHTML data attributes. Do not use `escapeHtml()` or raw output.
- **GraphQL types:** After any schema change, check the frontend types file and the GraphQL operation for the same operation — all layers must stay in sync.
- **REST vs GraphQL boundary:** REST endpoints are for B2B/external integrations and Magento service extensions. React widgets always use GraphQL — do not add REST endpoints for frontend data needs.
- **REST conventions:** One method per endpoint interface. Reference existing REST modules for authenticated POST and anonymous GET patterns.
