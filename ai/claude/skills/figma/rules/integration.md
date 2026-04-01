# Figma Ticket Context Integration Rule

Extract Figma links from ticket content and fetch design data for the ticket intake pipeline. Covers INTAKE-04 and SKILL-02.

## Section 1: When This Rule Runs

**Invocation:** Called by the jira skill's fetch workflow (jira rules/fetch.md) when Figma links are found in a ticket

**Mode:** Automated pipeline step — do NOT prompt the user for choices

**Input:** Figma URL(s) extracted from ticket description/comments

**Output:** Design data files in `todo/MT-XXXX/context/`

This is context gathering, not code generation. The goal is to save design data alongside ticket content so downstream agents (planning, execution) have full context.

## Section 2: Figma Link Extraction

Extract Figma URLs from ticket markdown content.

### URL Patterns to Match

- `https://www.figma.com/file/{file_key}/{file_name}?node-id={node_id}`
- `https://www.figma.com/design/{file_key}/{file_name}?node-id={node_id}`
- `https://figma.com/file/{file_key}/...`
- `https://figma.com/design/{file_key}/...`

### Extraction Approach

```bash
# Extract all Figma URLs from ticket markdown
grep -oE 'https://[^/]*\.?figma\.com/(file|design)/[^ )\]"]+' "$TICKET_DIR/TICKET_DESCRIPTION.md" | sort -u
```

### Parse URL Components

For each URL, extract:

**file_key:** The segment after `/file/` or `/design/`

Example: from `figma.com/design/abc123def456/My-Design` extract `abc123def456`

```bash
file_key=$(echo "$url" | grep -oE '/(file|design)/[^/]+' | cut -d/ -f3)
```

**node_id:** From `?node-id=...` query parameter (optional, may not be present)

Note: May be URL-encoded as `%3A` for `:`

```bash
node_id=$(echo "$url" | grep -oE 'node-id=[^&"]+' | cut -d= -f2 | python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))")
```

## Section 3: Fetching Figma Design Data

For each extracted Figma link:

### Step 1: Get Design Structure

**If `node_id` is available:**
- Call `mcp__figma__get_file_nodes` with `file_key` and `node_id`
- This gives focused data for the specific frame/component referenced
- More efficient — returns only the relevant design node

**If only `file_key` (no node_id):**
- Call `mcp__figma__get_file` with `file_key`
- This gives the full file structure (may be large)
- Use when ticket references entire file, not specific node

### Step 2: Validate Response

Follow MCP validation patterns from `~/.claude/skills/jira/rules/mcp-utils.md`:

**Check isError flag:**
```bash
python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('isError', False):
    print('MCP_ERROR: ' + str(data.get('error', 'unknown')), file=sys.stderr)
    sys.exit(1)
sys.exit(0)
" <<< "$response"
```

**Retry logic (per D-03):**
- For Figma: 1 retry only with 30s wait
- Figma MCP is less critical and slower than Jira/Confluence
- If retry fails: log warning, mark figma status as "failed", continue with other sources

**Pattern:**
```bash
retry_figma_fetch() {
    local file_key="$1"
    local node_id="$2"
    local max_attempts=1
    local delay=30

    for attempt in $(seq 1 $((max_attempts + 1))); do
        echo "Attempt $attempt/2: Fetching Figma $file_key" >&2

        if [ -n "$node_id" ]; then
            result=$(mcp__figma__get_file_nodes file_key="$file_key" node_id="$node_id")
        else
            result=$(mcp__figma__get_file file_key="$file_key")
        fi

        # Validate response
        if echo "$result" | python3 -c "import json,sys; data=json.load(sys.stdin); sys.exit(0 if not data.get('isError') else 1)"; then
            echo "$result"
            return 0
        fi

        if [ "$attempt" -le "$max_attempts" ]; then
            echo "Figma fetch failed, retrying in ${delay}s..." >&2
            sleep "$delay"
        fi
    done

    echo "ERROR: Figma fetch failed after 1 retry" >&2
    return 1
}
```

### Step 3: Get Visual Screenshot

After fetching design data, export a visual screenshot:

**Call `mcp__figma__get_images`:**
- Pass `file_key` and `node_id` (if available)
- Request PNG format
- Save to `$TICKET_DIR/context/figma-{FILE_KEY}-screenshot.png`

**Pattern:**
```bash
# Export screenshot
screenshot_result=$(mcp__figma__get_images file_key="$file_key" node_ids="$node_id" format="png")

# Extract image URL from response and download
if ! echo "$screenshot_result" | python3 -c "import json,sys; data=json.load(sys.stdin); sys.exit(0 if not data.get('isError') else 1)"; then
    echo "WARNING: Screenshot export failed, continuing without screenshot" >&2
else
    # Parse image URL from MCP response and download
    image_url=$(echo "$screenshot_result" | python3 -c "import json,sys; data=json.load(sys.stdin); print(list(data.get('images', {}).values())[0] if data.get('images') else '')")
    if [ -n "$image_url" ]; then
        curl -sL "$image_url" -o "$TICKET_DIR/context/figma-$file_key-screenshot.png"
    fi
fi
```

**If screenshot export fails:** Log warning, continue without screenshot. Screenshot is nice-to-have, not critical.

## Section 4: Saving Figma Design Data

Save the design data to `$TICKET_DIR/context/figma-{FILE_KEY}.json`:

### Output Format

```json
{
  "source_url": "{original Figma URL}",
  "file_key": "{file_key}",
  "node_id": "{node_id or null}",
  "fetched_at": "{ISO timestamp}",
  "design_data": {
    // Raw MCP response data — component tree, styles, properties
  },
  "screenshot": "figma-{FILE_KEY}-screenshot.png"
}
```

### Save Pattern

Use Python for JSON serialization to ensure proper escaping and formatting:

```bash
python3 -c "
import json, sys
data = json.load(sys.stdin)
output = {
    'source_url': '$url',
    'file_key': '$file_key',
    'node_id': '$node_id' if '$node_id' else None,
    'fetched_at': '$(date -u +"%Y-%m-%dT%H:%M:%SZ")',
    'design_data': data,
    'screenshot': 'figma-$file_key-screenshot.png'
}
with open('$TICKET_DIR/context/figma-$file_key.json', 'w') as f:
    json.dump(output, f, indent=2)
" <<< "$figma_response"
```

### Large File Handling

If the Figma file is very large and `get_file` returns truncated data:

- Note this in the JSON output under a `truncated` field
- Log: "WARNING: Figma file {file_key} is very large, data may be truncated"
- Suggest: "Use get_file_nodes with a specific node_id for complete data"

This guides future agents to use more targeted fetching.

**Next step:** After saving design data, proceed to Section 4.5 for design token extraction.

## Section 4.5: Design Token Extraction (D-04, D-05)

After saving the design data JSON (Section 4), extract design tokens from the saved `figma-{FILE_KEY}.json` and save as `figma-{FILE_KEY}-tokens.json` in the same context directory.

**Important:** These tokens are advisory context only (D-04). Do NOT generate Tailwind config files, do NOT auto-modify any project source code. The tokens JSON file is consumed by the context consolidation step (Plan 02) to enrich the planning document with concrete design values.

### Token Extraction Steps

1. **Read** the saved `$TICKET_DIR/context/figma-$file_key.json` file.

2. **Parse** the `design_data` field from the JSON.

3. **Walk the node tree recursively**, extracting:

   **Colors:** From `fills[]` where `type === 'SOLID'`. Convert `color.r, color.g, color.b` (0-1 float range) to hex:
   ```
   Math.round(c * 255).toString(16).padStart(2, '0')
   ```
   for each RGB component. Record hex value and node name as usage context.

   **Typography:** From `style` objects with `fontSize`. Extract `fontFamily`, `fontSize`, `fontWeight`, `lineHeightPx`.

   **Spacing:** From `paddingLeft`, `paddingRight`, `paddingTop`, `paddingBottom`, `itemSpacing` properties where value > 0.

   **Border Radius:** From `cornerRadius` property where value > 0.

4. **Deduplicate:** Colors by hex value, spacing by value, typography by fontSize+fontWeight combo.

5. **Add Tailwind hints** using these lookup tables:

   **Colors:** Match hex against standard Tailwind palette:
   - `#3B82F6` = blue-500, `#EF4444` = red-500, `#10B981` = emerald-500
   - `#F59E0B` = amber-500, `#6366F1` = indigo-500, `#8B5CF6` = violet-500
   - `#EC4899` = pink-500, `#06B6D4` = cyan-500, `#F97316` = orange-500, `#14B8A6` = teal-500
   - `#FFFFFF` = white, `#000000` = black
   - `#F3F4F6` = gray-100, `#E5E7EB` = gray-200, `#D1D5DB` = gray-300
   - `#9CA3AF` = gray-400, `#6B7280` = gray-500, `#4B5563` = gray-600
   - `#374151` = gray-700, `#1F2937` = gray-800, `#111827` = gray-900
   - If no exact match, note "custom".

   **Typography fontSize:** 12=text-xs, 14=text-sm, 16=text-base, 18=text-lg, 20=text-xl, 24=text-2xl, 30=text-3xl, 36=text-4xl.

   **Typography fontWeight:** 400=font-normal, 500=font-medium, 600=font-semibold, 700=font-bold.

   **Spacing (px to Tailwind scale):** 4=1, 8=2, 12=3, 16=4, 20=5, 24=6, 32=8, 40=10, 48=12, 64=16. Format as `p-{n}`, `m-{n}`, or `gap-{n}` based on context (paddingLeft -> `pl-{n}`, itemSpacing -> `gap-{n}`).

   **Border radius:** 2=rounded-sm, 4=rounded, 6=rounded-md, 8=rounded-lg, 12=rounded-xl, 16=rounded-2xl, 9999=rounded-full.

6. **Save** the tokens JSON to `$TICKET_DIR/context/figma-$file_key-tokens.json` with this structure:

   ```json
   {
     "extracted_at": "{ISO timestamp}",
     "source_file": "figma-{FILE_KEY}.json",
     "colors": [
       { "hex": "#3B82F6", "usage": "fill on ButtonPrimary", "tailwind_hint": "blue-500" }
     ],
     "typography": [
       { "fontFamily": "Inter", "fontSize": 16, "fontWeight": 600, "lineHeight": 24, "tailwind_hint": "text-base font-semibold" }
     ],
     "spacing": [
       { "value": 16, "context": "paddingLeft", "tailwind_hint": "pl-4" }
     ],
     "borderRadius": [
       { "value": 8, "tailwind_hint": "rounded-lg" }
     ]
   }
   ```

7. **If token extraction fails** for any reason (malformed JSON, missing `design_data` field), log a warning and continue without tokens. Do NOT block the intake pipeline.

### Token Extraction Pattern

```bash
python3 -c "
import json, sys
from datetime import datetime, timezone

with open('$TICKET_DIR/context/figma-$file_key.json') as f:
    figma_data = json.load(f)

design_data = figma_data.get('design_data')
if not design_data:
    print('WARNING: No design_data field in figma-$file_key.json, skipping token extraction', file=sys.stderr)
    sys.exit(0)

# Tailwind color lookup
tw_colors = {
    '#3B82F6': 'blue-500', '#EF4444': 'red-500', '#10B981': 'emerald-500',
    '#F59E0B': 'amber-500', '#6366F1': 'indigo-500', '#8B5CF6': 'violet-500',
    '#EC4899': 'pink-500', '#06B6D4': 'cyan-500', '#F97316': 'orange-500',
    '#14B8A6': 'teal-500', '#FFFFFF': 'white', '#000000': 'black',
    '#F3F4F6': 'gray-100', '#E5E7EB': 'gray-200', '#D1D5DB': 'gray-300',
    '#9CA3AF': 'gray-400', '#6B7280': 'gray-500', '#4B5563': 'gray-600',
    '#374151': 'gray-700', '#1F2937': 'gray-800', '#111827': 'gray-900',
}
tw_font_size = {12: 'text-xs', 14: 'text-sm', 16: 'text-base', 18: 'text-lg', 20: 'text-xl', 24: 'text-2xl', 30: 'text-3xl', 36: 'text-4xl'}
tw_font_weight = {400: 'font-normal', 500: 'font-medium', 600: 'font-semibold', 700: 'font-bold'}
tw_spacing = {4: '1', 8: '2', 12: '3', 16: '4', 20: '5', 24: '6', 32: '8', 40: '10', 48: '12', 64: '16'}
tw_radius = {2: 'rounded-sm', 4: 'rounded', 6: 'rounded-md', 8: 'rounded-lg', 12: 'rounded-xl', 16: 'rounded-2xl', 9999: 'rounded-full'}
spacing_prefix = {'paddingLeft': 'pl', 'paddingRight': 'pr', 'paddingTop': 'pt', 'paddingBottom': 'pb', 'itemSpacing': 'gap'}

tokens = {'colors': [], 'typography': [], 'spacing': [], 'borderRadius': []}
seen_colors = set()
seen_spacing = set()
seen_typo = set()

def walk(node):
    if not isinstance(node, dict):
        return
    name = node.get('name', 'unknown')
    # Colors
    for fill in (node.get('fills') or []):
        if fill.get('type') == 'SOLID' and fill.get('color'):
            c = fill['color']
            h = '#' + ''.join(format(round(c.get(k, 0) * 255), '02x') for k in ('r', 'g', 'b'))
            h_upper = h.upper()
            if h_upper not in seen_colors:
                seen_colors.add(h_upper)
                tokens['colors'].append({'hex': h_upper, 'usage': f'fill on {name}', 'tailwind_hint': tw_colors.get(h_upper, 'custom')})
    # Typography
    style = node.get('style') or {}
    if style.get('fontSize'):
        key = (style.get('fontSize'), style.get('fontWeight'))
        if key not in seen_typo:
            seen_typo.add(key)
            fs_hint = tw_font_size.get(style['fontSize'], f'text-[{style[\"fontSize\"]}px]')
            fw_hint = tw_font_weight.get(style.get('fontWeight', 400), f'font-[{style.get(\"fontWeight\", 400)}]')
            tokens['typography'].append({
                'fontFamily': style.get('fontFamily', 'unknown'),
                'fontSize': style['fontSize'],
                'fontWeight': style.get('fontWeight', 400),
                'lineHeight': style.get('lineHeightPx'),
                'tailwind_hint': f'{fs_hint} {fw_hint}'
            })
    # Spacing
    for prop in ('paddingLeft', 'paddingRight', 'paddingTop', 'paddingBottom', 'itemSpacing'):
        val = node.get(prop)
        if val is not None and val > 0 and val not in seen_spacing:
            seen_spacing.add(val)
            prefix = spacing_prefix.get(prop, 'p')
            tw_val = tw_spacing.get(val, f'[{val}px]')
            tokens['spacing'].append({'value': val, 'context': prop, 'tailwind_hint': f'{prefix}-{tw_val}'})
    # Border radius
    cr = node.get('cornerRadius')
    if cr is not None and cr > 0:
        if not any(br['value'] == cr for br in tokens['borderRadius']):
            tokens['borderRadius'].append({'value': cr, 'tailwind_hint': tw_radius.get(cr, f'rounded-[{cr}px]')})
    # Recurse
    for child in (node.get('children') or []):
        walk(child)

# Handle both get_file_nodes (has nodes map) and get_file (has document)
if isinstance(design_data, dict):
    if 'nodes' in design_data:
        for nd in design_data['nodes'].values():
            walk(nd.get('document', nd))
    elif 'document' in design_data:
        walk(design_data['document'])
    else:
        walk(design_data)

output = {
    'extracted_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'source_file': 'figma-$file_key.json',
    **tokens
}
with open('$TICKET_DIR/context/figma-$file_key-tokens.json', 'w') as f:
    json.dump(output, f, indent=2)
print(f'Tokens extracted: {len(tokens[\"colors\"])} colors, {len(tokens[\"typography\"])} typography, {len(tokens[\"spacing\"])} spacing, {len(tokens[\"borderRadius\"])} borderRadius')
" 2>&1 || echo "WARNING: Token extraction failed, continuing without tokens"
```

### State File Update

After token extraction, update `.state.json` to include the tokens file:

```json
{
  "sources": {
    "figma": {
      "status": "success",
      "files": ["context/figma-abc123.json", "context/figma-abc123-tokens.json"],
      "tokens_extracted": true
    }
  }
}
```

If token extraction failed but design data was saved successfully, set `tokens_extracted: false` while keeping `status: "success"` (the design data fetch itself succeeded).

## Section 6: No Figma Links Found (formerly Section 5)

**Scenario:** No Figma links are found in the ticket content

**Action:**
- Mark figma status as "skipped" in state file
- Do not create any files in context/
- Log: "No Figma links found in ticket"

**This is normal:** Not all tickets have Figma references. Ticket is still valid without Figma context.

## Section 7: Error Handling (per D-03)

### Partial Context Resilience

Figma is best-effort with reduced retry: 1 retry only (not 3 like Jira/Confluence)

**If MCP fails after the single retry:**
- Log: `WARNING: Figma design data fetch failed for {file_key}: {reason}`
- Mark status as "failed" in state file
- Continue with ticket processing — do NOT block planning

**The ticket is still valid without Figma context.** Jira content (description, attachments) is critical; Figma is supplemental.

### Security

**Never include any API keys or tokens in error messages.**

When logging Figma failures:
- ✓ Good: "Figma MCP timeout after 1 retry"
- ✓ Good: "Figma file abc123 not found"
- ✗ Bad: "Figma API token xyz789 invalid"

### State File Updates

After Figma fetch completes (success or failure), update `.state.json`:

```json
{
  "sources": {
    "figma": {
      "status": "success",  // or "failed" or "skipped"
      "files": ["context/figma-abc123.json"],
      "error": null  // or error message if failed
    }
  }
}
```

**Status values:**
- `success`: Figma data fetched and saved
- `failed`: MCP error after retry, could not fetch
- `skipped`: No Figma links found in ticket

## Section 8: Multiple Figma Links

**Scenario:** Ticket contains multiple Figma links (different files or nodes)

**Action:**
- Process each link separately
- Save each to its own JSON file: `figma-{FILE_KEY}.json`
- If multiple nodes from same file, save once with all node data
- Update state file with array of saved files

**Pattern:**
```bash
figma_links=$(grep -oE 'https://[^/]*\.?figma\.com/(file|design)/[^ )\]"]+' "$TICKET_DIR/TICKET_DESCRIPTION.md" | sort -u)

for url in $figma_links; do
    file_key=$(extract_file_key "$url")
    node_id=$(extract_node_id "$url")

    # Skip if already processed this file_key
    if [ -f "$TICKET_DIR/context/figma-$file_key.json" ]; then
        echo "Figma $file_key already fetched, skipping" >&2
        continue
    fi

    # Fetch and save
    fetch_figma_design "$url" "$file_key" "$node_id"
done
```

## Section 9: Integration with Jira Fetch Workflow

This rule is called from `~/.claude/skills/jira/rules/fetch.md` after Jira ticket and attachments are saved.

**Invocation:**
```bash
# In jira/rules/fetch.md, after Jira ticket saved:
fetch_figma_context "$TICKET_DIR/TICKET_DESCRIPTION.md" "$TICKET_DIR"
```

**Expected behavior:**
1. Scan TICKET_DESCRIPTION.md for Figma URLs
2. If found: fetch design data and save to context/
3. If not found: mark status as "skipped"
4. If MCP fails: mark status as "failed", continue
5. Update .state.json with results
6. Return success (even if Figma failed — partial context is OK)

**Do NOT block ticket intake on Figma failures.** The ticket is still usable for planning without Figma context.
