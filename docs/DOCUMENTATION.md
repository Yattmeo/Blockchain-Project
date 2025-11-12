# 📚 Weather Index Insurance Platform - Complete Documentation

A blockchain-based parametric insurance platform built on Hyperledger Fabric.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Key Features](#key-features)
4. [Multi-Organization Workflow](#multi-organization-workflow)
5. [Smart Contracts](#smart-contracts)
6. [API Structure](#api-structure)
7. [User Interface](#user-interface)
8. [Deployment](#deployment)
9. [Testing](#testing)
10. [Troubleshooting](#troubleshooting)

---

## System Overview

### What is This Platform?

The Weather Index Insurance Platform is a **parametric insurance system** that automatically pays out claims based on objective weather data triggers, eliminating the need for traditional loss assessment.

### How It Works

```
1. Farmer purchases policy → Multi-org approval required
2. Premium auto-deposited to shared pool
3. Weather data submitted by oracles
4. If weather triggers threshold → Claim automatically triggered
5. Payout executed from pool → Funds transferred to farmer
```

### Why Blockchain?

- ✅ **Transparency**: All transactions visible and auditable
- ✅ **Trust**: Multi-party approval prevents fraud
- ✅ **Automation**: Smart contracts execute payouts automatically
- ✅ **Immutability**: Records cannot be altered or deleted
- ✅ **Decentralization**: No single point of control

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                      User Interface (React)                  │
│                     http://localhost:5173                    │
└──────────────────────────┬──────────────────────────────────┘
                           │ REST API
                           ▼
┌─────────────────────────────────────────────────────────────┐
│               API Gateway (Node.js/Express)                  │
│                  http://localhost:3001                       │
└──────────────────────────┬──────────────────────────────────┘
                           │ Fabric SDK
                           ▼
┌─────────────────────────────────────────────────────────────┐
│            Hyperledger Fabric Network                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Coop MSP   │  │ Insurer1 MSP │  │ Insurer2 MSP │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Smart Contracts (Go)                      │
│  • policy            • approval-manager                      │
│  • premium-pool      • claim-processor                       │
│  • weather-oracle    • farmer                                │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Blockchain** | Hyperledger Fabric 2.5 | Distributed ledger |
| **Smart Contracts** | Go 1.20 | Business logic |
| **API Gateway** | Node.js 18 + Express | REST interface |
| **Frontend** | React 18 + TypeScript | User interface |
| **State Management** | React Context | UI state |
| **Styling** | Tailwind CSS | UI design |

### Network Topology

#### Organizations
1. **CoopMSP** - Farmer cooperative
2. **Insurer1MSP** - Primary insurance provider
3. **Insurer2MSP** - Secondary insurance provider

#### Channels
- **insurance-channel** - Main channel for all transactions

#### Peers
- `peer0.coop.example.com` - Coop organization peer
- `peer0.insurer1.example.com` - Insurer1 organization peer
- `peer0.insurer2.example.com` - Insurer2 organization peer

#### Orderer
- `orderer.example.com` - Raft consensus orderer

---

## Key Features

### 1. Multi-Organization Approval Workflow

**Purpose**: Ensure policy legitimacy through consensus

**Process**:
```
Policy Creation → Pending Approval
                ↓
        Insurer1 Approves → 1/2 Approved
                ↓
        Insurer2 Approves → FULLY APPROVED
                ↓
            Execute Policy → Active
                ↓
        Auto-deposit Premium → Pool Funded
```

**Endorsement Policy**: Requires approval from **2 out of 2** insurers

### 2. Premium Pool Management

**Purpose**: Shared fund for all payouts

**Features**:
- ✅ Automatic premium deposits on policy execution
- ✅ Payout execution with balance validation
- ✅ Complete transaction history
- ✅ Real-time balance tracking
- ✅ Overdraft protection

**Transactions**:
- **Premium** - Deposits from policies
- **Payout** - Withdrawals for claims

### 3. Parametric Claims Processing

**Purpose**: Automatic payouts based on weather triggers

**Trigger Example** (Rice Drought):
```
IF rainfall < 50mm in growing season
THEN payout = 50% of coverage
```

**Process**:
1. Weather oracle submits rainfall data (35mm)
2. System detects threshold breach (< 50mm)
3. Claim triggered automatically
4. Payout calculated (50% of coverage)
5. Funds withdrawn from pool
6. Transaction recorded immutably

### 4. Weather Oracle System

**Purpose**: Provide trusted weather data

**Features**:
- ✅ Multiple oracle support
- ✅ Trust score tracking
- ✅ Location-based queries
- ✅ Timestamp validation
- ✅ Data source attribution

**Data Points**:
- Rainfall (mm)
- Temperature (°C)
- Humidity (%)
- Wind speed (km/h)

### 5. Farmer Management

**Purpose**: Track insured farmers

**Information Stored**:
- Personal details (name, contact)
- Farm details (location, size)
- Crop types
- Cooperative membership
- Policy history
- Claims history

### 6. Policy Templates

**Purpose**: Standardized coverage options

**Available Templates**:
- **Rice Drought** - Rainfall-based coverage
- **Rice Flood** - Excess rainfall coverage
- **Vegetable Drought** - Vegetable crop protection
- **Wheat Drought** - Wheat crop protection

**Template Fields**:
- Crop type
- Coverage amount ranges
- Premium rates
- Index type (drought/flood/temperature)
- Trigger thresholds
- Payout percentages

---

## Multi-Organization Workflow

### Policy Approval Flow

```javascript
// Step 1: Create Policy (any org)
POST /api/policies
→ Status: "Pending Approval"
→ Creates approval request

// Step 2: Insurer1 Approves
POST /api/approvals/:requestId/approve
Body: { organizationID: "Insurer1MSP" }
→ Approval count: 1/2

// Step 3: Insurer2 Approves
POST /api/approvals/:requestId/approve
Body: { organizationID: "Insurer2MSP" }
→ Approval count: 2/2
→ Status: "APPROVED"

// Step 4: Execute Policy
POST /api/approvals/:requestId/execute
→ Policy becomes "Active"
→ Premium auto-deposited to pool
→ Coverage begins
```

### Why Multi-Org Approval?

1. **Risk Distribution**: Multiple insurers share risk
2. **Fraud Prevention**: No single org can approve alone
3. **Consensus**: All parties agree on terms
4. **Audit Trail**: Every approval recorded immutably

---

## Smart Contracts

### Overview

| Chaincode | Purpose | Key Functions |
|-----------|---------|---------------|
| **policy** | Policy lifecycle | CreatePolicy, GetPolicy, UpdateStatus |
| **approval-manager** | Multi-org approval | CreateRequest, Approve, Execute |
| **premium-pool** | Fund management | DepositPremium, ExecutePayout, GetBalance |
| **claim-processor** | Claims handling | TriggerPayout, ProcessClaim, GetClaim |
| **weather-oracle** | Weather data | SubmitData, GetData, RegisterProvider |
| **farmer** | Farmer registry | RegisterFarmer, GetFarmer, UpdateFarmer |

### Detailed Chaincode Functions

#### policy (Policy Management)
```go
// Create new policy
CreatePolicy(policyID, farmerID, cropType, coverage, premium, dates...)

// Get policy details
GetPolicy(policyID) → Policy

// Update policy status
UpdatePolicyStatus(policyID, status)

// Get policies by farmer
GetPoliciesByFarmer(farmerID) → []Policy

// Get all policies
GetAllPolicies() → []Policy
```

#### approval-manager (Multi-Org Workflow)
```go
// Create approval request for policy
CreateApprovalRequest(requestID, policyID, requester, metadata)

// Approve request (requires 2 orgs)
ApproveRequest(requestID, organizationID, approverID, comments)

// Reject request
RejectRequest(requestID, organizationID, approverID, reason)

// Execute approved policy
ExecuteApprovedRequest(requestID, executorID)

// Get approval details
GetApprovalRequest(requestID) → ApprovalRequest

// Get approval history
GetApprovalHistory(requestID) → []ApprovalAction
```

#### premium-pool (Fund Management)
```go
// Deposit premium (auto-triggered on policy execution)
DepositPremium(txID, policyID, farmerID, amount)

// Execute payout for claim
ExecutePayout(txID, farmerID, policyID, claimID, amount)

// Get current pool balance
GetPoolBalance() → float64

// Get transaction history
GetTransactionHistory() → []Transaction

// Get pool statistics
GetPoolStats() → PoolStats
```

#### claim-processor (Claims)
```go
// Trigger payout based on weather
TriggerPayout(claimID, policyID, farmerID, indexID, coverage, percent)

// Process claim manually
ProcessClaim(claimID, approved, payoutAmount)

// Get claim details
GetClaim(claimID) → Claim

// Get claims by status
GetClaimsByStatus(status) → []Claim

// Get claim history
GetClaimHistory(claimID) → []ClaimAction
```

#### weather-oracle (Weather Data)
```go
// Submit weather data
SubmitWeatherData(dataID, oracleID, location, rainfall, temp, ...)

// Register oracle provider
RegisterProvider(oracleID, name, dataSource, trustScore)

// Get weather data by ID
GetWeatherData(dataID) → WeatherData

// Get weather by location
GetWeatherDataByLocation(location) → []WeatherData

// Validate oracle consensus
ValidateConsensus(location, dataID) → bool
```

#### farmer (Farmer Registry)
```go
// Register new farmer
RegisterFarmer(farmerID, name, email, location, farmSize, crops...)

// Update farmer details
UpdateFarmer(farmerID, updates)

// Get farmer details
GetFarmer(farmerID) → Farmer

// Get farmers by cooperative
GetFarmersByCoop(coopID) → []Farmer

// Get all farmers
GetAllFarmers() → []Farmer
```

### Endorsement Policies

```yaml
# Policy Creation & Updates
Policy: "OR('Insurer1MSP.peer', 'Insurer2MSP.peer', 'CoopMSP.peer')"

# Approval Actions
Approval: "AND('Insurer1MSP.peer', 'Insurer2MSP.peer')"

# Premium Pool Operations
PremiumPool: "OR('Insurer1MSP.peer', 'Insurer2MSP.peer')"

# Claims Processing
Claims: "OR('Insurer1MSP.peer', 'Insurer2MSP.peer')"

# Weather Oracle
Weather: "OR('Insurer1MSP.peer', 'Insurer2MSP.peer', 'CoopMSP.peer')"

# Farmer Management
Farmer: "OR('CoopMSP.peer', 'Insurer1MSP.peer')"
```

---

## API Structure

### Base URL
```
http://localhost:3001/api
```

### Endpoints Overview

| Category | Endpoints | Methods |
|----------|-----------|---------|
| **Policies** | `/policies` | GET, POST |
| **Approvals** | `/approvals` | GET, POST |
| **Claims** | `/claims` | GET, POST |
| **Premium Pool** | `/premium-pool` | GET, POST |
| **Weather** | `/weather-oracle` | GET, POST |
| **Farmers** | `/farmers` | GET, POST, PUT |
| **Dashboard** | `/dashboard` | GET |
| **Templates** | `/policy-templates` | GET |

### Example API Calls

#### Create Policy
```bash
POST /api/policies
Content-Type: application/json

{
  "policyID": "POLICY_001",
  "farmerID": "FARMER_001",
  "cropType": "Rice",
  "coverageAmount": 5000,
  "premium": 500,
  "startDate": "2025-01-01",
  "endDate": "2025-12-31",
  "indexType": "Rice Drought",
  "thresholds": {
    "rainfallMin": 50,
    "rainfallMax": 300
  }
}
```

#### Approve Policy
```bash
POST /api/approvals/:requestId/approve
Content-Type: application/json

{
  "organizationID": "Insurer1MSP",
  "approverID": "insurer1.admin",
  "comments": "Approved after review"
}
```

#### Submit Weather Data
```bash
POST /api/weather-oracle
Content-Type: application/json

{
  "dataID": "WEATHER_001",
  "oracleID": "ORACLE_001",
  "location": "Singapore",
  "rainfall": 35.0,
  "temperature": 32.0,
  "humidity": 65.0
}
```

#### Trigger Claim
```bash
POST /api/claims
Content-Type: application/json

{
  "claimID": "CLAIM_001",
  "policyID": "POLICY_001",
  "farmerID": "FARMER_001",
  "weatherDataID": "WEATHER_001",
  "payoutPercent": 50
}
```

For complete API documentation, see **GATEWAY.md**.

---

## User Interface

### Pages

1. **Dashboard** (`/`)
   - System overview
   - Key metrics (policies, claims, pool balance)
   - Recent transactions
   - Quick actions

2. **Policies** (`/policies`)
   - View all policies
   - Filter by status (Active, Pending, Expired)
   - Create new policy
   - View policy details

3. **Approvals** (`/approvals`)
   - Pending approval requests
   - Approve/reject actions
   - Approval history
   - Multi-org status tracking

4. **Claims** (`/claims`)
   - View all claims
   - Submit new claim
   - Track claim status
   - View payout history

5. **Premium Pool** (`/premium-pool`)
   - Current pool balance
   - Total deposits/payouts
   - Transaction history
   - Balance trends

6. **Farmers** (`/farmers`)
   - Farmer registry
   - Register new farmer
   - View farmer details
   - Policy/claim history per farmer

7. **Weather** (`/weather`)
   - Submit weather data
   - View weather history
   - Location-based queries
   - Oracle provider management

For detailed UI documentation, see **FRONTEND.md**.

---

## Deployment

### Quick Deploy (Recommended)

```bash
# Deploy everything in one command
./deploy-complete-system.sh
```

This script:
1. Starts Fabric network (3 orgs, 1 channel)
2. Installs all chaincode (latest versions)
3. Builds and starts API Gateway
4. Builds and starts UI
5. Seeds demo data

### Manual Deployment

#### Step 1: Network Setup
```bash
cd network
./network.sh up createChannel -c insurance-channel
```

#### Step 2: Install Chaincode
```bash
./deploy-policy.sh
./deploy-approval-manager.sh
./deploy-premium-pool.sh
./deploy-claim-processor.sh
./deploy-weather-oracle.sh
./deploy-farmer.sh
```

#### Step 3: API Gateway
```bash
cd api-gateway
npm install
npm run build
npm start
```

#### Step 4: UI
```bash
cd insurance-ui
npm install
npm run dev
```

### Environment Variables

#### API Gateway (.env)
```env
PORT=3001
FABRIC_NETWORK_PATH=../network
CHANNEL_NAME=insurance-channel
```

#### UI (.env)
```env
VITE_API_URL=http://localhost:3001/api
```

---

## Testing

### End-to-End Test Suite

Run comprehensive tests:
```bash
./test-e2e-complete.sh
```

**Tests Included**:
- ✅ Farmer registration
- ✅ Policy templates
- ✅ Policy creation
- ✅ Multi-org approval (2 orgs)
- ✅ Premium pool auto-deposit
- ✅ Weather data submission
- ✅ Claims processing
- ✅ Payout execution
- ✅ Dashboard statistics
- ✅ UI accessibility

**Expected Result**: 100% pass rate (all tests green)

### Individual Test Scripts

```bash
# Test policy creation with auto-deposit
./test-premium-auto-deposit.sh

# Test weather-triggered claim and payout
./test-claim-payout-simple.sh

# Test approval workflow
./test-approval-api.sh

# Test endorsement policies
./test-endorsement-policies.sh
```

### Manual Testing

```bash
# Check API health
curl http://localhost:3001/api/health

# Get pool balance
curl http://localhost:3001/api/premium-pool/balance

# Get all policies
curl http://localhost:3001/api/policies | jq

# Get pending approvals
curl http://localhost:3001/api/approvals/pending | jq
```

---

## Troubleshooting

### Common Issues

#### 1. Port Already in Use

**Problem**: `EADDRINUSE: address already in use :::3001`

**Solution**:
```bash
# Kill process on port 3001
lsof -ti:3001 | xargs kill -9

# Or use different port
export PORT=3002
npm start
```

#### 2. Chaincode Not Installed

**Problem**: `chaincode definition not found`

**Solution**:
```bash
# Verify installation
./verify-chaincode-installation.sh

# Redeploy specific chaincode
./deploy-policy.sh
```

#### 3. Endorsement Policy Failure

**Problem**: `failed to endorse transaction, see attached details for more info`

**Solution**:
- Ensure all required orgs are running
- Check endorsement policies match requirements
- Verify chaincode is installed on all required peers

```bash
# Verify endorsement policies
./test-endorsement-policies.sh
```

#### 4. Pool Balance Not Updating

**Problem**: Auto-deposit not triggering after policy execution

**Solution**:
1. Verify policy status is "Active"
2. Check API Gateway logs for errors
3. Ensure premium-pool chaincode is deployed
4. Verify policyID is in metadata

```bash
# Check policy status
curl http://localhost:3001/api/policies/POLICY_ID

# Check pool history
curl http://localhost:3001/api/premium-pool/history | jq
```

#### 5. UI Not Loading Data

**Problem**: UI shows "Demo Data" or empty tables

**Solution**:
1. Check API Gateway is running: `curl http://localhost:3001/api/health`
2. Check browser console for CORS errors
3. Verify API_URL in UI .env file
4. Hard refresh browser (Cmd+Shift+R on Mac)

#### 6. Docker Container Errors

**Problem**: Containers crash or won't start

**Solution**:
```bash
# Clean everything
./teardown-complete-system.sh
docker system prune -af --volumes

# Redeploy
./deploy-complete-system.sh
```

### Logs

#### API Gateway Logs
```bash
cd api-gateway
npm run dev
# Watch terminal output
```

#### Fabric Peer Logs
```bash
docker logs peer0.insurer1.example.com
docker logs peer0.insurer2.example.com
docker logs peer0.coop.example.com
```

#### Orderer Logs
```bash
docker logs orderer.example.com
```

### Debugging Tips

1. **Check Docker**: `docker ps` - ensure all containers running
2. **Check Ports**: `lsof -i :3001,5173` - verify no conflicts
3. **Check Network**: `docker network inspect fabric_test` - verify connectivity
4. **Check Chaincode**: `./verify-chaincode-installation.sh` - verify deployment
5. **Check Logs**: Always check API Gateway logs for errors

---

## Production Considerations

### Security

- [ ] Enable TLS for all Fabric connections
- [ ] Implement authentication/authorization
- [ ] Use environment-specific credentials
- [ ] Enable HTTPS for API Gateway
- [ ] Implement rate limiting
- [ ] Add input validation and sanitization

### Scalability

- [ ] Add more peers per organization
- [ ] Implement load balancing
- [ ] Use production-grade database (CouchDB)
- [ ] Add caching layer (Redis)
- [ ] Optimize chaincode queries

### Monitoring

- [ ] Implement logging framework
- [ ] Add performance metrics
- [ ] Set up alerting
- [ ] Monitor blockchain health
- [ ] Track transaction throughput

### Backup & Recovery

- [ ] Regular ledger backups
- [ ] Disaster recovery plan
- [ ] Database replication
- [ ] Document recovery procedures

---

## Additional Resources

- **QUICKSTART.md** - Get started in 5 minutes
- **FRONTEND.md** - UI development guide
- **GATEWAY.md** - Complete API reference
- **CHAINCODE.md** - Smart contract documentation

---

## Support

For issues, questions, or contributions, please refer to the project repository or contact the development team.

---

**Version**: 1.0.0  
**Last Updated**: November 2025
