> **[EXAMPLE - Magento 2 + React]** This concept doc is from a Magento 2 + React project. It will be deleted when you run `/setup-project`. It serves as an example of the kind of architecture knowledge you should capture for your own project.

# Module scope conventions

All custom modules live under `app/code/<VendorNamespace>/` (see CLAUDE.md → Project Overview for the vendor namespace). Key rules:

- **React code lives only in the frontend/React module** — never add React components, widgets, or TypeScript to other modules (check CLAUDE.md → Conventions → React for this project's rule)
- **Each module owns one domain** — one concern per module, avoid mixing unrelated functionality
- **Shared PHP utilities** live in a dedicated utilities module (often a `Theme` or `Common` module) or in the module that owns the domain
- **Cross-module dependencies** should go through GraphQL or Magento's service contracts (interfaces in `Api/`), not direct class references

The `magento-module` skill encodes these conventions and is loaded into agents that create or modify PHP code.
