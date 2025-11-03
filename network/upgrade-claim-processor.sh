#!/bin/bash

# Upgrade claim-processor chaincode to v2 with deterministic timestamps

CC_NAME="claim-processor"
CC_VERSION="2"
CC_PATH="../chaincode/claim-processor"

echo "Packaging ${CC_NAME} v${CC_VERSION}..."
docker exec cli peer lifecycle chaincode package ${CC_NAME}-v${CC_VERSION}.tar.gz \
  --path ${CC_PATH} \
  --lang golang \
  --label ${CC_NAME}_${CC_VERSION} > /dev/null 2>&1

echo "Installing on all peers..."
# Install on all 4 peers with proper MSP credentials
for peer in "peer0.insurer1.insurance.com:7051:Insurer1MSP" "peer0.insurer2.insurance.com:8051:Insurer2MSP" "peer0.coop.insurance.com:9051:CoopMSP" "peer0.platform.insurance.com:10051:PlatformMSP"; do
  IFS=':' read -r address port msp <<< "$peer"
  orgname=$(echo $address | cut -d'.' -f2)
  docker exec -e CORE_PEER_LOCALMSPID=${msp} \
    -e CORE_PEER_ADDRESS=${address}:${port} \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${orgname}.insurance.com/peers/${address}/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${orgname}.insurance.com/users/Admin@${orgname}.insurance.com/msp \
    cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz > /dev/null 2>&1
  echo "  ✓ Installed on ${address}"
done

# Get package ID
PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled 2>&1 | grep -oE "${CC_NAME}_${CC_VERSION}:[a-f0-9]+" | head -1)
echo "Package ID: $PACKAGE_ID"

echo "Approving for all organizations..."
# Approve for all orgs
for org in "insurer1:7051:Insurer1MSP" "insurer2:8051:Insurer2MSP" "coop:9051:CoopMSP" "platform:10051:PlatformMSP"; do
  IFS=':' read -r name port msp <<< "$org"
  docker exec -e CORE_PEER_LOCALMSPID=${msp} \
    -e CORE_PEER_ADDRESS=peer0.${name}.insurance.com:${port} \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${name}.insurance.com/peers/peer0.${name}.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${name}.insurance.com/users/Admin@${name}.insurance.com/msp \
    cli peer lifecycle chaincode approveformyorg \
    -o orderer.insurance.com:7050 \
    --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
    --channelID insurance-main \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence 2 > /dev/null 2>&1
  echo "  ✓ Approved by ${msp}"
done

echo "Committing chaincode..."
docker exec cli peer lifecycle chaincode commit \
  -o orderer.insurance.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
  --channelID insurance-main \
  --name ${CC_NAME} \
  --version ${CC_VERSION} \
  --sequence 2 \
  --peerAddresses peer0.insurer1.insurance.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
  --peerAddresses peer0.insurer2.insurance.com:8051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
  --peerAddresses peer0.coop.insurance.com:9051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
  --peerAddresses peer0.platform.insurance.com:10051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt > /dev/null 2>&1

echo "✓✓✓ claim-processor v2 deployed successfully! ✓✓✓"
