#!/usr/bin/env bash
#
# Hook: react-lint-on-edit.sh
#
# Triggered by PostToolUse on Write and Edit tools.
# Runs ESLint auto-fix and then ESLint check for edited React source files
# (.ts/.tsx/.js/.jsx) under the React app source directory.
#
# Outputs nothing (exits 0 silently) for non-React files.

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
")

[ -z "$FILE_PATH" ] && exit 0

# Load project-specific paths
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HOOK_DIR/config.sh"

case "$FILE_PATH" in
    */${REACT_SRC}/*.[jt]s | \
    */${REACT_SRC}/*.[jt]sx)
        ;;
    *)
        exit 0
        ;;
esac

[ ! -f "$FILE_PATH" ] && exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

if yarn eslint --fix "$FILE_PATH" >/dev/null 2>&1; then
    FIX_EXIT=0
else
    FIX_EXIT=$?
fi

if yarn eslint "$FILE_PATH" >/dev/null 2>&1; then
    CHECK_EXIT=0
else
    CHECK_EXIT=$?
fi

if [ "$FIX_EXIT" -eq 0 ] && [ "$CHECK_EXIT" -eq 0 ]; then
    CONTEXT="[react-lint-on-edit] ESLint fix and check passed for ${FILE_PATH}."
else
    CONTEXT="[react-lint-on-edit] ESLint check still reports issues for ${FILE_PATH}. Run yarn eslint --fix '${FILE_PATH}' and review remaining lint errors."
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "${CONTEXT}"
  }
}
EOF

exit 0
