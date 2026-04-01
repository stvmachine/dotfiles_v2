#!/bin/bash
#
# Jira-Kimi Orchestrator Script
# Automates the workflow from Jira ticket to code completion
#

set -e

# Configuration
TICKET_KEY="$1"
ACTION="${2:-full}"
KIMI_PLANS_DIR="$HOME/.kimi/plans"
KIMI_LOGS_DIR="$HOME/.kimi/logs"
PLANNING_DIR=".planning"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

validate_ticket_key() {
    if [[ ! "$TICKET_KEY" =~ ^MT-[0-9]+$ ]]; then
        log_error "Invalid ticket key format. Expected: MT-XXXX"
        exit 1
    fi
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check gh CLI
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) not found. Install: https://cli.github.com/"
        exit 1
    fi
    
    # Check kimi
    if ! command -v kimi &> /dev/null; then
        log_error "kimi CLI not found. Install: https://github.com/moonshot-ai/kimi-cli"
        exit 1
    fi
    
    # Check directories
    mkdir -p "$KIMI_PLANS_DIR"
    mkdir -p "$KIMI_LOGS_DIR"
    
    log_success "Prerequisites check passed"
}

fetch_jira_context() {
    log_info "Fetching Jira ticket: $TICKET_KEY"
    
    # This will be handled by Claude via MCP
    # We create a placeholder that Claude will populate
    CONTEXT_FILE="$PLANNING_DIR/${TICKET_KEY}-CONTEXT.md"
    
    log_info "Context will be saved to: $CONTEXT_FILE"
    echo "$CONTEXT_FILE"
}

create_branch() {
    log_info "Creating feature branch..."
    
    # Get ticket summary for branch name
    # This would come from Jira - placeholder
    BRANCH_NAME="feature/${TICKET_KEY}-implementation"
    
    # Check if branch exists
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        log_warn "Branch $BRANCH_NAME already exists"
        git checkout "$BRANCH_NAME"
    else
        git checkout -b "$BRANCH_NAME"
        git push -u origin "$BRANCH_NAME"
        log_success "Created and pushed branch: $BRANCH_NAME"
    fi
    
    echo "$BRANCH_NAME"
}

create_kimi_plan() {
    log_info "Creating kimi plan..."
    
    PLAN_FILE="$KIMI_PLANS_DIR/${TICKET_KEY}.md"
    
    cat > "$PLAN_FILE" << EOF
# Plan: ${TICKET_KEY}

## Overview
[To be populated by Claude with ticket context]

## Context
See: ${PLANNING_DIR}/${TICKET_KEY}-CONTEXT.md

## Implementation Steps
[To be populated by Claude from GSD plans]

## Git Commands
\`\`\`bash
# When done:
git add .
git commit -m "feat(${TICKET_KEY}): [description]"
git push origin $(git branch --show-current)
\`\`\`

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
EOF
    
    log_success "Created kimi plan: $PLAN_FILE"
    echo "$PLAN_FILE"
}

execute_kimi() {
    log_info "Executing kimi plan..."
    
    PLAN_FILE="$KIMI_PLANS_DIR/${TICKET_KEY}.md"
    LOG_FILE="$KIMI_LOGS_DIR/${TICKET_KEY}-$(date +%Y%m%d-%H%M%S).log"
    
    if [[ ! -f "$PLAN_FILE" ]]; then
        log_error "Plan file not found: $PLAN_FILE"
        exit 1
    fi
    
    log_info "Starting kimi execution (log: $LOG_FILE)"
    
    kimi --yolo --print \
        --prompt "Execute the plan in $PLAN_FILE. Work through each step systematically. Commit changes with clear messages. Push when complete. Return a summary of what was done." \
        > "$LOG_FILE" 2>&1
    
    EXIT_CODE=$?
    
    if [[ $EXIT_CODE -eq 0 ]]; then
        log_success "Kimi execution completed successfully"
    else
        log_error "Kimi execution failed (exit code: $EXIT_CODE)"
        log_info "Check log: $LOG_FILE"
    fi
    
    echo "$LOG_FILE"
    return $EXIT_CODE
}

show_status() {
    log_info "Jira-Kimi Orchestrator Status"
    echo ""
    
    echo "📋 Kimi Plans:"
    ls -1 "$KIMI_PLANS_DIR"/MT-*.md 2>/dev/null | while read -r f; do
        echo "  - $(basename "$f")"
    done || echo "  (none)"
    
    echo ""
    echo "🌿 Feature Branches:"
    git branch -a | grep "feature/MT-" || echo "  (none)"
    
    echo ""
    echo "🔀 Open PRs:"
    gh pr list --search "MT-" --state open 2>/dev/null || echo "  (none)"
    
    echo ""
    echo "📜 Recent Logs:"
    ls -1t "$KIMI_LOGS_DIR"/MT-*.log 2>/dev/null | head -5 | while read -r f; do
        echo "  - $(basename "$f")"
    done || echo "  (none)"
}

# Main
main() {
    if [[ -z "$TICKET_KEY" && "$ACTION" != "status" ]]; then
        echo "Usage: $0 <MT-XXXX> [context|plan|execute|full|status]"
        echo ""
        echo "Actions:"
        echo "  context  - Fetch Jira context only"
        echo "  plan     - Create GSD and kimi plans"
        echo "  execute  - Execute kimi plan"
        echo "  full     - Run complete workflow (default)"
        echo "  status   - Show workflow status"
        exit 1
    fi
    
    case "$ACTION" in
        status)
            show_status
            ;;
        context)
            validate_ticket_key
            check_prerequisites
            fetch_jira_context
            ;;
        plan)
            validate_ticket_key
            check_prerequisites
            fetch_jira_context
            create_branch
            create_kimi_plan
            ;;
        execute)
            validate_ticket_key
            check_prerequisites
            execute_kimi
            ;;
        full)
            validate_ticket_key
            check_prerequisites
            fetch_jira_context
            create_branch
            create_kimi_plan
            execute_kimi
            log_success "Workflow complete for $TICKET_KEY"
            ;;
        *)
            log_error "Unknown action: $ACTION"
            exit 1
            ;;
    esac
}

main
