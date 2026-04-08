# Project Manuals

> Use this folder as the entrypoint for AI tooling and workflow docs. These manuals are project-portable — they reference CLAUDE.md for project-specific values (vendor namespace, module names, paths, commands).

---

## I need to...

- **Get started in this repo** → [`00-getting-started/onboarding.md`](00-getting-started/onboarding.md)
- **Plan and deliver a feature** → [`01-workflows/feature-development.md`](01-workflows/feature-development.md)
- **Debug a broken flow or toolchain issue** → [`02-playbooks/debugging.md`](02-playbooks/debugging.md)
- **Explore unfamiliar code and assess impact** → [`02-playbooks/exploration-and-investigation.md`](02-playbooks/exploration-and-investigation.md)
- **Manage session context for long features** → [`02-playbooks/context-management.md`](02-playbooks/context-management.md)
- **Look up agents, commands, and skills** → [`03-reference/ai-tools-reference.md`](03-reference/ai-tools-reference.md)
- **Understand architecture decisions and pitfalls** → [`05-concepts/knowledgebase-react-magento-data-bridge.md`](05-concepts/knowledgebase-react-magento-data-bridge.md) (and related topic docs in `05-concepts/`)

## Folder map

- `00-getting-started/` — onboarding and first-day orientation.
- `01-workflows/` — end-to-end delivery sequences for common work types.
- `02-playbooks/` — troubleshooting and investigation guides by problem type.
- `03-reference/` — canonical command/agent/skill inventory.
- `04-templates/` — templates for adding new manuals consistently.
- `05-concepts/` — architecture rationale, constraints, and failure modes (one topic per file).

See also `docs/scripts/` — workflow utility scripts (e.g. `fetch-jira-ticket.sh` for fetching requirements with mockup images).

### Concept docs:
  - `knowledgebase-magento-extension-mechanisms.md`
  - `knowledgebase-graphql-schema-contract.md`
  - `knowledgebase-react-magento-data-bridge.md`
  - `knowledgebase-apollo-caching-behaviour.md`
  - `knowledgebase-formwizard-cross-step-data-sharing.md`
  - `knowledgebase-email-template-rendering.md`
  - `knowledgebase-recaptcha-integration-pattern.md`
  - `knowledgebase-build-output-lifecycle.md`
  - `knowledgebase-module-scope-conventions.md`
  - `knowledgebase-comprehension-debt.md`

## Review cadence

- **Review trigger:** any `.claude/agents`, `.claude/commands`, `.claude/skills`, hook, or `CLAUDE.md` change
