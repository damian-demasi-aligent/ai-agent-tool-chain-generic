#!/usr/bin/env bash
#
# Hook: graphql-sync-check.sh
#
# PreToolUse hook for Bash commands.
# When a `git commit` is about to run, checks whether GraphQL-related files
# have been modified in only one layer without corresponding changes in the
# others. The three layers that must stay in sync are configured in
# config.sh via these variables:
#
#   1. Backend schema:  $GQL_SCHEMA_GLOB
#   2. GQL templates:   $GQL_TEMPLATES_GLOB
#   3. TypeScript types: $GQL_TYPES_FILE
#
# If only one or two layers are staged, the hook blocks the commit and
# instructs Claude to run /react-sync-types before proceeding.

set -euo pipefail

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
")

[ -z "$COMMAND" ] && exit 0

# Only run on git commit commands
case "$COMMAND" in
    *git\ commit* | *git\ -c\ *commit*)
        ;;
    *)
        exit 0
        ;;
esac

# Load project-specific paths
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HOOK_DIR/config.sh"

# Skip if GraphQL sync paths are not configured
[[ -z "$GQL_SCHEMA_GLOB" || -z "$GQL_TEMPLATES_GLOB" || -z "$GQL_TYPES_FILE" ]] && exit 0

# Check staged files for each layer
STAGED=$(git diff --cached --name-only 2>/dev/null || true)
[ -z "$STAGED" ] && exit 0

HAS_SCHEMA=false
HAS_GQL_TEMPLATES=false
HAS_TS_TYPES=false

while IFS= read -r file; do
    case "$file" in
        ${GQL_SCHEMA_GLOB})
            HAS_SCHEMA=true
            ;;
        ${GQL_TEMPLATES_GLOB})
            HAS_GQL_TEMPLATES=true
            ;;
        ${GQL_TYPES_FILE})
            HAS_TS_TYPES=true
            ;;
    esac
done <<< "$STAGED"

# If none of the GraphQL layers are staged, nothing to check
if ! $HAS_SCHEMA && ! $HAS_GQL_TEMPLATES && ! $HAS_TS_TYPES; then
    exit 0
fi

# If all three layers are staged, assume they're in sync
if $HAS_SCHEMA && $HAS_GQL_TEMPLATES && $HAS_TS_TYPES; then
    exit 0
fi

# Build a message describing what's missing
PRESENT=""
MISSING=""

if $HAS_SCHEMA; then
    PRESENT="$PRESENT schema.graphqls"
else
    MISSING="$MISSING schema.graphqls"
fi

if $HAS_GQL_TEMPLATES; then
    PRESENT="$PRESENT GQL templates"
else
    MISSING="$MISSING GQL templates (${GQL_TEMPLATES_GLOB})"
fi

if $HAS_TS_TYPES; then
    PRESENT="$PRESENT TypeScript types"
else
    MISSING="$MISSING TypeScript types (${GQL_TYPES_FILE})"
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "GraphQL layer sync check failed. Staged files include changes to:${PRESENT}, but NOT to:${MISSING}. These layers must stay in sync (see docs/manuals/concepts/knowledgebase.md). Run /react-sync-types to check for mismatches, then stage the missing files before committing. If the other layers genuinely don't need changes, re-run the commit with a comment explaining why."
  }
}
EOF
