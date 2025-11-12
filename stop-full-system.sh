#!/bin/bash

# Stop Full System Script
# Stops UI, API Gateway, and Fabric network

echo "=================================================="
echo "Stopping Full Insurance System"
echo "=================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ========================================
# 1. Stop UI Development Server
# ========================================

echo -e "${BLUE}[1/3] Stopping UI Development Server...${NC}"

if [ -f ".ui-dev.pid" ]; then
    UI_PID=$(cat .ui-dev.pid)
    if ps -p $UI_PID > /dev/null 2>&1; then
        kill $UI_PID
        echo -e "${GREEN}✓ UI server stopped (PID: $UI_PID)${NC}"
    else
        echo "UI server not running"
    fi
    rm .ui-dev.pid
else
    # Try to kill by port
    if lsof -ti:5173 &> /dev/null; then
        kill -9 $(lsof -ti:5173) 2>/dev/null || true
        echo -e "${GREEN}✓ UI server on port 5173 stopped${NC}"
    else
        echo "UI server not running on port 5173"
    fi
fi

# ========================================
# 2. Stop API Gateway
# ========================================

echo ""
echo -e "${BLUE}[2/3] Stopping API Gateway...${NC}"

if [ -f ".api-gateway.pid" ]; then
    API_PID=$(cat .api-gateway.pid)
    if ps -p $API_PID > /dev/null 2>&1; then
        kill $API_PID
        echo -e "${GREEN}✓ API Gateway stopped (PID: $API_PID)${NC}"
    else
        echo "API Gateway not running"
    fi
    rm .api-gateway.pid
else
    # Try to kill by port
    if lsof -ti:3001 &> /dev/null; then
        kill -9 $(lsof -ti:3001) 2>/dev/null || true
        echo -e "${GREEN}✓ API Gateway on port 3001 stopped${NC}"
    else
        echo "API Gateway not running on port 3001"
    fi
fi

# ========================================
# 3. Stop Fabric Network (Optional)
# ========================================

echo ""
echo -e "${BLUE}[3/3] Fabric Network...${NC}"
echo -e "${YELLOW}Do you want to stop the Fabric network? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    cd network
    ./network.sh down
    cd ..
    echo -e "${GREEN}✓ Fabric network stopped${NC}"
else
    echo "Fabric network left running"
fi

# ========================================
# COMPLETE
# ========================================

echo ""
echo -e "${GREEN}=================================================="
echo "✅ System Stopped"
echo "==================================================${NC}"
echo ""
echo "Services stopped:"
echo "  • UI Development Server"
echo "  • API Gateway"
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "  • Fabric Network"
fi
echo ""

