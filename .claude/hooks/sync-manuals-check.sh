#!/usr/bin/env bash
#
# Hook: sync-manuals-check.sh
#
# Triggered by PostToolUse on Write and Edit tools.
# When a file that defines Claude Code tooling (agents, commands, skills, settings,
# rules, or CLAUDE.md itself) is modified, outputs imperative instructions for Claude Code
# to update docs/manuals/ and cross-references so documentation stays in sync.
#
# Outputs nothing (exits 0 silently) for all other file modifications.

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

MANUALS_DIR="docs/manuals"
REF_FILE="$MANUALS_DIR/reference/ai-tools-reference.md"

is_known_item() {
    grep -q "$1" "$REF_FILE" 2>/dev/null
}

case "$FILE_PATH" in

    */CLAUDE.md)
        cat <<'INSTRUCTIONS'
[sync-docs] CLAUDE.md was modified.

You MUST now perform these steps:

1. Read CLAUDE.md to understand what changed.
2. Read each of the files in the docs/manuals/ directory and update any sections that are now out of date.
3. Read docs/manuals/README.md and update the "I need to..." routing, folder map, or review notes if this change affects manual navigation.

Only update what is genuinely affected — do not rewrite sections that are still accurate.
INSTRUCTIONS
        ;;

    */.claude/rules/*.md)
        RULE=$(basename "$FILE_PATH")
        cat <<INSTRUCTIONS
[sync-docs] Project rule "${RULE}" was modified.

You MUST now perform these steps:

1. Read .claude/rules/${RULE} to understand what changed.
2. Read each of the files in the docs/manuals/ directory and update any sections that reference conventions, standards, or commit rules that are now out of date.
3. Read docs/manuals/README.md and update if this change affects manual navigation.

Only update what is genuinely affected — do not rewrite sections that are still accurate.
INSTRUCTIONS
        ;;

    */.claude/agents/*.md)
        AGENT=$(basename "$FILE_PATH" .md)
        if is_known_item "$AGENT"; then
            INVENTORY_ACTION="Update the existing row in the Agents table to reflect any changes to description or invoke syntax."
            STATUS="UPDATED"
        else
            INVENTORY_ACTION="Add a new row to the Agents table with invoke syntax (\`@${AGENT}\`) and purpose."
            STATUS="NEW"
        fi
        cat <<INSTRUCTIONS
[sync-docs] Agent "${AGENT}" was ${STATUS}.

You MUST now perform these steps:

1. Read .claude/agents/${AGENT}.md to extract: name, description, invoke syntax, skills list, and purpose.
2. Read docs/manuals/reference/ai-tools-reference.md:
   - ${INVENTORY_ACTION}
   - If the agent's skills: frontmatter changed, update the "Agent context skills" table's "Loaded by" column for each affected skill.
3. Search for files in the docs/manuals/ directory for references to @${AGENT} or \`${AGENT}\` and update if the agent's purpose or usage changed.
4. Read docs/manuals/README.md and update it if this agent change affects top-level manual navigation or lookup guidance.

Only update what is genuinely affected — do not rewrite sections that are still accurate.
INSTRUCTIONS
        ;;

    */.claude/commands/*.md)
        CMD=$(basename "$FILE_PATH" .md)

        if is_known_item "$CMD"; then
            # Extract category dynamically by finding the ### section header above the command's table row
            CATEGORY=$(awk '/^### /{section=$0; sub(/^### /,"",section)} /\/'"$CMD"'/{print section; exit}' "$REF_FILE")
            CATEGORY="${CATEGORY:-Slash commands}"
            INVENTORY_ACTION="Update the existing row in the \"${CATEGORY}\" Slash commands table to reflect any changes."
            STATUS="UPDATED"
        else
            INVENTORY_ACTION="Read the command file to understand its purpose, then add a new row to the appropriate Slash commands category table (Exploration, Feature scaffolding, Quality, or Git — whichever best matches the command's purpose). Also add a matching entry to the \"Choosing the right tool\" table and check docs/manuals/workflows/feature-development.md's quick decision guide."
            STATUS="NEW"
        fi

        cat <<INSTRUCTIONS
[sync-docs] Slash command "/${CMD}" was ${STATUS}.

You MUST now perform these steps:

1. Read .claude/commands/${CMD}.md to extract: purpose and usage syntax.
2. Read docs/manuals/reference/ai-tools-reference.md:
   - ${INVENTORY_ACTION}
3. Search for files in the docs/manuals/ directory for references to /${CMD} and update if the command's purpose or usage changed.
4. Read docs/manuals/README.md and update it if this command change affects top-level manual navigation or lookup guidance.

Only update what is genuinely affected — do not rewrite sections that are still accurate.
INSTRUCTIONS
        ;;

    */.claude/skills/*/SKILL.md)
        SKILL=$(basename "$(dirname "$FILE_PATH")")
        if is_known_item "$SKILL"; then
            STATUS="UPDATED"
        else
            STATUS="NEW"
        fi

        # Detect whether the skill is also a user-invocable command via frontmatter
        IS_ALSO_COMMAND=$(grep -q 'also_command: true' "$FILE_PATH" 2>/dev/null && echo "yes" || echo "no")
        if [ "$IS_ALSO_COMMAND" = "yes" ]; then
            SKILL_TYPE="user-invocable (also_command: true)"
            INVENTORY_INSTRUCTIONS="- Add/update a row in the \"User-invocable skills\" table with invoke syntax (\`/${SKILL}\`).
   - Also add/update a matching row in the appropriate Slash commands category table (the skill doubles as a command)."
        else
            SKILL_TYPE="agent-context only"
            INVENTORY_INSTRUCTIONS="- Add/update a row in the \"Agent context skills\" table with the correct \"Loaded by\" agents."
        fi

        cat <<INSTRUCTIONS
[sync-docs] Skill "${SKILL}" was ${STATUS} (${SKILL_TYPE}).

You MUST now perform these steps:

1. Read .claude/skills/${SKILL}/SKILL.md to extract: purpose, whether it has \`also_command: true\` in frontmatter, and its invoke syntax (if any).
2. Read docs/manuals/reference/ai-tools-reference.md:
   ${INVENTORY_INSTRUCTIONS}
3. Search for files in the docs/manuals/ directory for references to ${SKILL} or \`${SKILL}\` and update if the skill's purpose or invoke syntax changed.
4. Read docs/manuals/README.md and update it if this skill change affects top-level manual navigation or lookup guidance.

Only update what is genuinely affected — do not rewrite sections that are still accurate.
INSTRUCTIONS
        ;;

    */.claude/settings.json | */.claude/settings.local.json)
        SETTINGS_FILE=$(basename "$FILE_PATH")
        cat <<INSTRUCTIONS
[sync-docs] Claude Code settings file "${SETTINGS_FILE}" was modified.

You MUST now perform these steps:

1. Read .claude/${SETTINGS_FILE} to understand what changed.
2. If hooks were added, removed, or renamed:
   - Read docs/manuals/reference/ai-tools-reference.md and update any mention of hooks or automation.
3. If MCP servers were added or removed:
   - Read docs/manuals/reference/ai-tools-reference.md and update MCP-related entries.
4. If permission rules changed significantly:
   - No documentation update needed (permissions are local config).
5. Read docs/manuals/README.md and update it if settings changes affect how people discover manuals or automation docs.

Only update what is genuinely affected — do not rewrite sections that are still accurate.
INSTRUCTIONS
        ;;

    *)
        exit 0
        ;;
esac
