#!/bin/bash

# Deploy remaining chaincodes
# This script deploys the 3 missing chaincodes

set -e

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

CHANNEL_NAME="insurance-main"

echo "========================================="
echo "Deploying Remaining Chaincodes"
echo "========================================="
echo ""

deploy_chaincode() {
    local CC_NAME=$1
    local CC_VERSION=$2
    
    echo "Deploying: ${CC_NAME} v${CC_VERSION}"
    
    # Package
    echo "  - Packaging..."
    docker exec cli peer lifecycle chaincode package ${CC_NAME}-v${CC_VERSION}.tar.gz \
        --path /opt/gopath/src/github.com/chaincode/${CC_NAME}/ \
        --lang golang \
        --label ${CC_NAME}_${CC_VERSION} > /dev/null 2>&1
    
    # Install on all peers
    echo "  - Installing on all peers..."
    INSTALL_OUTPUT=$(docker exec cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz 2>&1 || true)
    docker exec -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz > /dev/null 2>&1 || true
    docker exec -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz > /dev/null 2>&1 || true
    docker exec -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz > /dev/null 2>&1 || true
    
    # Extract package ID
    PKG_ID=$(echo "$INSTALL_OUTPUT" | grep -oE "${CC_NAME}_${CC_VERSION}:[a-f0-9]+" | head -1)
    echo "  - Package ID: $PKG_ID"
    
    # Approve for all orgs
    echo "  - Approving for all organizations..."
    docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
        --package-id ${PKG_ID} --sequence 1 --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        > /dev/null 2>&1
    
    docker exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
        --package-id ${PKG_ID} --sequence 1 --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        > /dev/null 2>&1
    
    docker exec -e CORE_PEER_LOCALMSPID=CoopMSP \
        -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
        --package-id ${PKG_ID} --sequence 1 --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        > /dev/null 2>&1
    
    docker exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
        -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
        --package-id ${PKG_ID} --sequence 1 --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        > /dev/null 2>&1
    
    # Commit
    echo "  - Committing to channel..."
    docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
        cli peer lifecycle chaincode commit \
        --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
        --sequence 1 --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        --peerAddresses peer0.insurer1.insurance.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        --peerAddresses peer0.insurer2.insurance.com:8051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
        --peerAddresses peer0.coop.insurance.com:9051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
        --peerAddresses peer0.platform.insurance.com:10051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
        > /dev/null 2>&1
    
    echo "✓ ${CC_NAME} v${CC_VERSION} deployed!"
    echo ""
    sleep 2
}

# Deploy remaining chaincodes
deploy_chaincode "index-calculator" "2"
deploy_chaincode "claim-processor" "1"
deploy_chaincode "premium-pool" "2"

echo "========================================="
echo "✓✓✓ ALL REMAINING CHAINCODES DEPLOYED ✓✓✓"
echo "========================================="
echo ""
echo "Verifying deployment..."
docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp cli peer lifecycle chaincode querycommitted --channelID insurance-main 2>&1 | grep "Name:"
