#!/bin/bash

################################################################################
# Deployment Validation Script
# Validates that the deployed system has all required components and data
################################################################################

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

API_BASE="http://localhost:3001/api"
PASSED=0
FAILED=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Validating System Deployment                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_field="$3"
    
    echo -n "Testing $name... "
    
    RESPONSE=$(curl -s "$url")
    
    if echo "$RESPONSE" | jq -e "$expected_field" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  Response: $RESPONSE"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# 1. Test API Gateway Health
echo -e "${YELLOW}1. API Gateway${NC}"
test_endpoint "Health Check" "http://localhost:3001/health" ".status"

# 2. Test Templates
echo -e "${YELLOW}2. Policy Templates${NC}"
test_endpoint "Active Templates" "${API_BASE}/policy-templates" '.data[0].status'
TEMPLATE_STATUS=$(curl -s "${API_BASE}/policy-templates/TEMPLATE_RICE_DROUGHT_001" | jq -r '.data.status // "Unknown"')
if [ "$TEMPLATE_STATUS" == "Active" ]; then
    echo -e "  Template status: ${GREEN}Active${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "  Template status: ${RED}$TEMPLATE_STATUS${NC}"
    FAILED=$((FAILED + 1))
fi

# 3. Test Farmers
echo -e "${YELLOW}3. Farmers${NC}"
test_endpoint "Farmers by Coop" "${API_BASE}/farmers/by-coop/COOP001" '.data[0].farmerID'
FARMER_COUNT=$(curl -s "${API_BASE}/farmers/by-coop/COOP001" | jq '.data | length')
echo "  Total farmers registered: $FARMER_COUNT"

# 4. Test Policies
echo -e "${YELLOW}4. Policies${NC}"
test_endpoint "Active Policies" "${API_BASE}/policies" '.data[0].policyID'
POLICY_COUNT=$(curl -s "${API_BASE}/policies" | jq '.data | length')
echo "  Total active policies: $POLICY_COUNT"

# 5. Test Premium Pool
echo -e "${YELLOW}5. Premium Pool${NC}"
test_endpoint "Pool Balance" "${API_BASE}/premium-pool/balance" '.data'
BALANCE=$(curl -s "${API_BASE}/premium-pool/balance" | jq -r '.data // 0')
if (( $(echo "$BALANCE > 0" | bc -l 2>/dev/null || echo 0) )); then
    echo -e "  Pool balance: ${GREEN}\$$BALANCE${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "  Pool balance: ${RED}\$$BALANCE (should be > 0)${NC}"
    FAILED=$((FAILED + 1))
fi

# 6. Test Dashboard
echo -e "${YELLOW}6. Dashboard Statistics${NC}"
test_endpoint "Dashboard Stats" "${API_BASE}/dashboard/stats" '.data.totalFarmers'
STATS=$(curl -s "${API_BASE}/dashboard/stats" | jq '.data')
echo "  Statistics:"
echo "$STATS" | jq -r 'to_entries | .[] | "    \(.key): \(.value)"'

# 7. Test Approvals
echo -e "${YELLOW}7. Approval System${NC}"
test_endpoint "Pending Approvals" "${API_BASE}/approval/pending" '.data'

# 8. Verify UI is accessible
echo -e "${YELLOW}8. User Interface${NC}"
echo -n "Testing UI accessibility... "
if curl -s -f http://localhost:5173 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  UI running at: ${BLUE}http://localhost:5173${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "  UI not responding on http://localhost:5173"
    FAILED=$((FAILED + 1))
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "Validation Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All validation checks passed!${NC}"
    echo ""
    echo "System is ready for use:"
    echo "  • UI: ${BLUE}http://localhost:5173${NC}"
    echo "  • API: ${BLUE}http://localhost:3001${NC}"
    echo ""
    echo "Demo credentials:"
    echo "  • Admin: admin / admin123"
    echo "  • Insurer: insurer1 / insurer123"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some validation checks failed${NC}"
    echo ""
    echo "Please check:"
    echo "  • Network is running: docker ps"
    echo "  • API logs: api-gateway/logs/api-gateway.log"
    echo "  • Redeploy: ./deploy-complete-system.sh"
    echo ""
    exit 1
fi

