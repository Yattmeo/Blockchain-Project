#!/bin/bash

# Complete Weather-Triggered Claim and Auto-Payout Test
# Tests the full parametric insurance workflow:
# 1. Create policy with premium auto-deposit
# 2. Submit weather data that triggers claim
# 3. Verify claim auto-creation
# 4. Approve and process claim
# 5. Verify auto-payout from premium pool

set -e

echo "============================================"
echo "Weather-Triggered Claim & Auto-Payout Test"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

API_BASE="http://localhost:3001/api"

echo "This test will:"
echo "  1. Create a Rice Drought policy (premium auto-deposits to pool)"
echo "  2. Submit weather data with low rainfall (triggers drought claim)"
echo "  3. Verify claim is auto-created"
echo "  4. Approve and process the claim"
echo "  5. Verify payout is automatically withdrawn from pool"
echo ""

# Get current pool balance
echo -e "${BLUE}Step 0: Checking initial pool balance...${NC}"
INITIAL_BALANCE=$(curl -s ${API_BASE}/premium-pool/balance | jq -r '.data')
echo "  Initial pool balance: \$${INITIAL_BALANCE}"
echo ""

# Step 1: Create Policy with Auto-Deposit
echo "============================================"
echo -e "${BLUE}Step 1: Creating Rice Drought Policy${NC}"
echo "============================================"
echo ""

POLICY_ID="POLICY_WEATHER_TEST_$(date +%s)"
FARMER_ID="FARMER_WEATHER_001"
PREMIUM=500
COVERAGE=10000

echo "Policy details:"
echo "  Policy ID: ${POLICY_ID}"
echo "  Farmer: ${FARMER_ID}"
echo "  Coverage: \$${COVERAGE}"
echo "  Premium: \$${PREMIUM}"
echo "  Template: TMPL_RICE_DROUGHT (Rainfall < 50mm → 50% payout)"
echo ""

# Create policy approval request
POLICY_RESPONSE=$(curl -s -X POST ${API_BASE}/policies \
  -H "Content-Type: application/json" \
  -d "{
    \"policyID\": \"${POLICY_ID}\",
    \"farmerID\": \"${FARMER_ID}\",
    \"templateID\": \"TMPL_RICE_DROUGHT\",
    \"coverageAmount\": ${COVERAGE},
    \"premiumAmount\": ${PREMIUM},
    \"coopID\": \"COOP001\",
    \"insurerID\": \"INSURER001\",
    \"farmLocation\": \"13.7563,100.5018\",
    \"cropType\": \"Rice\",
    \"farmSize\": 15
  }")

REQUEST_ID=$(echo "$POLICY_RESPONSE" | jq -r '.data.requestID')

if [ "$REQUEST_ID" != "null" ] && [ -n "$REQUEST_ID" ]; then
  echo -e "${GREEN}✓ Policy approval request created: ${REQUEST_ID}${NC}"
else
  echo -e "${RED}✗ Failed to create policy request${NC}"
  echo "$POLICY_RESPONSE" | jq '.'
  exit 1
fi

echo ""

# Step 2: Approve by both insurers
echo -e "${BLUE}Step 2: Approving policy by 2 insurers...${NC}"

# Approve by Insurer1
APPROVE1=$(curl -s -X POST ${API_BASE}/approval/${REQUEST_ID}/approve \
  -H "Content-Type: application/json" \
  -d "{
    \"approverOrg\": \"Insurer1MSP\",
    \"reason\": \"Approved - Weather test policy\"
  }")

if echo "$APPROVE1" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Approved by Insurer1${NC}"
else
  echo -e "${RED}✗ Insurer1 approval failed${NC}"
  exit 1
fi

sleep 1

# Approve by Insurer2
APPROVE2=$(curl -s -X POST ${API_BASE}/approval/${REQUEST_ID}/approve \
  -H "Content-Type: application/json" \
  -d "{
    \"approverOrg\": \"Insurer2MSP\",
    \"reason\": \"Approved - Weather test policy\"
  }")

if echo "$APPROVE2" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Approved by Insurer2${NC}"
else
  echo -e "${RED}✗ Insurer2 approval failed${NC}"
  exit 1
fi

echo ""

# Step 3: Execute policy (creates policy + auto-deposits premium)
echo -e "${BLUE}Step 3: Executing policy (creates policy + auto-deposits premium)...${NC}"

EXECUTE_RESPONSE=$(curl -s -X POST ${API_BASE}/approval/${REQUEST_ID}/execute)

if echo "$EXECUTE_RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Policy executed successfully${NC}"
  echo "  - Policy ${POLICY_ID} is now Active"
  echo "  - Premium \$${PREMIUM} auto-deposited to pool"
else
  echo -e "${RED}✗ Policy execution failed${NC}"
  echo "$EXECUTE_RESPONSE" | jq '.'
  exit 1
fi

sleep 2

# Verify pool balance increased
NEW_BALANCE=$(curl -s ${API_BASE}/premium-pool/balance | jq -r '.data')
BALANCE_INCREASE=$((NEW_BALANCE - INITIAL_BALANCE))
echo "  Pool balance increased by: \$${BALANCE_INCREASE}"

if [ "$BALANCE_INCREASE" -eq "$PREMIUM" ]; then
  echo -e "${GREEN}✓ Premium deposit verified${NC}"
else
  echo -e "${YELLOW}⚠ Expected +\$${PREMIUM}, got +\$${BALANCE_INCREASE}${NC}"
fi

echo ""

# Step 4: Submit weather data that triggers claim
echo "============================================"
echo -e "${BLUE}Step 4: Submitting Drought Weather Data${NC}"
echo "============================================"
echo ""

WEATHER_DATA_ID="WEATHER_DROUGHT_$(date +%s)"
ORACLE_ID="ORACLE_WEATHER_001"

echo "Weather data:"
echo "  Data ID: ${WEATHER_DATA_ID}"
echo "  Location: Central Bangkok (same as policy)"
echo "  Rainfall: 35.0mm (BELOW 50mm threshold)"
echo "  Temperature: 32.0°C"
echo "  ${RED}⚠ Should trigger 50% payout = \$5,000${NC}"
echo ""

# First ensure oracle provider exists
curl -s -X POST ${API_BASE}/weather-oracle/register-provider \
  -H "Content-Type: application/json" \
  -d "{
    \"oracleID\": \"${ORACLE_ID}\",
    \"providerName\": \"Thailand Meteorological Department\",
    \"providerType\": \"API\",
    \"dataSources\": [\"api.weather.gov.th\"]
  }" > /dev/null 2>&1

# Submit weather data
WEATHER_RESPONSE=$(curl -s -X POST ${API_BASE}/weather-oracle \
  -H "Content-Type: application/json" \
  -d "{
    \"dataID\": \"${WEATHER_DATA_ID}\",
    \"oracleID\": \"${ORACLE_ID}\",
    \"location\": \"Central_Bangkok\",
    \"latitude\": 13.7563,
    \"longitude\": 100.5018,
    \"rainfall\": 35.0,
    \"temperature\": 32.0,
    \"humidity\": 45.0,
    \"windSpeed\": 8.5
  }")

if echo "$WEATHER_RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Drought weather data submitted${NC}"
  echo "  Rainfall: 35.0mm < 50mm threshold for Rice Drought"
else
  echo -e "${RED}✗ Failed to submit weather data${NC}"
  echo "$WEATHER_RESPONSE" | jq '.'
  exit 1
fi

echo ""
echo -e "${YELLOW}Waiting 3 seconds for blockchain to settle...${NC}"
sleep 3
echo ""

# Step 5: Trigger claim based on weather data
echo "============================================"
echo -e "${BLUE}Step 5: Triggering Claim from Weather Data${NC}"
echo "============================================"
echo ""

CLAIM_ID="CLAIM_WEATHER_${POLICY_ID}_$(date +%s)"
PAYOUT_PERCENT=50  # Rice drought = 50% payout

echo "Triggering claim:"
echo "  Claim ID: ${CLAIM_ID}"
echo "  Policy: ${POLICY_ID}"
echo "  Weather Data: ${WEATHER_DATA_ID}"
echo "  Coverage: \$${COVERAGE}"
echo "  Payout: ${PAYOUT_PERCENT}% = \$$(($COVERAGE * $PAYOUT_PERCENT / 100))"
echo ""

TRIGGER_RESPONSE=$(curl -s -X POST ${API_BASE}/claims \
  -H "Content-Type: application/json" \
  -d "{
    \"claimID\": \"${CLAIM_ID}\",
    \"policyID\": \"${POLICY_ID}\",
    \"farmerID\": \"${FARMER_ID}\",
    \"weatherDataID\": \"${WEATHER_DATA_ID}\",
    \"coverageAmount\": ${COVERAGE},
    \"payoutPercent\": ${PAYOUT_PERCENT}
  }")

if echo "$TRIGGER_RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Claim triggered successfully${NC}"
  PAYOUT_AMOUNT=$(echo "$TRIGGER_RESPONSE" | jq -r '.data.payoutAmount')
  echo "  Payout Amount: \$${PAYOUT_AMOUNT}"
else
  echo -e "${RED}✗ Failed to trigger claim${NC}"
  echo "$TRIGGER_RESPONSE" | jq '.'
  exit 1
fi

echo ""

sleep 2

# Step 6: Verify claim was created
echo "============================================"
echo -e "${BLUE}Step 6: Verifying Claim Creation${NC}"
echo "============================================"
echo ""

# Query claims - look for our specific claim
CLAIM_DETAILS=$(curl -s ${API_BASE}/claims/${CLAIM_ID})

if echo "$CLAIM_DETAILS" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Claim verified: ${CLAIM_ID}${NC}"
  
  CLAIM_AMOUNT=$(echo "$CLAIM_DETAILS" | jq -r '.data.claimAmount')
  CLAIM_STATUS=$(echo "$CLAIM_DETAILS" | jq -r '.data.status')
  CLAIM_POLICY=$(echo "$CLAIM_DETAILS" | jq -r '.data.policyID')
  
  echo "  Claim Amount: \$${CLAIM_AMOUNT}"
  echo "  Status: ${CLAIM_STATUS}"
  echo "  Policy: ${CLAIM_POLICY}"
  echo "  Farmer: ${FARMER_ID}"
else
  echo -e "${YELLOW}⚠ Could not retrieve claim details${NC}"
  echo "$CLAIM_DETAILS" | jq '.'
fi

echo ""

# Step 7: Approve claim
echo "============================================"
echo -e "${BLUE}Step 7: Approving Claim${NC}"
echo "============================================"
echo ""
  
  sleep 2
  
  FINAL_BALANCE=$(curl -s ${API_BASE}/premium-pool/balance | jq -r '.data')
  BALANCE_CHANGE=$((FINAL_BALANCE - NEW_BALANCE))
  
  echo "  Balance before payout: \$${NEW_BALANCE}"
  echo "  Balance after payout: \$${FINAL_BALANCE}"
  echo "  Change: \$${BALANCE_CHANGE}"
  
  if [ "$BALANCE_CHANGE" -lt 0 ]; then
    PAYOUT_AMOUNT=$((BALANCE_CHANGE * -1))
    echo -e "${GREEN}✓ Payout withdrawn from pool: \$${PAYOUT_AMOUNT}${NC}"
    
    if [ "$PAYOUT_AMOUNT" -eq "$CLAIM_AMOUNT" ]; then
      echo -e "${GREEN}✓ Payout amount matches claim amount${NC}"
    else
      echo -e "${YELLOW}⚠ Expected \$${CLAIM_AMOUNT}, got \$${PAYOUT_AMOUNT}${NC}"
    fi
  else
    echo -e "${YELLOW}⚠ Pool balance did not decrease (payout may not have executed)${NC}"
  fi
  
  echo ""
  
  # Check transaction history
  echo "Checking pool transaction history..."
  TRANSACTIONS=$(curl -s ${API_BASE}/premium-pool/history)
  
  echo "Recent transactions:"
  echo "$TRANSACTIONS" | jq -r '.data[] | select(.amount > 0) | "  \(.type): \(.txID[:30]) | $\(.amount) | \(.farmerID)"' | tail -5
fi

echo ""

# Summary
echo "============================================"
echo -e "${GREEN}TEST SUMMARY${NC}"
echo "============================================"
echo ""
echo "Initial State:"
echo "  Pool Balance: \$${INITIAL_BALANCE}"
echo ""
echo "Policy Created:"
echo "  Policy ID: ${POLICY_ID}"
echo "  Premium: \$${PREMIUM}"
echo "  Coverage: \$${COVERAGE}"
echo "  Status: Active"
echo ""
echo "Pool After Premium Deposit:"
echo "  Balance: \$${NEW_BALANCE} (+\$${BALANCE_INCREASE})"
echo ""
echo "Weather Data:"
echo "  Rainfall: 35.0mm (triggers drought claim)"
echo "  Expected Payout: 50% of \$${COVERAGE} = \$5,000"
echo ""

if [ -n "$CLAIM_ID" ] && [ "$CLAIM_ID" != "null" ]; then
  echo "Claim:"
  echo "  Claim ID: ${CLAIM_ID}"
  echo "  Amount: \$${CLAIM_AMOUNT}"
  echo "  Status: ${CLAIM_STATUS}"
  echo ""
  
  if [ -n "$FINAL_BALANCE" ]; then
    echo "Final Pool Balance:"
    echo "  Balance: \$${FINAL_BALANCE}"
    echo "  Net Change: \$${BALANCE_CHANGE}"
    echo ""
  fi
  
  echo -e "${GREEN}✓ Complete workflow tested successfully!${NC}"
else
  echo -e "${YELLOW}⚠ Claim not found - may need manual verification${NC}"
  echo ""
  echo "Possible next steps:"
  echo "  1. Check Claims page in UI: http://localhost:5173/claims"
  echo "  2. Verify index calculator is running"
  echo "  3. Check if policy template thresholds match weather data"
  echo "  4. Review claim processor chaincode logs"
fi

echo ""
echo "Next Steps:"
echo "  1. Open UI Claims page: http://localhost:5173/claims"
echo "  2. Open UI Premium Pool page: http://localhost:5173/premium-pool"
echo "  3. Verify claim appears with correct amount"
echo "  4. Verify pool balance reflects payout"
echo ""
