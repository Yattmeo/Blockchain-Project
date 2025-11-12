#!/bin/bash

# Enhanced Endorsement Policy Verification Test
# This script verifies that transactions are actually validated correctly in the blockchain

# Add Docker to PATH
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

echo "=========================================================="
echo "ENDORSEMENT POLICY VALIDATION TEST (Enhanced)"
echo "=========================================================="
echo ""
echo "This test verifies actual transaction validation in the blockchain"
echo "by checking peer logs for ENDORSEMENT_POLICY_FAILURE markers."
echo ""

CHANNEL_NAME="insurance-main"
ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo "========================================="
    echo -e "${BLUE}$1${NC}"
    echo "========================================="
}

print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS: $2${NC}"
    else
        echo -e "${RED}✗ FAIL: $2${NC}"
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Get current block height to compare before/after
get_block_height() {
    docker exec cli peer channel getinfo -c ${CHANNEL_NAME} 2>&1 | grep -oP 'height:\K\d+' || echo "0"
}

# Check if a transaction was marked as invalid
check_transaction_validity() {
    local TX_ID=$1
    local EXPECTED_STATUS=$2  # "VALID" or "INVALID"
    
    sleep 2  # Wait for block to be committed and logged
    
    # Check peer logs for this transaction
    local LOG_OUTPUT=$(docker logs peer0.insurer1.insurance.com 2>&1 | grep "$TX_ID" | tail -5)
    
    if echo "$LOG_OUTPUT" | grep -q "ENDORSEMENT_POLICY_FAILURE"; then
        if [ "$EXPECTED_STATUS" = "INVALID" ]; then
            return 0  # Success - transaction was correctly marked invalid
        else
            return 1  # Failure - transaction should have been valid
        fi
    else
        if [ "$EXPECTED_STATUS" = "VALID" ]; then
            return 0  # Success - transaction was valid
        else
            return 1  # Failure - transaction should have been invalid
        fi
    fi
}

# Clear old logs to make checking easier
echo "Preparing test environment..."
docker exec cli peer channel getinfo -c ${CHANNEL_NAME} > /dev/null 2>&1

print_header "TEST 1: Farmer Registration - Insufficient Endorsements"
print_info "Policy: Coop + ANY Insurer (both required)"
print_info "Attempt: Only Insurer1MSP signature (missing Coop)"
print_info "Expected: Transaction marked as INVALID"

TX_OUTPUT=$(docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
    -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
    cli peer chaincode invoke \
    -C ${CHANNEL_NAME} -n farmer \
    --peerAddresses peer0.insurer1.insurance.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    -c '{"function":"RegisterFarmer","Args":["TEST-FAIL-001","John","Doe","TestCoop","1234567890","test@example.com","0xWallet123","10.5","20.3","TestRegion","TestDistrict","5.5","[\"Arabica\"]","kychash123"]}' \
    --tls --cafile ${ORDERER_CA} 2>&1)

# Extract transaction ID (macOS compatible)
TX_ID_1=$(echo "$TX_OUTPUT" | grep "txid" | sed -n 's/.*txid \[\([^]]*\)\].*/\1/p' | head -1)
echo "Transaction ID: $TX_ID_1"

# Wait and check logs
sleep 3
VALIDATION_LOG=$(docker logs peer0.insurer1.insurance.com 2>&1 | grep -A2 "$TX_ID_1" | grep "ENDORSEMENT_POLICY_FAILURE")

if [ -n "$VALIDATION_LOG" ]; then
    print_result 0 "Transaction correctly marked as INVALID due to insufficient endorsements"
else
    print_result 1 "Transaction should have been marked INVALID but wasn't found in logs"
fi

print_header "TEST 2: Farmer Registration - Sufficient Endorsements"
print_info "Policy: Coop + ANY Insurer (both required)"
print_info "Attempt: CoopMSP + Insurer1MSP signatures"
print_info "Expected: Transaction marked as VALID"

TX_OUTPUT=$(docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
    -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
    cli peer chaincode invoke \
    -C ${CHANNEL_NAME} -n farmer \
    --peerAddresses peer0.insurer1.insurance.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    --peerAddresses peer0.coop.insurance.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
    -c '{"function":"RegisterFarmer","Args":["TEST-SUCCESS-001","Jane","Smith","TestCoop","9876543210","test2@example.com","0xWallet456","11.5","21.3","TestRegion","TestDistrict","7.2","[\"Robusta\"]","kychash456"]}' \
    --tls --cafile ${ORDERER_CA} 2>&1)

TX_ID_2=$(echo "$TX_OUTPUT" | grep "txid" | sed -n 's/.*txid \[\([^]]*\)\].*/\1/p' | head -1)
echo "Transaction ID: $TX_ID_2"

sleep 3
VALIDATION_LOG=$(docker logs peer0.insurer1.insurance.com 2>&1 | grep "$TX_ID_2" | grep "ENDORSEMENT_POLICY_FAILURE")

if [ -z "$VALIDATION_LOG" ]; then
    print_result 0 "Transaction correctly marked as VALID with proper endorsements"
else
    print_result 1 "Transaction should have been VALID but was marked INVALID"
fi

print_header "TEST 3: Policy Creation - Insufficient Endorsements"
print_info "Policy: ANY Insurer + Coop (both required)"
print_info "Attempt: Only PlatformMSP signature (has neither)"
print_info "Expected: Transaction marked as INVALID"

TX_OUTPUT=$(docker exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
    -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
    cli peer chaincode invoke \
    -C ${CHANNEL_NAME} -n policy \
    --peerAddresses peer0.platform.insurance.com:10051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
    -c '{"function":"CreatePolicy","Args":["TEST-POL-FAIL-001","TEST-SUCCESS-001","TMPL-001","TestCoop","Insurer1","10000","500","90","TestLocation","Arabica","5.5","policyhash123"]}' \
    --tls --cafile ${ORDERER_CA} 2>&1)

TX_ID_3=$(echo "$TX_OUTPUT" | grep "txid" | sed -n 's/.*txid \[\([^]]*\)\].*/\1/p' | head -1)
echo "Transaction ID: $TX_ID_3"

sleep 3
VALIDATION_LOG=$(docker logs peer0.insurer1.insurance.com 2>&1 | grep "$TX_ID_3" | grep "ENDORSEMENT_POLICY_FAILURE")

if [ -n "$VALIDATION_LOG" ]; then
    print_result 0 "Transaction correctly marked as INVALID due to insufficient endorsements"
else
    print_result 1 "Transaction should have been marked INVALID but wasn't found in logs"
fi

print_header "TEST 4: Policy Creation - Sufficient Endorsements"
print_info "Policy: ANY Insurer + Coop (both required)"
print_info "Attempt: Insurer1MSP + CoopMSP signatures"
print_info "Expected: Transaction marked as VALID"

TX_OUTPUT=$(docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
    -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
    cli peer chaincode invoke \
    -C ${CHANNEL_NAME} -n policy \
    --peerAddresses peer0.insurer1.insurance.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    --peerAddresses peer0.coop.insurance.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
    -c '{"function":"CreatePolicy","Args":["TEST-POL-SUCCESS-001","TEST-SUCCESS-001","TMPL-001","TestCoop","Insurer1","10000","500","90","TestLocation","Arabica","5.5","policyhash456"]}' \
    --tls --cafile ${ORDERER_CA} 2>&1)

TX_ID_4=$(echo "$TX_OUTPUT" | grep "txid" | sed -n 's/.*txid \[\([^]]*\)\].*/\1/p' | head -1)
echo "Transaction ID: $TX_ID_4"

sleep 3
VALIDATION_LOG=$(docker logs peer0.insurer1.insurance.com 2>&1 | grep "$TX_ID_4" | grep "ENDORSEMENT_POLICY_FAILURE")

if [ -z "$VALIDATION_LOG" ]; then
    print_result 0 "Transaction correctly marked as VALID with proper endorsements"
else
    print_result 1 "Transaction should have been VALID but was marked INVALID"
fi

print_header "TEST 5: Query Committed Policies"
print_info "Checking blockchain state for committed endorsement policies"
echo ""

echo "Farmer Chaincode:"
docker exec cli peer lifecycle chaincode querycommitted --channelID insurance-main --name farmer 2>&1 | grep -E "Version|Sequence|Endorsement|Validation"
echo ""

echo "Policy Chaincode:"
docker exec cli peer lifecycle chaincode querycommitted --channelID insurance-main --name policy 2>&1 | grep -E "Version|Sequence|Endorsement|Validation"
echo ""

echo "Weather Oracle Chaincode:"
docker exec cli peer lifecycle chaincode querycommitted --channelID insurance-main --name weather-oracle 2>&1 | grep -E "Version|Sequence|Endorsement|Validation"
echo ""

echo "Premium Pool Chaincode:"
docker exec cli peer lifecycle chaincode querycommitted --channelID insurance-main --name premium-pool 2>&1 | grep -E "Version|Sequence|Endorsement|Validation"

echo ""
print_header "SUMMARY"
echo ""
echo "Expected Results:"
echo "  ✓ Test 1: INVALID - Single org cannot register farmers (missing Coop)"
echo "  ✓ Test 2: VALID   - Coop + Insurer can register farmers"
echo "  ✓ Test 3: INVALID - Platform alone cannot create policies"
echo "  ✓ Test 4: VALID   - Insurer + Coop can create policies"
echo ""
echo "All tests passing = Endorsement policies are working correctly!"
echo ""
print_info "Note: Peer logs show ENDORSEMENT_POLICY_FAILURE for invalid transactions"
print_info "View full logs: docker logs peer0.insurer1.insurance.com 2>&1 | grep -i endorsement"
echo ""
echo "=========================================================="
