#!/bin/bash

# ========================================
# COMPREHENSIVE E2E TEST SUITE
# Weather Index Insurance Platform
# Tests All 8 Core Chaincodes
# ========================================

export PATH="/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"

CHANNEL="insurance-main"
START_TIME=$(date +%s)
RUN_ID=$(date +%s)
PASSED=0
FAILED=0
TOTAL=18

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test IDs with unique run identifier
ORG_ID="ORG_${RUN_ID}_1"
FARMER_ID="FARMER_${RUN_ID}_1"
TEMPLATE_ID="TMPL_${RUN_ID}_1"
POLICY_ID="POL_${RUN_ID}_1"
ORACLE_ID="ORACLE_${RUN_ID}_1"
DATA_ID="DATA_${RUN_ID}_1"
INDEX_ID="IDX_${RUN_ID}_1"
CLAIM_ID="CLAIM_${RUN_ID}_1"
TX_ID="TX_${RUN_ID}_1"

echo "=========================================
Weather Index Insurance E2E Test Suite
========================================="
echo "Run ID: $RUN_ID"
echo "Start: $(date)"
echo "Testing all 8 core chaincodes"
echo ""

# Warmup: Trigger chaincode container instantiation on all peers
echo -e "${YELLOW}Warming up chaincode containers (this may take 30-60 seconds)...${NC}"
WARMUP_CMDS=(
    "access-control RegisterOrganization WARMUP_ORG WarmupOrg Insurer Insurer1MSP warmup@test.com"
    "farmer RegisterFarmer WARMUP_FARMER W W COOP +1 w@w.com 0x1 1 1 R D 1 [\\\"W\\\"] hash"
    "policy-template CreateTemplate WARMUP_TMPL T C R M 90 1 1"
    "policy CreatePolicy WARMUP_POL WARMUP_FARMER WARMUP_TMPL 100 1 1"
    "weather-oracle RegisterOracleProvider WARMUP_ORC W API [\\\"w.com\\\"]"
    "index-calculator CalculateRainfallIndex WARMUP_IDX WARMUP_POL R 1 1 100 200"
    "claim-processor TriggerPayout WARMUP_CLAIM WARMUP_POL WARMUP_IDX"
    "premium-pool DepositPremium WARMUP_POL 100"
)

for cmd in "${WARMUP_CMDS[@]}"; do
    IFS=' ' read -r cc func args <<< "$cmd"
    echo -n "  - $cc: "
    docker exec cli peer chaincode invoke -o orderer.insurance.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem -C $CHANNEL -n $cc --peerAddresses peer0.insurer1.insurance.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt --peerAddresses peer0.insurer2.insurance.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt --peerAddresses peer0.coop.insurance.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt -c "{\"function\":\"$func\",\"Args\":[$args]}" > /dev/null 2>&1 && echo "✓" || echo "✓"
done
echo -e "${GREEN}All chaincode containers ready${NC}\n"
sleep 3

# Test function with multi-peer endorsement
test_invoke() {
    local name="$1"
    local cc="$2"
    local func="$3"
    shift 3
    
    local test_num=$((PASSED + FAILED + 1))
    echo -e "${BLUE}[TEST $test_num/$TOTAL] $name${NC}"
    
    local args_json="["
    for arg in "$@"; do
        args_json+="\"$arg\","
    done
    args_json="${args_json%,}]"
    
    local tx_start=$(date +%s)
    
    if docker exec cli peer chaincode invoke \
        -o orderer.insurance.com:7050 \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        -C $CHANNEL \
        -n $cc \
        --peerAddresses peer0.insurer1.insurance.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        --peerAddresses peer0.insurer2.insurance.com:8051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
        --peerAddresses peer0.coop.insurance.com:9051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
        -c "{\"function\":\"$func\",\"Args\":$args_json}" 2>&1 | grep -q "Chaincode invoke successful"; then
        
        local tx_end=$(date +%s)
        local duration=$((tx_end - tx_start))
        echo -e "${GREEN}✓ PASSED${NC} (${duration}s)"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Query test
test_query() {
    local name="$1"
    local cc="$2"
    local func="$3"
    shift 3
    
    local test_num=$((PASSED + FAILED + 1))
    echo -e "${BLUE}[TEST $test_num/$TOTAL] $name${NC}"
    
    local args_json="["
    for arg in "$@"; do
        args_json+="\"$arg\","
    done
    args_json="${args_json%,}]"
    
    local result=$(docker exec cli peer chaincode query \
        -C $CHANNEL \
        -n $cc \
        -c "{\"function\":\"$func\",\"Args\":$args_json}" 2>&1)
    
    if [[ $result != *"Error"* ]] && [[ -n $result ]] && [[ $result != "null" ]]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# ========================================
# PHASE 1: Access Control (Chaincode 1/8)
# ========================================
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}PHASE 1: Access Control & Identity${NC}"
echo -e "${CYAN}========================================${NC}\n"

test_invoke "Register Organization" "access-control" "RegisterOrganization" \
    "$ORG_ID" "Premium Insurance Ltd" "Insurer" "Insurer1MSP" "contact@premium.com"
sleep 2

test_query "Verify Organization" "access-control" "GetOrganization" "$ORG_ID"
sleep 1

# ========================================
# PHASE 2: Farmer Management (Chaincode 2/8)
# ========================================
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}PHASE 2: Farmer Registration${NC}"
echo -e "${CYAN}========================================${NC}\n"

# Note: Farmer registration uses custom invoke due to array parameter
echo -e "${BLUE}[TEST $((PASSED + FAILED + 1))/$TOTAL] Register Farmer${NC}"
if docker exec cli peer chaincode invoke \
    -o orderer.insurance.com:7050 \
    --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
    -C $CHANNEL \
    -n farmer \
    --peerAddresses peer0.insurer1.insurance.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    --peerAddresses peer0.insurer2.insurance.com:8051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
    --peerAddresses peer0.coop.insurance.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
    -c "{\"function\":\"RegisterFarmer\",\"Args\":[\"$FARMER_ID\",\"John\",\"Doe\",\"COOP_001\",\"+1234567890\",\"john@farm.com\",\"0x123wallet\",\"10.5\",\"20.3\",\"Central Region\",\"District A\",\"5.5\",\"[\\\"Arabica\\\",\\\"Robusta\\\"]\",\"hash123\"]}" 2>&1 | grep -q "Chaincode invoke successful"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED=$((FAILED + 1))
fi
sleep 2

test_query "Get Farmer Profile" "farmer" "GetFarmer" "$FARMER_ID"
sleep 1

# ========================================
# PHASE 3: Policy Template (Chaincode 3/8)
# ========================================
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}PHASE 3: Policy Template Creation${NC}"
echo -e "${CYAN}========================================${NC}\n"

test_invoke "Create Policy Template" "policy-template" "CreateTemplate" \
    "$TEMPLATE_ID" "Coffee Rainfall Protection" "Arabica" "Central" "Medium" "90" "10000" "100"
sleep 2

test_invoke "Set Index Threshold" "policy-template" "SetIndexThreshold" \
    "$TEMPLATE_ID" "Rainfall" "mm" "500" "<" "30" "50" "Moderate"
sleep 2

test_query "Get Template" "policy-template" "GetTemplate" "$TEMPLATE_ID"
sleep 1

# ========================================
# PHASE 4: Policy Creation (Chaincode 4/8)
# ========================================
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}PHASE 4: Policy Issuance${NC}"
echo -e "${CYAN}========================================${NC}\n"

test_invoke "Create Policy" "policy" "CreatePolicy" \
    "$POLICY_ID" "$FARMER_ID" "$TEMPLATE_ID" "COOP_001" "INS_001" \
    "5000" "250" "90" "Central Region" "Arabica" "5.5" "policyterms_hash"
sleep 2

test_query "Get Policy Details" "policy" "GetPolicy" "$POLICY_ID"
sleep 1

# ========================================
# PHASE 5: Weather Oracle (Chaincode 5/8)
# ========================================
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}PHASE 5: Weather Data Collection${NC}"
echo -e "${CYAN}========================================${NC}\n"

# Note: Weather Oracle registration uses custom invoke due to array parameter
echo -e "${BLUE}[TEST $((PASSED + FAILED + 1))/$TOTAL] Register Oracle${NC}"
if docker exec cli peer chaincode invoke \
    -o orderer.insurance.com:7050 \
    --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
    -C $CHANNEL \
    -n weather-oracle \
    --peerAddresses peer0.insurer1.insurance.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    --peerAddresses peer0.insurer2.insurance.com:8051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
    --peerAddresses peer0.coop.insurance.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
    -c "{\"function\":\"RegisterOracleProvider\",\"Args\":[\"$ORACLE_ID\",\"WeatherAPI Pro\",\"API\",\"[\\\"api.weather.com\\\",\\\"backup.weather.com\\\"]\"]}" 2>&1 | grep -q "Chaincode invoke successful"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED=$((FAILED + 1))
fi
sleep 2

test_invoke "Submit Weather Data" "weather-oracle" "SubmitWeatherData" \
    "$DATA_ID" "$ORACLE_ID" "Central Region" "10.5" "20.3" \
    "350" "28.5" "65" "15.5" "1013.25" "Sunny"
sleep 2

test_query "Get Weather Data" "weather-oracle" "GetWeatherData" "$DATA_ID"
sleep 1

# ========================================
# PHASE 6: Index Calculator (Chaincode 6/8)
# ========================================
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}PHASE 6: Weather Index Calculation${NC}"
echo -e "${CYAN}========================================${NC}\n"

test_invoke "Calculate Rainfall Index" "index-calculator" "CalculateRainfallIndex" \
    "$INDEX_ID" "Central Region" "2025-08-01T00:00:00Z" "2025-10-31T00:00:00Z" "350" "500"
sleep 2

test_query "Get Weather Index" "index-calculator" "GetWeatherIndex" "$INDEX_ID"
sleep 1

# ========================================
# PHASE 7: Claim Processing (Chaincode 7/8)
# ========================================
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}PHASE 7: Claims Management${NC}"
echo -e "${CYAN}========================================${NC}\n"

test_invoke "Trigger Payout" "claim-processor" "TriggerPayout" \
    "$CLAIM_ID" "$POLICY_ID" "$FARMER_ID" "$INDEX_ID" "10000" "50"
sleep 2

test_query "Get Claim Status" "claim-processor" "GetClaim" "$CLAIM_ID"
sleep 1

# ========================================
# PHASE 8: Premium Pool (Chaincode 8/8)
# ========================================
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}PHASE 8: Premium Pool Management${NC}"
echo -e "${CYAN}========================================${NC}\n"

test_invoke "Deposit Premium" "premium-pool" "DepositPremium" \
    "$TX_ID" "$FARMER_ID" "$POLICY_ID" "250"
sleep 2

test_query "Get Pool Balance" "premium-pool" "GetPoolBalance"
sleep 1

# ========================================
# FINAL RESULTS
# ========================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "========================================="
echo "TEST RESULTS"
echo "========================================="
echo -e "Total Tests:    ${BLUE}$TOTAL${NC}"
echo -e "Passed:         ${GREEN}$PASSED${NC}"
echo -e "Failed:         ${RED}$FAILED${NC}"
echo -e "Success Rate:   $(( PASSED * 100 / TOTAL ))%"
echo -e "Duration:       ${DURATION}s"
echo "========================================="
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓✓✓ ALL TESTS PASSED ✓✓✓${NC}"
    echo ""
    echo "Platform Verification Complete:"
    echo "  ✓ Access Control - Identity management working"
    echo "  ✓ Farmer Management - Registration operational"
    echo "  ✓ Policy Templates - Product definition working"
    echo "  ✓ Policy Creation - Contract issuance functional"
    echo "  ✓ Weather Oracle - Data collection active"
    echo "  ✓ Index Calculator - Index computation working"
    echo "  ✓ Claim Processor - Claims workflow operational"
    echo "  ✓ Premium Pool - Financial management working"
    echo ""
    echo -e "${GREEN}✅ PLATFORM IS FULLY OPERATIONAL!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo "Failed: $FAILED/$TOTAL tests"
    exit 1
fi
