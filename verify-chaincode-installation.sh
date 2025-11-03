#!/bin/bash

# Script to verify chaincode installation across all peers

export PATH="/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"

echo "========================================="
echo "Chaincode Installation Verification"
echo "========================================="
echo ""

CHAINCODES=("access-control" "farmer" "policy-template" "policy" "weather-oracle" "index-calculator" "claim-processor" "premium-pool")
PEERS=(
    "Insurer1MSP:peer0.insurer1.insurance.com:7051:insurer1"
    "Insurer2MSP:peer0.insurer2.insurance.com:8051:insurer2"
    "CoopMSP:peer0.coop.insurance.com:9051:coop"
    "PlatformMSP:peer0.platform.insurance.com:10051:platform"
)

for PEER_INFO in "${PEERS[@]}"; do
    IFS=':' read -r MSP_ID PEER_ADDR PEER_PORT ORG <<< "$PEER_INFO"
    
    echo "Peer: $PEER_ADDR ($MSP_ID)"
    echo "----------------------------------------"
    
    for CC in "${CHAINCODES[@]}"; do
        RESULT=$(docker exec -e CORE_PEER_LOCALMSPID=$MSP_ID \
            -e CORE_PEER_ADDRESS=$PEER_ADDR:$PEER_PORT \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/$ORG.insurance.com/peers/$PEER_ADDR/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/$ORG.insurance.com/users/Admin@$ORG.insurance.com/msp \
            cli peer lifecycle chaincode queryinstalled 2>&1 | grep "$CC" || echo "NOT_INSTALLED")
        
        if [[ "$RESULT" == "NOT_INSTALLED" ]]; then
            echo "  ✗ $CC - NOT INSTALLED"
        else
            echo "  ✓ $CC - Installed"
        fi
    done
    echo ""
done

echo "========================================="
echo "Verification Complete"
echo "========================================="
