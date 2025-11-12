# Quick Start Guide - API Gateway

## ⚡ Quick Commands

### Start API Gateway
```bash
cd api-gateway
npm run dev
```
Server will run on **http://localhost:3001**

### Test It Works
```bash
# Health check
curl http://localhost:3001/health

# Get API info
curl http://localhost:3001/api/v1
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-07T...",
  "uptime": 123.45
}
```

## 🔧 Setup (First Time Only)

### 1. Configure Environment
```bash
cd api-gateway
cp .env.example .env
```

Edit `.env` and update these paths:
```env
CONNECTION_PROFILE_PATH=../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/connection-org1.json
CERTIFICATE_PATH=../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts/cert.pem
PRIVATE_KEY_PATH=../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore/priv_sk
TLS_CERT_PATH=../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
```

### 2. Start Fabric Network
```bash
cd ../fabric-samples/test-network
./network.sh up createChannel -ca
```

### 3. Deploy Chaincodes
```bash
# Deploy all 8 chaincodes (example for one)
./network.sh deployCC -ccn farmer -ccp ../../Blockchain-Project/chaincode/farmer -ccl typescript

# Repeat for: policy, policy-template, claim-processor, weather-oracle, 
# index-calculator, premium-pool, access-control
```

## 🧪 Testing Endpoints

### Register a Farmer
```bash
curl -X POST http://localhost:3001/api/v1/farmers \
  -H "Content-Type: application/json" \
  -d '{
    "farmerID": "F001",
    "name": "John Doe",
    "location": "Region A",
    "contactInfo": "john@example.com"
  }'
```

### Get All Farmers
```bash
curl http://localhost:3001/api/v1/farmers
```

### Create a Policy
```bash
curl -X POST http://localhost:3001/api/v1/policies \
  -H "Content-Type: application/json" \
  -d '{
    "policyID": "P001",
    "farmerID": "F001",
    "templateID": "T001",
    "premiumAmount": 1000
  }'
```

### View Claims Audit Trail
```bash
# All claims
curl http://localhost:3001/api/v1/claims

# Claims by status
curl http://localhost:3001/api/v1/claims/status/Paid

# Claims by farmer
curl http://localhost:3001/api/v1/claims/farmer/F001
```

### Submit Weather Data
```bash
curl -X POST http://localhost:3001/api/v1/weather-oracle \
  -H "Content-Type: application/json" \
  -d '{
    "dataID": "W001",
    "location": "Region A",
    "timestamp": "2025-01-07T10:00:00Z",
    "temperature": 35.5,
    "rainfall": 12.3,
    "humidity": 65,
    "windSpeed": 15,
    "oracleID": "Oracle1"
  }'
```

### Check Premium Pool
```bash
# Balance
curl http://localhost:3001/api/v1/premium-pool/balance

# Stats
curl http://localhost:3001/api/v1/premium-pool/stats

# History
curl http://localhost:3001/api/v1/premium-pool/history
```

## 🔗 Connect to React UI

### 1. Start API Gateway
```bash
cd api-gateway
npm run dev
```
Server running on port 3001 ✅

### 2. Configure React UI
```bash
cd ../insurance-ui
```

Edit `.env`:
```env
VITE_DEV_MODE=false
```

### 3. Start React UI
```bash
npm run dev
```
UI running on port 5173 ✅

### 4. Test Full Flow
1. Open http://localhost:5173
2. Register a farmer
3. Create a policy
4. Submit weather data (from Weather Oracle page)
5. Watch claim auto-trigger (when conditions met)
6. View claim in audit trail

## 📊 All Available Endpoints

### Farmers
- `POST /api/v1/farmers` - Register
- `GET /api/v1/farmers` - Get all
- `GET /api/v1/farmers/:farmerId` - Get one
- `PUT /api/v1/farmers/:farmerId` - Update

### Policies
- `POST /api/v1/policies` - Create
- `GET /api/v1/policies` - Get all
- `GET /api/v1/policies/:policyId` - Get one
- `GET /api/v1/policies/farmer/:farmerId` - By farmer
- `POST /api/v1/policies/:policyId/activate` - Activate
- `GET /api/v1/policies/:policyId/history` - History

### Claims (Audit Trail)
- `GET /api/v1/claims` - Get all
- `GET /api/v1/claims/:claimId` - Get one
- `GET /api/v1/claims/farmer/:farmerId` - By farmer
- `GET /api/v1/claims/status/:status` - By status
- `POST /api/v1/claims/:claimId/retry` - Retry failed
- `GET /api/v1/claims/:claimId/history` - History

### Weather Oracle
- `POST /api/v1/weather-oracle` - Submit data
- `GET /api/v1/weather-oracle/:dataId` - Get one
- `GET /api/v1/weather-oracle/location/:location` - By location
- `POST /api/v1/weather-oracle/:dataId/validate` - Validate

### Premium Pool
- `GET /api/v1/premium-pool/balance` - Balance
- `GET /api/v1/premium-pool/stats` - Statistics
- `GET /api/v1/premium-pool/history` - Transactions
- `POST /api/v1/premium-pool/add` - Add funds
- `POST /api/v1/premium-pool/withdraw` - Withdraw

## 🐛 Troubleshooting

### "npm: command not found"
Install Node.js:
```bash
brew install node
```

### "Failed to connect to Fabric Gateway"
1. Check Fabric network is running:
   ```bash
   cd ../fabric-samples/test-network
   docker ps
   ```
2. Verify certificate paths in `.env`
3. Ensure peer is accessible on localhost:7051

### "Contract not found"
Deploy the chaincode:
```bash
cd ../fabric-samples/test-network
./network.sh deployCC -ccn <chaincode-name> -ccp ../../Blockchain-Project/chaincode/<name> -ccl typescript
```

### Port 3001 already in use
```bash
lsof -i :3001
kill -9 <PID>
```

Or change PORT in `.env`

## 📝 Logs

Check logs for debugging:
```bash
# Real-time logs
tail -f logs/combined.log

# Error logs only
tail -f logs/error.log
```

## ✅ Success Checklist

Before testing:
- [ ] Node.js installed (`node --version`)
- [ ] Dependencies installed (`npm install`)
- [ ] `.env` file configured with correct paths
- [ ] Fabric network running (`docker ps` shows containers)
- [ ] Chaincodes deployed (all 8)
- [ ] API Gateway started (`npm run dev`)
- [ ] Health check passes (`curl http://localhost:3001/health`)

## 🎯 What's Next?

1. **Test blockchain integration**: Submit real transactions and verify on Fabric ledger
2. **Test automatic claims**: Submit weather data and watch claims auto-trigger
3. **Connect React UI**: Set DEV_MODE=false and test full user flows
4. **Monitor logs**: Watch real-time transaction processing
5. **Test error handling**: Try invalid requests and check error responses

## 📚 More Info

- Full API docs: See [README.md](./README.md)
- Setup guide: See [SETUP.md](./SETUP.md)
- Implementation details: See [IMPLEMENTATION.md](./IMPLEMENTATION.md)

---

**Status: Ready to use! 🚀**
