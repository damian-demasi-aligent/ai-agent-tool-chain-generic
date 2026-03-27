---
description: LESS styling, theme colour variables, custom mixins, and Magento theme override patterns
paths:
  - "**/*.less"
  - "**/app/design/**"
---

# Theme Conventions

Theme-level styles use LESS (not Tailwind — Tailwind is only for React components).

## Colour Variables

Theme colour variables are prefixed `@ccg-theme__color__*` (primary, secondary, tertiary, black, white, info-blue, and variants) — always use these instead of hardcoding hex values.

## Custom Mixins

Custom mixins live in `web/css/source/lib/_ccg-mixins.less` (page titles, modals) and `web/css/source/_mixins.less` (buttons, dropdowns, Font Awesome icons). Before writing new styles, search the theme's mixin files to see if a reusable mixin already exists.

## File Organisation

- Responsive styles go in dedicated `_media-query-*.less` files (mobile, desktop-medium, desktop-large), not inline in component LESS
- Module-specific overrides use `_extend.less` in the module's directory under the theme (e.g. `Magento_Catalog/web/css/source/_extend.less`)
