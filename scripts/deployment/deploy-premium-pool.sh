#!/bin/bash

set -e

DOCKER="/usr/local/bin/docker"

echo "Deploying premium-pool chaincode..."

CC_NAME="premium-pool"
CC_VERSION="3"
CHANNEL_NAME="insurance-channel"
SEQUENCE="2"
POLICY_EXPR="OR('Insurer1MSP.peer','Insurer2MSP.peer','CoopMSP.peer','PlatformMSP.peer')"

echo "Step 1: Packaging chaincode..."
$DOCKER exec cli peer lifecycle chaincode package ${CC_NAME}-v${CC_VERSION}.tar.gz \
    --path /opt/gopath/src/github.com/chaincode/${CC_NAME}/ \
    --lang golang \
    --label ${CC_NAME}_${CC_VERSION}

echo "Step 2: Installing on all peers..."
# Install on Insurer1
INSTALL_OUTPUT=$($DOCKER exec cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz 2>&1 || true)

# Install on Insurer2
$DOCKER exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
    -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
    cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz > /dev/null 2>&1 || true

# Install on Coop
$DOCKER exec -e CORE_PEER_LOCALMSPID=CoopMSP \
    -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
    cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz > /dev/null 2>&1 || true

# Install on Platform
$DOCKER exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
    -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
    cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz > /dev/null 2>&1 || true

# Extract package ID
PKG_ID=$(echo "$INSTALL_OUTPUT" | grep -oE "${CC_NAME}_${CC_VERSION}:[a-f0-9]+" | head -1)
echo "Package ID: ${PKG_ID}"

echo "Step 3: Approving for all organizations..."

# Approve for Insurer1
$DOCKER exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
    -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
    cli peer lifecycle chaincode approveformyorg \
    --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
    --package-id ${PKG_ID} --sequence ${SEQUENCE} \
    --signature-policy "${POLICY_EXPR}" --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem

# Approve for Insurer2
$DOCKER exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
    -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
    cli peer lifecycle chaincode approveformyorg \
    --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
    --package-id ${PKG_ID} --sequence ${SEQUENCE} \
    --signature-policy "${POLICY_EXPR}" --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem

# Approve for Coop
$DOCKER exec -e CORE_PEER_LOCALMSPID=CoopMSP \
    -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
    cli peer lifecycle chaincode approveformyorg \
    --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
    --package-id ${PKG_ID} --sequence ${SEQUENCE} \
    --signature-policy "${POLICY_EXPR}" --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem

# Approve for Platform
$DOCKER exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
    -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
    cli peer lifecycle chaincode approveformyorg \
    --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
    --package-id ${PKG_ID} --sequence ${SEQUENCE} \
    --signature-policy "${POLICY_EXPR}" --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem

echo "Step 4: Checking commit readiness..."
$DOCKER exec cli peer lifecycle chaincode checkcommitreadiness \
    --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
    --sequence ${SEQUENCE} --signature-policy "${POLICY_EXPR}" --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem

echo "Step 5: Committing to channel..."
$DOCKER exec cli peer lifecycle chaincode commit \
    --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
    --sequence ${SEQUENCE} --signature-policy "${POLICY_EXPR}" --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
    --peerAddresses peer0.insurer1.insurance.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    --peerAddresses peer0.insurer2.insurance.com:8051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
    --peerAddresses peer0.coop.insurance.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
    --peerAddresses peer0.platform.insurance.com:10051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt

echo "✓ premium-pool deployed successfully!"

echo "Verifying deployment..."
$DOCKER exec cli peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME} --name ${CC_NAME}
