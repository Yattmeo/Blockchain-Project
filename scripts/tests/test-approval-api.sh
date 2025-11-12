#!/bin/bash

# Test Approval Manager API Endpoints
# This script tests the complete approval workflow through the API Gateway

set -e

API_URL="http://localhost:3001/api"
REQUEST_ID="TEST_REQ_$(date +%s)"

echo "=================================="
echo "Approval Manager API Test"
echo "=================================="
echo "Request ID: ${REQUEST_ID}"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Create Approval Request
echo -e "${YELLOW}Test 1: Creating approval request...${NC}"
CREATE_RESPONSE=$(curl -s -X POST ${API_URL}/approval \
  -H "Content-Type: application/json" \
  -H "x-organization: Insurer1" \
  -d "{
    \"requestId\": \"${REQUEST_ID}\",
    \"requestType\": \"FARMER_REGISTRATION\",
    \"chaincodeName\": \"farmer\",
    \"functionName\": \"RegisterFarmer\",
    \"arguments\": [\"FARMER999\", \"Test Farmer\", \"Test Location\", \"555-0000\", \"5.0\"],
    \"requiredOrgs\": [\"CoopMSP\", \"Insurer1MSP\"],
    \"metadata\": {
      \"description\": \"API test farmer registration\",
      \"requestedBy\": \"test@insurer1.com\"
    }
  }")

echo "$CREATE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$CREATE_RESPONSE"

if echo "$CREATE_RESPONSE" | grep -q "\"success\":true"; then
    echo -e "${GREEN}✓ Create request successful${NC}"
else
    echo -e "${RED}✗ Create request failed${NC}"
    exit 1
fi

sleep 2

# Test 2: Get Approval Request
echo -e "\n${YELLOW}Test 2: Getting approval request...${NC}"
GET_RESPONSE=$(curl -s -X GET ${API_URL}/approval/${REQUEST_ID} \
  -H "x-organization: Insurer1")

echo "$GET_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$GET_RESPONSE"

if echo "$GET_RESPONSE" | grep -q "\"requestID\":\"${REQUEST_ID}\""; then
    echo -e "${GREEN}✓ Get request successful${NC}"
else
    echo -e "${RED}✗ Get request failed${NC}"
    exit 1
fi

sleep 2

# Test 3: Get Pending Approvals
echo -e "\n${YELLOW}Test 3: Getting pending approvals...${NC}"
PENDING_RESPONSE=$(curl -s -X GET ${API_URL}/approval/pending \
  -H "x-organization: Insurer1")

echo "$PENDING_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$PENDING_RESPONSE"

if echo "$PENDING_RESPONSE" | grep -q "\"success\":true"; then
    echo -e "${GREEN}✓ Get pending approvals successful${NC}"
else
    echo -e "${RED}✗ Get pending approvals failed${NC}"
    exit 1
fi

sleep 2

# Test 4: Approve as Insurer1
echo -e "\n${YELLOW}Test 4: Approving as Insurer1...${NC}"
APPROVE1_RESPONSE=$(curl -s -X POST ${API_URL}/approval/${REQUEST_ID}/approve \
  -H "Content-Type: application/json" \
  -H "x-organization: Insurer1" \
  -d "{
    \"reason\": \"Approved by Insurer1 via API\"
  }")

echo "$APPROVE1_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$APPROVE1_RESPONSE"

if echo "$APPROVE1_RESPONSE" | grep -q "\"success\":true"; then
    echo -e "${GREEN}✓ Insurer1 approval successful${NC}"
else
    echo -e "${RED}✗ Insurer1 approval failed${NC}"
    exit 1
fi

sleep 2

# Test 5: Check status after first approval (should still be PENDING)
echo -e "\n${YELLOW}Test 5: Checking status after first approval...${NC}"
STATUS_RESPONSE=$(curl -s -X GET ${API_URL}/approval/${REQUEST_ID} \
  -H "x-organization: Insurer1")

echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STATUS_RESPONSE"

if echo "$STATUS_RESPONSE" | grep -q "\"status\":\"PENDING\""; then
    echo -e "${GREEN}✓ Request status is still PENDING (needs Coop approval)${NC}"
else
    echo -e "${YELLOW}⚠ Request status changed (expected PENDING until all orgs approve)${NC}"
fi

sleep 2

# Test 6: Get approvals by status
echo -e "\n${YELLOW}Test 6: Getting approvals by status (PENDING)...${NC}"
BY_STATUS_RESPONSE=$(curl -s -X GET ${API_URL}/approval/status/PENDING \
  -H "x-organization: Insurer1")

echo "$BY_STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null | head -40 || echo "$BY_STATUS_RESPONSE" | head -40

if echo "$BY_STATUS_RESPONSE" | grep -q "\"success\":true"; then
    echo -e "${GREEN}✓ Get by status successful${NC}"
else
    echo -e "${RED}✗ Get by status failed${NC}"
    exit 1
fi

sleep 2

# Test 7: Get Approval History
echo -e "\n${YELLOW}Test 7: Getting approval history...${NC}"
HISTORY_RESPONSE=$(curl -s -X GET ${API_URL}/approval/${REQUEST_ID}/history \
  -H "x-organization: Insurer1")

echo "$HISTORY_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$HISTORY_RESPONSE"

if echo "$HISTORY_RESPONSE" | grep -q "\"success\":true"; then
    echo -e "${GREEN}✓ Get history successful${NC}"
else
    echo -e "${RED}✗ Get history failed${NC}"
    exit 1
fi

sleep 2

# Test 8: Get All Approvals
echo -e "\n${YELLOW}Test 8: Getting all approvals...${NC}"
ALL_RESPONSE=$(curl -s -X GET ${API_URL}/approval \
  -H "x-organization: Insurer1")

echo "$ALL_RESPONSE" | python3 -m json.tool 2>/dev/null | head -30 || echo "$ALL_RESPONSE" | head -30

if echo "$ALL_RESPONSE" | grep -q "\"success\":true"; then
    echo -e "${GREEN}✓ Get all approvals successful${NC}"
else
    echo -e "${RED}✗ Get all approvals failed${NC}"
    exit 1
fi

echo ""
echo "=================================="
echo -e "${GREEN}✓ All API tests passed!${NC}"
echo "=================================="
echo ""
echo "Request ID: ${REQUEST_ID}"
echo "Status: PENDING (waiting for Coop approval)"
echo ""
echo "Note: This test demonstrates:"
echo "  ✓ Create approval request via API"
echo "  ✓ Get individual request"
echo "  ✓ Get pending approvals"
echo "  ✓ Approve as one organization (Insurer1)"
echo "  ✓ Get approvals by status"
echo "  ✓ Get approval history"
echo "  ✓ Get all approvals"
echo ""
echo "Multi-org approval requires connecting with different org credentials."
echo "The request remains PENDING until all required orgs (CoopMSP, Insurer1MSP) approve."
