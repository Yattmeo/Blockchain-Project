# System Startup Guide

## ✅ Prerequisites Checklist

Before starting the system, ensure you have:
- [ ] Docker Desktop installed and running
- [ ] Node.js v20.19+ or v22.12+ installed
- [ ] Go 1.21+ installed (for chaincode)
- [ ] Terminal access (preferably multiple tabs)

## 🚀 Quick Start (3 Steps)

### Step 1: Start the Blockchain Network

```bash
cd network
./deploy-network.sh
```

**What this does:**
- Starts 4 peer organizations (Insurer1, Insurer2, Coop, Platform)
- Creates the `insurance-main` channel
- Deploys 8 chaincodes (access-control, farmer, policy, weather-oracle, etc.)
- Takes ~5-10 minutes on first run

**Expected output:**
```
✓✓✓ DEPLOYMENT COMPLETE ✓✓✓
Network Status:
  - Network: Running
  - Channel: insurance-main created
  - Chaincodes: 8 deployed
```

**Verify network is running:**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```
You should see containers like:
- peer0.insurer1.insurance.com
- peer0.insurer2.insurance.com
- peer0.coop.insurance.com
- peer0.platform.insurance.com
- orderer.insurance.com
- cli

### Step 2: Start the API Gateway

```bash
cd api-gateway
npm install  # Only needed once
npm run dev
```

**What this does:**
- Connects to the Fabric network via peer0.insurer1.insurance.com:7051
- Exposes REST API on http://localhost:3001
- Provides endpoints for all chaincodes

**Expected output:**
```
[nodemon] starting `ts-node src/server.ts`
info: Connecting to Hyperledger Fabric network...
info: Successfully connected to Fabric Gateway
info: API Gateway running on port 3001
info: Environment: development
info: API Prefix: /api
```

**Test the API:**
```bash
curl http://localhost:3001/health
# Should return: {"status":"healthy","timestamp":"...","uptime":...}

curl http://localhost:3001/api
# Should return API info with all endpoint paths
```

### Step 3: Start the Frontend UI

```bash
cd insurance-ui
npm install  # Only needed once
npm run dev
```

**What this does:**
- Starts React app on http://localhost:5173
- Connects to API Gateway at http://localhost:3001

**Expected output:**
```
VITE v5.x.x  ready in XXX ms

➜  Local:   http://localhost:5173/
➜  Network: use --host to expose
```

**Access the UI:**
Open http://localhost:5173 in your browser

## 🔧 Configuration Files

### API Gateway Configuration (`.env`)

Located at: `api-gateway/.env`

```env
# Network
CHANNEL_NAME=insurance-main
ORG_NAME=Insurer1
MSP_ID=Insurer1MSP

# Gateway Peer
GATEWAY_PEER=peer0.insurer1.insurance.com
GATEWAY_PEER_ENDPOINT=localhost:7051

# Paths (relative to api-gateway folder)
CERTIFICATE_PATH=../network/organizations/peerOrganizations/insurer1.insurance.com/users/User1@insurer1.insurance.com/msp/signcerts/User1@insurer1.insurance.com-cert.pem
PRIVATE_KEY_PATH=../network/organizations/peerOrganizations/insurer1.insurance.com/users/User1@insurer1.insurance.com/msp/keystore/priv_sk
TLS_CERT_PATH=../network/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt

# Chaincode Names
CHAINCODE_FARMER=farmer
CHAINCODE_POLICY=policy
CHAINCODE_CLAIM_PROCESSOR=claim-processor
CHAINCODE_WEATHER_ORACLE=weather-oracle
CHAINCODE_PREMIUM_POOL=premium-pool
```

### Frontend Configuration

Located at: `insurance-ui/src/config/index.ts`

To use LIVE data (not mock):
```typescript
export const APP_CONFIG = {
  DEV_MODE: false,  // Set to false to use real API
  API_BASE_URL: 'http://localhost:3001/api',
  // ...
};
```

To use MOCK data (no backend needed):
```typescript
export const APP_CONFIG = {
  DEV_MODE: true,  // Set to true to use mock data
  // ...
};
```

## 🧪 Testing the Integration

### Run Automated Tests

```bash
./test-api-integration.sh
```

This tests:
- ✅ API Gateway health
- ✅ All major endpoints (farmers, policies, claims, weather, pool)
- ✅ CORS configuration
- ✅ POST requests

### Manual Testing via UI

1. **Login**: http://localhost:5173/login
   - Select "Insurance Company 1" → Role: Insurer
   - Select "Farmers Cooperative" → Role: Coop
   
2. **Test Farmer Registration** (Coop role):
   - Navigate to Farmers page
   - Click "Register Farmer"
   - Fill form and submit
   - Verify farmer appears in table

3. **Test Policy Creation** (Insurer/Coop role):
   - Navigate to Policies page
   - Click "Create Policy"
   - Fill form and submit
   - Verify policy appears in table

4. **Test Claim Approval** (Insurer role):
   - Navigate to Claims page
   - Click "Approve" on a pending claim
   - Verify status changes

## 📊 System Architecture

```
┌─────────────────┐
│  Frontend (UI)  │  http://localhost:5173
│  React + Vite   │
└────────┬────────┘
         │ HTTP/REST
         ▼
┌─────────────────┐
│  API Gateway    │  http://localhost:3001
│  Express + TS   │
└────────┬────────┘
         │ Fabric Gateway SDK
         ▼
┌─────────────────┐
│ Fabric Network  │  peer0.insurer1:7051
│  4 Peers        │
│  8 Chaincodes   │
└─────────────────┘
```

## 🐛 Troubleshooting

### Network Issues

**Problem:** `Error: ENOENT: no such file or directory`
```bash
# Solution: Check paths in api-gateway/.env
# Verify certificates exist:
ls ../network/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt
```

**Problem:** `Error: failed to connect to peer0.insurer1.insurance.com:7051`
```bash
# Solution: Verify Docker containers are running
docker ps --filter "name=peer0.insurer1"

# If not running, restart network:
cd network
./deploy-network.sh
```

### API Gateway Issues

**Problem:** `ECONNREFUSED localhost:3001`
```bash
# Solution: Start the API Gateway
cd api-gateway
npm run dev
```

**Problem:** Chaincode errors (e.g., `chaincode not found`)
```bash
# Solution: Verify chaincodes are deployed
docker exec cli peer lifecycle chaincode queryinstalled

# Re-deploy if needed:
cd network
./deploy-network.sh
```

### Frontend Issues

**Problem:** CORS errors
```bash
# Solution: Check CORS_ORIGIN in api-gateway/.env
# Should be: CORS_ORIGIN=http://localhost:5173
```

**Problem:** All API calls return mock data
```javascript
// Solution: Set DEV_MODE=false in insurance-ui/src/config/index.ts
export const APP_CONFIG = {
  DEV_MODE: false,  // ← Change this
  // ...
};
```

## 🔄 Restart Everything

If things get messy, clean restart:

```bash
# 1. Stop everything
cd network
docker compose down --volumes --remove-orphans

# 2. Remove chaincode images
docker images | grep "dev-peer" | awk '{print $3}' | xargs docker rmi

# 3. Restart from scratch
./deploy-network.sh

# 4. Start API Gateway
cd ../api-gateway
npm run dev

# 5. Start UI (in another terminal)
cd ../insurance-ui
npm run dev
```

## 📝 Useful Commands

### Network Commands
```bash
# View network logs
docker logs peer0.insurer1.insurance.com

# View all chaincodes
docker exec cli peer lifecycle chaincode querycommitted -C insurance-main

# Stop network
cd network && docker compose down
```

### API Commands
```bash
# Test health
curl http://localhost:3001/health

# List farmers
curl http://localhost:3001/api/farmers

# Get pool balance
curl http://localhost:3001/api/premium-pool/balance
```

### Frontend Commands
```bash
# Build for production
cd insurance-ui && npm run build

# Preview production build
npm run preview
```

## 📚 Next Steps

1. **Production Deployment**: See `DEPLOYMENT.md`
2. **API Documentation**: See `API_INTEGRATION_STATUS.md`
3. **UI Features**: See `insurance-ui/PROGRESS.md`
4. **Testing**: See `TEST_SUMMARY.md`

## 🆘 Getting Help

If you encounter issues:
1. Check logs: `docker logs <container_name>`
2. Review error messages in terminal
3. Verify all prerequisites are met
4. Try a clean restart (see "Restart Everything" above)

---

**Last Updated:** November 10, 2025  
**System Version:** 1.0.0  
**Network:** Hyperledger Fabric 2.5.x
