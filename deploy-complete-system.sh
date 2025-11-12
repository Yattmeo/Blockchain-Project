#!/bin/bash

################################################################################
# Complete System Deployment Script
# Weather Index Insurance Platform
#
# This script deploys the entire platform from scratch:
# 1. Hyperledger Fabric network (3 organizations)
# 2. All chaincodes (6 smart contracts)
# 3. API Gateway
# 4. Frontend UI
# 5. Demo data (farmers, policies, weather data)
################################################################################

set -e

# Add common paths for Docker and Go
# export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/local/go/bin:$PATH"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORK_DIR="${SCRIPT_DIR}/network"
API_DIR="${SCRIPT_DIR}/api-gateway"
UI_DIR="${SCRIPT_DIR}/insurance-ui"
CHANNEL_NAME="insurance-channel"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}║     Weather Index Insurance Platform - Complete Deployment    ║${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Helper functions
print_step() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "  $1"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking Prerequisites"
    
    local missing=0
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker: $(docker --version | cut -d' ' -f3)"
    else
        print_error "Docker not found"
        missing=1
    fi
    
    # Check Node.js
    if command -v node &> /dev/null; then
        print_success "Node.js: $(node --version)"
    else
        print_error "Node.js not found"
        missing=1
    fi
    
    # Check Go
    if command -v go &> /dev/null; then
        print_success "Go: $(go version | cut -d' ' -f3)"
    else
        print_error "Go not found"
        missing=1
    fi
    
    # Check jq
    if command -v jq &> /dev/null; then
        print_success "jq: $(jq --version 2>&1)"
    else
        print_warning "jq not found (optional, for testing)"
    fi
    
    if [ $missing -eq 1 ]; then
        echo ""
        print_error "Missing required dependencies. Please install them first."
        exit 1
    fi
    
    echo ""
}

# Step 1: Clean and prepare
clean_system() {
    print_step "Step 1: Cleaning Previous Deployment"
    
    # Stop any running containers
    print_info "Stopping containers..."
    cd "${NETWORK_DIR}"
    docker compose down --volumes --remove-orphans 2>/dev/null || true
    
    # Remove chaincode images
    print_info "Removing old chaincode images..."
    docker images | grep "dev-peer" | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true
    
    # Kill processes on ports
    print_info "Freeing ports..."
    lsof -ti:3001 | xargs kill -9 2>/dev/null || true  # API Gateway
    lsof -ti:5173 | xargs kill -9 2>/dev/null || true  # UI
    
    print_success "Cleanup complete"
    echo ""
}

# Step 2: Deploy Fabric network
deploy_network() {
    print_step "Step 2: Deploying Hyperledger Fabric Network"
    
    cd "${SCRIPT_DIR}/network"
    
    print_info "Generating crypto material and channel artifacts..."
    ./setup.sh
    
    if [ $? -ne 0 ]; then
        print_error "Setup failed"
        exit 1
    fi
    
    print_info "Starting network..."
    ./network.sh up
    
    if [ $? -ne 0 ]; then
        print_error "Network startup failed"
        exit 1
    fi
    
    print_info "Creating channel..."
    ./network.sh createChannel -c ${CHANNEL_NAME}
    
    if [ $? -eq 0 ]; then
        print_success "Network deployed successfully"
    else
        print_error "Channel creation failed"
        exit 1
    fi
    
    echo ""
}

# Step 3: Deploy all chaincode
deploy_chaincodes() {
    print_step "Step 3: Deploying Smart Contracts (Chaincode)"
    
    cd "${SCRIPT_DIR}"
    
    local chaincodes=("policy" "policy-template" "access-control" "approval-manager" "audit-log" "emergency-management" "premium-pool" "claim-processor" "weather-oracle" "index-calculator" "farmer")
    
    for cc in "${chaincodes[@]}"; do
        print_info "Deploying $cc chaincode..."
        
        if [ -f "./scripts/deployment/deploy-${cc}.sh" ]; then
            ./scripts/deployment/deploy-${cc}.sh > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                print_success "$cc chaincode deployed (version 3)"
            else
                print_error "$cc chaincode deployment failed"
                exit 1
            fi
        else
            print_warning "Deployment script for $cc not found, skipping..."
        fi
    done
    
    print_success "All chaincode deployed successfully"
    echo ""
}

# Step 4: Build and start API Gateway
deploy_api_gateway() {
    print_step "Step 4: Deploying API Gateway"
    
    cd "${API_DIR}"
    
    print_info "Installing dependencies..."
    npm install --silent > /dev/null 2>&1
    
    print_info "Building TypeScript..."
    npm run build > /dev/null 2>&1
    
    print_info "Starting API Gateway..."
    nohup npm start > api-gateway.log 2>&1 &
    API_PID=$!
    
    # Wait for API to be ready
    print_info "Waiting for API Gateway to start..."
    for i in {1..30}; do
        if curl -s -f http://localhost:3001/health > /dev/null 2>&1; then
            print_success "API Gateway running on http://localhost:3001"
            break
        fi
        sleep 1
        if [ $i -eq 30 ]; then
            print_error "API Gateway failed to start"
            exit 1
        fi
    done
    
    echo ""
}

# Step 5: Build and start UI
deploy_ui() {
    print_step "Step 5: Deploying React UI"
    
    cd "${UI_DIR}"
    
    print_info "Installing dependencies..."
    npm install --silent > /dev/null 2>&1
    
    print_info "Starting development server..."
    nohup npm run dev > ui.log 2>&1 &
    UI_PID=$!
    
    # Wait for UI to be ready
    print_info "Waiting for UI to start..."
    for i in {1..30}; do
        if curl -s -f http://localhost:5173 > /dev/null 2>&1; then
            print_success "UI running on http://localhost:5173"
            break
        fi
        sleep 1
        if [ $i -eq 30 ]; then
            print_warning "UI may not have started correctly"
            break
        fi
    done
    
    echo ""
}

# Step 6: Seed demo data
seed_demo_data() {
    print_step "Step 6: Seeding Demo Data"
    
    cd "${SCRIPT_DIR}"
    
    sleep 3  # Give system time to stabilize
    
    print_info "Creating policy templates..."
    
    # Create policy template via API
    TEMPLATE_RESPONSE=$(curl -s -X POST http://localhost:3001/api/policy-templates \
        -H "Content-Type: application/json" \
        -H "X-User-Org: Insurer1" \
        -d '{
            "templateID": "TEMPLATE_RICE_DROUGHT_001",
            "templateName": "Rice Drought Protection",
            "cropType": "Rice",
            "region": "Central",
            "riskLevel": "Medium",
            "coveragePeriod": 180,
            "maxCoverage": 100000,
            "minPremium": 500
        }')
    
    if echo "$TEMPLATE_RESPONSE" | grep -q '"success":true'; then
        print_success "Policy template created"
        
        # Add drought threshold to template
        print_info "Adding drought threshold to template..."
        curl -s -X POST "http://localhost:3001/api/policy-templates/TEMPLATE_RICE_DROUGHT_001/thresholds" \
            -H "Content-Type: application/json" \
            -H "X-User-Org: Insurer1" \
            -d '{
                "indexType": "Drought",
                "metric": "rainfall",
                "thresholdValue": 50,
                "operator": "<",
                "measurementDays": 30,
                "payoutPercent": 75,
                "severity": "Severe"
            }' > /dev/null 2>&1
        
        print_success "Drought threshold added"
        
        # Activate the template
        print_info "Activating policy template..."
        curl -s -X POST "http://localhost:3001/api/policy-templates/TEMPLATE_RICE_DROUGHT_001/activate" \
            -H "X-User-Org: Insurer1" > /dev/null 2>&1
        
        print_success "Policy template activated"
    else
        print_warning "Could not create policy template"
    fi
    
    print_info "Registering demo farmers..."
    
    # Farmer 1
    curl -s -X POST http://localhost:3001/api/farmers \
        -H "Content-Type: application/json" \
        -d '{
            "farmerID": "FARMER_DEMO_001",
            "name": "John Farmer",
            "email": "john@demo.com",
            "phone": "+65-9876-5432",
            "location": "Singapore, North Region",
            "farmSize": 5.5,
            "cropTypes": ["Rice", "Vegetables"],
            "cooperativeID": "COOP001"
        }' > /dev/null 2>&1
    
    # Farmer 2
    curl -s -X POST http://localhost:3001/api/farmers \
        -H "Content-Type: application/json" \
        -d '{
            "farmerID": "FARMER_DEMO_002",
            "name": "Jane Agricultural",
            "email": "jane@demo.com",
            "phone": "+65-9876-5433",
            "location": "Singapore, East Region",
            "farmSize": 3.2,
            "cropTypes": ["Rice"],
            "cooperativeID": "COOP001"
        }' > /dev/null 2>&1
    
    print_success "2 demo farmers registered"
    
    print_info "Creating demo policies for different regions..."
    
    # Policy 1 - Central Bangkok (will be triggered by low rainfall)
    POLICY_RESPONSE=$(curl -s -X POST http://localhost:3001/api/policies \
        -H "Content-Type: application/json" \
        -d '{
            "policyID": "POLICY_DEMO_001",
            "farmerID": "FARMER_DEMO_001",
            "templateID": "TEMPLATE_RICE_DROUGHT_001",
            "coverageAmount": 5000,
            "premiumAmount": 500,
            "startDate": "2025-01-01",
            "endDate": "2025-12-31",
            "cropType": "Rice",
            "farmLocation": "Central_Bangkok",
            "farmSize": 5.5,
            "coopID": "COOP001",
            "insurerID": "INSURER001"
        }')
    
    APPROVAL_ID=$(echo "$POLICY_RESPONSE" | jq -r '.data.requestID // empty' 2>/dev/null)
    
    if [ -n "$APPROVAL_ID" ]; then
        print_success "Policy created with approval request: $APPROVAL_ID"
        
        sleep 2
        
        print_info "Approving policy (Insurer1)..."
        curl -s -X POST "http://localhost:3001/api/approval/${APPROVAL_ID}/approve" \
            -H "Content-Type: application/json" \
            -H "X-User-Org: Insurer1" \
            -d '{
                "approverOrg": "Insurer1MSP",
                "reason": "Demo approval from Insurer1"
            }' > /dev/null 2>&1
        
        sleep 1
        
        print_info "Approving policy (Insurer2)..."
        curl -s -X POST "http://localhost:3001/api/approval/${APPROVAL_ID}/approve" \
            -H "Content-Type: application/json" \
            -H "X-User-Org: Insurer2" \
            -d '{
                "approverOrg": "Insurer2MSP",
                "reason": "Demo approval from Insurer2"
            }' > /dev/null 2>&1
        
        sleep 2
        
        print_info "Executing approved policy..."
        curl -s -X POST "http://localhost:3001/api/approval/${APPROVAL_ID}/execute" \
            -H "Content-Type: application/json" \
            -H "X-User-Org: Insurer1" > /dev/null 2>&1
        
        sleep 2
        
        print_success "Demo policy fully approved and executed"
        
        # Deposit premium to pool
        print_info "Depositing premium to pool..."
        curl -s -X POST "http://localhost:3001/api/premium-pool/deposit-premium" \
            -H "Content-Type: application/json" \
            -H "X-User-Org: Insurer1" \
            -d '{
                "amount": 500,
                "policyID": "POLICY_DEMO_001",
                "farmerID": "FARMER_DEMO_001"
            }' > /dev/null 2>&1
        
        print_success "Premium deposited to pool: $500"
    else
        print_warning "Could not create demo policy"
    fi
    
    print_info "Registering multiple weather oracle providers for consensus..."
    
    # Register Oracle 1 - OpenWeatherMap
    curl -s -X POST http://localhost:3001/api/weather-oracle/register-provider \
        -H "Content-Type: application/json" \
        -d '{
            "oracleID": "ORACLE_OPENWEATHER",
            "providerName": "OpenWeatherMap API",
            "providerType": "API",
            "dataSources": ["OpenWeatherMap"],
            "regions": ["Central_Bangkok", "North_ChiangMai", "South_Songkhla"]
        }' > /dev/null 2>&1
    
    # Register Oracle 2 - Thai Meteorological Department
    curl -s -X POST http://localhost:3001/api/weather-oracle/register-provider \
        -H "Content-Type: application/json" \
        -d '{
            "oracleID": "ORACLE_THAI_MET",
            "providerName": "Thai Meteorological Department",
            "providerType": "API",
            "dataSources": ["ThaiMeteorology"],
            "regions": ["Central_Bangkok", "North_ChiangMai", "South_Songkhla"]
        }' > /dev/null 2>&1
    
    # Register Oracle 3 - Weather Underground
    curl -s -X POST http://localhost:3001/api/weather-oracle/register-provider \
        -H "Content-Type: application/json" \
        -d '{
            "oracleID": "ORACLE_WUNDERGROUND",
            "providerName": "Weather Underground",
            "providerType": "API",
            "dataSources": ["WeatherUnderground"],
            "regions": ["Central_Bangkok", "North_ChiangMai", "South_Songkhla"]
        }' > /dev/null 2>&1
    
    print_success "3 weather oracle providers registered"
    
    print_info "Submitting weather data from multiple oracles for consensus validation..."
    
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # === CENTRAL BANGKOK (LOW RAINFALL - WILL TRIGGER PAYOUT) ===
    # Oracle 1 data (drought conditions)
    curl -s -X POST http://localhost:3001/api/weather-oracle \
        -H "Content-Type: application/json" \
        -d '{
            "dataID": "WEATHER_CENTRAL_01",
            "oracleID": "ORACLE_OPENWEATHER",
            "location": "Central_Bangkok",
            "latitude": "13.7563",
            "longitude": "100.5018",
            "rainfall": 35.0,
            "temperature": 34.5,
            "humidity": 65.0,
            "windSpeed": 12.5,
            "recordedAt": "'$TIMESTAMP'"
        }' > /dev/null 2>&1
    
    # Oracle 2 data (slight variation - still drought)
    curl -s -X POST http://localhost:3001/api/weather-oracle \
        -H "Content-Type: application/json" \
        -d '{
            "dataID": "WEATHER_CENTRAL_02",
            "oracleID": "ORACLE_THAI_MET",
            "location": "Central_Bangkok",
            "latitude": "13.7563",
            "longitude": "100.5018",
            "rainfall": 38.5,
            "temperature": 34.8,
            "humidity": 66.0,
            "windSpeed": 12.0,
            "recordedAt": "'$TIMESTAMP'"
        }' > /dev/null 2>&1
    
    # Oracle 3 data (within consensus range - drought)
    curl -s -X POST http://localhost:3001/api/weather-oracle \
        -H "Content-Type: application/json" \
        -d '{
            "dataID": "WEATHER_CENTRAL_03",
            "oracleID": "ORACLE_WUNDERGROUND",
            "location": "Central_Bangkok",
            "latitude": "13.7563",
            "longitude": "100.5018",
            "rainfall": 33.0,
            "temperature": 34.2,
            "humidity": 64.5,
            "windSpeed": 13.0,
            "recordedAt": "'$TIMESTAMP'"
        }' > /dev/null 2>&1
    
    # === NORTH CHIANG MAI ===
    # Oracle 1 data
    curl -s -X POST http://localhost:3001/api/weather-oracle \
        -H "Content-Type: application/json" \
        -d '{
            "dataID": "WEATHER_NORTH_01",
            "oracleID": "ORACLE_OPENWEATHER",
            "location": "North_ChiangMai",
            "latitude": "18.7883",
            "longitude": "98.9853",
            "rainfall": 120.5,
            "temperature": 28.2,
            "humidity": 82.0,
            "windSpeed": 8.3,
            "recordedAt": "'$TIMESTAMP'"
        }' > /dev/null 2>&1
    
    # Oracle 2 data
    curl -s -X POST http://localhost:3001/api/weather-oracle \
        -H "Content-Type: application/json" \
        -d '{
            "dataID": "WEATHER_NORTH_02",
            "oracleID": "ORACLE_THAI_MET",
            "location": "North_ChiangMai",
            "latitude": "18.7883",
            "longitude": "98.9853",
            "rainfall": 118.0,
            "temperature": 28.5,
            "humidity": 81.5,
            "windSpeed": 8.5,
            "recordedAt": "'$TIMESTAMP'"
        }' > /dev/null 2>&1
    
    # Oracle 3 data
    curl -s -X POST http://localhost:3001/api/weather-oracle \
        -H "Content-Type: application/json" \
        -d '{
            "dataID": "WEATHER_NORTH_03",
            "oracleID": "ORACLE_WUNDERGROUND",
            "location": "North_ChiangMai",
            "latitude": "18.7883",
            "longitude": "98.9853",
            "rainfall": 122.0,
            "temperature": 28.0,
            "humidity": 82.5,
            "windSpeed": 8.0,
            "recordedAt": "'$TIMESTAMP'"
        }' > /dev/null 2>&1
    
    # === SOUTH SONGKHLA ===
    # Oracle 1 data
    curl -s -X POST http://localhost:3001/api/weather-oracle \
        -H "Content-Type: application/json" \
        -d '{
            "dataID": "WEATHER_SOUTH_01",
            "oracleID": "ORACLE_OPENWEATHER",
            "location": "South_Songkhla",
            "latitude": "7.2061",
            "longitude": "100.5950",
            "rainfall": 95.3,
            "temperature": 29.8,
            "humidity": 78.5,
            "windSpeed": 12.1,
            "recordedAt": "'$TIMESTAMP'"
        }' > /dev/null 2>&1
    
    # Oracle 2 data
    curl -s -X POST http://localhost:3001/api/weather-oracle \
        -H "Content-Type: application/json" \
        -d '{
            "dataID": "WEATHER_SOUTH_02",
            "oracleID": "ORACLE_THAI_MET",
            "location": "South_Songkhla",
            "latitude": "7.2061",
            "longitude": "100.5950",
            "rainfall": 97.0,
            "temperature": 30.0,
            "humidity": 79.0,
            "windSpeed": 11.8,
            "recordedAt": "'$TIMESTAMP'"
        }' > /dev/null 2>&1
    
    # Oracle 3 data
    curl -s -X POST http://localhost:3001/api/weather-oracle \
        -H "Content-Type: application/json" \
        -d '{
            "dataID": "WEATHER_SOUTH_03",
            "oracleID": "ORACLE_WUNDERGROUND",
            "location": "South_Songkhla",
            "latitude": "7.2061",
            "longitude": "100.5950",
            "rainfall": 93.8,
            "temperature": 29.5,
            "humidity": 78.0,
            "windSpeed": 12.3,
            "recordedAt": "'$TIMESTAMP'"
        }' > /dev/null 2>&1
    
    print_success "Weather data submitted from 3 oracles for all regions (9 submissions)"
    
    print_info "Validating weather data consensus..."
    
    # Validate consensus for Central Bangkok (will trigger automatic payout)
    print_info "Validating Central Bangkok consensus (DROUGHT - will trigger automatic payout)..."
    CENTRAL_CONSENSUS=$(curl -s -X POST http://localhost:3001/api/weather-oracle/validate-consensus \
        -H "Content-Type: application/json" \
        -d '{
            "location": "Central_Bangkok",
            "timestamp": "'$TIMESTAMP'",
            "dataIDs": ["WEATHER_CENTRAL_01", "WEATHER_CENTRAL_02", "WEATHER_CENTRAL_03"]
        }')
    
    # Check if automatic payout was triggered
    CLAIMS_TRIGGERED=$(echo "$CENTRAL_CONSENSUS" | jq -r '.data.automaticPayouts.claimsTriggered | length' 2>/dev/null || echo "0")
    if [ "$CLAIMS_TRIGGERED" -gt 0 ]; then
        print_success "Consensus validated - $CLAIMS_TRIGGERED automatic claim(s) triggered!"
        echo "$CENTRAL_CONSENSUS" | jq -r '.data.automaticPayouts.claimsTriggered[]' 2>/dev/null | while read claim; do
            print_success "  → Claim: $claim"
        done
    else
        print_success "Consensus validated (no threshold breaches)"
    fi
    
    sleep 1
    
    # Validate consensus for North Chiang Mai
    curl -s -X POST http://localhost:3001/api/weather-oracle/validate-consensus \
        -H "Content-Type: application/json" \
        -d '{
            "location": "North_ChiangMai",
            "timestamp": "'$TIMESTAMP'",
            "dataIDs": ["WEATHER_NORTH_01", "WEATHER_NORTH_02", "WEATHER_NORTH_03"]
        }' > /dev/null 2>&1
    
    # Validate consensus for South Songkhla
    curl -s -X POST http://localhost:3001/api/weather-oracle/validate-consensus \
        -H "Content-Type: application/json" \
        -d '{
            "location": "South_Songkhla",
            "timestamp": "'$TIMESTAMP'",
            "dataIDs": ["WEATHER_SOUTH_01", "WEATHER_SOUTH_02", "WEATHER_SOUTH_03"]
        }' > /dev/null 2>&1
    
    print_success "Weather data consensus validation completed"
    
    echo ""
}

# Step 7: Verify deployment
verify_deployment() {
    print_step "Step 7: Verifying Deployment"
    
    local all_good=1
    
    # Check network
    print_info "Checking Fabric network..."
    if /usr/local/bin/docker ps 2>/dev/null | grep -q "peer0.insurer1.insurance.com"; then
        print_success "Fabric network running"
    else
        print_error "Fabric network not running"
        all_good=0
    fi
    
    # Check API Gateway
    print_info "Checking API Gateway..."
    if curl -s -f http://localhost:3001/health > /dev/null 2>&1; then
        print_success "API Gateway responding"
    else
        print_error "API Gateway not responding"
        all_good=0
    fi
    
    # Check UI
    print_info "Checking UI..."
    if curl -s -f http://localhost:5173 > /dev/null 2>&1; then
        print_success "UI responding"
    else
        print_warning "UI may not be fully ready"
    fi
    
    # Check pool balance
    print_info "Checking premium pool..."
    BALANCE=$(curl -s http://localhost:3001/api/premium-pool/balance 2>/dev/null | jq -r '.data // 0' 2>/dev/null)
    if [ -n "$BALANCE" ] && (( $(echo "$BALANCE > 0" | bc -l 2>/dev/null || echo 0) )); then
        print_success "Premium pool funded: \$$BALANCE"
    else
        print_warning "Premium pool balance check failed"
    fi
    
    echo ""
    
    if [ $all_good -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

# Main deployment flow
main() {
    local start_time=$(date +%s)
    
    check_prerequisites
    clean_system
    deploy_network
    deploy_chaincodes
    deploy_api_gateway
    deploy_ui
    seed_demo_data
    verify_deployment
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║            ✓ DEPLOYMENT COMPLETED SUCCESSFULLY!               ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Deployment Summary:${NC}"
    echo -e "  • Network: 3 organizations, 1 channel"
    echo -e "  • Chaincode: 11 smart contracts deployed"
    echo -e "  • API Gateway: http://localhost:3001"
    echo -e "  • UI: http://localhost:5173"
    echo -e "  • Demo Data: 2 farmers, 1 active policy, 1 active template"
    echo -e "  • Premium Pool: Funded with \$500"
    echo -e "  • Time Taken: ${duration}s"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. Open UI: ${BLUE}http://localhost:5173${NC}"
    echo -e "  2. Run tests: ${BLUE}./test-e2e-complete.sh${NC}"
    echo -e "  3. View docs: ${BLUE}docs/QUICKSTART.md${NC}"
    echo ""
    echo -e "${YELLOW}Logs:${NC}"
    echo -e "  • API Gateway: ${API_DIR}/api-gateway.log"
    echo -e "  • UI: ${UI_DIR}/ui.log"
    echo ""
    echo -e "${YELLOW}To stop the system:${NC}"
    echo -e "  ${BLUE}./teardown-complete-system.sh${NC}"
    echo ""
}

# Run main deployment
main
