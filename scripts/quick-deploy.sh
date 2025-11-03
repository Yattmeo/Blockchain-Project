#!/bin/bash

# Quick deploy script for essential chaincodes only
#  This deploys just the chaincodes needed for end-to-end testing

set -e

# Add docker to PATH
export PATH="/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"

CHANNEL_NAME="insurance-main"
CC_LANG="golang"
CC_VERSION="1.0"
SEQUENCE=1

echo "========================================="
echo "Deploying Essential Chaincodes"
echo "========================================="
echo ""

# Function to deploy a chaincode quickly
deploy_chaincode() {
    local CC_NAME=$1
    local CC_PATH="/opt/gopath/src/github.com/chaincode/${CC_NAME}"
    
    echo ">>> Deploying: ${CC_NAME}"
    
    # Package
    docker exec cli peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_PATH} \
        --lang ${CC_LANG} \
        --label ${CC_NAME}_${CC_VERSION} > /dev/null 2>&1
    
    # Install on Insurer1 only (for testing)
    docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}.tar.gz > /dev/null 2>&1
    
    # Insurer2
    docker exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}.tar.gz > /dev/null 2>&1
    
    # Coop
    docker exec -e CORE_PEER_LOCALMSPID=CoopMSP \
        -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}.tar.gz > /dev/null 2>&1
    
    # Platform
    docker exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
        -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}.tar.gz > /dev/null 2>&1
    
    # Get package ID
    PACKAGE_ID=$(docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
        cli peer lifecycle chaincode queryinstalled 2>/dev/null | grep "${CC_NAME}_${CC_VERSION}" | awk '{print $3}' | sed 's/,$//')
    
    # Approve for all orgs
    for ORG in "Insurer1MSP:peer0.insurer1.insurance.com:7051:insurer1" "Insurer2MSP:peer0.insurer2.insurance.com:8051:insurer2" "CoopMSP:peer0.coop.insurance.com:9051:coop" "PlatformMSP:peer0.platform.insurance.com:10051:platform"; do
        IFS=':' read -r MSP_ID PEER_ADDR PEER_PORT ORG_NAME <<< "$ORG"
        docker exec -e CORE_PEER_LOCALMSPID=${MSP_ID} \
            -e CORE_PEER_ADDRESS=${PEER_ADDR}:${PEER_PORT} \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG_NAME}.insurance.com/peers/${PEER_ADDR}/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG_NAME}.insurance.com/users/Admin@${ORG_NAME}.insurance.com/msp \
            cli peer lifecycle chaincode approveformyorg \
            -o orderer.insurance.com:7050 \
            --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
            --channelID ${CHANNEL_NAME} \
            --name ${CC_NAME} \
            --version ${CC_VERSION} \
            --package-id ${PACKAGE_ID} \
            --sequence ${SEQUENCE} > /dev/null 2>&1
    done
    
    # Commit
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
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt > /dev/null 2>&1
    
    echo "✅ ${CC_NAME}"
}

# Deploy essential chaincodes
deploy_chaincode "farmer"
deploy_chaincode "policy-template"
deploy_chaincode "policy"
deploy_chaincode "weather-oracle"
deploy_chaincode "index-calculator"
deploy_chaincode "claim-processor"
deploy_chaincode "premium-pool"

echo ""
echo "✅ All essential chaincodes deployed!"
echo ""
docker exec cli peer lifecycle chaincode querycommitted -C ${CHANNEL_NAME}
