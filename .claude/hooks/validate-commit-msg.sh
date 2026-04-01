#!/usr/bin/env bash
#
# Hook: validate-commit-msg.sh
#
# PreToolUse hook for Bash commands.
# When a `git commit` is about to run, extracts the commit message from the
# command arguments and validates it against the project conventions defined
# in .claude/rules/commit-conventions.md:
#
#   1. Ticket prefix from branch name (e.g. PROJ-123:)
#   2. Capital letter after the colon
#   3. Subject line ≤ 72 characters
#   4. No trailing period on subject line
#   5. Co-Authored-By trailer present
#
# Branches without a ticket number (UPPERCASE-digits) skip the prefix check.
# Exits silently for all other Bash commands.

set -euo pipefail

# Source project config for COMMIT_PREFIX_PATTERN (if available)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=config.sh
[ -f "$SCRIPT_DIR/config.sh" ] && source "$SCRIPT_DIR/config.sh"

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

# Only intercept git commit commands
case "$COMMAND" in
    *git\ commit* | *git\ -c\ *commit*)
        ;;
    *)
        exit 0
        ;;
esac

# Extract the commit message from -m flag or heredoc pattern
# Supports: git commit -m "msg", git commit -m "$(cat <<'EOF'\nmsg\nEOF\n)"
MSG=$(python3 -c "
import sys, re

cmd = '''$COMMAND'''

# Try heredoc pattern first: -m \"\$(cat <<'EOF' ... EOF ... )\"
heredoc = re.search(r\"<<'?EOF'?\\n(.*?)\\nEOF\", cmd, re.DOTALL)
if heredoc:
    print(heredoc.group(1).strip())
    sys.exit(0)

# Try -m \"...\" or -m '...'
m_flag = re.search(r'-m\s+[\"\\x27](.*?)[\"\\x27]', cmd, re.DOTALL)
if m_flag:
    print(m_flag.group(1).strip())
    sys.exit(0)

# No message found (might be --amend or interactive)
print('')
" 2>/dev/null || echo "")

# If no message extracted, skip validation (e.g. --amend without -m)
[ -z "$MSG" ] && exit 0

SUBJECT=$(echo "$MSG" | head -n 1)
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
PREFIX_RE="${COMMIT_PREFIX_PATTERN:-[A-Z]+-[0-9]+}"
TICKET=$(echo "$BRANCH" | grep -oE "$PREFIX_RE" | head -n 1 || true)

ERRORS=()

# 1. Ticket prefix check (only when branch has a ticket)
if [[ -n "$TICKET" ]]; then
    if [[ ! "$SUBJECT" =~ ^${TICKET}: ]]; then
        ERRORS+=("Subject must start with '${TICKET}:' (extracted from branch '${BRANCH}')")
    fi
fi

# 2. Capital letter after colon (only when a ticket prefix is present)
if [[ -n "$TICKET" && "$SUBJECT" =~ ^${TICKET}:\ . ]]; then
    AFTER_COLON="${SUBJECT#*: }"
    FIRST_CHAR="${AFTER_COLON:0:1}"
    if [[ "$FIRST_CHAR" != "$(echo "$FIRST_CHAR" | tr '[:lower:]' '[:upper:]')" ]]; then
        ERRORS+=("First letter after '${TICKET}: ' must be capitalised")
    fi
elif [[ -z "$TICKET" ]]; then
    # No ticket — still check first char is capitalised
    FIRST_CHAR="${SUBJECT:0:1}"
    if [[ "$FIRST_CHAR" != "$(echo "$FIRST_CHAR" | tr '[:lower:]' '[:upper:]')" ]]; then
        ERRORS+=("Subject line must start with a capital letter")
    fi
fi

# 3. Subject line length
if [[ ${#SUBJECT} -gt 72 ]]; then
    ERRORS+=("Subject line is ${#SUBJECT} chars (max 72)")
fi

# 4. No trailing period
if [[ "$SUBJECT" =~ \.$ ]]; then
    ERRORS+=("Subject line must not end with a period")
fi

# 5. Co-Authored-By trailer
if ! echo "$MSG" | grep -q '^Co-Authored-By:'; then
    ERRORS+=("Missing 'Co-Authored-By:' trailer")
fi

# Report errors — block the commit
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    ERROR_LIST=""
    for ERR in "${ERRORS[@]}"; do
        ERROR_LIST="${ERROR_LIST}  - ${ERR}\n"
    done

    cat <<HOOKEOF
{
  "decision": "block",
  "reason": "Commit message does not follow project conventions (.claude/rules/commit-conventions.md):\n${ERROR_LIST}\nExpected format: TICKET-123: <Verb> <what changed>"
}
HOOKEOF
    exit 0
fi

exit 0
