#!/bin/bash

# Script to setup and deploy remaining chaincodes
# This script creates go.mod files and deploys each chaincode

set -e

CHANNEL_NAME="insurance-main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORK_DIR="${SCRIPT_DIR}/../network"
CHAINCODE_DIR="${SCRIPT_DIR}/../chaincode"

echo "========================================="
echo "Setup and Deploy Remaining Chaincodes"
echo "========================================="
echo ""

# Function to create go.mod for a chaincode
setup_chaincode() {
    local cc_name=$1
    local cc_dir="${CHAINCODE_DIR}/${cc_name}"
    
    if [ ! -f "${cc_dir}/go.mod" ]; then
        echo "Creating go.mod for ${cc_name}..."
        cd "${cc_dir}"
        
        cat > go.mod << EOF
module ${cc_name}

go 1.20

require github.com/hyperledger/fabric-contract-api-go v1.2.2

require (
	github.com/go-openapi/jsonpointer v0.20.0 // indirect
	github.com/go-openapi/jsonreference v0.20.2 // indirect
	github.com/go-openapi/spec v0.20.9 // indirect
	github.com/go-openapi/swag v0.22.4 // indirect
	github.com/gobuffalo/envy v1.10.2 // indirect
	github.com/gobuffalo/packd v1.0.2 // indirect
	github.com/gobuffalo/packr v1.30.1 // indirect
	github.com/golang/protobuf v1.5.3 // indirect
	github.com/hyperledger/fabric-chaincode-go v0.0.0-20230731094759-d626e9ab09b9 // indirect
	github.com/hyperledger/fabric-protos-go v0.3.0 // indirect
	github.com/joho/godotenv v1.5.1 // indirect
	github.com/josharian/intern v1.0.0 // indirect
	github.com/mailru/easyjson v0.7.7 // indirect
	github.com/rogpeppe/go-internal v1.11.0 // indirect
	github.com/xeipuuv/gojsonpointer v0.0.0-20190905194746-02993c407bfb // indirect
	github.com/xeipuuv/gojsonreference v0.0.0-20180127040603-bd5ef7bd5415 // indirect
	github.com/xeipuuv/gojsonschema v1.2.0 // indirect
	golang.org/x/net v0.17.0 // indirect
	golang.org/x/sys v0.13.0 // indirect
	golang.org/x/text v0.13.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20231002182017-d307bd883b97 // indirect
	google.golang.org/grpc v1.58.3 // indirect
	google.golang.org/protobuf v1.31.0 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
)
EOF
        
        echo "Running go mod tidy for ${cc_name}..."
        go mod tidy
        echo "✓ ${cc_name} setup complete"
        echo ""
    else
        echo "✓ ${cc_name} already has go.mod"
        echo ""
    fi
}

# Function to deploy a chaincode
deploy_chaincode() {
    local cc_name=$1
    
    echo "Deploying ${cc_name}..."
    cd "${NETWORK_DIR}"
    ./network.sh deployCC -ccn ${cc_name} -ccp ../chaincode/${cc_name} -c ${CHANNEL_NAME}
    echo "✓ ${cc_name} deployed successfully"
    echo ""
    sleep 2
}

# List of chaincodes to deploy (excluding access-control which is already deployed)
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

# Phase 1: Setup all chaincodes
echo "========================================="
echo "PHASE 1: Setting up chaincodes"
echo "========================================="
for cc in "${CHAINCODES[@]}"; do
    setup_chaincode "${cc}"
done

# Phase 2: Deploy all chaincodes
echo "========================================="
echo "PHASE 2: Deploying chaincodes"
echo "========================================="
for cc in "${CHAINCODES[@]}"; do
    deploy_chaincode "${cc}"
done

echo ""
echo "========================================="
echo "All chaincodes deployed successfully!"
echo "========================================="
echo ""
echo "Deployed chaincodes:"
peer lifecycle chaincode querycommitted -C ${CHANNEL_NAME}
echo ""
echo "Platform is ready for testing!"
