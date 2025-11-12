#!/bin/bash

echo "Adding weather thresholds to policy templates..."

# Rice Drought - Threshold 1: Low rainfall
echo "Rice: Adding low rainfall threshold..."
/usr/local/bin/docker exec cli peer chaincode invoke \
  -o orderer.insurance.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
  -C insurance-main \
  -n policy-template \
  --peerAddresses peer0.insurer1.insurance.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
  -c '{"Args":["SetIndexThreshold","TMPL_RICE_DROUGHT","Rainfall","mm","50","<","30","50","Moderate"]}' > /dev/null 2>&1 && echo "  ✓ Rainfall < 50mm in 30 days → 50% payout"

# Wheat Excess Rain - Threshold 1: High rainfall
echo "Wheat: Adding excess rainfall threshold..."
/usr/local/bin/docker exec cli peer chaincode invoke \
  -o orderer.insurance.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
  -C insurance-main \
  -n policy-template \
  --peerAddresses peer0.insurer1.insurance.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
  -c '{"Args":["SetIndexThreshold","TMPL_WHEAT_RAIN","Rainfall","mm","200",">","7","60","Severe"]}' > /dev/null 2>&1 && echo "  ✓ Rainfall > 200mm in 7 days → 60% payout"

# Corn Multi-Peril - Threshold 1: Temperature
echo "Corn: Adding temperature threshold..."
/usr/local/bin/docker exec cli peer chaincode invoke \
  -o orderer.insurance.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
  -C insurance-main \
  -n policy-template \
  --peerAddresses peer0.insurer1.insurance.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
  -c '{"Args":["SetIndexThreshold","TMPL_CORN_MULTI","Temperature","celsius","35",">","14","40","Moderate"]}' > /dev/null 2>&1 && echo "  ✓ Temperature > 35°C for 14 days → 40% payout"

# Corn Multi-Peril - Threshold 2: Rainfall
echo "Corn: Adding rainfall threshold..."
/usr/local/bin/docker exec cli peer chaincode invoke \
  -o orderer.insurance.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
  -C insurance-main \
  -n policy-template \
  --peerAddresses peer0.insurer1.insurance.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
  -c '{"Args":["SetIndexThreshold","TMPL_CORN_MULTI","Rainfall","mm","30","<","21","35","Mild"]}' > /dev/null 2>&1 && echo "  ✓ Rainfall < 30mm in 21 days → 35% payout"

echo ""
echo "✓ Weather thresholds added successfully!"
echo ""
echo "Verifying Rice template with thresholds..."
/usr/local/bin/docker exec cli peer chaincode query -C insurance-main -n policy-template -c '{"Args":["GetTemplate","TMPL_RICE_DROUGHT"]}'
