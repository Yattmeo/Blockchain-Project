#!/bin/bash

################################################################################
# Complete System Teardown Script
# Weather Index Insurance Platform
#
# This script completely stops and cleans the system:
# 1. Stop UI
# 2. Stop API Gateway
# 3. Stop Fabric network
# 4. Remove containers and volumes
# 5. Clean artifacts
################################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORK_DIR="${SCRIPT_DIR}/network"
API_DIR="${SCRIPT_DIR}/api-gateway"
UI_DIR="${SCRIPT_DIR}/insurance-ui"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}║      Weather Index Insurance Platform - System Teardown       ║${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Helper functions
print_step() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "  $1"
}

# Confirmation prompt
confirm_teardown() {
    echo -e "${YELLOW}⚠ WARNING: This will stop and remove all system components!${NC}"
    echo ""
    echo "This will:"
    echo "  • Stop UI and API Gateway"
    echo "  • Stop Fabric network"
    echo "  • Remove all Docker containers and volumes"
    echo "  • Clean all blockchain data"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Teardown cancelled."
        exit 0
    fi
}

# Step 1: Stop UI
stop_ui() {
    print_step "Step 1: Stopping UI"
    
    print_info "Killing UI processes on port 5173..."
    lsof -ti:5173 | xargs kill -9 2>/dev/null || true
    
    print_info "Stopping Vite dev server..."
    pkill -f "vite" 2>/dev/null || true
    pkill -f "npm run dev" 2>/dev/null || true
    
    # Clean UI logs
    if [ -f "${UI_DIR}/ui.log" ]; then
        rm "${UI_DIR}/ui.log"
        print_info "Removed UI logs"
    fi
    
    print_success "UI stopped"
    echo ""
}

# Step 2: Stop API Gateway
stop_api_gateway() {
    print_step "Step 2: Stopping API Gateway"
    
    print_info "Killing API processes on port 3001..."
    lsof -ti:3001 | xargs kill -9 2>/dev/null || true
    
    print_info "Stopping Node.js processes..."
    pkill -f "npm start" 2>/dev/null || true
    pkill -f "node.*api-gateway" 2>/dev/null || true
    
    # Clean API logs
    if [ -f "${API_DIR}/api-gateway.log" ]; then
        rm "${API_DIR}/api-gateway.log"
        print_info "Removed API logs"
    fi
    
    print_success "API Gateway stopped"
    echo ""
}

# Step 3: Stop Fabric network
stop_fabric_network() {
    print_step "Step 3: Stopping Hyperledger Fabric Network"
    
    cd "${NETWORK_DIR}"
    
    print_info "Bringing down network..."
    ./network.sh down 2>/dev/null || docker compose down --volumes --remove-orphans 2>/dev/null || true
    
    print_success "Fabric network stopped"
    echo ""
}

# Step 4: Remove Docker artifacts
clean_docker() {
    print_step "Step 4: Cleaning Docker Artifacts"
    
    print_info "Removing chaincode containers..."
    docker ps -a | grep "dev-peer" | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true
    
    print_info "Removing chaincode images..."
    docker images | grep "dev-peer" | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true
    
    print_info "Removing unused volumes..."
    docker volume prune -f > /dev/null 2>&1 || true
    
    print_info "Removing unused networks..."
    docker network prune -f > /dev/null 2>&1 || true
    
    print_success "Docker artifacts cleaned"
    echo ""
}

# Step 5: Clean build artifacts
clean_build_artifacts() {
    print_step "Step 5: Cleaning Build Artifacts"
    
    # Clean API build
    if [ -d "${API_DIR}/dist" ]; then
        print_info "Removing API build artifacts..."
        rm -rf "${API_DIR}/dist"
    fi
    
    # Clean UI build
    if [ -d "${UI_DIR}/dist" ]; then
        print_info "Removing UI build artifacts..."
        rm -rf "${UI_DIR}/dist"
    fi
    
    # Clean chaincode packages (optional)
    # print_info "Removing chaincode packages..."
    # find "${SCRIPT_DIR}/chaincode" -name "*.tar.gz" -delete 2>/dev/null || true
    
    print_success "Build artifacts cleaned"
    echo ""
}

# Step 6: Verify cleanup
verify_cleanup() {
    print_step "Step 6: Verifying Cleanup"
    
    local all_clean=1
    
    # Check no containers running
    print_info "Checking for running containers..."
    CONTAINERS=$(docker ps | grep -E "(peer|orderer|ca)" | wc -l)
    if [ "$CONTAINERS" -eq 0 ]; then
        print_success "No Fabric containers running"
    else
        print_warning "$CONTAINERS Fabric containers still running"
        all_clean=0
    fi
    
    # Check ports are free
    print_info "Checking ports..."
    if ! lsof -i:3001 > /dev/null 2>&1; then
        print_success "Port 3001 (API) is free"
    else
        print_warning "Port 3001 is still in use"
        all_clean=0
    fi
    
    if ! lsof -i:5173 > /dev/null 2>&1; then
        print_success "Port 5173 (UI) is free"
    else
        print_warning "Port 5173 is still in use"
        all_clean=0
    fi
    
    # Check no chaincode images
    print_info "Checking chaincode images..."
    CC_IMAGES=$(docker images | grep "dev-peer" | wc -l)
    if [ "$CC_IMAGES" -eq 0 ]; then
        print_success "No chaincode images remaining"
    else
        print_warning "$CC_IMAGES chaincode images still present"
        all_clean=0
    fi
    
    echo ""
    
    if [ $all_clean -eq 1 ]; then
        return 0
    else
        print_warning "Some components may not be fully cleaned"
        return 1
    fi
}

# Optional: Deep clean
deep_clean() {
    print_step "Optional: Deep Clean"
    
    echo -e "${YELLOW}Do you want to perform a deep clean?${NC}"
    echo "This will:"
    echo "  • Remove all Docker containers (including non-Fabric)"
    echo "  • Remove all Docker images"
    echo "  • Remove all Docker volumes"
    echo "  • Free up maximum disk space"
    echo ""
    read -p "Perform deep clean? (yes/no): " -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Removing all stopped containers..."
        docker container prune -f > /dev/null 2>&1
        
        print_info "Removing all unused images..."
        docker image prune -a -f > /dev/null 2>&1
        
        print_info "Removing all unused volumes..."
        docker volume prune -f > /dev/null 2>&1
        
        print_info "Removing all unused networks..."
        docker network prune -f > /dev/null 2>&1
        
        print_success "Deep clean completed"
        
        # Show disk space reclaimed
        echo ""
        print_info "Docker disk usage after cleanup:"
        docker system df
    else
        print_info "Skipping deep clean"
    fi
    
    echo ""
}

# Show summary
show_summary() {
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║              ✓ TEARDOWN COMPLETED SUCCESSFULLY!               ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}System Status:${NC}"
    echo -e "  • UI: Stopped"
    echo -e "  • API Gateway: Stopped"
    echo -e "  • Fabric Network: Stopped"
    echo -e "  • Containers: Removed"
    echo -e "  • Volumes: Cleaned"
    echo ""
    echo -e "${YELLOW}To redeploy the system:${NC}"
    echo -e "  ${BLUE}./deploy-complete-system.sh${NC}"
    echo ""
    echo -e "${YELLOW}To deploy and run tests:${NC}"
    echo -e "  ${BLUE}./deploy-complete-system.sh && ./test-e2e-complete.sh${NC}"
    echo ""
}

# Main teardown flow
main() {
    local start_time=$(date +%s)
    
    confirm_teardown
    stop_ui
    stop_api_gateway
    stop_fabric_network
    clean_docker
    clean_build_artifacts
    verify_cleanup
    deep_clean
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    show_summary
    
    echo -e "${BLUE}Time taken: ${duration}s${NC}"
    echo ""
}

# Run main teardown
main
