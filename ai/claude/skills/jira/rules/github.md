# GitHub Reference Analysis Rule

Extract GitHub links from ticket content and analyze PR/repo references using gh CLI. Covers INTAKE-05.

## Section 1: When This Rule Runs

- Called by the fetch workflow (rules/fetch.md) after TICKET_DESCRIPTION.md is created
- Input: the full ticket content (description + comments text)
- Output: `todo/MT-XXXX/context/github-pr-{NUMBER}.md` or `todo/MT-XXXX/context/github-issue-{NUMBER}.md` files

## Section 2: GitHub Link Extraction

Instructions for finding GitHub URLs in ticket content:

- Scan description AND all comments for GitHub URLs
- URL patterns to match:
  - PR: `https://github.com/{owner}/{repo}/pull/{number}`
  - Issue: `https://github.com/{owner}/{repo}/issues/{number}`
  - Repo: `https://github.com/{owner}/{repo}`
  - File: `https://github.com/{owner}/{repo}/blob/{branch}/{path}`
  - Commit: `https://github.com/{owner}/{repo}/commit/{sha}`

- Extraction approach:
```bash
# Extract all GitHub URLs from ticket markdown
grep -oE 'https://github\.com/[^ )\]"]+' "$TICKET_DIR/TICKET_DESCRIPTION.md" | sort -u
```

- Classify each URL by type (PR, issue, repo, file, commit):
```bash
classify_github_url() {
    local url="$1"

    if echo "$url" | grep -q '/pull/[0-9]\+'; then
        echo "pr"
    elif echo "$url" | grep -q '/issues/[0-9]\+'; then
        echo "issue"
    elif echo "$url" | grep -q '/commit/[a-f0-9]\+'; then
        echo "commit"
    elif echo "$url" | grep -q '/blob/'; then
        echo "file"
    else
        echo "repo"
    fi
}
```

## Section 3: PR Analysis (most common case)

For each PR URL (`github.com/{owner}/{repo}/pull/{number}`):

1. Extract owner, repo, and PR number from URL:
```bash
extract_pr_info() {
    local url="$1"

    # Extract owner/repo/number
    # URL format: https://github.com/owner/repo/pull/123
    owner=$(echo "$url" | grep -oE 'github\.com/[^/]+' | cut -d/ -f2)
    repo=$(echo "$url" | grep -oE 'github\.com/[^/]+/[^/]+' | cut -d/ -f3)
    number=$(echo "$url" | grep -oE '/pull/[0-9]+' | grep -oE '[0-9]+')

    echo "$owner|$repo|$number"
}
```

2. Use gh CLI to fetch PR details:
```bash
gh pr view "$number" --repo "$owner/$repo" --json title,body,state,author,additions,deletions,changedFiles,files,reviews,comments
```

3. If gh CLI is not installed or fails: log warning, mark github status as "failed", continue
4. Save to `$TICKET_DIR/context/github-pr-{NUMBER}.md` with this format:

```markdown
# PR #{NUMBER}: {TITLE}

**Repository:** {owner}/{repo}
**Source:** {PR URL}
**State:** {open/closed/merged}
**Author:** {author login}
**Changes:** +{additions} -{deletions} across {changedFiles} files

## Description

{PR body}

## Files Changed

{List of changed files with status: added/modified/deleted}

## Review Summary

{Number of approvals, requested changes, comments}
```

**Complete PR fetch implementation:**
```bash
fetch_github_pr() {
    local owner="$1"
    local repo="$2"
    local number="$3"
    local pr_url="$4"
    local ticket_dir="$5"

    # Check gh CLI availability and authentication
    if ! command -v gh &> /dev/null; then
        echo "WARNING: gh CLI not installed, skipping PR analysis" >&2
        return 1
    fi

    if ! gh auth status 2>&1 | grep -q "Logged in"; then
        echo "WARNING: gh CLI not authenticated, skipping PR analysis" >&2
        return 1
    fi

    # Fetch PR data
    pr_json=$(gh pr view "$number" --repo "$owner/$repo" \
        --json title,body,state,author,additions,deletions,changedFiles,files,reviews,comments 2>&1)

    if [ $? -ne 0 ]; then
        echo "WARNING: Failed to fetch PR #$number from $owner/$repo" >&2
        return 1
    fi

    # Extract fields using Python
    python3 -c "
import json, sys
pr = json.load(sys.stdin)
title = pr.get('title', 'Untitled')
body = pr.get('body', 'No description')
state = pr.get('state', 'unknown')
author = pr.get('author', {}).get('login', 'unknown')
additions = pr.get('additions', 0)
deletions = pr.get('deletions', 0)
changed_files = pr.get('changedFiles', 0)
files = pr.get('files', [])
reviews = pr.get('reviews', [])

# Generate markdown
print(f'# PR #{$number}: {title}')
print()
print(f'**Repository:** $owner/$repo')
print(f'**Source:** $pr_url')
print(f'**State:** {state}')
print(f'**Author:** {author}')
print(f'**Changes:** +{additions} -{deletions} across {changed_files} files')
print()
print('## Description')
print()
print(body)
print()
print('## Files Changed')
print()
for f in files:
    status = f.get('status', 'modified')
    path = f.get('path', '')
    print(f'- [{status}] {path}')
print()
print('## Review Summary')
print()
approved = sum(1 for r in reviews if r.get('state') == 'APPROVED')
changes_req = sum(1 for r in reviews if r.get('state') == 'CHANGES_REQUESTED')
print(f'- Approvals: {approved}')
print(f'- Changes requested: {changes_req}')
print(f'- Total reviews: {len(reviews)}')
" <<< "$pr_json" > "$ticket_dir/context/github-pr-$number.md"
}
```

## Section 4: Issue Reference Analysis

For each issue URL (`github.com/{owner}/{repo}/issues/{number}`):

1. Use gh CLI:
```bash
gh issue view "$number" --repo "$owner/$repo" --json title,body,state,author,labels,comments
```

2. Save to `$TICKET_DIR/context/github-issue-{NUMBER}.md` with title, body, state, labels:

```markdown
# Issue #{NUMBER}: {TITLE}

**Repository:** {owner}/{repo}
**Source:** {Issue URL}
**State:** {open/closed}
**Author:** {author login}
**Labels:** {comma-separated labels}

## Description

{Issue body}

## Recent Comments

{Last 3 comments with author and date}
```

**Complete issue fetch implementation:**
```bash
fetch_github_issue() {
    local owner="$1"
    local repo="$2"
    local number="$3"
    local issue_url="$4"
    local ticket_dir="$5"

    # Fetch issue data
    issue_json=$(gh issue view "$number" --repo "$owner/$repo" \
        --json title,body,state,author,labels,comments 2>&1)

    if [ $? -ne 0 ]; then
        echo "WARNING: Failed to fetch issue #$number from $owner/$repo" >&2
        return 1
    fi

    # Generate markdown
    python3 -c "
import json, sys
issue = json.load(sys.stdin)
title = issue.get('title', 'Untitled')
body = issue.get('body', 'No description')
state = issue.get('state', 'unknown')
author = issue.get('author', {}).get('login', 'unknown')
labels = ', '.join([l.get('name', '') for l in issue.get('labels', [])])
comments = issue.get('comments', [])

print(f'# Issue #{$number}: {title}')
print()
print(f'**Repository:** $owner/$repo')
print(f'**Source:** $issue_url')
print(f'**State:** {state}')
print(f'**Author:** {author}')
print(f'**Labels:** {labels or \"none\"}')
print()
print('## Description')
print()
print(body)
print()
print('## Recent Comments')
print()
for c in comments[:3]:  # Last 3 comments
    c_author = c.get('author', {}).get('login', 'unknown')
    c_date = c.get('createdAt', '')
    c_body = c.get('body', '')
    print(f'**{c_author}** ({c_date}):')
    print(c_body)
    print()
" <<< "$issue_json" > "$ticket_dir/context/github-issue-$number.md"
}
```

## Section 5: Repo and File References

- For repo links: note the repository name and URL, no deep fetch needed
- For file links: note the file path and branch, include the URL for manual reference
- For commit links: note the commit SHA and URL

- These are saved as entries in TICKET_DESCRIPTION.md References section (already handled by fetch.md), not as separate context files

**Reference tracking:**
```bash
# Extract metadata without creating separate files
extract_repo_reference() {
    local url="$1"
    owner=$(echo "$url" | grep -oE 'github\.com/[^/]+' | cut -d/ -f2)
    repo=$(echo "$url" | grep -oE 'github\.com/[^/]+/[^/]+' | cut -d/ -f3)
    echo "Repository: $owner/$repo - $url"
}

extract_file_reference() {
    local url="$1"
    # Extract file path and branch from URL
    # Format: github.com/owner/repo/blob/branch/path/to/file.ext
    path=$(echo "$url" | sed 's|.*/blob/[^/]*/||')
    branch=$(echo "$url" | grep -oE '/blob/[^/]+' | cut -d/ -f3)
    echo "File: $path (branch: $branch) - $url"
}

extract_commit_reference() {
    local url="$1"
    sha=$(echo "$url" | grep -oE '/commit/[a-f0-9]+' | cut -d/ -f3)
    echo "Commit: $sha - $url"
}
```

## Section 6: No GitHub Links Found

- If no GitHub links are found in the ticket content, mark github status as "skipped" in state file
- Do not create any files in context/
- This is normal — not all tickets have GitHub references

**Implementation:**
```bash
GITHUB_URLS=$(grep -oE 'https://github\.com/[^ )\]"]+' "$TICKET_DIR/TICKET_DESCRIPTION.md" | sort -u)

if [ -z "$GITHUB_URLS" ]; then
    echo "No GitHub links found in ticket"
    mark_source_status "github" "skipped"
    return 0
fi
```

## Section 7: Error Handling

- GitHub analysis is best-effort: if gh CLI is not available, skip entirely and mark as "failed" with error "gh CLI not installed"
- If gh CLI fails for a specific PR/issue, log warning and continue with other references
- Never include any auth tokens in error messages
- Check gh auth status first: `gh auth status 2>&1` — if not authenticated, mark as "failed" with error "gh CLI not authenticated"

**Complete error handling pattern:**
```bash
fetch_all_github_references() {
    local ticket_dir="$1"

    # Pre-flight check for gh CLI
    if ! command -v gh &> /dev/null; then
        echo "WARNING: gh CLI not installed, skipping all GitHub analysis" >&2
        mark_source_status "github" "failed" "gh CLI not installed"
        return 0
    fi

    if ! gh auth status 2>&1 | grep -q "Logged in"; then
        echo "WARNING: gh CLI not authenticated, skipping all GitHub analysis" >&2
        mark_source_status "github" "failed" "gh CLI not authenticated"
        return 0
    fi

    # Extract and classify GitHub URLs
    urls=$(grep -oE 'https://github\.com/[^ )\]"]+' "$ticket_dir/TICKET_DESCRIPTION.md" | sort -u)

    if [ -z "$urls" ]; then
        mark_source_status "github" "skipped"
        return 0
    fi

    # Process each URL
    failed_count=0
    success_count=0

    while IFS= read -r url; do
        url_type=$(classify_github_url "$url")

        case "$url_type" in
            pr)
                IFS='|' read -r owner repo number <<< "$(extract_pr_info "$url")"
                if fetch_github_pr "$owner" "$repo" "$number" "$url" "$ticket_dir"; then
                    ((success_count++))
                else
                    ((failed_count++))
                fi
                ;;
            issue)
                IFS='|' read -r owner repo number <<< "$(extract_issue_info "$url")"
                if fetch_github_issue "$owner" "$repo" "$number" "$url" "$ticket_dir"; then
                    ((success_count++))
                else
                    ((failed_count++))
                fi
                ;;
            *)
                # Repo/file/commit references tracked but not fetched
                ;;
        esac
    done <<< "$urls"

    # Mark final status
    if [ "$success_count" -gt 0 ]; then
        mark_source_status "github" "success"
    elif [ "$failed_count" -gt 0 ]; then
        mark_source_status "github" "failed" "Some references failed to fetch"
    else
        mark_source_status "github" "skipped"
    fi
}
```

**Security note:** Never log or expose GitHub authentication tokens, personal access tokens, or any other credentials in error messages or debug output.
