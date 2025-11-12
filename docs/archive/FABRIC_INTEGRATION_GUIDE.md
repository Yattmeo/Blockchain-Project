# Fabric Blockchain Integration Guide

**Date:** November 11, 2025  
**Status:** Ready for Production Testing with Real Blockchain

---

## 🎯 Overview

This guide walks you through running the complete insurance system with **real Hyperledger Fabric blockchain integration**, replacing mock data with actual on-chain transactions.

## 🔄 What Changed

### Development Mode → Production Mode

**Before (Dev Mode):**
```
UI → Mock Data (mockData.ts)
✓ Fast testing
✗ No blockchain
✗ Data lost on refresh
```

**After (Production Mode):**
```
UI → API Gateway → Fabric Network → Approval Manager Chaincode
✓ Real blockchain
✓ Persistent data
✓ Multi-org endorsement
✓ Full audit trail
```

---

## 📋 Prerequisites

### 1. Docker Desktop
**Required for Fabric network**

- **macOS:** Install from https://www.docker.com/products/docker-desktop
- **Verify:** Open Docker Desktop and ensure it's running
- **Check:**
  ```bash
  docker --version
  docker info
  ```

### 2. Node.js & npm
**Required for API Gateway and UI**

- **Version:** Node.js 18+ recommended
- **Install:** https://nodejs.org/
- **Verify:**
  ```bash
  node --version   # Should be v18+
  npm --version    # Should be 9+
  ```

### 3. Hyperledger Fabric Binaries
**Already included in your network folder**

- `peer`, `orderer`, `configtxgen`, etc.
- Located in: `network/bin/`

---

## 🚀 Quick Start (Automated)

### Option 1: One-Command Startup

```bash
./start-full-system.sh
```

This script will:
1. ✅ Check prerequisites (Docker, Node.js)
2. ✅ Start Fabric network (4 organizations)
3. ✅ Deploy approval-manager chaincode
4. ✅ Build and start API Gateway
5. ✅ Start UI dev server

**Expected Output:**
```
==================================================
✅ Full System Started Successfully!
==================================================

Services Running:
  • Fabric Network:    Running (4 orgs)
  • API Gateway:       http://localhost:3001
  • UI Dev Server:     http://localhost:5173

Mode: PRODUCTION (Real Blockchain)
  • VITE_DEV_MODE=false
  • All operations write to Fabric ledger

Ready to test multi-party approvals! 🚀
```

### Stopping the System

```bash
./stop-full-system.sh
```

---

## 📝 Manual Step-by-Step (Alternative)

### Step 1: Start Fabric Network

```bash
cd network
./network.sh up
cd ..
```

**Verify:**
```bash
docker ps | grep peer
# Should see: peer0.insurer1, peer0.insurer2, peer0.coop, peer0.oracle
```

### Step 2: Deploy Approval Manager Chaincode

```bash
./deploy-approval-manager.sh
```

**Verify:**
```bash
docker exec cli peer lifecycle chaincode queryinstalled
# Should see: approval-manager, Version: 2.0, Sequence: 2
```

### Step 3: Start API Gateway

```bash
cd api-gateway

# Install dependencies (first time only)
npm install

# Build TypeScript
npm run build

# Start server
npm start
```

**Verify in another terminal:**
```bash
curl http://localhost:3001/health
# Should return: {"status":"healthy",...}

curl http://localhost:3001/api
# Should return: API endpoint list including /approval
```

### Step 4: Start UI Development Server

```bash
cd insurance-ui

# Install dependencies (first time only)
npm install

# Start dev server
npm run dev
```

**Access UI:**
- Open browser: http://localhost:5173
- Should see login page

---

## 🔧 Configuration Files

### 1. UI Environment (`.env`)

**Location:** `insurance-ui/.env`

```properties
# CHANGED: Dev mode disabled
VITE_DEV_MODE=false

# API Gateway URL
VITE_API_BASE_URL=http://localhost:3001/api

# Debug Settings
VITE_DEBUG=true
VITE_LOG_API=true
```

### 2. API Gateway Environment (`.env`)

**Location:** `api-gateway/.env`

```properties
# Server
PORT=3001
NODE_ENV=development

# Fabric Network
CHANNEL_NAME=insurance-main

# Organization (API Gateway runs as Insurer1)
ORG_NAME=Insurer1
MSP_ID=Insurer1MSP

# Gateway Peer
GATEWAY_PEER=peer0.insurer1.insurance.com
GATEWAY_PEER_ENDPOINT=localhost:7051

# Chaincode Names
CHAINCODE_APPROVAL_MANAGER=approval-manager
CHAINCODE_FARMER=farmer
CHAINCODE_POLICY=policy
# ... etc

# Connection Credentials
CERTIFICATE_PATH=../network/organizations/peerOrganizations/insurer1.insurance.com/users/User1@insurer1.insurance.com/msp/signcerts/User1@insurer1.insurance.com-cert.pem
PRIVATE_KEY_PATH=../network/organizations/peerOrganizations/insurer1.insurance.com/users/User1@insurer1.insurance.com/msp/keystore/priv_sk
TLS_CERT_PATH=../network/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt
```

### 3. API Gateway Config (`config/index.ts`)

**Added approval-manager:**
```typescript
chaincodes: {
  // ... existing chaincodes
  approvalManager: process.env.CHAINCODE_APPROVAL_MANAGER || 'approval-manager',
},
```

---

## 🧪 Testing the Integration

### Test 1: Health Checks

**API Gateway:**
```bash
curl http://localhost:3001/health
```

**Expected:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-11T10:00:00.000Z",
  "uptime": 120.5
}
```

### Test 2: Query Pending Approvals

```bash
curl http://localhost:3001/api/approval/pending
```

**Expected (empty at first):**
```json
{
  "success": true,
  "data": [],
  "count": 0
}
```

### Test 3: Create Approval Request (CLI)

```bash
docker exec cli peer chaincode invoke \
  -o orderer.insurance.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
  -C insurance-main \
  -n approval-manager \
  --peerAddresses peer0.insurer1.insurance.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt \
  -c '{"function":"CreateApprovalRequest","Args":["REQ_TEST_001","FARMER_REGISTRATION","farmer","RegisterFarmer","[\"FARMER999\",\"Test\",\"User\",\"COOP001\",\"555-0000\",\"test@test.com\",\"0x123\",\"1.23\",\"4.56\",\"North\",\"District1\",\"5.0\",\"[\\\"Rice\\\"]\",\"kychash\"]","[\"CoopMSP\",\"Insurer1MSP\"]","{}"]}'
```

**Then query again:**
```bash
curl http://localhost:3001/api/approval/pending
```

**Expected:**
```json
{
  "success": true,
  "data": [
    {
      "requestId": "REQ_TEST_001",
      "requestType": "FARMER_REGISTRATION",
      "status": "PENDING",
      "requiredOrgs": ["CoopMSP", "Insurer1MSP"],
      "approvals": {},
      "rejections": {}
    }
  ],
  "count": 1
}
```

---

## 🎨 UI Testing Workflow

### Complete Multi-Party Approval Flow

#### 1. Login as Coop User

- **URL:** http://localhost:5173
- **Email:** coop@example.com
- **Password:** password

#### 2. Register a New Farmer

**Steps:**
1. Navigate to: **Farmers** page
2. Click: **+ Register New Farmer**
3. Fill in form:
   - Farmer ID: FARMER_NEW_001
   - First Name: John
   - Last Name: Doe
   - Cooperative: COOP001
   - Phone: 555-1234
   - Email: john.doe@farm.com
   - Wallet: 0x123...
   - Location: 13.7563, 100.5018
   - Region: Central
   - District: Bangkok
   - Land Size: 10.5 hectares
   - Crops: Rice, Corn
4. Click: **Register Farmer**

**Expected:**
- ✅ Success message: "Approval request created"
- ✅ Farmer appears in "Pending Approval" section
- ✅ Redirected to Approvals page

#### 3. View Approval Request

**On Approvals Page:**
- See new request: REQ_FARM_XXX
- Status: **PENDING**
- Type: **Farmer Registration**
- Progress: **0/2** (needs CoopMSP and Insurer1MSP)
- Alert: "Awaiting Your Action: 1 request"

#### 4. Approve as Coop

**Click:** 👍 **Approve** button

**Expected:**
- ✅ Success: "Request REQ_FARM_XXX approved successfully"
- ✅ Progress updates to: **1/2** (50%)
- ✅ CoopMSP shows with ✅ in approvals list
- ✅ Approve button disappears
- ✅ Status stays: **PENDING** (waiting for Insurer1)

#### 5. Switch to Insurer1 User

**Logout and login as:**
- **Email:** insurer1@example.com
- **Password:** password

#### 6. Approve as Insurer1

**On Approvals Page:**
- See same request: REQ_FARM_XXX
- Progress: **1/2** (CoopMSP approved)
- Alert: "Awaiting Your Action: 1 request"

**Click:** 👍 **Approve** button

**Expected:**
- ✅ Success: "Request approved successfully"
- ✅ Progress updates to: **2/2** (100%)
- ✅ Insurer1MSP shows with ✅
- ✅ Status changes to: **APPROVED** 🎉
- ✅ Execute button (▶️) appears

#### 7. Execute Approved Request

**Click:** ▶️ **Execute** button
**Confirm** in dialog

**Expected:**
- ✅ Success: "Request executed successfully"
- ✅ Status changes to: **EXECUTED**
- ✅ Farmer is now registered on blockchain!
- ✅ Execution details show:
  - Executed At: timestamp
  - Result: "SUCCESS: Farmer registered"

#### 8. Verify Farmer Registration

**Navigate to: Farmers page**

**Expected:**
- ✅ New farmer (FARMER_NEW_001) appears in table
- ✅ All details match registration form
- ✅ Data persists (refresh page, still there!)

---

## 🔍 Verification Checklist

### System Health

- [ ] Docker Desktop running
- [ ] 4 peer containers running (insurer1, insurer2, coop, oracle)
- [ ] 1 orderer container running
- [ ] API Gateway accessible at :3001
- [ ] UI accessible at :5173

### Blockchain Integration

- [ ] API calls return real data from chain (not mock)
- [ ] Approval requests persist across page refreshes
- [ ] Multi-org endorsement required for approval
- [ ] Status changes reflected on chain
- [ ] Execution invokes target chaincode

### Multi-Party Workflow

- [ ] Coop can create approval requests
- [ ] Each org only sees buttons for their approvals
- [ ] Progress bar updates after each approval
- [ ] Status changes to APPROVED when all orgs approve
- [ ] Execute button only shows for approved requests
- [ ] Execution actually registers farmer/policy/etc

### Data Persistence

- [ ] Refresh page → data still there
- [ ] Restart UI → data still there
- [ ] Different browser → same data visible
- [ ] Approval history maintained on chain

---

## 🐛 Troubleshooting

### Issue 1: API Gateway Won't Connect to Fabric

**Symptom:**
```
Failed to connect to Fabric Gateway
```

**Solutions:**

1. **Check network is running:**
   ```bash
   docker ps | grep peer
   # Should see 4 peers
   ```

2. **Verify certificate paths:**
   ```bash
   ls network/organizations/peerOrganizations/insurer1.insurance.com/users/User1@insurer1.insurance.com/msp/signcerts/
   # Should see .pem file
   ```

3. **Check peer endpoint:**
   ```bash
   nc -zv localhost 7051
   # Should connect
   ```

4. **Restart API Gateway:**
   ```bash
   cd api-gateway
   npm start
   ```

### Issue 2: UI Shows "API Error"

**Symptom:**
UI displays error: "Failed to fetch approvals"

**Solutions:**

1. **Check API Gateway is running:**
   ```bash
   curl http://localhost:3001/health
   ```

2. **Check CORS settings:**
   - API Gateway `.env`: `CORS_ORIGIN=http://localhost:5173`

3. **Check UI environment:**
   ```bash
   cat insurance-ui/.env
   # VITE_DEV_MODE should be false
   # VITE_API_BASE_URL should be http://localhost:3001/api
   ```

4. **Check browser console:**
   - Open DevTools (F12)
   - Look for network errors
   - Check if requests reach localhost:3001

5. **Restart UI:**
   ```bash
   cd insurance-ui
   npm run dev
   ```

### Issue 3: Approval Not Working

**Symptom:**
Click approve but nothing happens

**Solutions:**

1. **Check browser console for errors**

2. **Verify chaincode is deployed:**
   ```bash
   docker exec cli peer lifecycle chaincode queryinstalled
   # Should see approval-manager
   ```

3. **Check endorsement policy:**
   ```bash
   docker exec cli peer lifecycle chaincode querycommitted -C insurance-main -n approval-manager
   # Should show: AND('Insurer1MSP.peer','CoopMSP.peer')
   ```

4. **Test with CLI:**
   ```bash
   # Try approving directly via CLI
   docker exec cli peer chaincode invoke \
     -C insurance-main \
     -n approval-manager \
     -c '{"function":"ApproveRequest","Args":["REQ_TEST_001","Approved via CLI"]}'
   ```

### Issue 4: Docker Not Running

**Symptom:**
```
Cannot connect to the Docker daemon
```

**Solutions:**

1. **macOS:** Open Docker Desktop application

2. **Verify Docker is running:**
   ```bash
   docker info
   ```

3. **Restart Docker Desktop**

### Issue 5: Port Already in Use

**Symptom:**
```
Error: listen EADDRINUSE: address already in use :::3001
```

**Solutions:**

1. **Find and kill process:**
   ```bash
   lsof -ti:3001 | xargs kill -9
   # For UI port 5173:
   lsof -ti:5173 | xargs kill -9
   ```

2. **Or use stop script:**
   ```bash
   ./stop-full-system.sh
   ```

---

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        USER BROWSER                          │
│                    http://localhost:5173                     │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP REST
                     │ VITE_DEV_MODE=false
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      API GATEWAY                             │
│                  (Express + TypeScript)                      │
│                  http://localhost:3001/api                   │
│                                                              │
│  Routes:                                                     │
│    POST   /approval                  → CreateApprovalRequest│
│    POST   /approval/:id/approve      → ApproveRequest       │
│    POST   /approval/:id/reject       → RejectRequest        │
│    POST   /approval/:id/execute      → ExecuteApprovedReq   │
│    GET    /approval                  → GetAllApprovals      │
│    GET    /approval/pending          → GetPendingApprovals  │
│    GET    /approval/:id              → GetApprovalRequest   │
│    GET    /approval/:id/history      → GetApprovalHistory   │
│                                                              │
└────────────────────┬────────────────────────────────────────┘
                     │ Fabric Gateway SDK
                     │ gRPC + TLS
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              HYPERLEDGER FABRIC NETWORK                      │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Insurer1   │  │   Insurer2   │  │     Coop     │     │
│  │ peer0:7051   │  │ peer0:9051   │  │ peer0:11051  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌──────────────┐                    ┌──────────────┐      │
│  │    Oracle    │                    │   Orderer    │      │
│  │ peer0:13051  │                    │   :7050      │      │
│  └──────────────┘                    └──────────────┘      │
│                                                              │
│  Channel: insurance-main                                    │
│                                                              │
│  Chaincodes:                                                │
│    • approval-manager   (Multi-party approval workflow)    │
│    • farmer             (Farmer registration)               │
│    • policy             (Policy management)                 │
│    • claim-processor    (Claim processing)                  │
│    • premium-pool       (Premium pool management)           │
│    • weather-oracle     (Weather data validation)           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Key Differences: Dev vs Production

| Aspect | Dev Mode (Mock) | Production Mode (Fabric) |
|--------|----------------|--------------------------|
| **Data Storage** | In-memory JavaScript array | Blockchain ledger |
| **Persistence** | Lost on refresh | Permanent |
| **Endorsement** | Simulated | Real multi-org signatures |
| **Transaction ID** | Random string | Real Fabric TX ID |
| **Approval Workflow** | Instant | Requires chaincode execution |
| **Execution** | Mock result | Actually invokes target chaincode |
| **Audit Trail** | Simulated history | Immutable blockchain history |
| **Performance** | Instant | Network latency (~2-5 seconds) |
| **Multi-User** | Separate browser state | Shared blockchain state |
| **Rollback** | Just refresh | Must create new transaction |

---

## 📈 Performance Expectations

### Typical Response Times

- **Query (GET):** 100-500ms
  - Reads from local peer's state database
  - No consensus required
  
- **Submit (POST - Approve/Reject):** 2-5 seconds
  - Requires endorsement from multiple peers
  - Orderer commits to blockchain
  - Block creation time
  
- **Execute:** 3-10 seconds
  - Approval endorsement
  - Invokes target chaincode
  - Target chaincode execution
  - Double consensus overhead

### Optimization Tips

1. **Use appropriate timeouts:**
   - Query: 5 seconds
   - Endorse: 15 seconds
   - Commit: 60 seconds

2. **Cache query results:**
   - UI can cache approval list for 10-30 seconds
   - Refresh only when user performs action

3. **Show loading indicators:**
   - Users expect blockchain operations to take time
   - Clear feedback improves UX

---

## 🎓 Learning Resources

### Understanding the Flow

1. **Create Approval Request:**
   - UI → API → Fabric → approval-manager.CreateApprovalRequest()
   - Creates new approval request on ledger with PENDING status

2. **Approve Request:**
   - UI → API → Fabric → approval-manager.ApproveRequest()
   - Adds org's approval to the request
   - Checks if all required approvals received
   - If yes, changes status to APPROVED

3. **Execute Request:**
   - UI → API → Fabric → approval-manager.ExecuteApprovedRequest()
   - Invokes target chaincode (e.g., farmer.RegisterFarmer)
   - Marks request as EXECUTED with result

### Key Concepts

- **Endorsement:** Multiple orgs must sign transaction
- **Ordering:** Orderer sequences transactions into blocks
- **Commit:** Block is added to all peers' ledgers
- **State Database:** CouchDB stores current state for queries
- **History:** Blockchain maintains complete audit trail

---

## ✅ Success Criteria

Your integration is successful when:

1. **✅ System Starts:** All services running without errors
2. **✅ Network Health:** 4 peers + orderer visible in Docker
3. **✅ API Connectivity:** Health endpoint returns 200
4. **✅ UI Loads:** Login page appears at localhost:5173
5. **✅ Create Request:** Can register farmer from UI
6. **✅ View Request:** Approval shows in Approvals page
7. **✅ Multi-Party:** Both Coop and Insurer1 can approve
8. **✅ Status Changes:** PENDING → APPROVED → EXECUTED
9. **✅ Execution:** Execute actually registers farmer
10. **✅ Persistence:** Data survives page refresh
11. **✅ Multi-User:** Different browsers see same data
12. **✅ Audit Trail:** History shows all approval actions

---

## 🚀 Next Steps

After verifying basic integration:

1. **Test All Request Types:**
   - Farmer Registration
   - Policy Creation
   - Claim Approval
   - Pool Withdrawal

2. **Test Rejection Flow:**
   - Reject request with reason
   - Verify status changes to REJECTED
   - Check rejection reason is stored

3. **Test Edge Cases:**
   - What if org approves twice?
   - What if execute without approval?
   - What if network connection fails?

4. **Performance Testing:**
   - Create multiple requests
   - Measure response times
   - Test concurrent approvals

5. **Security Testing:**
   - Can wrong org approve?
   - Can execute without APPROVED status?
   - Are credentials properly protected?

---

*Integration Complete! Ready for production testing.* 🎉

