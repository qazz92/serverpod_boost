#!/bin/bash
# ServerPod Boost Installation Script
# Installs ServerPod Boost into a ServerPod project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}ServerPod Boost Installation${NC}"
echo "=================================="
echo ""

# Function to check if current directory is a ServerPod project
check_serverpod_project() {
    local dir="$1"

    # Check for *_server directory
    if ls "${dir}"/*_server/ >/dev/null 2>&1; then
        return 0
    fi

    # Check if we're in the server directory
    if [[ -f "${dir}/lib/server.dart" ]] && [[ -d "${dir}/config" ]]; then
        return 0
    fi

    return 1
}

# Find project root
find_project_root() {
    local current_dir="$(pwd)"

    # Check if we're in a ServerPod project
    if check_serverpod_project "$current_dir"; then
        echo "$current_dir"
        return 0
    fi

    # Check if we're in the server directory
    if [[ -f "lib/server.dart" ]] && [[ -d "config" ]]; then
        # Go up one level (should be monorepo root)
        cd ..
        echo "$(pwd)"
        return 0
    fi

    return 1
}

# Check if we're in the boost source directory
if [[ -f "$SCRIPT_DIR/../pubspec.yaml" ]] && grep -q "serverpod_boost" "$SCRIPT_DIR/../pubspec.yaml"; then
    # We're in the boost source directory
    echo -e "${YELLOW}Running from ServerPod Boost source directory${NC}"
    echo ""
    echo "To install ServerPod Boost into a ServerPod project:"
    echo "  1. Navigate to your ServerPod project root"
    echo "  2. Run: bash /path/to/serverpod_boost/bin/install.sh"
    echo ""
    exit 0
fi

# Find project root
PROJECT_ROOT=$(find_project_root)

if [[ -z "$PROJECT_ROOT" ]]; then
    echo -e "${RED}Error: Not in a ServerPod project${NC}"
    echo ""
    echo "This script must be run from within a ServerPod project."
    echo "Please navigate to your ServerPod project root and try again."
    exit 1
fi

echo -e "${GREEN}✓${NC} Detected ServerPod project at: $PROJECT_ROOT"
echo ""

# Create .ai/boost directory
BOOST_DIR="${PROJECT_ROOT}/.ai/boost"
echo "Creating Boost directory at: $BOOST_DIR"
mkdir -p "$BOOST_DIR/lib"
mkdir -p "$BOOST_DIR/bin"

# Copy files if running from source
if [[ -d "$SCRIPT_DIR/../.git" ]] || [[ -f "$SCRIPT_DIR/../pubspec.yaml" ]]; then
    echo -e "${BLUE}Copying ServerPod Boost files...${NC}"

    # Copy lib files
    if [[ -d "$SCRIPT_DIR/../lib" ]]; then
        cp -r "$SCRIPT_DIR/../lib/"* "$BOOST_DIR/lib/"
    fi

    # Copy bin files
    if [[ -d "$SCRIPT_DIR/../bin" ]]; then
        cp -r "$SCRIPT_DIR/../bin/"* "$BOOST_DIR/bin/"
    fi

    # Copy pubspec.yaml
    if [[ -f "$SCRIPT_DIR/../pubspec.yaml" ]]; then
        cp "$SCRIPT_DIR/../pubspec.yaml" "$BOOST_DIR/"
    fi

    # Create pubspec override for local development
    cat > "$BOOST_DIR/pubspec_overrides.yaml" << EOF
# ServerPod Boost local development override
dependency_overrides:
  serverpod_boost:
    path: $SCRIPT_DIR/..
EOF

    echo -e "${GREEN}✓${NC} Files copied successfully"
else
    echo -e "${YELLOW}Warning: Could not find source files to copy${NC}"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Navigate to .ai/boost directory:"
echo "     ${YELLOW}cd .ai/boost${NC}"
echo ""
echo "  2. Get dependencies:"
echo "     ${YELLOW}dart pub get${NC}"
echo ""
echo -e "${BLUE}Claude Desktop Configuration:${NC}"
echo ""
echo 'Add to ~/Library/Application Support/Claude/claude_desktop_config.json:'
echo ""
cat << EOF
{
  "mcpServers": {
    "serverpod-boost": {
      "command": "dart",
      "args": ["run", ".ai/boost/bin/boost.dart"],
      "cwd": "$PROJECT_ROOT"
    }
  }
}
EOF
echo ""
echo -e "${BLUE}For verbose logging, add environment variable:${NC}"
echo '  "env": { "SERVERPOD_BOOST_VERBOSE": "true" }'
echo ""
echo -e "${GREEN}Happy coding with ServerPod Boost! 🚀${NC}"
