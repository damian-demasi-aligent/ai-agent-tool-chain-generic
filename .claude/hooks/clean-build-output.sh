#!/usr/bin/env bash
#
# Hook: clean-build-output.sh
#
# PreToolUse hook for Bash commands.
# When a `git commit` is about to run, removes Vite build output files
# (web/js/ and web/css/) and unstages them if any were accidentally staged.
#
# Exits silently for all other Bash commands.

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

BUILD_JS="$REACT_BUILD_JS"
BUILD_CSS="$REACT_BUILD_CSS"

# Skip if no build paths configured
[[ -z "$BUILD_JS" && -z "$BUILD_CSS" ]] && exit 0

UNSTAGED=""

for DIR in "$BUILD_JS" "$BUILD_CSS"; do
    [ -z "$DIR" ] && continue
    if git diff --cached --name-only -- "$DIR" 2>/dev/null | grep -q .; then
        git reset HEAD -- "$DIR" 2>/dev/null
        UNSTAGED="$UNSTAGED $DIR"
    fi
done

DELETED=""

for DIR in "$BUILD_JS" "$BUILD_CSS"; do
    [ -z "$DIR" ] && continue
    if [ -d "$DIR" ]; then
        rm -rf "$DIR"
        DELETED="$DELETED $DIR"
    fi
done

if [ -n "$UNSTAGED" ] || [ -n "$DELETED" ]; then
    CONTEXT="[clean-build-output] Removed Vite build output before commit."
    [ -n "$UNSTAGED" ] && CONTEXT="$CONTEXT Unstaged:$UNSTAGED."
    [ -n "$DELETED" ] && CONTEXT="$CONTEXT Deleted:$DELETED."

    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "$CONTEXT"
  }
}
EOF
fi

exit 0
