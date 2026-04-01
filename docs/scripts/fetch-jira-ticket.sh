#!/usr/bin/env bash
#
# Fetch a Jira ticket's full content (description, comments, attachments)
# and save everything to docs/requirements/ for use with /plan-feature.
#
# Usage:
#   ./docs/scripts/fetch-jira-ticket.sh <ticket-id>                          (reads credentials from .env.development)
#   ./docs/scripts/fetch-jira-ticket.sh <email> <api-token> <ticket-id>      (explicit credentials)
#
# Example:
#   ./docs/scripts/fetch-jira-ticket.sh PROJ-123
#   ./docs/scripts/fetch-jira-ticket.sh user@example.com xxxxxxxxxxx PROJ-123
#
# Credentials:
#   Set JIRA_BASE_URL, JIRA_EMAIL, and JIRA_API_TOKEN in .env.development (see .env.development.example).
#   CLI arguments override .env.development values.
#
# Output:
#   docs/requirements/<TICKET>/
#     ticket.json          -- Raw JSON from Jira REST API
#     description.md       -- Ticket description converted to readable text
#     comments.md          -- All comments in chronological order
#     attachments/         -- All attached files (images, docs, etc.)
#       <filename>
#

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repo root early (needed for .env.development lookup)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# ---------------------------------------------------------------------------
# Load .env.development if it exists
# ---------------------------------------------------------------------------
ENV_FILE="${REPO_ROOT}/.env.development"
if [[ -f "${ENV_FILE}" ]]; then
    # Source only JIRA_* vars to avoid polluting the environment
    JIRA_BASE_URL="${JIRA_BASE_URL:-$(grep -E '^JIRA_BASE_URL=' "${ENV_FILE}" | cut -d'=' -f2- | tr -d "'" | tr -d '"')}"
    JIRA_EMAIL="${JIRA_EMAIL:-$(grep -E '^JIRA_EMAIL=' "${ENV_FILE}" | cut -d'=' -f2- | tr -d "'" | tr -d '"')}"
    JIRA_TOKEN="${JIRA_API_TOKEN:-$(grep -E '^JIRA_API_TOKEN=' "${ENV_FILE}" | cut -d'=' -f2- | tr -d "'" | tr -d '"')}"
fi

# ---------------------------------------------------------------------------
# Arguments — support both 1-arg and 3-arg forms
# ---------------------------------------------------------------------------
if [[ $# -eq 1 ]]; then
    TICKET_ID="$1"
elif [[ $# -ge 3 ]]; then
    JIRA_EMAIL="$1"
    JIRA_TOKEN="$2"
    TICKET_ID="$3"
else
    echo "Usage: $0 <ticket-id>                           (uses .env.development credentials)"
    echo "       $0 <jira-email> <jira-api-token> <ticket-id>"
    echo ""
    echo "Example: $0 PROJ-123"
    echo ""
    echo "Set JIRA_BASE_URL, JIRA_EMAIL, and JIRA_API_TOKEN in .env.development (see .env.development.example)."
    exit 1
fi

# Validate credentials are available
if [[ -z "${JIRA_EMAIL:-}" || -z "${JIRA_TOKEN:-}" ]]; then
    echo "Error: Jira credentials not found."
    echo "Either pass them as arguments or set JIRA_BASE_URL, JIRA_EMAIL, and JIRA_API_TOKEN in .env.development"
    echo "See .env.development.example for the expected format."
    exit 1
fi

JIRA_BASE="${JIRA_BASE_URL:-https://your-org.atlassian.net}"
API_URL="${JIRA_BASE}/rest/api/3/issue/${TICKET_ID}"
AUTH="${JIRA_EMAIL}:${JIRA_TOKEN}"

OUTPUT_DIR="${REPO_ROOT}/docs/requirements/${TICKET_ID}"
ATTACH_DIR="${OUTPUT_DIR}/attachments"

mkdir -p "${ATTACH_DIR}"

echo "Fetching ${TICKET_ID} from Jira..."

# ---------------------------------------------------------------------------
# 1. Fetch the full issue JSON
# ---------------------------------------------------------------------------
HTTP_CODE=$(curl -s -w "%{http_code}" -o "${OUTPUT_DIR}/ticket.json" \
    -u "${AUTH}" \
    -H "Accept: application/json" \
    "${API_URL}?expand=renderedFields")

if [[ "${HTTP_CODE}" != "200" ]]; then
    echo "Error: Jira API returned HTTP ${HTTP_CODE}"
    echo "Response:"
    cat "${OUTPUT_DIR}/ticket.json"
    rm -f "${OUTPUT_DIR}/ticket.json"
    exit 1
fi

echo "  Saved raw JSON to ${OUTPUT_DIR}/ticket.json"

# ---------------------------------------------------------------------------
# 2. Check for jq (used for JSON parsing)
# ---------------------------------------------------------------------------
if ! command -v jq &>/dev/null; then
    echo "Warning: jq is not installed. Skipping description/comments extraction."
    echo "Install with: brew install jq"
    echo "Raw JSON is still available at ${OUTPUT_DIR}/ticket.json"
    JQ_AVAILABLE=false
else
    JQ_AVAILABLE=true
fi

# ---------------------------------------------------------------------------
# 3. Extract ticket metadata and description
# ---------------------------------------------------------------------------
if [[ "${JQ_AVAILABLE}" == "true" ]]; then
    {
        echo "# ${TICKET_ID}: $(jq -r '.fields.summary' "${OUTPUT_DIR}/ticket.json")"
        echo ""
        echo "**Status:** $(jq -r '.fields.status.name' "${OUTPUT_DIR}/ticket.json")"
        echo "**Priority:** $(jq -r '.fields.priority.name' "${OUTPUT_DIR}/ticket.json")"
        echo "**Assignee:** $(jq -r '.fields.assignee.displayName // "Unassigned"' "${OUTPUT_DIR}/ticket.json")"
        echo "**Reporter:** $(jq -r '.fields.reporter.displayName // "Unknown"' "${OUTPUT_DIR}/ticket.json")"
        echo "**Created:** $(jq -r '.fields.created' "${OUTPUT_DIR}/ticket.json")"
        echo "**Updated:** $(jq -r '.fields.updated' "${OUTPUT_DIR}/ticket.json")"

        # Epic link
        EPIC=$(jq -r '.fields.customfield_10005 // empty' "${OUTPUT_DIR}/ticket.json" 2>/dev/null)
        if [[ -n "${EPIC}" ]]; then
            echo "**Epic:** ${EPIC}"
        fi

        # Parent
        PARENT=$(jq -r '.fields.parent.key // empty' "${OUTPUT_DIR}/ticket.json" 2>/dev/null)
        if [[ -n "${PARENT}" ]]; then
            echo "**Parent:** ${PARENT}"
        fi

        echo ""
        echo "---"
        echo ""
        echo "## Description"
        echo ""

        # Use the rendered HTML description and convert to readable text
        # The renderedFields.description contains HTML; strip tags for readability
        RENDERED_DESC=$(jq -r '.renderedFields.description // empty' "${OUTPUT_DIR}/ticket.json")
        if [[ -n "${RENDERED_DESC}" ]]; then
            # Replace common HTML patterns with markdown equivalents
            echo "${RENDERED_DESC}" \
                | sed 's/<br[^>]*>/\n/g' \
                | sed 's/<\/p>/\n\n/g' \
                | sed 's/<\/li>/\n/g' \
                | sed 's/<li>/- /g' \
                | sed 's/<\/ol>/\n/g' \
                | sed 's/<ol>/\n/g' \
                | sed 's/<\/ul>/\n/g' \
                | sed 's/<ul>/\n/g' \
                | sed 's/<h[1-6][^>]*>/\n### /g' \
                | sed 's/<\/h[1-6]>/\n/g' \
                | sed 's/<strong>/\*\*/g' \
                | sed 's/<\/strong>/\*\*/g' \
                | sed 's/<em>/_/g' \
                | sed 's/<\/em>/_/g' \
                | sed 's/<hr[^>]*>/\n---\n/g' \
                | sed 's/<[^>]*>//g' \
                | sed '/^$/N;/^\n$/d'
        else
            # Fallback: try the ADF (Atlassian Document Format) plain text
            jq -r '.fields.description.content[]?.content[]?.text // empty' "${OUTPUT_DIR}/ticket.json" 2>/dev/null || echo "(No description)"
        fi

        echo ""
        echo ""
        echo "---"
        echo ""
        echo "## Attachments"
        echo ""
        echo "The following files are saved in the \`attachments/\` directory:"
        echo ""

        # List attachments
        jq -r '.fields.attachment[]? | "- [\(.filename)](attachments/\(.filename)) (\(.mimeType), \(.size) bytes)"' \
            "${OUTPUT_DIR}/ticket.json" 2>/dev/null || echo "(No attachments)"

        # Inline image references for easy viewing
        echo ""
        echo "### Image Previews"
        echo ""
        jq -r '.fields.attachment[]? | select(.mimeType | startswith("image/")) | "![" + .filename + "](attachments/" + .filename + ")"' \
            "${OUTPUT_DIR}/ticket.json" 2>/dev/null || true

    } > "${OUTPUT_DIR}/description.md"

    echo "  Saved description to ${OUTPUT_DIR}/description.md"

    # ---------------------------------------------------------------------------
    # 4. Extract comments
    # ---------------------------------------------------------------------------
    COMMENT_COUNT=$(jq '.fields.comment.comments | length' "${OUTPUT_DIR}/ticket.json" 2>/dev/null || echo "0")

    if [[ "${COMMENT_COUNT}" -gt 0 ]]; then
        {
            echo "# ${TICKET_ID}: Comments"
            echo ""
            echo "Total comments: ${COMMENT_COUNT}"
            echo ""

            jq -r '.fields.comment.comments[] |
                "---\n\n**" + .author.displayName + "** — " + .created + "\n\n" +
                (.body.content[]?.content[]?.text // "(rich content — see ticket.json)") +
                "\n"' \
                "${OUTPUT_DIR}/ticket.json" 2>/dev/null

            # Also extract rendered comments if available
            RENDERED_COMMENTS=$(jq -r '.renderedFields.comment.comments[]? |
                "---\n\n**" + .author.displayName + "** — " + .created + "\n\n" + .body + "\n"' \
                "${OUTPUT_DIR}/ticket.json" 2>/dev/null || true)

            if [[ -n "${RENDERED_COMMENTS}" ]]; then
                echo ""
                echo "# Rendered Comments (HTML)"
                echo ""
                echo "${RENDERED_COMMENTS}" \
                    | sed 's/<br[^>]*>/\n/g' \
                    | sed 's/<\/p>/\n\n/g' \
                    | sed 's/<[^>]*>//g' \
                    | sed '/^$/N;/^\n$/d'
            fi

        } > "${OUTPUT_DIR}/comments.md"

        echo "  Saved ${COMMENT_COUNT} comments to ${OUTPUT_DIR}/comments.md"
    else
        echo "  No comments found"
    fi
fi

# ---------------------------------------------------------------------------
# 5. Download all attachments
# ---------------------------------------------------------------------------
if [[ "${JQ_AVAILABLE}" == "true" ]]; then
    ATTACHMENT_COUNT=$(jq '.fields.attachment | length' "${OUTPUT_DIR}/ticket.json" 2>/dev/null || echo "0")
else
    # Fallback: count attachment URLs with grep
    ATTACHMENT_COUNT=$(grep -c '"content":' "${OUTPUT_DIR}/ticket.json" 2>/dev/null || echo "0")
fi

if [[ "${ATTACHMENT_COUNT}" -gt 0 ]]; then
    echo "  Downloading ${ATTACHMENT_COUNT} attachments..."

    if [[ "${JQ_AVAILABLE}" == "true" ]]; then
        # Use jq to extract attachment URLs and filenames
        jq -r '.fields.attachment[]? | .content + "\t" + .filename' "${OUTPUT_DIR}/ticket.json" | \
        while IFS=$'\t' read -r url filename; do
            if [[ -n "${url}" && -n "${filename}" ]]; then
                echo "    Downloading: ${filename}"
                curl -s -L -u "${AUTH}" \
                    -o "${ATTACH_DIR}/${filename}" \
                    "${url}"
            fi
        done
    else
        # Fallback without jq: extract URLs with grep/sed
        grep -o '"content":"[^"]*"' "${OUTPUT_DIR}/ticket.json" | \
        sed 's/"content":"//;s/"//' | \
        while read -r url; do
            FILENAME=$(basename "${url}")
            echo "    Downloading: ${FILENAME}"
            curl -s -L -u "${AUTH}" \
                -o "${ATTACH_DIR}/${FILENAME}" \
                "${url}"
        done
    fi

    echo "  Attachments saved to ${ATTACH_DIR}/"
else
    echo "  No attachments found"
fi

# ---------------------------------------------------------------------------
# 6. Summary
# ---------------------------------------------------------------------------
echo ""
echo "Done! Ticket content saved to:"
echo "  ${OUTPUT_DIR}/"
echo ""
ls -la "${OUTPUT_DIR}/"
echo ""
if [[ -d "${ATTACH_DIR}" ]] && ls "${ATTACH_DIR}"/* &>/dev/null; then
    echo "Attachments:"
    ls -la "${ATTACH_DIR}/"
fi
echo ""
echo "Next step: run /plan-feature docs/requirements/${TICKET_ID}/description.md"
