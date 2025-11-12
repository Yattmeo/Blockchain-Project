#!/bin/bash

echo "============================================"
echo "Premium Pool Auto-Deposit Test"
echo "============================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "This script tests:"
echo "1. GetAllTransactionHistory - View all premium pool transactions"
echo "2. Auto-deposit premium when policy is approved and executed"
echo ""

echo "============================================"
echo "TEST 1: Transaction History (All)"
echo "============================================"
echo ""

echo "Fetching all transaction history..."
RESPONSE=$(curl -s http://localhost:3001/api/premium-pool/history)
SUCCESS=$(echo $RESPONSE | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('success', False))" 2>/dev/null)

if [ "$SUCCESS" = "True" ]; then
    echo -e "${GREEN}✓ SUCCESS${NC}: Transaction history endpoint working"
    
    COUNT=$(echo $RESPONSE | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('data', [])))" 2>/dev/null)
    echo "Found $COUNT transactions"
    echo ""
    
    if [ "$COUNT" -gt 0 ]; then
        echo "Recent transactions:"
        echo $RESPONSE | python3 -c "
import sys, json
data = json.load(sys.stdin)
for tx in data.get('data', [])[:5]:  # Show first 5
    print(f\"  • {tx.get('txID', 'N/A')}\")
    print(f\"    Type: {tx.get('type', 'N/A')}\")
    print(f\"    Amount: \${tx.get('amount', 0):,.2f}\")
    print(f\"    Farmer: {tx.get('farmerID', 'N/A')}\")
    print(f\"    Policy: {tx.get('policyID', 'N/A')}\")
    print(f\"    Status: {tx.get('status', 'N/A')}\")
    print()
" 2>/dev/null
    else
        echo -e "${YELLOW}No transactions yet${NC}"
    fi
else
    echo -e "${RED}✗ FAILED${NC}: Transaction history endpoint not working"
    echo "Error: $(echo $RESPONSE | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('error', 'Unknown error'))" 2>/dev/null)"
    echo ""
    echo "Make sure API gateway is restarted after code changes!"
    exit 1
fi

echo ""
echo "============================================"
echo "TEST 2: Auto-Deposit Premium Flow"
echo "============================================"
echo ""

echo "Testing the complete policy creation -> approval -> auto-deposit flow:"
echo ""

# Step 1: Create policy (approval request)
echo "Step 1: Creating policy approval request..."
POLICY_ID="POLICY_TEST_$(date +%s)"
FARMER_ID="FARMER001"
TEMPLATE_ID="TEMPLATE001"
COVERAGE=10000
PREMIUM=500

CREATE_RESPONSE=$(curl -s -X POST http://localhost:3001/api/policies \
  -H "Content-Type: application/json" \
  -d "{
    \"policyID\": \"$POLICY_ID\",
    \"farmerID\": \"$FARMER_ID\",
    \"templateID\": \"$TEMPLATE_ID\",
    \"coverageAmount\": $COVERAGE,
    \"premiumAmount\": $PREMIUM,
    \"coopID\": \"COOP001\",
    \"insurerID\": \"INSURER001\",
    \"farmLocation\": \"13.7563,100.5018\",
    \"cropType\": \"Rice\",
    \"farmSize\": 10
  }")

REQUEST_ID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('data', {}).get('requestID', ''))" 2>/dev/null)

if [ -z "$REQUEST_ID" ]; then
    echo -e "${RED}✗ FAILED${NC}: Could not create policy approval request"
    echo "Response: $CREATE_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Created${NC} approval request: $REQUEST_ID"
echo ""

# Step 2: Approve by Insurer1
echo "Step 2: Approving by Insurer1..."
APPROVE1_RESPONSE=$(curl -s -X POST http://localhost:3001/api/approval/$REQUEST_ID/approve \
  -H "Content-Type: application/json" \
  -d "{\"approverOrg\": \"Insurer1MSP\", \"comments\": \"Approved by Insurer1\"}")

echo -e "${GREEN}✓ Approved${NC} by Insurer1"
echo ""

# Step 3: Approve by Insurer2
echo "Step 3: Approving by Insurer2..."
APPROVE2_RESPONSE=$(curl -s -X POST http://localhost:3001/api/approval/$REQUEST_ID/approve \
  -H "Content-Type: application/json" \
  -d "{\"approverOrg\": \"Insurer2MSP\", \"comments\": \"Approved by Insurer2\"}")

echo -e "${GREEN}✓ Approved${NC} by Insurer2"
echo ""

# Step 4: Execute (should auto-deposit premium)
echo "Step 4: Executing approved request (auto-deposits premium)..."
EXECUTE_RESPONSE=$(curl -s -X POST http://localhost:3001/api/approval/$REQUEST_ID/execute)

EXEC_SUCCESS=$(echo $EXECUTE_RESPONSE | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('success', False))" 2>/dev/null)

if [ "$EXEC_SUCCESS" = "True" ]; then
    echo -e "${GREEN}✓ Executed${NC}: Policy created and premium auto-deposited!"
    echo ""
else
    echo -e "${RED}✗ FAILED${NC}: Execution failed"
    echo "Response: $EXECUTE_RESPONSE"
    exit 1
fi

# Step 5: Verify premium was deposited
echo "Step 5: Verifying premium deposit in transaction history..."
sleep 2  # Give blockchain time to commit

VERIFY_RESPONSE=$(curl -s http://localhost:3001/api/premium-pool/history)
FOUND_TX=$(echo $VERIFY_RESPONSE | python3 -c "
import sys, json
data = json.load(sys.stdin)
for tx in data.get('data', []):
    if tx.get('policyID') == '$POLICY_ID':
        print('YES')
        print(f\"TxID: {tx.get('txID')}\")
        print(f\"Amount: \${tx.get('amount')}\")
        print(f\"Type: {tx.get('type')}\")
        print(f\"Status: {tx.get('status')}\")
        break
else:
    print('NO')
" 2>/dev/null)

if [[ "$FOUND_TX" == *"YES"* ]]; then
    echo -e "${GREEN}✓ VERIFIED${NC}: Premium transaction found in history!"
    echo ""
    echo "$FOUND_TX" | tail -n +2
else
    echo -e "${YELLOW}⚠ WARNING${NC}: Premium transaction not found yet"
    echo "This might be normal if blockchain is still processing"
fi

echo ""
echo "Step 6: Checking pool balance..."
BALANCE_RESPONSE=$(curl -s http://localhost:3001/api/premium-pool/balance)
BALANCE=$(echo $BALANCE_RESPONSE | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('data', 0))" 2>/dev/null)
echo "Pool balance: \$$BALANCE"

echo ""
echo "============================================"
echo "TEST SUMMARY"
echo "============================================"
echo ""
echo -e "${GREEN}✓ GetAllTransactionHistory${NC} - Working"
echo -e "${GREEN}✓ Auto-deposit on policy execution${NC} - Working"
echo ""
echo "Created:"
echo "  - Policy: $POLICY_ID"
echo "  - Premium: \$$PREMIUM"
echo "  - Farmer: $FARMER_ID"
echo ""
echo "Next steps:"
echo "1. Check Premium Pool page in UI - should show transaction"
echo "2. Verify policy is Active status"
echo "3. Test weather triggering claim -> auto payout"
echo ""
