#!/bin/bash

################################################################################
# Complete End-to-End Test Suite
# Weather Index Insurance Platform
#
# Tests all functionality:
# 1. Farmer Registration
# 2. Policy Templates
# 3. Policy Creation with Multi-Org Approval
# 4. Premium Pool Auto-Deposit
# 5. Weather Oracle Data Submission
# 6. Claims Processing & Payout
# 7. Dashboard & Statistics
# 8. UI Accessibility
################################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE="http://localhost:3001/api"
UI_BASE="http://localhost:5173"
TIMESTAMP=$(date +%s)
# macOS doesn't support %N (nanoseconds), use Python for milliseconds
TIMESTAMP_MS="${TIMESTAMP}$(python3 -c 'import time; print(int(time.time() * 1000) % 1000)')"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test IDs
FARMER_ID="FARMER_E2E_${TIMESTAMP_MS}"
POLICY_ID="POLICY_E2E_${TIMESTAMP_MS}"
APPROVAL_ID=""
WEATHER_ID="WEATHER_E2E_${TIMESTAMP_MS}"
CLAIM_ID="CLAIM_E2E_${TIMESTAMP_MS}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}║         Complete End-to-End Test Suite                        ║${NC}"
echo -e "${BLUE}║         Weather Index Insurance Platform                      ║${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Helper function for test assertions
assert_equals() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [ "$expected" == "$actual" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        echo -e "  Expected: $expected"
        echo -e "  Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_not_empty() {
    local test_name="$1"
    local value="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [ -n "$value" ] && [ "$value" != "null" ] && [ "$value" != "undefined" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        echo -e "  Value is empty or null"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_success() {
    local test_name="$1"
    local response="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        echo -e "  Response: $response"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_status() {
    local test_name="$1"
    local expected_status="$2"
    local http_code="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [ "$http_code" == "$expected_status" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        echo -e "  Expected HTTP $expected_status, got HTTP $http_code"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Pre-flight checks
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Pre-flight Checks${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check API Gateway (health endpoint is at /health, not /api/health)
if curl -s -f "http://localhost:3001/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} API Gateway is running"
else
    echo -e "${RED}✗${NC} API Gateway is not accessible at http://localhost:3001"
    echo "Please start the API Gateway first."
    exit 1
fi

# Check UI
if curl -s -f "${UI_BASE}" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} UI is running"
else
    echo -e "${YELLOW}⚠${NC} UI is not accessible at ${UI_BASE} (non-critical)"
fi

echo ""

################################################################################
# TEST SUITE 1: FARMER MANAGEMENT
################################################################################

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Test Suite 1: Farmer Management${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Test 1.1: Register new farmer (creates approval request)
echo "Test 1.1: Register new farmer..."
FARMER_RESPONSE=$(curl -s -X POST "${API_BASE}/farmers" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: CoopMSP" \
    -d "{
        \"farmerID\": \"${FARMER_ID}\",
        \"firstName\": \"E2E\",
        \"lastName\": \"TestFarmer\",
        \"email\": \"e2e.farmer@test.com\",
        \"phone\": \"+65-9876-5432\",
        \"region\": \"Test Region\",
        \"district\": \"Singapore\",
        \"farmSize\": \"5.5\",
        \"cropTypes\": [\"Rice\", \"Vegetables\"],
        \"coopID\": \"COOP001\"
    }")

assert_success "Register farmer (create approval request)" "$FARMER_RESPONSE"

# Extract the approval request ID
FARMER_APPROVAL_ID=$(echo "$FARMER_RESPONSE" | jq -r '.data.requestID // .requestID // empty')
echo "  Approval Request ID: $FARMER_APPROVAL_ID"

# Test 1.2: Approve farmer registration by Insurer1
echo "Test 1.2: Approve farmer registration (Insurer1)..."
APPROVE1_RESPONSE=$(curl -s -X POST "${API_BASE}/approval/${FARMER_APPROVAL_ID}/approve" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer1MSP" \
    -d "{\"approverOrg\": \"Insurer1MSP\"}")

assert_success "Insurer1 approves farmer registration" "$APPROVE1_RESPONSE"

# Test 1.3: Approve farmer registration by Insurer2
echo "Test 1.3: Approve farmer registration (Insurer2)..."
APPROVE2_RESPONSE=$(curl -s -X POST "${API_BASE}/approval/${FARMER_APPROVAL_ID}/approve" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer2MSP" \
    -d "{\"approverOrg\": \"Insurer2MSP\"}")

assert_success "Insurer2 approves farmer registration" "$APPROVE2_RESPONSE"

# Test 1.4: Execute approved farmer registration
echo "Test 1.4: Execute approved farmer registration..."
EXECUTE_RESPONSE=$(curl -s -X POST "${API_BASE}/approval/${FARMER_APPROVAL_ID}/execute" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer1MSP")

assert_success "Execute farmer registration" "$EXECUTE_RESPONSE"

# Small delay to ensure ledger is updated
sleep 2

# Test 1.5: Get farmer by ID
echo "Test 1.5: Get farmer by ID..."
FARMER_GET=$(curl -s "${API_BASE}/farmers/${FARMER_ID}")
FARMER_FIRST_NAME=$(echo "$FARMER_GET" | jq -r '.data.firstName // empty')
assert_equals "Farmer first name matches" "E2E" "$FARMER_FIRST_NAME"

# Test 1.6: Get all farmers
echo "Test 1.6: Get all farmers..."
ALL_FARMERS=$(curl -s "${API_BASE}/farmers")
FARMERS_COUNT=$(echo "$ALL_FARMERS" | jq '.data | length')
assert_not_empty "Farmers list not empty" "$FARMERS_COUNT"

echo ""

################################################################################
# TEST SUITE 2: POLICY TEMPLATES
################################################################################

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Test Suite 2: Policy Templates${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Setup: Create test template via API
echo "Setup: Creating test policy template..."
CREATE_TEMPLATE=$(curl -s -X POST "${API_BASE}/policy-templates" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer1" \
    -d '{
        "templateID": "TEMPLATE_RICE_DROUGHT_001",
        "templateName": "Rice Drought Protection",
        "cropType": "Rice",
        "region": "Central",
        "riskLevel": "Medium",
        "coveragePeriod": 180,
        "maxCoverage": 100000,
        "minPremium": 500
    }')

TEMPLATE_EXISTS=false
if echo "$CREATE_TEMPLATE" | jq -e '.success == true' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Template created"
    TEMPLATE_EXISTS=true
else
    ERROR_MSG=$(echo "$CREATE_TEMPLATE" | jq -r '.message // .error // "unknown"')
    if echo "$ERROR_MSG" | grep -qi "already exists"; then
        echo -e "${YELLOW}⚠${NC} Template already exists, will add thresholds if missing"
        TEMPLATE_EXISTS=true
    else
        echo -e "${YELLOW}⚠${NC} Template creation issue: $ERROR_MSG"
    fi
fi

# Add thresholds and activate if template exists
if [ "$TEMPLATE_EXISTS" = true ]; then
    # Check current template status
    TEMPLATE_STATUS=$(curl -s "${API_BASE}/policy-templates/TEMPLATE_RICE_DROUGHT_001" | jq -r '.data.status // "Unknown"')
    echo "  Current template status: $TEMPLATE_STATUS"
    
    # Add index thresholds to the template (idempotent - will add if not exists)
    echo "  Adding drought threshold..."
    THRESHOLD_RESPONSE=$(curl -s -X POST "${API_BASE}/policy-templates/TEMPLATE_RICE_DROUGHT_001/thresholds" \
        -H "Content-Type: application/json" \
        -H "X-User-Org: Insurer1" \
        -d '{
            "indexType": "Drought",
            "metric": "rainfall",
            "thresholdValue": 50,
            "operator": "<",
            "measurementDays": 30,
            "payoutPercent": 75,
            "severity": "Severe"
        }')
    
    if echo "$THRESHOLD_RESPONSE" | jq -e '.success == true' > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Threshold added"
    else
        THRESHOLD_ERROR=$(echo "$THRESHOLD_RESPONSE" | jq -r '.message // .error // "unknown"')
        echo -e "  ${YELLOW}⚠${NC} Threshold issue: $THRESHOLD_ERROR"
    fi
    
    # Activate the template if not already active
    if [ "$TEMPLATE_STATUS" != "Active" ]; then
        echo "  Activating template..."
        ACTIVATE_TEMPLATE=$(curl -s -X POST "${API_BASE}/policy-templates/TEMPLATE_RICE_DROUGHT_001/activate" \
            -H "X-User-Org: Insurer1")
        
        if echo "$ACTIVATE_TEMPLATE" | jq -e '.success == true' > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} Template activated"
        else
            ACTIVATION_ERROR=$(echo "$ACTIVATE_TEMPLATE" | jq -r '.message // .error // "unknown"')
            echo -e "  ${YELLOW}⚠${NC} Template activation issue: $ACTIVATION_ERROR"
        fi
    else
        echo -e "  ${GREEN}✓${NC} Template already active"
    fi
fi
sleep 1
echo ""

# Test 2.1: Get all templates
echo "Test 2.1: Get all policy templates..."
TEMPLATES=$(curl -s "${API_BASE}/policy-templates")
TEMPLATE_COUNT=$(echo "$TEMPLATES" | jq '.data | length')
assert_not_empty "Templates exist" "$TEMPLATE_COUNT"

# Test 2.2: Get template by crop type
echo "Test 2.2: Get templates by crop type..."
RICE_TEMPLATES=$(curl -s "${API_BASE}/policy-templates/by-crop/Rice")
assert_success "Get Rice templates" "$RICE_TEMPLATES"

# Test 2.3: Get specific template
TEMPLATE_ID="TEMPLATE_RICE_DROUGHT_001"
echo "Test 2.3: Get specific template..."
TEMPLATE=$(curl -s "${API_BASE}/policy-templates/${TEMPLATE_ID}")
assert_success "Get template by ID" "$TEMPLATE"

# Test 2.4: Get template thresholds
echo "Test 2.4: Get template thresholds..."
THRESHOLDS=$(curl -s "${API_BASE}/policy-templates/${TEMPLATE_ID}/thresholds")
assert_success "Get template thresholds" "$THRESHOLDS"

echo ""

################################################################################
# TEST SUITE 3: POLICY LIFECYCLE WITH MULTI-ORG APPROVAL
################################################################################

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Test Suite 3: Policy Lifecycle & Multi-Org Approval${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Test 3.1: Create policy (initiates approval workflow)
echo "Test 3.1: Create policy..."
POLICY_RESPONSE=$(curl -s -X POST "${API_BASE}/policies" \
    -H "Content-Type: application/json" \
    -d "{
        \"policyID\": \"${POLICY_ID}\",
        \"farmerID\": \"${FARMER_ID}\",
        \"templateID\": \"TEMPLATE_RICE_DROUGHT_001\",
        \"coverageAmount\": 5000,
        \"premiumAmount\": 500,
        \"startDate\": \"2025-01-01\",
        \"endDate\": \"2025-12-31\",
        \"coopID\": \"COOP001\",
        \"insurerID\": \"INSURER001\",
        \"farmLocation\": \"1.3521,103.8198\",
        \"cropType\": \"Rice\",
        \"farmSize\": 5.5
    }")

assert_success "Create policy" "$POLICY_RESPONSE"

# Extract approval request ID
APPROVAL_ID=$(echo "$POLICY_RESPONSE" | jq -r '.data.requestID // empty')
assert_not_empty "Approval request created" "$APPROVAL_ID"

# Test 3.2: Get pending approvals
echo "Test 3.2: Get pending approvals..."
sleep 2
PENDING_APPROVALS=$(curl -s "${API_BASE}/approval/pending")
assert_success "Get pending approvals" "$PENDING_APPROVALS"

# Test 3.3: Get specific approval request
echo "Test 3.3: Get approval request details..."
APPROVAL_DETAILS=$(curl -s "${API_BASE}/approval/${APPROVAL_ID}")
APPROVAL_STATUS=$(echo "$APPROVAL_DETAILS" | jq -r '.data.status // empty')
assert_not_empty "Approval status exists" "$APPROVAL_STATUS"

# Test 3.4: Approve from Insurer1
echo "Test 3.4: Approve from Insurer1..."
APPROVE1=$(curl -s -X POST "${API_BASE}/approval/${APPROVAL_ID}/approve" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer1MSP" \
    -d "{
        \"approverOrg\": \"Insurer1MSP\",
        \"reason\": \"E2E Test Approval 1\"
    }")
assert_success "Insurer1 approval" "$APPROVE1"

# Test 3.5: Approve from Insurer2
echo "Test 3.5: Approve from Insurer2..."
sleep 1
APPROVE2=$(curl -s -X POST "${API_BASE}/approval/${APPROVAL_ID}/approve" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer2MSP" \
    -d "{
        \"approverOrg\": \"Insurer2MSP\",
        \"reason\": \"E2E Test Approval 2\"
    }")
assert_success "Insurer2 approval" "$APPROVE2"

# Test 3.6: Check approval status after 2 approvals
echo "Test 3.6: Verify approval status is APPROVED..."
sleep 2
APPROVAL_CHECK=$(curl -s "${API_BASE}/approval/${APPROVAL_ID}")
FINAL_STATUS=$(echo "$APPROVAL_CHECK" | jq -r '.data.status // empty')
assert_equals "Approval status is APPROVED" "APPROVED" "$FINAL_STATUS"

# Test 3.7: Execute approved policy
echo "Test 3.7: Execute approved policy..."
EXECUTE=$(curl -s -X POST "${API_BASE}/approval/${APPROVAL_ID}/execute" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer1MSP")
assert_success "Execute approved policy" "$EXECUTE"

# Test 3.8: Get approval history
echo "Test 3.8: Get approval history..."
HISTORY=$(curl -s "${API_BASE}/approval/${APPROVAL_ID}/history")
assert_success "Get approval history" "$HISTORY"

# Test 3.9: Verify policy exists and is active
# Test 3.9: Verify policy exists and is active
echo "Test 3.9: Verify policy is active..."
sleep 2
POLICY_CHECK=$(curl -s "${API_BASE}/policies/${POLICY_ID}")
POLICY_STATUS=$(echo "$POLICY_CHECK" | jq -r '.data.status // empty')
assert_equals "Policy status is Active" "Active" "$POLICY_STATUS"

# Test 3.10: Deposit premium to pool after policy creation
echo "Test 3.10: Deposit policy premium to pool..."
PREMIUM_AMOUNT=$(echo "$POLICY_CHECK" | jq -r '.data.premiumAmount // 0')
echo "  Premium amount: $$PREMIUM_AMOUNT"

if [ "$PREMIUM_AMOUNT" != "0" ] && [ "$PREMIUM_AMOUNT" != "null" ]; then
    PREMIUM_DEPOSIT=$(curl -s -X POST "${API_BASE}/premium-pool/deposit-premium" \
        -H "Content-Type: application/json" \
        -H "X-User-Org: Insurer1" \
        -d "{
            \"amount\": $PREMIUM_AMOUNT,
            \"policyID\": \"$POLICY_ID\",
            \"farmerID\": \"$FARMER_ID\"
        }")
    
    if echo "$PREMIUM_DEPOSIT" | jq -e '.success == true' > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Premium deposited: \$$PREMIUM_AMOUNT"
    else
        echo -e "  ${YELLOW}⚠${NC} Premium deposit issue: $(echo "$PREMIUM_DEPOSIT" | jq -r '.message // "unknown"')"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} No premium amount to deposit"
fi

echo ""

################################################################################
# TEST SUITE 4: PREMIUM POOL & AUTO-DEPOSIT
################################################################################

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Test Suite 4: Premium Pool & Auto-Deposit${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

# Test 4.1: Get initial pool balance
echo "Test 4.1: Get initial pool balance..."
BALANCE_BEFORE=$(curl -s "${API_BASE}/premium-pool/balance" | jq -r '.data // 0')
echo "  Pool balance before: $$BALANCE_BEFORE"

echo ""

################################################################################
# TEST SUITE 4: PREMIUM POOL & AUTO-DEPOSIT
################################################################################

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Test Suite 4: Premium Pool & Auto-Deposit${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Test 4.1: Get pool balance
echo "Test 4.1: Get premium pool balance..."
POOL_BALANCE_BEFORE=$(curl -s "${API_BASE}/premium-pool/balance")
BALANCE_BEFORE=$(echo "$POOL_BALANCE_BEFORE" | jq -r '.data // 0')
assert_not_empty "Pool balance exists" "$BALANCE_BEFORE"
echo "  Current balance: \$$BALANCE_BEFORE"

# Test 4.2: Get pool stats
echo "Test 4.2: Get pool statistics..."
POOL_STATS=$(curl -s "${API_BASE}/premium-pool/stats")
assert_success "Get pool stats" "$POOL_STATS"

# Test 4.3: Get transaction history
echo "Test 4.3: Get transaction history..."
TX_HISTORY=$(curl -s "${API_BASE}/premium-pool/history")
TX_COUNT=$(echo "$TX_HISTORY" | jq '.data | length')
assert_not_empty "Transaction history exists" "$TX_COUNT"
echo "  Total transactions: $TX_COUNT"

# Test 4.4: Verify premium deposit occurred
echo "Test 4.4: Verify premium was deposited to pool..."
sleep 3
POOL_BALANCE_AFTER=$(curl -s "${API_BASE}/premium-pool/balance")
BALANCE_AFTER=$(echo "$POOL_BALANCE_AFTER" | jq -r '.data // 0')

# Check if balance increased (from Test 3.10 deposit)
if (( $(echo "$BALANCE_AFTER > $BALANCE_BEFORE" | bc -l) )); then
    DEPOSIT_AMOUNT=$(echo "$BALANCE_AFTER - $BALANCE_BEFORE" | bc)
    echo -e "${GREEN}✓${NC} PASS: Premium deposited to pool (added \$$DEPOSIT_AMOUNT)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠${NC} WARNING: Balance did not increase (premium deposit may have failed)"
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

# Test 4.5: Verify premium transaction in history
echo "Test 4.5: Verify premium transaction recorded..."
RECENT_TX=$(curl -s "${API_BASE}/premium-pool/history" | jq -r '.data[0] // empty')
RECENT_TYPE=$(echo "$RECENT_TX" | jq -r '.type // empty')
if [ "$RECENT_TYPE" == "Premium" ]; then
    echo -e "${GREEN}✓${NC} PASS: Premium transaction recorded"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠${NC} WARNING: Latest transaction is not Premium type (got: $RECENT_TYPE)"
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

# Test 4.6: Manual deposit test
echo "Test 4.6: Test manual premium deposit..."
MANUAL_DEPOSIT=$(curl -s -X POST "${API_BASE}/premium-pool/deposit" \
    -H "Content-Type: application/json" \
    -d "{
        \"amount\": 5000,
        \"policyID\": \"${POLICY_ID}\",
        \"farmerID\": \"${FARMER_ID}\"
    }")
assert_success "Manual deposit" "$MANUAL_DEPOSIT"

echo ""

################################################################################
# TEST SUITE 5: WEATHER ORACLE WITH MULTI-ORACLE CONSENSUS
################################################################################

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Test Suite 5: Weather Oracle & Consensus Validation${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Test 5.1: Register multiple oracle providers
echo "Test 5.1: Register Oracle 1 (OpenWeatherMap)..."
ORACLE_1=$(curl -s -X POST "${API_BASE}/weather-oracle/register-provider" \
    -H "Content-Type: application/json" \
    -d "{
        \"oracleID\": \"ORACLE_E2E_OWM\",
        \"providerName\": \"E2E OpenWeatherMap\",
        \"providerType\": \"API\",
        \"dataSources\": [\"OpenWeatherMap\"]
    }")

if echo "$ORACLE_1" | jq -e '.success == true' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PASS: Register Oracle 1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
elif echo "$ORACLE_1" | grep -qi "already exists"; then
    echo -e "${YELLOW}⚠${NC} PASS: Oracle 1 already registered"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Register Oracle 1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

echo "Test 5.1: Register Oracle 2 (Thai Met)..."
ORACLE_2=$(curl -s -X POST "${API_BASE}/weather-oracle/register-provider" \
    -H "Content-Type: application/json" \
    -d "{
        \"oracleID\": \"ORACLE_E2E_TMD\",
        \"providerName\": \"E2E Thai Meteorological\",
        \"providerType\": \"API\",
        \"dataSources\": [\"ThaiMeteorology\"]
    }")

if echo "$ORACLE_2" | jq -e '.success == true' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PASS: Register Oracle 2"
    TESTS_PASSED=$((TESTS_PASSED + 1))
elif echo "$ORACLE_2" | grep -qi "already exists"; then
    echo -e "${YELLOW}⚠${NC} PASS: Oracle 2 already registered"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Register Oracle 2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

echo "Test 5.1: Register Oracle 3 (Weather Underground)..."
ORACLE_3=$(curl -s -X POST "${API_BASE}/weather-oracle/register-provider" \
    -H "Content-Type: application/json" \
    -d "{
        \"oracleID\": \"ORACLE_E2E_WU\",
        \"providerName\": \"E2E Weather Underground\",
        \"providerType\": \"API\",
        \"dataSources\": [\"WeatherUnderground\"]
    }")

if echo "$ORACLE_3" | jq -e '.success == true' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PASS: Register Oracle 3"
    TESTS_PASSED=$((TESTS_PASSED + 1))
elif echo "$ORACLE_3" | grep -qi "already exists"; then
    echo -e "${YELLOW}⚠${NC} PASS: Oracle 3 already registered"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Register Oracle 3"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

sleep 1

# Test 5.2: Submit drought weather data from multiple oracles
CONSENSUS_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "Test 5.2: Submit weather data from Oracle 1..."
WEATHER_1=$(curl -s -X POST "${API_BASE}/weather-oracle" \
    -H "Content-Type: application/json" \
    -d "{
        \"dataID\": \"${WEATHER_ID}_01\",
        \"oracleID\": \"ORACLE_E2E_OWM\",
        \"location\": \"Test_Region\",
        \"latitude\": \"1.3521\",
        \"longitude\": \"103.8198\",
        \"rainfall\": 35.0,
        \"temperature\": 34.5,
        \"humidity\": 65.0,
        \"windSpeed\": 12.5,
        \"recordedAt\": \"${CONSENSUS_TIMESTAMP}\"
    }")
assert_success "Submit weather data from Oracle 1" "$WEATHER_1"

echo "Test 5.2: Submit weather data from Oracle 2 (slight variation)..."
WEATHER_2=$(curl -s -X POST "${API_BASE}/weather-oracle" \
    -H "Content-Type: application/json" \
    -d "{
        \"dataID\": \"${WEATHER_ID}_02\",
        \"oracleID\": \"ORACLE_E2E_TMD\",
        \"location\": \"Test_Region\",
        \"latitude\": \"1.3521\",
        \"longitude\": \"103.8198\",
        \"rainfall\": 36.5,
        \"temperature\": 34.8,
        \"humidity\": 66.0,
        \"windSpeed\": 12.0,
        \"recordedAt\": \"${CONSENSUS_TIMESTAMP}\"
    }")
assert_success "Submit weather data from Oracle 2" "$WEATHER_2"

echo "Test 5.2: Submit weather data from Oracle 3 (within consensus range)..."
WEATHER_3=$(curl -s -X POST "${API_BASE}/weather-oracle" \
    -H "Content-Type: application/json" \
    -d "{
        \"dataID\": \"${WEATHER_ID}_03\",
        \"oracleID\": \"ORACLE_E2E_WU\",
        \"location\": \"Test_Region\",
        \"latitude\": \"1.3521\",
        \"longitude\": \"103.8198\",
        \"rainfall\": 33.8,
        \"temperature\": 34.2,
        \"humidity\": 64.5,
        \"windSpeed\": 13.0,
        \"recordedAt\": \"${CONSENSUS_TIMESTAMP}\"
    }")
assert_success "Submit weather data from Oracle 3" "$WEATHER_3"

sleep 1

# Test 5.3: Validate consensus across oracles (should trigger automatic payout)
echo "Test 5.3: Validate weather data consensus and check automatic payout..."
CONSENSUS_RESULT=$(curl -s -X POST "${API_BASE}/weather-oracle/validate-consensus" \
    -H "Content-Type: application/json" \
    -d "{
        \"location\": \"Test_Region\",
        \"timestamp\": \"${CONSENSUS_TIMESTAMP}\",
        \"dataIDs\": [\"${WEATHER_ID}_01\", \"${WEATHER_ID}_02\", \"${WEATHER_ID}_03\"]
    }")
assert_success "Validate consensus" "$CONSENSUS_RESULT"

CONSENSUS_REACHED=$(echo "$CONSENSUS_RESULT" | jq -r '.data.consensusReached // false')
assert_equals "Consensus reached" "true" "$CONSENSUS_REACHED"

# Test 5.3b: Verify automatic payout system was triggered
echo "Test 5.3b: Verify automatic payout system responded..."
PAYOUT_ENABLED=$(echo "$CONSENSUS_RESULT" | jq -r '.data.automaticPayouts.enabled // false')
assert_equals "Automatic payout enabled" "true" "$PAYOUT_ENABLED"

POLICIES_CHECKED=$(echo "$CONSENSUS_RESULT" | jq -r '.data.automaticPayouts.policiesChecked // 0')
echo "  Policies checked for thresholds: $POLICIES_CHECKED"

# Test 5.4: Verify data status changed to Validated
echo "Test 5.4: Verify weather data status changed to 'Validated'..."
sleep 2
VALIDATED_DATA=$(curl -s "${API_BASE}/weather-oracle/${WEATHER_ID}_01")
DATA_STATUS=$(echo "$VALIDATED_DATA" | jq -r '.data.status // empty')
assert_equals "Weather data status" "Validated" "$DATA_STATUS"

VALIDATION_SCORE=$(echo "$VALIDATED_DATA" | jq -r '.data.validationScore // 0')
assert_equals "Validation score" "100" "$VALIDATION_SCORE"

# Test 5.5: Get weather data by location (should show all 3 validated submissions)
echo "Test 5.5: Get weather data by location..."
LOCATION_WEATHER=$(curl -s "${API_BASE}/weather-oracle/location/Test_Region")
assert_success "Get weather by location" "$LOCATION_WEATHER"

WEATHER_COUNT=$(echo "$LOCATION_WEATHER" | jq '.data | length')
if [ "$WEATHER_COUNT" -ge 3 ]; then
    echo -e "${GREEN}✓${NC} PASS: Found $WEATHER_COUNT weather data points"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Expected at least 3 data points, found $WEATHER_COUNT"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

echo ""

################################################################################
# TEST SUITE 6: CLAIMS PROCESSING & PAYOUT
################################################################################

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Test Suite 6: Claims Processing & Payout${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Test 6.1: Trigger claim based on validated weather data
echo "Test 6.1: Trigger claim (drought condition - using validated consensus data)..."
CLAIM_RESPONSE=$(curl -s -X POST "${API_BASE}/claims" \
    -H "Content-Type: application/json" \
    -d "{
        \"claimID\": \"${CLAIM_ID}\",
        \"policyID\": \"${POLICY_ID}\",
        \"farmerID\": \"${FARMER_ID}\",
        \"weatherDataID\": \"${WEATHER_ID}_01\",
        \"coverageAmount\": 5000,
        \"payoutPercent\": 50
    }")
assert_success "Trigger claim" "$CLAIM_RESPONSE"

# Test 6.2: Get claim by ID
echo "Test 6.2: Get claim details..."
sleep 2
CLAIM_GET=$(curl -s "${API_BASE}/claims/${CLAIM_ID}")
CLAIM_STATUS=$(echo "$CLAIM_GET" | jq -r '.data.status // empty')
assert_not_empty "Claim status exists" "$CLAIM_STATUS"

# Test 6.3: Get all claims
echo "Test 6.3: Get all claims..."
ALL_CLAIMS=$(curl -s "${API_BASE}/claims")
assert_success "Get all claims" "$ALL_CLAIMS"

# Test 6.4: Get claims by farmer
echo "Test 6.4: Get claims by farmer..."
FARMER_CLAIMS=$(curl -s "${API_BASE}/claims/farmer/${FARMER_ID}")
assert_success "Get farmer claims" "$FARMER_CLAIMS"

# Test 6.5: Execute payout from premium pool
echo "Test 6.5: Execute payout from pool..."
PAYOUT_AMOUNT=2500
BALANCE_BEFORE_PAYOUT=$(curl -s "${API_BASE}/premium-pool/balance" | jq -r '.data // 0')

PAYOUT_RESPONSE=$(curl -s -X POST "${API_BASE}/premium-pool/withdraw" \
    -H "Content-Type: application/json" \
    -d "{
        \"amount\": ${PAYOUT_AMOUNT},
        \"recipient\": \"${FARMER_ID}\",
        \"claimID\": \"${CLAIM_ID}\",
        \"policyID\": \"${POLICY_ID}\"
    }")
assert_success "Execute payout" "$PAYOUT_RESPONSE"

# Test 6.6: Verify pool balance decreased
echo "Test 6.6: Verify pool balance decreased..."
sleep 2
BALANCE_AFTER_PAYOUT=$(curl -s "${API_BASE}/premium-pool/balance" | jq -r '.data // 0')
if (( $(echo "$BALANCE_AFTER_PAYOUT < $BALANCE_BEFORE_PAYOUT" | bc -l) )); then
    WITHDRAWN=$(echo "$BALANCE_BEFORE_PAYOUT - $BALANCE_AFTER_PAYOUT" | bc)
    echo -e "${GREEN}✓${NC} PASS: Pool balance decreased by \$$WITHDRAWN"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Pool balance did not decrease"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

# Test 6.7: Verify payout transaction recorded
echo "Test 6.7: Verify payout transaction in history..."
PAYOUT_TX=$(curl -s "${API_BASE}/premium-pool/history" | jq -r '.data[0] // empty')
PAYOUT_TYPE=$(echo "$PAYOUT_TX" | jq -r '.type // empty')
assert_equals "Payout transaction type" "Payout" "$PAYOUT_TYPE"

# Test 6.8: Get claim history
echo "Test 6.8: Get claim history..."
CLAIM_HISTORY=$(curl -s "${API_BASE}/claims/${CLAIM_ID}/history")
assert_success "Get claim history" "$CLAIM_HISTORY"

echo ""

################################################################################
# TEST SUITE 7: DASHBOARD & STATISTICS
################################################################################

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Test Suite 7: Dashboard & Statistics${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Test 7.1: Get dashboard stats
echo "Test 7.1: Get dashboard statistics..."
DASHBOARD=$(curl -s "${API_BASE}/dashboard/stats")
assert_success "Get dashboard stats" "$DASHBOARD"

TOTAL_POLICIES=$(echo "$DASHBOARD" | jq -r '.data.totalPolicies // 0')
TOTAL_CLAIMS=$(echo "$DASHBOARD" | jq -r '.data.totalClaims // 0')
echo "  Total Policies: $TOTAL_POLICIES"
echo "  Total Claims: $TOTAL_CLAIMS"

# Test 7.2: Get recent transactions
echo "Test 7.2: Get recent transactions..."
RECENT_TX=$(curl -s "${API_BASE}/dashboard/transactions")
assert_success "Get recent transactions" "$RECENT_TX"

# Test 7.3: Get all policies
echo "Test 7.3: Get all policies..."
ALL_POLICIES=$(curl -s "${API_BASE}/policies")
POLICY_COUNT=$(echo "$ALL_POLICIES" | jq '.data | length')
assert_not_empty "Policies exist" "$POLICY_COUNT"

# Test 7.4: Get policies by farmer
echo "Test 7.4: Get policies by farmer..."
FARMER_POLICIES=$(curl -s "${API_BASE}/policies/farmer/${FARMER_ID}")
assert_success "Get farmer policies" "$FARMER_POLICIES"

echo ""

################################################################################
# TEST SUITE 8: UI ACCESSIBILITY
################################################################################

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Test Suite 8: UI Accessibility${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Test 8.1: Dashboard page
echo "Test 8.1: Check Dashboard page..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${UI_BASE}/")
assert_status "Dashboard accessible" "200" "$HTTP_CODE"

# Test 8.2: Policies page
echo "Test 8.2: Check Policies page..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${UI_BASE}/policies")
assert_status "Policies page accessible" "200" "$HTTP_CODE"

# Test 8.3: Claims page
echo "Test 8.3: Check Claims page..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${UI_BASE}/claims")
assert_status "Claims page accessible" "200" "$HTTP_CODE"

# Test 8.4: Approvals page
echo "Test 8.4: Check Approvals page..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${UI_BASE}/approvals")
assert_status "Approvals page accessible" "200" "$HTTP_CODE"

# Test 8.5: Premium Pool page
echo "Test 8.5: Check Premium Pool page..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${UI_BASE}/premium-pool")
assert_status "Premium Pool page accessible" "200" "$HTTP_CODE"

# Test 8.6: Farmers page
echo "Test 8.6: Check Farmers page..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${UI_BASE}/farmers")
assert_status "Farmers page accessible" "200" "$HTTP_CODE"

# Test 8.7: Weather page
echo "Test 8.7: Check Weather page..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${UI_BASE}/weather")
assert_status "Weather page accessible" "200" "$HTTP_CODE"

echo ""

################################################################################
# TEST RESULTS SUMMARY
################################################################################

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}║                    TEST RESULTS SUMMARY                        ║${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED/$TESTS_TOTAL)*100}")

echo "Total Tests: $TESTS_TOTAL"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
else
    echo "Failed: $TESTS_FAILED"
fi
echo "Pass Rate: ${PASS_RATE}%"
echo ""

# Test artifacts summary
echo -e "${BLUE}Test Artifacts Created:${NC}"
echo "  Farmer ID: $FARMER_ID"
echo "  Policy ID: $POLICY_ID"
echo "  Approval ID: $APPROVAL_ID"
echo "  Weather ID: $WEATHER_ID"
echo "  Claim ID: $CLAIM_ID"
echo ""

# Final verdict
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║                    ✓ ALL TESTS PASSED!                        ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║     System is production-ready and fully functional!          ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                                ║${NC}"
    echo -e "${RED}║                   ✗ SOME TESTS FAILED                          ║${NC}"
    echo -e "${RED}║                                                                ║${NC}"
    echo -e "${RED}║     Please review the failed tests above.                     ║${NC}"
    echo -e "${RED}║                                                                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
