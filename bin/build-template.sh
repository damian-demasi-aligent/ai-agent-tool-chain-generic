#!/usr/bin/env bash
#
# Assembles the template/ directory from the repo source files.
# Run this before `npm publish` to package the toolchain files.
#
# The template/ directory is what `claude-toolchain init` copies into
# the target project. It contains everything except repo-specific and
# development files.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/template"

echo "Building template/ from repo source..."

# Clean previous build
rm -rf "$TEMPLATE_DIR"
mkdir -p "$TEMPLATE_DIR"

# ── .claude/ (agents, hooks, rules, settings, skills, capabilities) ───
cp -r "$REPO_ROOT/.claude" "$TEMPLATE_DIR/.claude"

# Remove local-only settings (users create their own)
rm -f "$TEMPLATE_DIR/.claude/settings.local.json"

# ── docs/ ──────────────────────────────────────────────────────────────
cp -r "$REPO_ROOT/docs" "$TEMPLATE_DIR/docs"

# Create empty placeholder directories with .gitkeep
for DIR in docs/plans docs/features docs/requirements; do
    mkdir -p "$TEMPLATE_DIR/$DIR"
    touch "$TEMPLATE_DIR/$DIR/.gitkeep"
done

# ── Root config files ──────────────────────────────────────────────────
cp "$REPO_ROOT/CLAUDE.md.example" "$TEMPLATE_DIR/CLAUDE.md.example"
cp "$REPO_ROOT/.mcp.json" "$TEMPLATE_DIR/.mcp.json"
cp "$REPO_ROOT/.env.development.example" "$TEMPLATE_DIR/.env.development.example"

# ── .gitignore additions ──────────────────────────────────────────────
# Ship a toolchain-specific gitignore that projects can merge into theirs
cat > "$TEMPLATE_DIR/.gitignore.toolchain" << 'EOF'
# Claude Code toolchain
.claude/settings.local.json
.claude/stack-config.json
.env.development
tmp/
.DS_Store
EOF

# ── .playwright-mcp/ (empty dir for Playwright MCP) ───────────────────
mkdir -p "$TEMPLATE_DIR/.playwright-mcp"

# ── Clean up development artifacts and non-portable content ────────────
find "$TEMPLATE_DIR" -name ".DS_Store" -delete 2>/dev/null || true

# Count what was assembled
FILE_COUNT=$(find "$TEMPLATE_DIR" -type f | wc -l | tr -d ' ')
DIR_COUNT=$(find "$TEMPLATE_DIR" -type d | wc -l | tr -d ' ')

echo "✓ template/ built: $FILE_COUNT files in $DIR_COUNT directories"
echo ""
echo "Ready to publish. Run: npm publish"
