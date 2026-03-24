# Setup Prompts (Deprecated)

The manual setup prompts have been replaced by automated skills:

1. **`/detect-stack`** — Auto-detects your project's technology stack and writes `.claude/stack-config.json`
2. **`/setup-project`** — Reads the stack config, generates `CLAUDE.md`, prunes inapplicable skills/hooks, and configures the toolchain

See [../README.md](../README.md) for the full setup workflow.

## Legacy prompts (kept as reference)

The original Magento-specific setup prompts are preserved below for reference. They demonstrate the discovery process that `/detect-stack` and `/setup-project` now automate.

- `generate-claude-md-for-new-project.md` — 20-step Magento 2 CLAUDE.md generator
- `review-claude-toolchain-for-new-project.md` — Toolchain compatibility validator
