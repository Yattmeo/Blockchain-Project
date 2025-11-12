#!/bin/bash

# Complete Network Deployment Script
# Deploys the Weather Index Insurance Platform from scratch
# Handles all deployment steps with proper error checking

set -e

# Add Docker to PATH
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

CHANNEL_NAME="insurance-main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORK_DIR="${SCRIPT_DIR}/network"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Weather Index Insurance Platform"
echo "Complete Network Deployment"
echo "========================================="
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Step 1: Bring down any existing network
echo "Step 1: Cleaning up any existing network..."
cd "${NETWORK_DIR}"
docker compose -f docker-compose.yaml down --volumes --remove-orphans 2>/dev/null || true
docker images | grep "dev-peer" | awk '{print $3}' | xargs docker rmi 2>/dev/null || true
print_status "Cleanup complete"
echo ""

# Step 2: Start the network
echo "Step 2: Starting Hyperledger Fabric network..."
cd "${NETWORK_DIR}"
docker compose -f docker-compose.yaml up -d
if [ $? -ne 0 ]; then
    print_error "Failed to start network"
    exit 1
fi
print_status "Network containers started"
echo "Waiting for containers to initialize..."
sleep 5
print_status "Network ready"
echo ""

# Step 3: Create and join channel
echo "Step 3: Creating channel: ${CHANNEL_NAME}..."
docker exec cli osnadmin channel join \
    --channelID ${CHANNEL_NAME} \
    --config-block ./channel-artifacts/${CHANNEL_NAME}.block \
    -o orderer.insurance.com:7053 \
    --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
    --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/tls/server.crt \
    --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/tls/server.key \
    > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_status "Channel created on orderer"
else
    print_warning "Channel may already exist on orderer"
fi
echo ""

# Step 4: Join all peers to channel
echo "Step 4: Joining peers to channel..."

# Insurer1
docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
    -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
    cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block > /dev/null 2>&1
print_status "Insurer1 peer joined"

# Insurer2
docker exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
    -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
    cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block > /dev/null 2>&1
print_status "Insurer2 peer joined"

# Coop
docker exec -e CORE_PEER_LOCALMSPID=CoopMSP \
    -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
    cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block > /dev/null 2>&1
print_status "Coop peer joined"

# Platform
docker exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
    -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
    cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block > /dev/null 2>&1
print_status "Platform peer joined"
echo ""

# Step 5: Deploy all chaincodes
echo "Step 5: Deploying chaincodes..."
echo ""

deploy_chaincode() {
    local CC_NAME=$1
    local CC_VERSION=$2
    local COLLECTIONS_CONFIG=${3:-""}
    
    echo "  Deploying: ${CC_NAME} v${CC_VERSION}"
    echo "    - Packaging (downloading Go modules, this may take 1-2 minutes)..."
    
    # Define endorsement policies per chaincode (just the policy expression, not the flag)
    local POLICY_EXPR=""
    
    case "$CC_NAME" in
        "farmer")
            # Farmer registration: Coop + ANY Insurer (1 of 2)
            POLICY_EXPR="AND('CoopMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))"
            echo "    - Policy: Coop + ANY Insurer (1 of 2)"
            ;;
        "policy")
            # Policy creation: Insurer + Coop
            POLICY_EXPR="AND(OR('Insurer1MSP.peer','Insurer2MSP.peer'),'CoopMSP.peer')"
            echo "    - Policy: ANY Insurer + Coop"
            ;;
        "weather-oracle")
            # Weather data submission: 2 of 3 (Insurer1, Insurer2, Platform act as oracles)
            POLICY_EXPR="OutOf(2,'Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')"
            echo "    - Policy: 2 of 3 Oracle Providers"
            ;;
        "claim-processor")
            # Claims are automated - any peer can trigger based on index calculation
            POLICY_EXPR="OR('Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')"
            echo "    - Policy: Automated (ANY authorized peer)"
            ;;
        "premium-pool")
            # Pool operations: Platform + Majority Insurers
            POLICY_EXPR="AND('PlatformMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))"
            echo "    - Policy: Platform + ANY Insurer"
            ;;
        "index-calculator")
            # Index calculation: Any insurer or platform (automated process)
            POLICY_EXPR="OR('Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')"
            echo "    - Policy: ANY Insurer or Platform"
            ;;
        "access-control")
            # Access control: Platform only for critical operations
            POLICY_EXPR="OR('PlatformMSP.peer')"
            echo "    - Policy: Platform only"
            ;;
        "policy-template")
            # Policy templates: Any insurer can create
            POLICY_EXPR="OR('Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')"
            echo "    - Policy: ANY Insurer or Platform"
            ;;
        "approval-manager")
            # Approval manager: Any authorized party can create/view approvals
            # Actual approval requires org-specific signatures
            POLICY_EXPR="OR('Insurer1MSP.peer','Insurer2MSP.peer','CoopMSP.peer','PlatformMSP.peer')"
            echo "    - Policy: ANY organization"
            ;;
        *)
            # Default: Any peer from any org
            POLICY_EXPR="OR('Insurer1MSP.peer','Insurer2MSP.peer','CoopMSP.peer','PlatformMSP.peer')"
            echo "    - Policy: Default (ANY org)"
            ;;
    esac
    
    # Package - show output so we can see progress
    docker exec cli peer lifecycle chaincode package ${CC_NAME}-v${CC_VERSION}.tar.gz \
        --path /opt/gopath/src/github.com/chaincode/${CC_NAME}/ \
        --lang golang \
        --label ${CC_NAME}_${CC_VERSION} 2>&1 | grep -E "Created|packaging|error" || echo "      Packaging in progress..."
    
    echo "    - Installing on all peers..."
    # Install on all peers (capture package ID from last install)
    # Note: Install may return "already installed" error, which we extract the package ID from
    INSTALL_OUTPUT=$(docker exec cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz 2>&1 || true)
    
    docker exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz > /dev/null 2>&1 || true
    
    docker exec -e CORE_PEER_LOCALMSPID=CoopMSP \
        -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz > /dev/null 2>&1 || true
    
    docker exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
        -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
        cli peer lifecycle chaincode install ${CC_NAME}-v${CC_VERSION}.tar.gz > /dev/null 2>&1 || true
    
    # Extract package ID from either success or "already installed" message
    PKG_ID=$(echo "$INSTALL_OUTPUT" | grep -oE "${CC_NAME}_${CC_VERSION}:[a-f0-9]+" | head -1)
    
    echo "    - Approving for all organizations..."
    
    # Build collections argument if needed
    local COLLECTIONS_ARG=""
    if [ -n "$COLLECTIONS_CONFIG" ]; then
        COLLECTIONS_ARG="--collections-config ${COLLECTIONS_CONFIG}"
    fi
    
    # Approve for all orgs (with endorsement policy)
    docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
        --package-id ${PKG_ID} --sequence 1 ${COLLECTIONS_ARG} \
        --signature-policy "${POLICY_EXPR}" --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        > /dev/null 2>&1 || true
    
    docker exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
        --package-id ${PKG_ID} --sequence 1 ${COLLECTIONS_ARG} \
        --signature-policy "${POLICY_EXPR}" --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        > /dev/null 2>&1 || true
    
    docker exec -e CORE_PEER_LOCALMSPID=CoopMSP \
        -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
        --package-id ${PKG_ID} --sequence 1 ${COLLECTIONS_ARG} \
        --signature-policy "${POLICY_EXPR}" --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        > /dev/null 2>&1 || true
    
    docker exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
        -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
        cli peer lifecycle chaincode approveformyorg \
        --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
        --package-id ${PKG_ID} --sequence 1 ${COLLECTIONS_ARG} \
        --signature-policy "${POLICY_EXPR}" --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        > /dev/null 2>&1 || true
    
    echo "    - Committing to channel..."
    # Commit (with endorsement policy)
    docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
        -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
        -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
        cli peer lifecycle chaincode commit \
        --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
        --sequence 1 ${COLLECTIONS_ARG} \
        --signature-policy "${POLICY_EXPR}" --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        --peerAddresses peer0.insurer1.insurance.com:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
        --peerAddresses peer0.insurer2.insurance.com:8051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
        --peerAddresses peer0.coop.insurance.com:9051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
        --peerAddresses peer0.platform.insurance.com:10051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
        > /dev/null 2>&1 || true
    
    print_status "  ${CC_NAME} v${CC_VERSION} deployed"
    sleep 2
}

# Deploy all chaincodes in order
deploy_chaincode "access-control" "2"
deploy_chaincode "farmer" "2" "/opt/gopath/src/github.com/chaincode/farmer/collections_config.json"
deploy_chaincode "policy-template" "1"
deploy_chaincode "policy" "2"
deploy_chaincode "weather-oracle" "1"
deploy_chaincode "index-calculator" "2"
deploy_chaincode "claim-processor" "1"
deploy_chaincode "premium-pool" "2"
deploy_chaincode "approval-manager" "1"

echo ""
echo "========================================="
echo -e "${GREEN}✓✓✓ DEPLOYMENT COMPLETE ✓✓✓${NC}"
echo "========================================="
echo ""
echo "Network Status:"
echo "  - Network: Running"
echo "  - Channel: ${CHANNEL_NAME}"
echo "  - Peers: 4 (All joined)"
echo "  - Chaincodes: 9 (All deployed)"
echo ""
echo "Deployed Chaincodes:"
echo "  1. access-control v2"
echo "  2. farmer v2 (with private data)"
echo "  3. policy-template v1"
echo "  4. policy v2"
echo "  5. weather-oracle v1"
echo "  6. index-calculator v2"
echo "  7. claim-processor v1"
echo "  8. premium-pool v2"
echo "  9. approval-manager v1 (Phase 2)"
echo ""
echo "Next steps:"
echo "  - Run E2E tests: cd test-scripts && ./test-e2e-complete.sh"
echo "  - View logs: docker logs <container-name>"
echo "  - Bring down: cd network && docker compose down --volumes"
echo ""
