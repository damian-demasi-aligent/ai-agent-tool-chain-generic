#!/usr/bin/env bash
#
# Shared configuration for Claude Code hooks.
# All project-specific paths are centralised here.
#
# This file is rewritten by /setup-project based on stack-config.json.
# Variables for absent capabilities are left empty — hooks check before using.
#
# TEMPLATE VALUES: Replace these with your project's values, or run
# /detect-stack followed by /setup-project to populate automatically.
#

# ── Commit conventions ─────────────────────────────────────────────────
# Regex pattern to extract a ticket prefix from the branch name.
# Examples: "CCG-[0-9]+" for Jira project CCG, "PROJ-[0-9]+" for PROJ.
# Leave empty to auto-detect any UPPERCASE-digits pattern ([A-Z]+-[0-9]+).
export COMMIT_PREFIX_PATTERN=""

# ── Magento backend (capability: magento) ──────────────────────────────
# Set VENDOR_NAMESPACE to your Magento vendor namespace (e.g., "Acme").
# Leave empty for non-Magento projects.
export VENDOR_NAMESPACE=""

# ── React frontend (capability: react) ─────────────────────────────────
# Path to frontend source root (relative to repo root).
# Examples: "src/", "app/code/Vendor/React/view/frontend/src/app"
export REACT_SRC=""

# Build output directories to clean before commits (relative to repo root).
# Examples: "dist/js", ".next/", "build/"
export REACT_BUILD_JS=""
export REACT_BUILD_CSS=""

# Lint commands used by react-lint-on-edit hook.
# Examples: "yarn eslint", "npm run lint", "npx eslint"
export LINT_CMD=""
export LINT_FIX_CMD=""

# ── GraphQL sync check (capability: magento + graphql + react) ─────────
# These three paths must stay in sync — the graphql-sync-check hook blocks
# commits when only 1-2 of the 3 layers have staged changes.
# Leave empty if your project doesn't have this three-layer sync requirement.
export GQL_SCHEMA_GLOB=""
export GQL_TEMPLATES_GLOB=""
export GQL_TYPES_FILE=""
