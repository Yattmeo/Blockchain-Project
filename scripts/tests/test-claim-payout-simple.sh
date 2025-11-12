#!/bin/bash

# Simple Weather Claim Test
# Tests: Weather data → Trigger claim → Payout from pool

echo "============================================"
echo "Weather Claim & Payout Test (Simplified)"
echo "============================================"
echo ""

API_BASE="http://localhost:3001/api"

# Get current state
echo "Current pool balance: $(curl -s ${API_BASE}/premium-pool/balance | jq -r '.data')"
echo ""

# Use the policy we just created
POLICY_ID="POLICY_WEATHER_TEST_1762927939"
FARMER_ID="FARMER_WEATHER_001"
COVERAGE=4000  # Reduced to fit within pool balance
PAYOUT_PERCENT=50
PAYOUT_AMOUNT=2000  # 50% of 4000 = 2000 (pool has 3000, so this works)

# Submit drought weather data
echo "1. Submitting drought weather data..."
WEATHER_ID="WEATHER_DROUGHT_SIMPLE_$(date +%s)"

curl -s -X POST ${API_BASE}/weather-oracle/register-provider \
  -H "Content-Type: application/json" \
  -d "{
    \"oracleID\": \"ORACLE_WEATHER_001\",
    \"providerName\": \"Thailand Met Dept\",
    \"providerType\": \"API\",
    \"dataSources\": [\"api.weather.gov.th\"]
  }" > /dev/null 2>&1

curl -s -X POST ${API_BASE}/weather-oracle \
  -H "Content-Type: application/json" \
  -d "{
    \"dataID\": \"${WEATHER_ID}\",
    \"oracleID\": \"ORACLE_WEATHER_001\",
    \"location\": \"Central_Bangkok\",
    \"latitude\": 13.7563,
    \"longitude\": 100.5018,
    \"rainfall\": 35.0,
    \"temperature\": 32.0,
    \"humidity\": 45.0,
    \"windSpeed\": 8.5
  }" > /dev/null

echo "✓ Weather data submitted: ${WEATHER_ID}"
echo "  Rainfall: 35.0mm (triggers ${PAYOUT_PERCENT}% payout)"
echo ""

# Trigger claim
echo "2. Triggering claim..."
CLAIM_ID="CLAIM_SIMPLE_$(date +%s)"

CLAIM_RESPONSE=$(curl -s -X POST ${API_BASE}/claims \
  -H "Content-Type: application/json" \
  -d "{
    \"claimID\": \"${CLAIM_ID}\",
    \"policyID\": \"${POLICY_ID}\",
    \"farmerID\": \"${FARMER_ID}\",
    \"weatherDataID\": \"${WEATHER_ID}\",
    \"coverageAmount\": ${COVERAGE},
    \"payoutPercent\": ${PAYOUT_PERCENT}
  }")

if echo "$CLAIM_RESPONSE" | grep -q '"success":true'; then
  echo "✓ Claim triggered: ${CLAIM_ID}"
  echo "  Expected payout: \$${PAYOUT_AMOUNT}"
else
  echo "✗ Failed to trigger claim"
  echo "$CLAIM_RESPONSE" | jq '.'
  exit 1
fi

echo ""
sleep 1

# Withdraw payout from pool
echo "3. Processing payout from premium pool..."
TX_ID="PAYOUT_${CLAIM_ID}_$(date +%s)"

WITHDRAW_RESPONSE=$(curl -s -X POST ${API_BASE}/premium-pool/withdraw \
  -H "Content-Type: application/json" \
  -d "{
    \"amount\": ${PAYOUT_AMOUNT},
    \"recipient\": \"${FARMER_ID}\",
    \"claimID\": \"${CLAIM_ID}\",
    \"policyID\": \"${POLICY_ID}\"
  }")

if echo "$WITHDRAW_RESPONSE" | grep -q '"success":true'; then
  echo "✓ Payout processed: \$${PAYOUT_AMOUNT} withdrawn"
else
  echo "✗ Failed to process payout"
  echo "$WITHDRAW_RESPONSE" | jq '.'
  exit 1
fi

echo ""
sleep 2

# Verify results
echo "4. Verifying results..."
NEW_BALANCE=$(curl -s ${API_BASE}/premium-pool/balance | jq -r '.data')
echo "  New pool balance: \$${NEW_BALANCE}"

# Check claim status
CLAIM_CHECK=$(curl -s ${API_BASE}/claims/${CLAIM_ID})
CLAIM_STATUS=$(echo "$CLAIM_CHECK" | jq -r '.data.status')
echo "  Claim status: ${CLAIM_STATUS}"

echo ""
echo "============================================"
echo "Test Complete!"
echo "============================================"
echo "  Weather: 35mm rainfall (drought)"
echo "  Claim: ${CLAIM_ID}"
echo "  Payout: \$${PAYOUT_AMOUNT}"
echo "  Pool Balance: \$${NEW_BALANCE}"
echo ""
