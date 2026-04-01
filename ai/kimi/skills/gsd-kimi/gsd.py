#!/usr/bin/env python3
"""
GSD (Get Shit Done) for Kimi CLI
A standalone spec-driven development system
"""

import os
import sys
import json
import argparse
import re
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict, Any

# Constants
PLANNING_DIR = ".planning"
CONFIG_FILE = f"{PLANNING_DIR}/config.json"
STATE_FILE = f"{PLANNING_DIR}/STATE.md"
PROJECT_FILE = f"{PLANNING_DIR}/PROJECT.md"
REQUIREMENTS_FILE = f"{PLANNING_DIR}/REQUIREMENTS.md"
ROADMAP_FILE = f"{PLANNING_DIR}/ROADMAP.md"


class GSDError(Exception):
    """GSD-specific error"""
    pass


class GSD:
    """Main GSD controller"""
    
    def __init__(self):
        self.root = Path.cwd()
        self.planning_dir = self.root / PLANNING_DIR
        
    def init_project(self, name: Optional[str] = None):
        """Initialize new GSD project"""
        if not name:
            name = self.root.name
            
        if self.planning_dir.exists():
            print(f"⚠️  GSD already initialized in {self.planning_dir}")
            return
            
        print(f"🚀 Initializing GSD project: {name}")
        
        # Create directories
        self.planning_dir.mkdir(parents=True)
        
        # Create config
        config = {
            "version": "1.0.0",
            "mode": "interactive",
            "granularity": "standard",
            "created": datetime.now().isoformat(),
            "agents": {
                "research": True,
                "plan_check": True,
                "verifier": True
            },
            "git": {
                "branching_strategy": "phase",
                "commit_docs": True
            }
        }
        
        with open(self.planning_dir / "config.json", "w") as f:
            json.dump(config, f, indent=2)
            
        # Create PROJECT.md
        project_content = f"""# {name}

## Overview
Project initialized with GSD (Get Shit Done) methodology.

## Tech Stack
- To be defined

## Goals
- To be defined

## Conventions
- Commit: Conventional Commits
- Planning: GSD phases

## Getting Started
1. Run `/gsd:new-milestone` to create roadmap
2. Work through phases with `/gsd:discuss-phase`, `/gsd:plan-phase`, `/gsd:execute-phase`
"""
        
        with open(self.planning_dir / "PROJECT.md", "w") as f:
            f.write(project_content)
            
        # Create STATE.md
        state_content = f"""# State

## Project
- **Name**: {name}
- **Initialized**: {datetime.now().isoformat()}

## Current
- **Milestone**: None
- **Phase**: None

## Completed
None

## Blockers
None

## Decisions
None
"""
        
        with open(self.planning_dir / "STATE.md", "w") as f:
            f.write(state_content)
            
        print(f"✅ GSD project initialized in {self.planning_dir}")
        print(f"   Next: Run `/gsd:new-milestone` to create your first milestone")
        
    def get_phase_dir(self, phase_num: int) -> Path:
        """Get phase directory, finding by number if exact name unknown"""
        # Try to find existing phase directory
        for item in self.planning_dir.iterdir():
            if item.is_dir() and item.name.startswith(f"phase-{phase_num}-"):
                return item
        # Return default naming if not found
        return self.planning_dir / f"phase-{phase_num}"
        
    def get_status(self):
        """Show current GSD status"""
        if not self.planning_dir.exists():
            print("❌ GSD not initialized. Run: gsd init")
            return
            
        print("📊 GSD Status\n")
        
        # Read STATE.md
        state_path = self.planning_dir / "STATE.md"
        if state_path.exists():
            content = state_path.read_text()
            # Extract current milestone/phase
            milestone = self._extract_field(content, "Milestone")
            phase = self._extract_field(content, "Phase")
            print(f"Current Milestone: {milestone or 'None'}")
            print(f"Current Phase: {phase or 'None'}")
            
        # List phases
        print("\n📁 Phases:")
        phases = sorted([d for d in self.planning_dir.iterdir() 
                        if d.is_dir() and d.name.startswith("phase-")])
        
        if phases:
            for phase_dir in phases:
                status = "⏳"
                summary_file = phase_dir / f"{phase_dir.name.replace('phase-', '').split('-')[0]}-SUMMARY.md"
                if summary_file.exists():
                    status = "✅"
                context_file = phase_dir / f"{phase_dir.name.replace('phase-', '').split('-')[0]}-CONTEXT.md"
                if context_file.exists() and not summary_file.exists():
                    status = "🔄"
                print(f"  {status} {phase_dir.name}")
        else:
            print("  (none)")
            
        # Show roadmap
        roadmap_path = self.planning_dir / "ROADMAP.md"
        if roadmap_path.exists():
            print("\n📋 Roadmap exists")
            
        print("\nNext steps:")
        if not phases:
            print("  - Run: gsd new-milestone")
        else:
            print(f"  - Run: gsd discuss-phase {len(phases)}")
            
    def _extract_field(self, content: str, field: str) -> Optional[str]:
        """Extract field value from markdown"""
        pattern = rf"- \*\*{field}\*\*: (.+)"
        match = re.search(pattern, content)
        return match.group(1).strip() if match else None
        
    def new_milestone(self, name: Optional[str] = None):
        """Create new milestone"""
        if not self.planning_dir.exists():
            raise GSDError("GSD not initialized. Run: gsd init")
            
        print("🎯 Creating new milestone\n")
        
        if not name:
            name = input("Milestone name: ")
            
        # Create REQUIREMENTS.md
        req_content = f"""# Requirements: {name}

## Overview
Milestone created: {datetime.now().isoformat()}

## Goals
- Define your goals here

## Requirements

### Must Have (v1)
| ID | Requirement | Priority | Phase |
|----|-------------|----------|-------|
| R1 | Core feature | P0 | 1 |

### Should Have (v2)
| ID | Requirement | Priority | Phase |
|----|-------------|----------|-------|

### Won't Have
- Out of scope items

## Acceptance Criteria
- [ ] Milestone complete

## Constraints
- Time, budget, technical constraints
"""
        
        with open(self.planning_dir / "REQUIREMENTS.md", "w") as f:
            f.write(req_content)
            
        # Create ROADMAP.md
        roadmap_content = f"""# Roadmap: {name}

## Overview
{name} milestone

## Phases

### Phase 1: Foundation
**Goal**: Set up project structure and core components
**Deliverables**:
- Project skeleton
- Basic configuration
**Requirements**: R1
**Status**: Not Started

### Phase 2: Core Features
**Goal**: Implement main functionality
**Deliverables**:
- Feature set 1
- Feature set 2
**Requirements**: R1
**Status**: Not Started

## Status
| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| 1 | Not Started | - | - |
| 2 | Not Started | - | - |

## Notes
Add planning notes here
"""
        
        with open(self.planning_dir / "ROADMAP.md", "w") as f:
            f.write(roadmap_content)
            
        # Update STATE.md
        state_path = self.planning_dir / "STATE.md"
        if state_path.exists():
            content = state_path.read_text()
            content = content.replace(
                "- **Milestone**: None",
                f"- **Milestone**: {name}"
            )
            content = content.replace(
                "- **Phase**: None",
                "- **Phase**: 1"
            )
            state_path.write_text(content)
            
        print(f"✅ Milestone '{name}' created")
        print(f"   - {REQUIREMENTS_FILE}")
        print(f"   - {ROADMAP_FILE}")
        print(f"\n   Next: Edit {ROADMAP_FILE} to define your phases")
        print(f"   Then: Run 'gsd discuss-phase 1'")
        
    def discuss_phase(self, phase_num: int):
        """Start discussion phase"""
        phase_dir = self.get_phase_dir(phase_num)
        phase_dir.mkdir(exist_ok=True)
        
        # Extract phase name from ROADMAP
        roadmap_path = self.planning_dir / "ROADMAP.md"
        phase_name = f"Phase {phase_num}"
        
        if roadmap_path.exists():
            content = roadmap_path.read_text()
            match = re.search(rf"### Phase {phase_num}: (.+)", content)
            if match:
                phase_name = match.group(1).strip()
                
        # Create CONTEXT.md
        context_file = phase_dir / f"{phase_num}-CONTEXT.md"
        
        context_content = f"""# Context: Phase {phase_num} - {phase_name}

## Phase Goal
What this phase accomplishes

## Requirements
List requirements from REQUIREMENTS.md

## Decisions

### Architecture
**Decision**: 
**Rationale**: 

### Implementation
**Decision**: 
**Rationale**: 

## Technical Details

### Approach
How we'll implement

### Constraints
- Constraint 1
- Constraint 2

## Open Questions
- [ ] Question 1
- [ ] Question 2

## Notes
Add context here
"""
        
        context_file.write_text(context_content)
        
        print(f"📝 Created context for Phase {phase_num}: {phase_name}")
        print(f"   File: {context_file}")
        print(f"\n   Edit this file to capture:")
        print(f"   - Implementation decisions")
        print(f"   - Technical approach")
        print(f"   - Constraints and questions")
        print(f"\n   Then run: gsd plan-phase {phase_num}")
        
    def plan_phase(self, phase_num: int):
        """Create plans for phase"""
        phase_dir = self.get_phase_dir(phase_num)
        
        if not phase_dir.exists():
            raise GSDError(f"Phase {phase_num} not found. Run: gsd discuss-phase {phase_num}")
            
        context_file = phase_dir / f"{phase_num}-CONTEXT.md"
        if not context_file.exists():
            raise GSDError(f"Context not found: {context_file}")
            
        print(f"📐 Planning Phase {phase_num}\n")
        
        # Create RESEARCH.md
        research_file = phase_dir / f"{phase_num}-RESEARCH.md"
        research_content = f"""# Research: Phase {phase_num}

## Stack Analysis
Current technology stack

## Implementation Options

### Option 1: Approach A
- Pros: Fast, simple
- Cons: Less flexible
- Complexity: Low

### Option 2: Approach B
- Pros: Scalable, robust
- Cons: More complex
- Complexity: Medium

## Recommendation
Recommended approach with justification

## Potential Pitfalls
- Issue and mitigation

## Resources
- Documentation links
- Example projects
"""
        research_file.write_text(research_content)
        
        # Create PLAN.md
        plan_file = phase_dir / f"{phase_num}-1-PLAN.md"
        plan_content = f"""<?xml version="1.0"?>
<plan>
  <metadata>
    <phase>{phase_num}</phase>
    <plan>1</plan>
    <name>Implementation Plan</name>
    <estimated_hours>4</estimated_hours>
    <created>{datetime.now().isoformat()}</created>
  </metadata>
  
  <overview>
    Implement phase {phase_num} requirements
  </overview>
  
  <prerequisites>
    <item>Phase context defined</item>
    <item>Research complete</item>
  </prerequisites>
  
  <tasks>
    <task type="auto" priority="1">
      <id>{phase_num}-1-001</id>
      <name>Setup and Configuration</name>
      <files>config files</files>
      <action>
        Set up project structure and configuration
      </action>
      <verify>
        Configuration is valid
      </verify>
      <done>
        Setup complete
      </done>
    </task>
    
    <task type="auto" priority="2">
      <id>{phase_num}-1-002</id>
      <name>Core Implementation</name>
      <files>source files</files>
      <action>
        Implement core functionality
      </action>
      <verify>
        Tests pass
      </verify>
      <done>
        Implementation complete
      </done>
    </task>
  </tasks>
  
  <verification>
    <overall>
      All tasks complete, tests pass
    </overall>
    <acceptance_criteria>
      <criterion id="1">Feature works as expected</criterion>
      <criterion id="2">Tests pass</criterion>
    </acceptance_criteria>
  </verification>
</plan>
"""
        plan_file.write_text(plan_content)
        
        print(f"✅ Created plans for Phase {phase_num}")
        print(f"   - {research_file}")
        print(f"   - {plan_file}")
        print(f"\n   Edit these files with your specific implementation details")
        print(f"   Then run: gsd execute-phase {phase_num}")


def main():
    parser = argparse.ArgumentParser(
        description="GSD (Get Shit Done) for Kimi CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  gsd init                    Initialize GSD project
  gsd status                  Show current status
  gsd new-milestone           Create new milestone
  gsd discuss-phase 1         Discuss phase 1
  gsd plan-phase 1            Plan phase 1
  gsd execute-phase 1         Execute phase 1
        """
    )
    
    parser.add_argument(
        "command",
        choices=["init", "status", "new-milestone", "discuss-phase", 
                 "plan-phase", "execute-phase", "verify-phase", "ship"],
        help="GSD command to run"
    )
    
    parser.add_argument(
        "arg",
        nargs="?",
        help="Command argument (e.g., phase number)"
    )
    
    parser.add_argument(
        "--name",
        help="Project or milestone name"
    )
    
    args = parser.parse_args()
    
    gsd = GSD()
    
    try:
        if args.command == "init":
            gsd.init_project(args.name)
            
        elif args.command == "status":
            gsd.get_status()
            
        elif args.command == "new-milestone":
            gsd.new_milestone(args.name)
            
        elif args.command == "discuss-phase":
            if not args.arg:
                print("❌ Phase number required")
                print("   Usage: gsd discuss-phase <number>")
                sys.exit(1)
            gsd.discuss_phase(int(args.arg))
            
        elif args.command == "plan-phase":
            if not args.arg:
                print("❌ Phase number required")
                print("   Usage: gsd plan-phase <number>")
                sys.exit(1)
            gsd.plan_phase(int(args.arg))
            
        elif args.command == "execute-phase":
            print("⚠️  Execute phase requires kimi agent")
            print(f"   Run: kimi --prompt 'Execute plan in .planning/phase-{args.arg}/'")
            
        elif args.command == "verify-phase":
            print("⚠️  Verify phase requires manual review")
            print(f"   Check: .planning/phase-{args.arg}/*-SUMMARY.md")
            
        elif args.command == "ship":
            print("⚠️  Ship requires git commands")
            print("   Create PR with: gh pr create")
            
    except GSDError as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
        

if __name__ == "__main__":
    main()
