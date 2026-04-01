#!/bin/bash
#
# Jira + GSD + Kimi Orchestrator
# Combines Jira ticket fetching with GSD planning and kimi execution
#

set -e

TICKET_KEY="$1"
ACTION="${2:-full}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

validate_ticket() {
    if [[ ! "$TICKET_KEY" =~ ^MT-[0-9]+$ ]]; then
        log_error "Invalid ticket key. Expected: MT-XXXX"
        exit 1
    fi
}

show_help() {
    cat << EOF
Jira-GSD-Kimi Orchestrator

Usage: $0 <MT-XXXX> [action]

Actions:
  fetch      - Fetch Jira ticket and context only
  init       - Initialize GSD for ticket
  plan       - Create GSD plans for ticket
  execute    - Execute with kimi
  full       - Run complete workflow (default)
  help       - Show this help

Examples:
  $0 MT-1234          # Full workflow
  $0 MT-1234 fetch    # Just fetch ticket
  $0 MT-1234 plan     # Create plans
  $0 MT-1234 execute  # Execute with kimi

EOF
}

fetch_ticket() {
    log_info "Fetching Jira ticket: $TICKET_KEY"
    
    # This would use MCP Atlassian via kimi
    # For now, create structure for manual input
    
    GSD_DIR=".planning/jira-${TICKET_KEY}"
    mkdir -p "$GSD_DIR"
    
    cat > "$GSD_DIR/ticket.md" << EOF
# ${TICKET_KEY}

## Summary
[To be filled from Jira]

## Description
[To be filled from Jira]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Links
- Jira: https://medtasker.atlassian.net/browse/${TICKET_KEY}

## Notes
[Confluence/Figma context]
EOF

    log_success "Created ticket structure: $GSD_DIR/ticket.md"
    echo "   Fill in details from Jira, then run: $0 $TICKET_KEY init"
}

init_gsd() {
    log_info "Initializing GSD for $TICKET_KEY"
    
    # Ensure GSD is initialized
    if [ ! -d ".planning" ]; then
        gsd init
    fi
    
    # Create milestone for ticket
    gsd new-milestone --name "$TICKET_KEY"
    
    # Copy ticket context
    TICKET_DIR=".planning/jira-${TICKET_KEY}"
    if [ -f "$TICKET_DIR/ticket.md" ]; then
        # Create first phase context from ticket
        mkdir -p ".planning/phase-1-${TICKET_KEY}"
        cp "$TICKET_DIR/ticket.md" ".planning/phase-1-${TICKET_KEY}/1-CONTEXT.md"
        log_success "Created phase context from ticket"
    fi
    
    log_success "GSD initialized for $TICKET_KEY"
    echo "   Next: Run '$0 $TICKET_KEY plan' or 'gsd plan-phase 1'"
}

create_plan() {
    log_info "Creating plans for $TICKET_KEY"
    
    # Create plans for phase 1
    gsd plan-phase 1
    
    # Enhance plan with ticket context
    PLAN_FILE=".planning/phase-1-${TICKET_KEY}/1-1-PLAN.md"
    if [ -f "$PLAN_FILE" ]; then
        log_info "Plan created: $PLAN_FILE"
        echo "   Edit this file to add specific implementation details"
    fi
}

execute_plan() {
    log_info "Executing plans for $TICKET_KEY"
    
    # Find phase directory
    PHASE_DIR=$(find .planning -type d -name "phase-1-*" | head -1)
    
    if [ -z "$PHASE_DIR" ]; then
        log_error "Phase directory not found"
        exit 1
    fi
    
    log_info "Found phase directory: $PHASE_DIR"
    
    # Run kimi with GSD agent
    kimi --agent-file "$HOME/.kimi/skills/gsd-kimi/gsd-agent.yaml" \
         --yolo \
         --prompt "Execute all plans in $PHASE_DIR. Follow the XML task structure. Commit after each task. Write SUMMARY.md when complete."
    
    log_success "Execution complete for $TICKET_KEY"
}

full_workflow() {
    log_info "Starting full workflow for $TICKET_KEY"
    
    fetch_ticket
    init_gsd
    create_plan
    
    log_info "Ready for execution"
    echo ""
    echo "Next steps:"
    echo "  1. Review and edit: .planning/phase-1-*/1-CONTEXT.md"
    echo "  2. Review and edit: .planning/phase-1-*/1-1-PLAN.md"
    echo "  3. Execute: $0 $TICKET_KEY execute"
    echo ""
    read -p "Execute now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        execute_plan
    fi
}

# Main
main() {
    case "$ACTION" in
        help|--help|-h)
            show_help
            ;;
        fetch)
            validate_ticket
            fetch_ticket
            ;;
        init)
            validate_ticket
            init_gsd
            ;;
        plan)
            validate_ticket
            create_plan
            ;;
        execute)
            validate_ticket
            execute_plan
            ;;
        full)
            validate_ticket
            full_workflow
            ;;
        *)
            log_error "Unknown action: $ACTION"
            show_help
            exit 1
            ;;
    esac
}

main
