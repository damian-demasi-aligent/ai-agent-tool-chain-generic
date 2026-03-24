#!/usr/bin/env bash
#
# Hook: core-vendor-guard.sh
#
# PreToolUse hook for Write and Edit tools.
# Blocks modifications to vendor/dependency directories that should not be
# edited directly. Instructs Claude Code to use the project's extension
# mechanisms instead.
#
# For Magento projects: blocks vendor/ and app/code/Magento/
# For all projects: blocks node_modules/
#
# Outputs nothing (exits 0 silently) for files outside protected directories.

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

case "$FILE_PATH" in
    */vendor/magento/* | */vendor/Magento/* | */app/code/Magento/*)
        cat <<'GUARD'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Modifying Magento core/vendor files is not allowed. Use a plugin (di.xml), observer (events.xml), preference, or theme override instead. Run /plugin or /create-theme-override for scaffolding help."
  }
}
GUARD
        ;;
    */vendor/*)
        cat <<'GUARD'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Modifying third-party vendor files is not allowed. Vendor files are managed by the package manager and will be overwritten on update. Use the project's extension mechanisms instead (see CLAUDE.md Conventions)."
  }
}
GUARD
        ;;
    */node_modules/*)
        cat <<'GUARD'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Modifying node_modules/ is not allowed. These files are managed by the package manager and will be overwritten on install. If you need to patch a dependency, use patch-package or the project's override mechanism."
  }
}
GUARD
        ;;
    *)
        exit 0
        ;;
esac
