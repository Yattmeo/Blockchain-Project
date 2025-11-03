#!/bin/bash

# Deployment script for all chaincodes
# This script deploys all chaincodes in the correct order

set -e

CHANNEL_NAME="insurance-main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORK_DIR="${SCRIPT_DIR}/../network"

echo "========================================="
echo "Weather Index Insurance Platform"
echo "Chaincode Deployment Script"
echo "========================================="
echo ""

# Function to deploy a chaincode
deploy_chaincode() {
    local cc_name=$1
    local cc_path=$2
    
    echo "Deploying ${cc_name}..."
    cd ${NETWORK_DIR}
    ./network.sh deployCC -ccn ${cc_name} -ccp ../chaincode/${cc_path} -c ${CHANNEL_NAME}
    echo ""
    sleep 2
}

# Phase 1: Identity Foundation
echo "========================================="
echo "PHASE 1: Identity Foundation"
echo "========================================="
deploy_chaincode "access-control" "access-control"
deploy_chaincode "farmer" "farmer"

# Phase 2: Insurance Core
echo "========================================="
echo "PHASE 2: Insurance Core"
echo "========================================="
deploy_chaincode "policy-template" "policy-template"
deploy_chaincode "policy" "policy"

# Phase 3: Data Layer
echo "========================================="
echo "PHASE 3: Data Layer"
echo "========================================="
deploy_chaincode "weather-oracle" "weather-oracle"
deploy_chaincode "index-calculator" "index-calculator"

# Phase 4: Automation
echo "========================================="
echo "PHASE 4: Automation"
echo "========================================="
deploy_chaincode "claim-processor" "claim-processor"
deploy_chaincode "premium-pool" "premium-pool"

# Phase 5: Utilities
echo "========================================="
echo "PHASE 5: Utilities"
echo "========================================="
deploy_chaincode "audit-log" "audit-log"
deploy_chaincode "notification" "notification"
deploy_chaincode "emergency-management" "emergency-management"

echo ""
echo "========================================="
echo "All chaincodes deployed successfully!"
echo "========================================="
echo ""
echo "Deployed chaincodes:"
echo "  1. access-control"
echo "  2. farmer"
echo "  3. policy-template"
echo "  4. policy"
echo "  5. weather-oracle"
echo "  6. index-calculator"
echo "  7. claim-processor"
echo "  8. premium-pool"
echo "  9. audit-log"
echo "  10. notification"
echo "  11. emergency-management"
echo ""
echo "Network is ready for use!"
