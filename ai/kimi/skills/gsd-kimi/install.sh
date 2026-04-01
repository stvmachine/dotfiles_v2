#!/bin/bash
# GSD for Kimi - Installation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📦 Installing GSD for Kimi..."

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
REQUIRED_VERSION="3.10"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Python 3.10+ required. Found: $PYTHON_VERSION"
    exit 1
fi

# Install gsd command
echo "🔧 Installing gsd command..."
pip install -e "$SCRIPT_DIR" --quiet

# Create kimi plans directory
mkdir -p "$HOME/.kimi/plans"
mkdir -p "$HOME/.kimi/logs"

# Add to kimi config if not present
KIMI_CONFIG="$HOME/.kimi/config.toml"
if [ -f "$KIMI_CONFIG" ]; then
    echo "⚙️  Kimi config found"
else
    echo "📝 Creating kimi config..."
fi

echo ""
echo "✅ GSD for Kimi installed successfully!"
echo ""
echo "Commands available:"
echo "  gsd init              - Initialize GSD project"
echo "  gsd status            - Show status"
echo "  gsd new-milestone     - Create milestone"
echo "  gsd discuss-phase N   - Discuss phase N"
echo "  gsd plan-phase N      - Plan phase N"
echo ""
echo "In kimi, use:"
echo "  /gsd:init             - Initialize (via kimi slash command)"
echo "  kimi --prompt 'Execute plan in .planning/phase-1/'"
echo ""
echo "Documentation: ~/.kimi/skills/gsd-kimi/SKILL.md"
