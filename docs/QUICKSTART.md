# 🚀 Quick Start Guide

Get the Weather Index Insurance Platform running in **under 5 minutes**.

---

## Prerequisites

### Required
- **Docker Desktop** (running)
- **Node.js** v18 or higher
- **Go** v1.20 or higher
- **jq** (for testing)

### Quick Check
```bash
docker --version
node --version
go version
jq --version
```

---

## 3-Step Setup

### Step 1: Deploy the Complete System
```bash
./deploy-complete-system.sh
```

This single command:
- ✅ Sets up Hyperledger Fabric network (3 orgs)
- ✅ Installs all smart contracts (latest versions)
- ✅ Builds and starts API Gateway
- ✅ Builds and starts UI
- ✅ Seeds demo data

**Time**: ~3-4 minutes

---

### Step 2: Verify System is Running

```bash
# Check API Gateway
curl http://localhost:3001/api/health

# Check UI
open http://localhost:5173
```

Expected output:
```json
{"success": true, "message": "API Gateway is healthy"}
```

---

### Step 3: Explore the Platform

#### Web UI (Recommended for First-Time Users)
```bash
open http://localhost:5173
```

**Pages**:
- **Dashboard** - Overview of system stats
- **Policies** - View and create insurance policies
- **Approvals** - Multi-org approval workflow
- **Claims** - Submit and track claims
- **Premium Pool** - View pool balance and transactions
- **Farmers** - Manage farmer registrations
- **Weather** - Submit and view weather data

#### API (For Developers)
```bash
# Get all policies
curl http://localhost:3001/api/policies | jq

# Get premium pool balance
curl http://localhost:3001/api/premium-pool/balance | jq

# Get all claims
curl http://localhost:3001/api/claims | jq
```

---

## Demo Data Included

The system comes pre-loaded with:
- ✅ **2 Farmers** - Demo farmer accounts
- ✅ **1 Active Policy** - Fully approved and funded
- ✅ **Premium Pool** - Pre-funded with demo premiums
- ✅ **Weather Data** - Sample weather records
- ✅ **Policy Templates** - Rice, Vegetables, Wheat templates

---

## Run End-to-End Tests

Verify all functionality:
```bash
./test-e2e-complete.sh
```

This validates:
- Farmer registration
- Policy creation with multi-org approval
- Premium pool auto-deposit
- Weather data submission
- Claims processing and payout
- UI accessibility

**Expected**: All tests pass (100% success rate)

---

## Common Operations

### Create a New Policy
```bash
curl -X POST http://localhost:3001/api/policies \
  -H "Content-Type: application/json" \
  -d '{
    "policyID": "POLICY_001",
    "farmerID": "FARMER_001",
    "cropType": "Rice",
    "coverageAmount": 5000,
    "premium": 500,
    "startDate": "2025-01-01",
    "endDate": "2025-12-31"
  }'
```

### Submit Weather Data
```bash
curl -X POST http://localhost:3001/api/weather-oracle \
  -H "Content-Type: application/json" \
  -d '{
    "dataID": "WEATHER_001",
    "location": "Singapore",
    "rainfall": 35.0,
    "temperature": 32.0
  }'
```

### Trigger a Claim
```bash
curl -X POST http://localhost:3001/api/claims \
  -H "Content-Type: application/json" \
  -d '{
    "claimID": "CLAIM_001",
    "policyID": "POLICY_001",
    "farmerID": "FARMER_001",
    "payoutPercent": 50
  }'
```

---

## Stop the System

```bash
./teardown-complete-system.sh
```

This will:
- Stop UI
- Stop API Gateway
- Stop Fabric network
- Clean up all containers and volumes

---

## Troubleshooting

### Issue: "Port already in use"
```bash
# Kill processes on ports
lsof -ti:3001 | xargs kill -9  # API Gateway
lsof -ti:5173 | xargs kill -9  # UI
```

### Issue: "Docker containers still running"
```bash
# Force teardown
./teardown-complete-system.sh
docker system prune -af --volumes
```

### Issue: "Chaincode installation failed"
```bash
# Clean and redeploy
./teardown-complete-system.sh
./deploy-complete-system.sh
```

### Issue: "Cannot connect to API"
```bash
# Check API Gateway logs
cd api-gateway
npm run dev
# Check for errors in terminal output
```

---

## Next Steps

1. **Read Full Documentation**: See `DOCUMENTATION.md` for architecture details
2. **Explore API**: See `GATEWAY.md` for all API endpoints
3. **Understand Smart Contracts**: See `CHAINCODE.md` for chaincode details
4. **Customize UI**: See `FRONTEND.md` for UI development guide

---

## Quick Reference

| Component | URL | Purpose |
|-----------|-----|---------|
| UI | http://localhost:5173 | Web interface |
| API Gateway | http://localhost:3001 | REST API |
| Health Check | http://localhost:3001/api/health | System status |

| Script | Purpose |
|--------|---------|
| `deploy-complete-system.sh` | Deploy everything |
| `teardown-complete-system.sh` | Stop and clean |
| `test-e2e-complete.sh` | Run all tests |

---

## Need Help?

- **Documentation**: See `DOCUMENTATION.md`
- **API Reference**: See `GATEWAY.md`
- **Frontend Guide**: See `FRONTEND.md`
- **Chaincode Details**: See `CHAINCODE.md`

---

**That's it!** You now have a fully functional parametric insurance platform. 🎉
