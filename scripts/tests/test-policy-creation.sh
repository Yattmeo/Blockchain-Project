#!/bin/bash

echo "========================================="
echo "Testing Policy Creation with Templates"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API Base URL
API_URL="http://localhost:3001/api"

echo "${BLUE}Step 1: Verify Policy Templates Available${NC}"
echo "----------------------------------------"
TEMPLATES=$(curl -s "$API_URL/policy-templates" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"{len(d['data'])} templates available\")")
echo "✓ $TEMPLATES"
echo ""

echo "${BLUE}Step 2: Get Template Details - Rice Drought${NC}"
echo "----------------------------------------"
curl -s "$API_URL/policy-templates/TMPL_RICE_DROUGHT" | python3 -m json.tool | grep -A 5 "templateName\|cropType\|coveragePeriod\|maxCoverage\|indexThresholds"
echo ""

echo "${BLUE}Step 3: Create Policy Approval Request${NC}"
echo "----------------------------------------"
POLICY_DATA='{
  "policyID": "POL001",
  "farmerID": "FARM001",
  "templateID": "TMPL_RICE_DROUGHT",
  "coverageAmount": 50000,
  "premiumAmount": 2500,
  "startDate": "2025-11-15",
  "endDate": "2026-05-14"
}'

echo "Creating policy with data:"
echo "$POLICY_DATA" | python3 -m json.tool
echo ""

RESPONSE=$(curl -s -X POST "$API_URL/policies" \
  -H "Content-Type: application/json" \
  -d "$POLICY_DATA")

echo "Response:"
echo "$RESPONSE" | python3 -m json.tool
echo ""

REQUEST_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data', {}).get('requestID', ''))" 2>/dev/null || echo "")

if [ -n "$REQUEST_ID" ]; then
  echo "${GREEN}✓ Policy creation request submitted: $REQUEST_ID${NC}"
  echo ""
  
  echo "${BLUE}Step 4: Check Approval Request Status${NC}"
  echo "----------------------------------------"
  curl -s "$API_URL/approval/$REQUEST_ID" | python3 -m json.tool | grep -A 5 "requestID\|requestType\|status\|metadata"
  echo ""
  
  echo "${GREEN}✓ Policy creation request is now in approval workflow${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Insurers can view the request in Approvals page"
  echo "2. Request shows policy details and weather conditions"
  echo "3. Two insurers need to approve (Insurer1, Insurer2)"
  echo "4. After approval, policy will be created on blockchain"
  echo ""
else
  echo "⚠ Could not extract request ID from response"
fi

echo "========================================="
echo "Test Complete!"
echo "========================================="
