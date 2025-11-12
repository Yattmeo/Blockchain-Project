#!/bin/bash

################################################################################
# Cleanup Script for Temporary Files
# Removes old logs and temporary files to keep the directory clean
################################################################################

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Cleaning Up Temporary Files                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Remove old log files from root directory
echo "Removing old deployment logs..."
rm -f "${SCRIPT_DIR}/deploy-output.log"
rm -f "${SCRIPT_DIR}/deploy-full.log"
rm -f "${SCRIPT_DIR}/deploy-phase2.log"
rm -f "${SCRIPT_DIR}/deployment-fresh.log"
rm -f "${SCRIPT_DIR}/test-output.log"
rm -f "${SCRIPT_DIR}/deployment-output.txt"
echo -e "${GREEN}✓${NC} Old log files removed"

# Clean up API Gateway logs (keep only latest)
if [ -d "${SCRIPT_DIR}/api-gateway/logs" ]; then
    echo "Cleaning API Gateway logs..."
    # Keep only the most recent log file
    cd "${SCRIPT_DIR}/api-gateway/logs"
    ls -t api-gateway*.log 2>/dev/null | tail -n +2 | xargs rm -f 2>/dev/null || true
    echo -e "${GREEN}✓${NC} API Gateway logs cleaned"
fi

# Clean up network artifacts (only when network is down)
if ! docker ps | grep -q "peer0.insurer1.insurance.com"; then
    echo "Network is down, cleaning artifacts..."
    rm -rf "${SCRIPT_DIR}/network/channel-artifacts/"*.block 2>/dev/null || true
    rm -rf "${SCRIPT_DIR}/network/channel-artifacts/"*.tx 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Network artifacts cleaned"
else
    echo -e "${YELLOW}⚠${NC} Network is running, skipping artifact cleanup"
fi

# Clean up node_modules cache (optional, only if requested)
if [ "$1" == "--deep" ]; then
    echo "Deep cleaning (node_modules, build artifacts)..."
    
    # Remove node_modules if present
    if [ -d "${SCRIPT_DIR}/api-gateway/node_modules" ]; then
        echo "  Removing API Gateway node_modules..."
        rm -rf "${SCRIPT_DIR}/api-gateway/node_modules"
    fi
    
    if [ -d "${SCRIPT_DIR}/insurance-ui/node_modules" ]; then
        echo "  Removing UI node_modules..."
        rm -rf "${SCRIPT_DIR}/insurance-ui/node_modules"
    fi
    
    # Remove build artifacts
    rm -rf "${SCRIPT_DIR}/api-gateway/dist"
    rm -rf "${SCRIPT_DIR}/insurance-ui/dist"
    
    echo -e "${GREEN}✓${NC} Deep clean completed"
fi

echo ""
echo -e "${GREEN}Cleanup completed successfully!${NC}"
echo ""

if [ "$1" != "--deep" ]; then
    echo "Tip: Run with --deep flag to also remove node_modules and build artifacts"
    echo "  ./cleanup-temp-files.sh --deep"
fi

