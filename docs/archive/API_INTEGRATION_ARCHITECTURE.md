# API Integration Architecture

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER BROWSER                                 │
│                     http://localhost:5173                            │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   React App     │
                    │   (Vite + TS)   │
                    │                 │
                    │  • Components   │
                    │  • Pages        │
                    │  • Forms        │
                    └────────┬────────┘
                             │
                ┌────────────▼────────────┐
                │   Service Layer         │
                │   (api.service.ts)      │
                │                         │
                │  DEV_MODE = true  ──┐   │
                │  DEV_MODE = false ──┤   │
                └────────────┬────────┘   │
                             │            │
                      ┌──────▼──────┐     │
                      │  Mock Data  │◄────┘
                      │  (Dev Mode) │
                      └─────────────┘
                             │
                    HTTP Requests
                    (Axios + JSON)
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY                                   │
│                    http://localhost:3001                             │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Express.js Server                         │  │
│  │                                                              │  │
│  │  Middleware:                                                │  │
│  │  • CORS (allow localhost:5173)                             │  │
│  │  • Helmet (security)                                        │  │
│  │  • Body Parser (JSON)                                       │  │
│  │  • Error Handler                                            │  │
│  └──────────────────┬───────────────────────────────────────────┘  │
│                     │                                               │
│  ┌──────────────────▼───────────────────────────────────────────┐  │
│  │                         Routes                               │  │
│  │                                                              │  │
│  │  /api/farmers          → farmer.routes.ts                  │  │
│  │  /api/policies         → policy.routes.ts                  │  │
│  │  /api/claims           → claim.routes.ts                   │  │
│  │  /api/weather-oracle   → weatherOracle.routes.ts           │  │
│  │  /api/premium-pool     → premiumPool.routes.ts             │  │
│  └──────────────────┬───────────────────────────────────────────┘  │
│                     │                                               │
│  ┌──────────────────▼───────────────────────────────────────────┐  │
│  │                      Controllers                             │  │
│  │                                                              │  │
│  │  • farmerController      → RegisterFarmer()                │  │
│  │  • policyController      → CreatePolicy()                  │  │
│  │  • claimController       → ApproveClaim()                  │  │
│  │  • weatherController     → SubmitWeatherData()             │  │
│  │  • premiumPoolController → GetBalance()                    │  │
│  └──────────────────┬───────────────────────────────────────────┘  │
│                     │                                               │
│  ┌──────────────────▼───────────────────────────────────────────┐  │
│  │                   Fabric Gateway Service                     │  │
│  │                (fabricGateway.ts)                            │  │
│  │                                                              │  │
│  │  • Connect to Fabric Network                                │  │
│  │  • Load Identity & Wallet                                   │  │
│  │  • Submit Transactions                                      │  │
│  │  • Evaluate Queries                                         │  │
│  └──────────────────┬───────────────────────────────────────────┘  │
│                     │                                               │
└─────────────────────┼───────────────────────────────────────────────┘
                      │
            gRPC + TLS Protocol
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│               HYPERLEDGER FABRIC NETWORK                             │
│                  (Docker Containers)                                 │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Channel: insurance-channel                │  │
│  │                                                              │  │
│  │  Peers:                                                      │  │
│  │  • peer0.org1.example.com:7051                              │  │
│  │  • peer0.org2.example.com:9051                              │  │
│  │                                                              │  │
│  │  Orderer:                                                    │  │
│  │  • orderer.example.com:7050                                 │  │
│  └──────────────────┬───────────────────────────────────────────┘  │
│                     │                                               │
│  ┌──────────────────▼───────────────────────────────────────────┐  │
│  │                      Smart Contracts (Chaincodes)            │  │
│  │                                                              │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │  │
│  │  │  farmer-cc     │  │   policy-cc    │  │  claim-cc    │  │  │
│  │  │                │  │                │  │              │  │  │
│  │  │ • Register     │  │ • CreatePolicy │  │ • Approve    │  │  │
│  │  │ • GetFarmer    │  │ • GetPolicy    │  │ • GetClaim   │  │  │
│  │  │ • UpdateFarmer │  │ • ListActive   │  │ • ListAll    │  │  │
│  │  └────────────────┘  └────────────────┘  └──────────────┘  │  │
│  │                                                              │  │
│  │  ┌────────────────┐  ┌────────────────┐                    │  │
│  │  │ weather-cc     │  │ premium-pool-cc│                    │  │
│  │  │                │  │                │                    │  │
│  │  │ • SubmitData   │  │ • GetBalance   │                    │  │
│  │  │ • GetWeather   │  │ • AddFunds     │                    │  │
│  │  │ • Validate     │  │ • Withdraw     │                    │  │
│  │  └────────────────┘  └────────────────┘                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      Blockchain Ledger                       │  │
│  │                      (State Database)                        │  │
│  │                                                              │  │
│  │  CouchDB Containers:                                         │  │
│  │  • couchdb0 (for peer0.org1)                                │  │
│  │  • couchdb1 (for peer0.org2)                                │  │
│  │                                                              │  │
│  │  Stores:                                                     │  │
│  │  • Farmer records                                            │  │
│  │  • Policy data                                               │  │
│  │  • Claims information                                        │  │
│  │  • Weather data                                              │  │
│  │  • Transaction history                                       │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Request Flow Example: Register Farmer

```
┌─────────┐    ┌─────────┐    ┌──────────┐    ┌────────┐    ┌──────────┐
│ Browser │    │   UI    │    │   API    │    │ Fabric │    │ Chaincode│
│         │    │ Service │    │ Gateway  │    │ Gateway│    │          │
└────┬────┘    └────┬────┘    └────┬─────┘    └───┬────┘    └────┬─────┘
     │              │              │              │              │
     │ 1. Submit    │              │              │              │
     │    Form      │              │              │              │
     │─────────────>│              │              │              │
     │              │              │              │              │
     │              │ 2. POST /api/farmers        │              │
     │              │    { farmerID, name, ... }  │              │
     │              │─────────────>│              │              │
     │              │              │              │              │
     │              │              │ 3. Submit    │              │
     │              │              │    Transaction              │
     │              │              │    (RegisterFarmer)         │
     │              │              │─────────────>│              │
     │              │              │              │              │
     │              │              │              │ 4. Invoke    │
     │              │              │              │    Chaincode │
     │              │              │              │─────────────>│
     │              │              │              │              │
     │              │              │              │              │ 5. Write
     │              │              │              │              │    to
     │              │              │              │              │    Ledger
     │              │              │              │              │
     │              │              │              │ 6. Response  │
     │              │              │              │<─────────────│
     │              │              │              │              │
     │              │              │ 7. Transaction              │
     │              │              │    Result                   │
     │              │              │<─────────────│              │
     │              │              │              │              │
     │              │ 8. HTTP 201  │              │              │
     │              │    { success: true, ... }   │              │
     │              │<─────────────│              │              │
     │              │              │              │              │
     │ 9. Success   │              │              │              │
     │    Message   │              │              │              │
     │<─────────────│              │              │              │
     │              │              │              │              │
```

## Data Flow Mapping

### Frontend → Backend Data Transformation

#### Farmer Registration
```typescript
// FRONTEND sends:
{
  farmerID: "F001",
  firstName: "John",
  lastName: "Doe",
  coopID: "COOP001",
  phone: "+1234567890",
  email: "john@example.com",
  walletAddress: "0x123...",
  latitude: 1.234,
  longitude: 5.678,
  region: "North",
  district: "District1",
  farmSize: 10.5,
  cropTypes: ["Rice", "Corn"],
  kycHash: "hash123"
}

// BACKEND transforms to:
{
  farmerID: "F001",
  name: "John Doe",
  location: "North, District1",
  contactInfo: "john@example.com, +1234567890"
}

// CHAINCODE stores:
Farmer {
  FarmerID: "F001",
  Name: "John Doe",
  Location: "North, District1",
  ContactInfo: "john@example.com, +1234567890",
  CoopID: "COOP001",
  Status: "Active",
  CreatedAt: "2025-11-10T00:00:00Z"
}
```

## Configuration Files

### Frontend (.env)
```bash
VITE_API_BASE_URL=http://localhost:3001/api
VITE_DEV_MODE=false              # Set to false for real API calls
VITE_DEBUG=true                  # Enable debug logging
VITE_LOG_API=true                # Log all API calls
```

### Backend (.env)
```bash
PORT=3001
NODE_ENV=development
CHANNEL_NAME=insurance-channel

# Chaincode names
CHAINCODE_FARMER=farmer-cc
CHAINCODE_POLICY=policy-cc
CHAINCODE_CLAIM_PROCESSOR=claim-processor-cc
CHAINCODE_WEATHER_ORACLE=weather-oracle-cc
CHAINCODE_PREMIUM_POOL=premium-pool-cc

# CORS
CORS_ORIGIN=http://localhost:5173

# Fabric Network Paths
CONNECTION_PROFILE_PATH=../network/organizations/...
CERTIFICATE_PATH=../network/organizations/...
PRIVATE_KEY_PATH=../network/organizations/...
```

## Port Mapping

| Service | Port | Purpose |
|---------|------|---------|
| Frontend (Vite) | 5173 | React UI Development Server |
| API Gateway | 3001 | Express.js REST API |
| Peer0.Org1 | 7051 | Fabric Peer gRPC |
| Peer0.Org2 | 9051 | Fabric Peer gRPC |
| Orderer | 7050 | Fabric Orderer |
| CouchDB0 | 5984 | Database for Peer0.Org1 |
| CouchDB1 | 7984 | Database for Peer0.Org2 |

## Security Features

### API Gateway
- ✅ CORS enabled for localhost:5173
- ✅ Helmet.js security headers
- ✅ Request body size limits
- ✅ Error handling middleware
- ❌ Authentication (not implemented)
- ❌ Rate limiting (not implemented)
- ❌ API keys (not implemented)

### Frontend
- ✅ HTTPS ready
- ✅ Input validation (React Hook Form)
- ✅ XSS protection (React default)
- ✅ CSP headers (Vite default)
- ❌ JWT token storage (not implemented)
- ❌ Refresh tokens (not implemented)

## Testing Endpoints

### Health Check
```bash
curl http://localhost:3001/health
# Expected: { "status": "healthy", "timestamp": "...", "uptime": 123 }
```

### Get All Farmers
```bash
curl http://localhost:3001/api/farmers
# Expected: { "success": true, "data": [...] }
```

### Register Farmer
```bash
curl -X POST http://localhost:3001/api/farmers \
  -H "Content-Type: application/json" \
  -d '{
    "farmerID": "F001",
    "name": "John Doe",
    "location": "North Region",
    "contactInfo": "john@example.com"
  }'
# Expected: { "success": true, "message": "...", "data": {...} }
```

### Get Premium Pool Balance
```bash
curl http://localhost:3001/api/premium-pool/balance
# Expected: { "success": true, "data": { "balance": 100000 } }
```

## Monitoring & Debugging

### Frontend Console Logs
When `VITE_LOG_API=true`:
```
[API] GET /farmers → 200 (1234ms)
[API] POST /farmers → 201 (2345ms)
[API] Error: Network timeout
```

### Backend Logs
Winston logger outputs:
```
info: GET /api/farmers {"query":{},"body":{}}
info: POST /api/farmers {"query":{},"body":{"farmerID":"F001"}}
error: Transaction failed: Error message
```

### Fabric Gateway Logs
```
info: Connected to Fabric network
info: Submitting transaction: RegisterFarmer
info: Transaction committed successfully
error: Failed to connect to peer: timeout
```

## Troubleshooting Guide

### Issue: CORS Error in Browser
**Symptom:** `Access-Control-Allow-Origin` error
**Solution:** Check API Gateway CORS config matches frontend URL

### Issue: Network Timeout
**Symptom:** Request hangs for 30 seconds
**Solution:** Verify Fabric network is running: `docker ps`

### Issue: 404 Not Found
**Symptom:** API endpoint returns 404
**Solution:** Check route is registered in `server.ts`

### Issue: 500 Internal Server Error
**Symptom:** All endpoints return 500
**Solution:** Check Fabric Gateway connection and chaincode deployment

### Issue: Data Structure Mismatch
**Symptom:** Success response but data looks wrong
**Solution:** Check controller transforms data correctly for chaincode

---

**Last Updated:** November 10, 2025  
**Status:** ✅ Architecture complete and ready for testing
