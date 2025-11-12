#!/bin/bash

# Full System Startup Script
# Starts Fabric network, API Gateway, and UI with real blockchain integration

set -e

# Add common binary paths to PATH
export PATH="/usr/local/bin:$PATH"

echo "=================================================="
echo "Starting Full Insurance System with Fabric Chain"
echo "=================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Detect docker command (handle macOS Docker Desktop)
if command -v docker &> /dev/null; then
    DOCKER_CMD="docker"
elif [ -f "/usr/local/bin/docker" ]; then
    DOCKER_CMD="/usr/local/bin/docker"
    # Add docker to PATH if needed
    export PATH="/usr/local/bin:$PATH"
elif [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
    DOCKER_CMD="/Applications/Docker.app/Contents/Resources/bin/docker"
    export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
else
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# ========================================
# 1. Check Prerequisites
# ========================================

echo -e "${BLUE}[1/6] Checking Prerequisites...${NC}"

# Check Docker daemon
if ! $DOCKER_CMD info &> /dev/null; then
    echo -e "${RED}Error: Docker daemon is not running${NC}"
    echo "Please start Docker Desktop"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running (${DOCKER_CMD})${NC}"

# Check Node.js and npm
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    echo "Please install Node.js from: https://nodejs.org/"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Node.js $(node --version) installed${NC}"
echo -e "${GREEN}✓ npm $(npm --version) installed${NC}"

# ========================================
# 2. Start Fabric Network
# ========================================

echo ""
echo -e "${BLUE}[2/6] Starting Hyperledger Fabric Network...${NC}"

cd network

# Check if network is already running
if docker ps | grep -q "peer0.insurer1"; then
    echo -e "${YELLOW}Network appears to be running.${NC}"
    echo -e "${YELLOW}Do you want to restart it? This will clear all data. (y/n)${NC}"
    read -r restart_response
    
    if [[ "$restart_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Stopping existing network..."
        ./network.sh down
        sleep 2
    else
        echo "Using existing network..."
        # Skip to approval manager deployment
        echo -e "${GREEN}✓ Using existing Fabric network${NC}"
        
        # Check if channel exists
        if docker exec cli peer channel list 2>/dev/null | grep -q "insurance-main"; then
            echo -e "${GREEN}✓ Channel 'insurance-main' already exists${NC}"
        else
            echo "Channel not found, creating..."
            ./network.sh createChannel
            if [ $? -ne 0 ]; then
                echo -e "${RED}Failed to create channel${NC}"
                exit 1
            fi
            echo -e "${GREEN}✓ Channel created${NC}"
        fi
        
        # Go back to project root
        cd ..
        SKIP_NETWORK_START=true
    fi
fi

if [ "$SKIP_NETWORK_START" != "true" ]; then
    # Start network
    echo "Starting network..."
    ./network.sh up

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to start Fabric network${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Fabric network started${NC}"

# Create channel
echo "Creating channel 'insurance-main'..."
./network.sh createChannel

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create channel${NC}"
    exit 1
fi

    echo -e "${GREEN}✓ Channel created and peers joined${NC}"
fi

cd ..

# ========================================
# 3. Deploy All Chaincodes
# ========================================

echo ""
echo -e "${BLUE}[3/6] Deploying All Chaincodes...${NC}"

# Check if chaincodes are already deployed
DEPLOYED_COUNT=$(docker exec cli peer lifecycle chaincode queryinstalled 2>/dev/null | grep -c "Package ID:")
if [ -z "$DEPLOYED_COUNT" ]; then
    DEPLOYED_COUNT=0
fi

if [ "$DEPLOYED_COUNT" -ge 8 ]; then
    echo -e "${GREEN}✓ Chaincodes already deployed (found $DEPLOYED_COUNT)${NC}"
    echo "  Installed chaincodes:"
    docker exec cli peer lifecycle chaincode queryinstalled 2>/dev/null | grep "Label:" | sed 's/Label: /    - /'
else
    echo "Deploying all 9 chaincodes using deploy-network.sh..."
    echo "This will take approximately 10-15 minutes."
    echo ""
    
    # Call the existing deployment script
    if [ -f "./deploy-network.sh" ]; then
        ./deploy-network.sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}✗ Chaincode deployment failed${NC}"
            echo "Check the output above for errors"
            exit 1
        fi
    else
        echo -e "${RED}✗ deploy-network.sh not found${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Chaincodes ready${NC}"

# ========================================
# 4. Setup API Gateway
# ========================================
else
    echo "Deploying all 9 chaincodes..."
    echo "This will take approximately 10-15 minutes."
    echo ""
    echo "Chaincodes to deploy:"
    echo "  1. access-control (v2)"
    echo "  2. farmer (v2 with private data)"
    echo "  3. policy-template (v1)"
    echo "  4. policy (v2)"
    echo "  5. weather-oracle (v1)"
    echo "  6. index-calculator (v2)"
    echo "  7. claim-processor (v1)"
    echo "  8. premium-pool (v2)"
    echo "  9. approval-manager (v1)"
    echo ""
    echo -e "${YELLOW}Note: Go module downloads may take 1-2 minutes per chaincode${NC}"
    echo ""
    
    # Function to deploy a chaincode
    deploy_chaincode() {
        local CC_NAME=$1
        local CC_VERSION=$2
        local CC_SEQUENCE=${3:-1}
        local COLLECTIONS_CONFIG=${4:-""}
        local POLICY=$5
        
        echo "  Deploying: ${CC_NAME} v${CC_VERSION}..."
        
        # Package
        echo "    - Packaging..."
        if ! docker exec cli peer lifecycle chaincode package ${CC_NAME}.tar.gz \
            --path /opt/gopath/src/github.com/chaincode/${CC_NAME}/ \
            --lang golang \
            --label ${CC_NAME}_${CC_VERSION} 2>&1 | tee /tmp/chaincode-package.log | grep -v "^$"; then
            echo -e "    ${RED}✗ Failed to package ${CC_NAME}${NC}"
            cat /tmp/chaincode-package.log
            return 1
        fi
        
        # Install on all peers
        echo "    - Installing on all peers..."
        INSTALL_OUTPUT=$(docker exec cli peer lifecycle chaincode install ${CC_NAME}.tar.gz 2>&1)
        INSTALL_EXIT=$?
        
        if [ $INSTALL_EXIT -ne 0 ] && ! echo "$INSTALL_OUTPUT" | grep -q "already installed"; then
            echo -e "    ${RED}✗ Failed to install on Insurer1${NC}"
            echo "$INSTALL_OUTPUT"
            return 1
        fi
        
        docker exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
            -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
            cli peer lifecycle chaincode install ${CC_NAME}.tar.gz 2>&1 | grep -v "already installed" || true
        
        docker exec -e CORE_PEER_LOCALMSPID=CoopMSP \
            -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
            cli peer lifecycle chaincode install ${CC_NAME}.tar.gz 2>&1 | grep -v "already installed" || true
        
        docker exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
            -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
            cli peer lifecycle chaincode install ${CC_NAME}.tar.gz 2>&1 | grep -v "already installed" || true
        
        # Extract package ID - query from peer
        PKG_ID=$(docker exec cli peer lifecycle chaincode queryinstalled 2>/dev/null | grep "${CC_NAME}_${CC_VERSION}" | sed 's/.*Package ID: //' | sed 's/, Label.*//')
        
        if [ -z "$PKG_ID" ]; then
            echo -e "    ${RED}✗ Failed to get package ID for ${CC_NAME}${NC}"
            return 1
        fi
        
        echo "    - Package ID: ${PKG_ID}"
        
        echo "    - Approving for all organizations..."
        
        # Build collections argument if needed
        local COLLECTIONS_ARG=""
        if [ -n "$COLLECTIONS_CONFIG" ]; then
            COLLECTIONS_ARG="--collections-config ${COLLECTIONS_CONFIG}"
        fi
        
        # Approve for all orgs (suppress errors for already approved)
        docker exec -e CORE_PEER_LOCALMSPID=Insurer1MSP \
            -e CORE_PEER_ADDRESS=peer0.insurer1.insurance.com:7051 \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/users/Admin@insurer1.insurance.com/msp \
            cli peer lifecycle chaincode approveformyorg \
            --channelID insurance-main --name ${CC_NAME} --version ${CC_VERSION} \
            --package-id ${PKG_ID} --sequence ${CC_SEQUENCE} ${COLLECTIONS_ARG} \
            --signature-policy "${POLICY}" --tls \
            --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
            2>&1 | grep -v "already" || true
        
        docker exec -e CORE_PEER_LOCALMSPID=Insurer2MSP \
            -e CORE_PEER_ADDRESS=peer0.insurer2.insurance.com:8051 \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer2.insurance.com/users/Admin@insurer2.insurance.com/msp \
            cli peer lifecycle chaincode approveformyorg \
            --channelID insurance-main --name ${CC_NAME} --version ${CC_VERSION} \
            --package-id ${PKG_ID} --sequence ${CC_SEQUENCE} ${COLLECTIONS_ARG} \
            --signature-policy "${POLICY}" --tls \
            --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
            2>&1 | grep -v "already" || true
        
        docker exec -e CORE_PEER_LOCALMSPID=CoopMSP \
            -e CORE_PEER_ADDRESS=peer0.coop.insurance.com:9051 \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/users/Admin@coop.insurance.com/msp \
            cli peer lifecycle chaincode approveformyorg \
            --channelID insurance-main --name ${CC_NAME} --version ${CC_VERSION} \
            --package-id ${PKG_ID} --sequence ${CC_SEQUENCE} ${COLLECTIONS_ARG} \
            --signature-policy "${POLICY}" --tls \
            --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
            2>&1 | grep -v "already" || true
        
        docker exec -e CORE_PEER_LOCALMSPID=PlatformMSP \
            -e CORE_PEER_ADDRESS=peer0.platform.insurance.com:10051 \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/platform.insurance.com/users/Admin@platform.insurance.com/msp \
            cli peer lifecycle chaincode approveformyorg \
            --channelID insurance-main --name ${CC_NAME} --version ${CC_VERSION} \
            --package-id ${PKG_ID} --sequence ${CC_SEQUENCE} ${COLLECTIONS_ARG} \
            --signature-policy "${POLICY}" --tls \
            --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
            2>&1 | grep -v "already" || true
        
        # Commit
        echo "    - Committing to channel..."
        COMMIT_OUTPUT=$(docker exec cli peer lifecycle chaincode commit \
            --channelID insurance-main --name ${CC_NAME} --version ${CC_VERSION} \
            --sequence ${CC_SEQUENCE} ${COLLECTIONS_ARG} \
            --signature-policy "${POLICY}" --tls \
            --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
            --peerAddresses peer0.insurer1.insurance.com:7051 \
            --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
            --peerAddresses peer0.coop.insurance.com:9051 \
            --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt \
            2>&1)
        
        COMMIT_EXIT=$?
        if [ $COMMIT_EXIT -ne 0 ] && ! echo "$COMMIT_OUTPUT" | grep -q "already committed"; then
            echo -e "    ${RED}✗ Failed to commit ${CC_NAME}${NC}"
            echo "$COMMIT_OUTPUT"
            return 1
        fi
        
        echo -e "    ${GREEN}✓ ${CC_NAME} deployed${NC}"
        sleep 2
    }
    
    # Deploy all chaincodes
    deploy_chaincode "access-control" "2" "2" "" "OR('PlatformMSP.peer')"
    deploy_chaincode "farmer" "2" "2" "/opt/gopath/src/github.com/chaincode/farmer/collections_config.json" "AND('CoopMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))"
    deploy_chaincode "policy-template" "1" "1" "" "OR('Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')"
    deploy_chaincode "policy" "2" "2" "" "AND(OR('Insurer1MSP.peer','Insurer2MSP.peer'),'CoopMSP.peer')"
    deploy_chaincode "weather-oracle" "1" "1" "" "OutOf(2,'Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')"
    deploy_chaincode "index-calculator" "2" "2" "" "OR('Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')"
    deploy_chaincode "claim-processor" "1" "1" "" "OR('Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')"
    deploy_chaincode "premium-pool" "2" "2" "" "AND('PlatformMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))"
    deploy_chaincode "approval-manager" "1" "1" "" "OR('Insurer1MSP.peer','Insurer2MSP.peer','CoopMSP.peer','PlatformMSP.peer')"
    
    echo ""
    echo -e "${GREEN}✓ All 9 chaincodes deployed successfully!${NC}"
fi

echo -e "${GREEN}✓ Chaincodes ready${NC}"

# ========================================
# 4. Install API Gateway Dependencies
# ========================================

echo ""
echo -e "${BLUE}[4/6] Setting up API Gateway...${NC}"

cd api-gateway

if [ ! -d "node_modules" ]; then
    echo "Installing API Gateway dependencies..."
    npm install
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install API Gateway dependencies${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ API Gateway dependencies already installed${NC}"
fi

# Build TypeScript
echo "Building API Gateway..."
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build API Gateway${NC}"
    exit 1
fi

echo -e "${GREEN}✓ API Gateway built successfully${NC}"

# ========================================
# 5. Start API Gateway
# ========================================

echo ""
echo -e "${BLUE}[5/6] Starting API Gateway...${NC}"

# Kill existing API Gateway process if running
if lsof -ti:3001 &> /dev/null; then
    echo "Stopping existing API Gateway on port 3001..."
    kill -9 $(lsof -ti:3001) 2>/dev/null || true
    sleep 2
fi

# Start API Gateway in background
echo "Starting API Gateway on port 3001..."
npm start > ../logs/api-gateway.log 2>&1 &
API_GATEWAY_PID=$!

# Wait for API Gateway to start
echo "Waiting for API Gateway to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:3001/health > /dev/null; then
        echo -e "${GREEN}✓ API Gateway is running (PID: $API_GATEWAY_PID)${NC}"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo -e "${RED}API Gateway failed to start${NC}"
        echo "Check logs at: logs/api-gateway.log"
        exit 1
    fi
    
    sleep 1
done

# ========================================
# 6. Start UI Development Server
# ========================================

cd ../insurance-ui

echo ""
echo -e "${BLUE}[6/6] Starting UI Development Server...${NC}"

if [ ! -d "node_modules" ]; then
    echo "Installing UI dependencies..."
    npm install
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install UI dependencies${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ UI dependencies already installed${NC}"
fi

# Kill existing UI server if running
if lsof -ti:5173 &> /dev/null; then
    echo "Stopping existing UI server on port 5173..."
    kill -9 $(lsof -ti:5173) 2>/dev/null || true
    sleep 2
fi

echo "Starting UI Development Server on port 5173..."
echo -e "${YELLOW}Note: UI is now in PRODUCTION mode - using real Fabric blockchain!${NC}"

npm run dev > ../logs/ui-dev.log 2>&1 &
UI_PID=$!

# Wait for UI to start
echo "Waiting for UI server to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:5173 > /dev/null; then
        echo -e "${GREEN}✓ UI Development Server is running (PID: $UI_PID)${NC}"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo -e "${RED}UI server failed to start${NC}"
        echo "Check logs at: logs/ui-dev.log"
        exit 1
    fi
    
    sleep 1
done

# ========================================
# SUCCESS
# ========================================

cd ..

echo ""
echo -e "${GREEN}=================================================="
echo "✅ Full System Started Successfully!"
echo "==================================================${NC}"
echo ""
echo -e "${BLUE}Services Running:${NC}"
echo -e "  • Fabric Network:    ${GREEN}Running${NC} (4 orgs: Insurer1, Insurer2, Coop, Oracle)"
echo -e "  • API Gateway:       ${GREEN}http://localhost:3001${NC} (PID: $API_GATEWAY_PID)"
echo -e "  • UI Dev Server:     ${GREEN}http://localhost:5173${NC} (PID: $UI_PID)"
echo ""
echo -e "${BLUE}Chaincode Deployed:${NC}"
echo "  • approval-manager"
echo "  • farmer, policy, claim-processor, etc."
echo ""
echo -e "${BLUE}Access Points:${NC}"
echo "  • UI:         http://localhost:5173"
echo "  • API:        http://localhost:3001/api"
echo "  • Health:     http://localhost:3001/health"
echo ""
echo -e "${YELLOW}Mode: PRODUCTION (Real Blockchain)${NC}"
echo "  • VITE_DEV_MODE=false"
echo "  • All operations write to Fabric ledger"
echo "  • Multi-party approvals required"
echo ""
echo -e "${BLUE}Logs:${NC}"
echo "  • API Gateway:    logs/api-gateway.log"
echo "  • UI Dev Server:  logs/ui-dev.log"
echo "  • Network logs:   network/logs/"
echo ""
echo -e "${BLUE}Test Accounts:${NC}"
echo "  • Coop:      coop@example.com / password"
echo "  • Insurer1:  insurer1@example.com / password"
echo "  • Insurer2:  insurer2@example.com / password"
echo "  • Oracle:    oracle@example.com / password"
echo ""
echo -e "${YELLOW}To Stop All Services:${NC}"
echo "  ./stop-full-system.sh"
echo ""
echo -e "${GREEN}Ready to test multi-party approvals! 🚀${NC}"
echo ""

# Save PIDs for stop script
echo "$API_GATEWAY_PID" > .api-gateway.pid
echo "$UI_PID" > .ui-dev.pid

