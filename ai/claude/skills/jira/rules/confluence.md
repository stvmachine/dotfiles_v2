# Confluence Context Gathering Rule

Extract Confluence links from ticket content and fetch page content via MCP. Covers INTAKE-03.

## Section 1: When This Rule Runs

- Called by the fetch workflow (rules/fetch.md) after TICKET_DESCRIPTION.md is created
- Input: the full ticket content (description + comments text)
- Output: `todo/MT-XXXX/context/confluence-{PAGE_ID}.md` files

## Section 2: Confluence Link Extraction

Instructions for finding Confluence URLs in ticket content:

- Scan description AND all comments for Confluence URLs
- URL patterns to match:
  - `https://medtasker.atlassian.net/wiki/spaces/{SPACE}/pages/{PAGE_ID}/{page-title}`
  - `https://medtasker.atlassian.net/wiki/display/{SPACE}/{Page+Title}`
  - Any URL containing `atlassian.net/wiki`

- Extraction approach:
```bash
# Extract all Confluence URLs from ticket markdown
grep -oE 'https://[^/]+\.atlassian\.net/wiki/[^ )\]"]+' "$TICKET_DIR/TICKET_DESCRIPTION.md" | sort -u
```

- For each URL, extract the page ID:
  - From `/pages/{PAGE_ID}/` path segment: `echo "$url" | grep -oE '/pages/[0-9]+' | cut -d/ -f3`
  - If URL uses `/display/SPACE/Title` format (no numeric ID), use the page title to search via MCP

## Section 3: Fetching Confluence Pages via MCP

For each extracted page ID:

1. Call `mcp__mcp-atlassian__confluence_get_page` with the page ID
2. Validate response using mcp-utils.md patterns (check isError, verify `id` and `body` fields)
3. If validation fails, retry using retry_with_backoff (3 attempts, 30s doubling — same as Jira per D-03, Confluence uses mcp-atlassian)
4. If all retries fail: log the failure reason, mark confluence status as "failed" in state file, continue processing
5. On success: extract the page content (body in storage format or rendered HTML)

**MCP validation pattern** (from mcp-utils.md):
```bash
validate_confluence_response() {
    local response="$1"

    # Check isError flag
    python3 -c "import json,sys; data=json.load(sys.stdin); sys.exit(0 if not data.get('isError') else 1)" <<< "$response" || return 1

    # Check critical fields present and non-empty
    python3 -c "
import json, sys
data = json.load(sys.stdin)
required = ['id', 'body']
if not all(field in data for field in required):
    print('ERROR: Missing required fields', file=sys.stderr)
    sys.exit(1)
sys.exit(0)
" <<< "$response"
}
```

**Retry pattern** (from mcp-utils.md):
```bash
# For Confluence MCP calls (3 retries with exponential backoff)
retry_with_backoff 3 "mcp__mcp-atlassian__confluence_get_page page_id=$PAGE_ID"
```

## Section 4: Saving Confluence Pages

Save each fetched page to `$TICKET_DIR/context/confluence-{PAGE_ID}.md` with this format:

```markdown
# {Page Title}

**Source:** {Original Confluence URL}
**Page ID:** {PAGE_ID}
**Space:** {SPACE_KEY}
**Fetched:** {ISO timestamp}

---

{Page body content converted to markdown}
```

- Convert HTML body content to readable markdown (strip HTML tags, preserve headings/lists/links)
- Preserve any images referenced in the page (note: image downloads from Confluence are best-effort)

**Content conversion approach:**
```bash
# Extract page title, space key, body from MCP response
TITLE=$(python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('title', 'Untitled'))" <<< "$response")
SPACE_KEY=$(python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('space', {}).get('key', 'UNKNOWN'))" <<< "$response")
BODY=$(python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('body', {}).get('storage', {}).get('value', ''))" <<< "$response")

# Create markdown file
cat > "$TICKET_DIR/context/confluence-$PAGE_ID.md" <<EOF
# $TITLE

**Source:** $CONFLUENCE_URL
**Page ID:** $PAGE_ID
**Space:** $SPACE_KEY
**Fetched:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")

---

$BODY
EOF
```

## Section 5: No Links Found

- If no Confluence links are found in the ticket content, mark confluence status as "skipped" in state file
- Do not create any files in context/
- This is normal — not all tickets have Confluence references

**Implementation:**
```bash
CONFLUENCE_URLS=$(grep -oE 'https://[^/]+\.atlassian\.net/wiki/[^ )\]"]+' "$TICKET_DIR/TICKET_DESCRIPTION.md" | sort -u)

if [ -z "$CONFLUENCE_URLS" ]; then
    echo "No Confluence links found in ticket"
    mark_source_status "confluence" "skipped"
    return 0
fi
```

## Section 6: Error Handling (per D-03)

- Confluence is best-effort: if MCP fails after retries, log the error and continue
- The ticket is still valid without Confluence context (partial context resilience)
- Error message format: "WARNING: Confluence page {PAGE_ID} fetch failed after 3 retries: {reason}"
- Never include credentials in error messages

**Partial context resilience pattern:**
```bash
fetch_confluence_page() {
    local page_id="$1"
    local ticket_dir="$2"

    # Try to fetch with retry
    if ! response=$(retry_with_backoff 3 "mcp__mcp-atlassian__confluence_get_page page_id=$page_id"); then
        echo "WARNING: Confluence page $page_id fetch failed after 3 retries" >&2
        return 1
    fi

    # Validate response
    if ! validate_confluence_response "$response"; then
        echo "WARNING: Confluence page $page_id returned invalid data" >&2
        return 1
    fi

    # Save page content
    save_confluence_page "$page_id" "$response" "$ticket_dir"
}

# Main confluence gathering logic
fetch_all_confluence_pages() {
    local ticket_dir="$1"

    # Extract page IDs
    page_ids=$(extract_confluence_page_ids "$ticket_dir/TICKET_DESCRIPTION.md")

    if [ -z "$page_ids" ]; then
        mark_source_status "confluence" "skipped"
        return 0
    fi

    # Attempt to fetch each page
    failed_count=0
    success_count=0

    for page_id in $page_ids; do
        if fetch_confluence_page "$page_id" "$ticket_dir"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done

    # Mark status based on results
    if [ "$success_count" -gt 0 ]; then
        mark_source_status "confluence" "success"
    else
        mark_source_status "confluence" "failed" "All page fetches failed"
    fi
}
```

**Security note:** Never log or expose JIRA_USERNAME, JIRA_API_TOKEN, or any other credentials in error messages or debug output.
