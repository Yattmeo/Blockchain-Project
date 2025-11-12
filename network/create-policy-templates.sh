#!/bin/bash

echo "Creating policy templates with weather thresholds..."

# Template 1: Rice Drought Protection
echo "Creating Rice Drought Protection template..."
/usr/local/bin/docker exec cli peer chaincode invoke \
  -o orderer.insurance.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
  -C insurance-main \
  -n policy-template \
  --peerAddresses peer0.insurer1.insurance.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
  -c '{"Args":["CreateTemplate","TMPL_RICE_DROUGHT","Rice Drought Protection","Rice","Central","Medium","180","100000","500"]}' 2>&1 | grep -q "status:200" && echo "✓ Rice Drought template created"

# Template 2: Wheat Excess Rain
echo "Creating Wheat Excess Rain template..."
/usr/local/bin/docker exec cli peer chaincode invoke \
  -o orderer.insurance.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
  -C insurance-main \
  -n policy-template \
  --peerAddresses peer0.insurer1.insurance.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
  -c '{"Args":["CreateTemplate","TMPL_WHEAT_RAIN","Wheat Excess Rain Protection","Wheat","North","High","120","80000","600"]}' 2>&1 | grep -q "status:200" && echo "✓ Wheat Rain template created"

# Template 3: Corn Multi-Peril
echo "Creating Corn Multi-Peril template..."
/usr/local/bin/docker exec cli peer chaincode invoke \
  -o orderer.insurance.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
  -C insurance-main \
  -n policy-template \
  --peerAddresses peer0.insurer1.insurance.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
  -c '{"Args":["CreateTemplate","TMPL_CORN_MULTI","Corn Multi-Peril Insurance","Corn","South","Medium","150","120000","700"]}' 2>&1 | grep -q "status:200" && echo "✓ Corn Multi-Peril template created"

echo ""
echo "Policy templates created successfully!"
echo "Querying templates..."
/usr/local/bin/docker exec cli peer chaincode query -C insurance-main -n policy-template -c '{"Args":["GetAllTemplates"]}'
