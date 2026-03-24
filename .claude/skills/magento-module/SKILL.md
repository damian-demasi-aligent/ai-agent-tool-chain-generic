---
name: magento-module
description: Magento 2 module conventions. Use when creating or modifying PHP code, GraphQL schemas, layout XML, plugins, observers, or resolvers in custom modules.
user-invocable: false
metadata:
  capabilities: [magento]
---

# Magento 2 Module Patterns

Follow these conventions when working with custom PHP modules. Before starting, **read CLAUDE.md** for the project's vendor namespace, module inventory, plugin naming convention, PHP quality commands, theme path, and any project-specific coding rules.

## Module Structure

Standard layout for each module:

```
ModuleName/
├── registration.php
├── composer.json
├── etc/
│   ├── module.xml
│   ├── di.xml                 # Preferences and plugin registration
│   ├── schema.graphqls        # GraphQL schema (if applicable)
│   ├── config.xml             # Default config values
│   ├── email_templates.xml    # Email template declarations
│   └── adminhtml/system.xml   # Admin config fields
├── Model/
│   ├── Resolver/              # GraphQL resolvers (implement ResolverInterface)
│   └── ValidationRules/       # Checkout/form validation
├── Plugin/                    # Interceptors (before/after/around)
├── Block/                     # PHP block classes
├── ViewModel/                 # View models for templates
├── Api/                       # Service contracts (interfaces)
└── Setup/Patch/Data/          # Data migration patches
```

## Plugins

- Register in `etc/di.xml` (or `etc/frontend/di.xml` for frontend-only)
- **Check CLAUDE.md for the project's plugin naming convention** (e.g. `<prefix>_<module>_<action>`)
- Use `before`/`after` plugins over `around` when possible (less risk of breaking the method chain)
- First parameter is always `$subject`

## GraphQL

- Schema in `etc/schema.graphqls` with `@resolver` directives pointing to `Model\Resolver\` classes
- Resolvers implement `\Magento\Framework\GraphQL\Query\ResolverInterface`
- Input types use `input` keyword, output types use `type`
- **Check CLAUDE.md** for any frontend type files that must stay in sync with the GraphQL schema

## PHP Standards

**Check CLAUDE.md for the project's PHP quality commands** (linter, static analysis) and how to run them. These typically run automatically on pre-commit for staged `.php` and `.phtml` files.

## Theme Overrides

- **Check CLAUDE.md for the project's theme path** and parent theme
- Use `referenceBlock`/`referenceContainer` in layout XML for surgical changes — avoid copying entire layout files
- LESS overrides go in the theme's `web/css/source/` directory (see the less-theme skill for details)
