#!/bin/bash

# Script to deploy all remaining chaincodes
# Runs inside the blockchain network

set -e

# Add docker to PATH
export PATH="/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"

CHANNEL_NAME="insurance-main"
CC_LANG="golang"
CC_VERSION="1.0"
SEQUENCE=1

# Array of chaincodes to deploy (excluding access-control)
CHAINCODES=(
    "farmer"
    "policy-template"
    "policy"
    "weather-oracle"
    "index-calculator"
    "claim-processor"
    "premium-pool"
    "audit-log"
    "notification"
    "emergency-management"
)

echo "========================================="
echo "Deploying Remaining Chaincodes"
echo "========================================="
echo ""

# Function to deploy a chaincode
deploy_chaincode() {
    local CC_NAME=$1
    local CC_PATH="/opt/gopath/src/github.com/chaincode/${CC_NAME}"
    
    echo "========================================="
    echo "Deploying: ${CC_NAME}"
    echo "========================================="
    
    # Step 1: Package
    echo "Step 1: Packaging ${CC_NAME}..."
    docker exec cli peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_PATH} \
        --lang ${CC_LANG} \
        --label ${CC_NAME}_${CC_VERSION}
    
    # Step 2: Install on all peers
    echo "Step 2: Installing on all peers..."
    
    # Insurer1
    docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}.tar.gz
    
    # Insurer2
    docker exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}.tar.gz
    
    # Coop
    docker exec -e CORE_PEER_LOCALMSPID=CoopMSP \
        -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}.tar.gz
    
    # Platform
    docker exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
        -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}.tar.gz
    
    # Step 3: Query to get package ID
    echo "Step 3: Querying package ID..."
    PACKAGE_ID=$(docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
        cli peer lifecycle chaincode queryinstalled | grep "${CC_NAME}_${CC_VERSION}" | awk '{print $3}' | sed 's/,$//')
    
    echo "Package ID: ${PACKAGE_ID}"
    
    # Step 4: Approve for all organizations
    echo "Step 4: Approving for all organizations..."
    
    # Insurer1
    docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        -o orderer.insurance.com:7050 \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        --channelID ${CHANNEL_NAME} \
        --name ${CC_NAME} \
        --version ${CC_VERSION} \
        --package-id ${PACKAGE_ID} \
        --sequence ${SEQUENCE}
    
    # Insurer2
    docker exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        -o orderer.insurance.com:7050 \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        --channelID ${CHANNEL_NAME} \
        --name ${CC_NAME} \
        --version ${CC_VERSION} \
        --package-id ${PACKAGE_ID} \
        --sequence ${SEQUENCE}
    
    # Coop
    docker exec -e CORE_PEER_LOCALMSPID=CoopMSP \
        -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        -o orderer.insurance.com:7050 \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        --channelID ${CHANNEL_NAME} \
        --name ${CC_NAME} \
        --version ${CC_VERSION} \
        --package-id ${PACKAGE_ID} \
        --sequence ${SEQUENCE}
    
    # Platform
    docker exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
        -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        -o orderer.insurance.com:7050 \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        --channelID ${CHANNEL_NAME} \
        --name ${CC_NAME} \
        --version ${CC_VERSION} \
        --package-id ${PACKAGE_ID} \
        --sequence ${SEQUENCE}
    
    # Step 5: Commit
    echo "Step 5: Committing chaincode..."
    docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
        cli peer lifecycle chaincode commit \
        -o orderer.insurance.com:7050 \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        --channelID ${CHANNEL_NAME} \
        --name ${CC_NAME} \
        --version ${CC_VERSION} \
        --sequence ${SEQUENCE} \
        --peerAddresses peer0.insurer1.insurance.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        --peerAddresses peer0.insurer2.insurance.com:8051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
        --peerAddresses peer0.coop.insurance.com:9051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
        --peerAddresses peer0.platform.insurance.com:10051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt
    
    echo "✅ ${CC_NAME} deployed successfully!"
    echo ""
    sleep 2
}

# Deploy each chaincode
for CC_NAME in "${CHAINCODES[@]}"; do
    deploy_chaincode "${CC_NAME}"
done

echo ""
echo "========================================="
echo "✅ All chaincodes deployed successfully!"
echo "========================================="
echo ""

# Show all committed chaincodes
echo "Deployed chaincodes:"
docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
    -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
    cli peer lifecycle chaincode querycommitted -C ${CHANNEL_NAME}

echo ""
echo "Platform is ready for testing!"
