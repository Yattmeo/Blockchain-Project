# API Gateway

Express.js API Gateway for the Hyperledger Fabric insurance blockchain network. Connects the React UI to 8 chaincodes using the Fabric Gateway SDK.

## Features

- ✅ **Fabric Gateway SDK 1.5.0** - Modern, efficient blockchain connection
- ✅ **Express.js REST API** - Clean endpoint design
- ✅ **TypeScript** - Type-safe development
- ✅ **Automatic Claims Processing** - Reflects parametric insurance model
- ✅ **Error Handling** - Comprehensive error middleware
- ✅ **Logging** - Winston logger with file and console output
- ✅ **Security** - Helmet and CORS middleware

## Architecture

```
React UI (port 5173)
       ↓
API Gateway (port 3001)
       ↓
Fabric Gateway SDK
       ↓
8 Chaincodes on Hyperledger Fabric
```

## Quick Start

### Prerequisites

- Node.js 18+ and npm
- Hyperledger Fabric test-network running
- All 8 chaincodes deployed

### Installation

```bash
# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env and update paths to match your network
nano .env
```

### Development

```bash
# Start in development mode (auto-restart)
npm run dev
```

### Production

```bash
# Build TypeScript
npm run build

# Start production server
npm start
```

## API Endpoints

### Farmers
- `POST /api/v1/farmers` - Register farmer
- `GET /api/v1/farmers` - Get all farmers
- `GET /api/v1/farmers/:farmerId` - Get farmer by ID
- `PUT /api/v1/farmers/:farmerId` - Update farmer

### Policies
- `POST /api/v1/policies` - Create policy
- `GET /api/v1/policies` - Get all policies
- `GET /api/v1/policies/:policyId` - Get policy by ID
- `GET /api/v1/policies/farmer/:farmerId` - Get farmer's policies
- `POST /api/v1/policies/:policyId/activate` - Activate policy
- `GET /api/v1/policies/:policyId/history` - Get policy history

### Claims (Audit Trail)
- `GET /api/v1/claims` - Get all claims
- `GET /api/v1/claims/:claimId` - Get claim by ID
- `GET /api/v1/claims/farmer/:farmerId` - Get farmer's claims
- `GET /api/v1/claims/status/:status` - Get claims by status
- `POST /api/v1/claims/:claimId/retry` - Retry failed payout
- `GET /api/v1/claims/:claimId/history` - Get claim history

### Weather Oracle
- `POST /api/v1/weather-oracle` - Submit weather data
- `GET /api/v1/weather-oracle/:dataId` - Get weather data
- `GET /api/v1/weather-oracle/location/:location` - Get location data
- `POST /api/v1/weather-oracle/:dataId/validate` - Validate consensus

### Premium Pool
- `GET /api/v1/premium-pool/balance` - Get pool balance
- `GET /api/v1/premium-pool/stats` - Get pool statistics
- `GET /api/v1/premium-pool/history` - Get transaction history
- `POST /api/v1/premium-pool/add` - Add funds to pool
- `POST /api/v1/premium-pool/withdraw` - Withdraw funds from pool

## Example Requests

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

### Get All Claims (Audit Trail)

```bash
curl http://localhost:3001/api/v1/claims
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

## Configuration

Key environment variables in `.env`:

```env
# Server
PORT=3001
NODE_ENV=development

# Fabric Network
CHANNEL_NAME=insurance-channel
MSP_ID=Org1MSP

# Chaincodes (must match deployed names)
CHAINCODE_FARMER=farmer
CHAINCODE_POLICY=policy
CHAINCODE_CLAIM_PROCESSOR=claim-processor
# ... etc

# Paths (update to match your network)
CONNECTION_PROFILE_PATH=../../fabric-samples/test-network/...
CERTIFICATE_PATH=../../fabric-samples/test-network/...
PRIVATE_KEY_PATH=../../fabric-samples/test-network/...
TLS_CERT_PATH=../../fabric-samples/test-network/...
```

## Parametric Insurance Flow

1. **Weather Data Submitted** → Oracle chaincode validates consensus
2. **Index Calculated** → Index calculator evaluates conditions
3. **Claim Auto-Triggered** → Claim processor checks policy terms
4. **Payout Processing** → Premium pool transfers funds
5. **Claim Paid** → Audit trail updated

**No manual approval needed!** Smart contracts automatically trigger payouts when conditions are met.

## Error Handling

All endpoints return consistent JSON responses:

**Success:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Error:**
```json
{
  "success": false,
  "message": "Error description"
}
```

## Logging

Logs are written to:
- `logs/combined.log` - All logs
- `logs/error.log` - Error logs only
- Console - Colored output in development

## Connecting to React UI

1. **Start API Gateway:**
   ```bash
   cd api-gateway
   npm run dev
   ```

2. **Configure React UI:**
   ```bash
   cd ../insurance-ui
   # Set DEV_MODE=false in .env
   echo "VITE_DEV_MODE=false" > .env
   ```

3. **Start React UI:**
   ```bash
   npm run dev
   ```

React will now use real blockchain data instead of mocks!

## Development Notes

- All transactions go through Fabric Gateway SDK
- Read operations use `evaluateTransaction` (no blockchain write)
- Write operations use `submitTransaction` (commits to ledger)
- Connection is established on server startup
- Graceful shutdown on SIGTERM/SIGINT

## Troubleshooting

See [SETUP.md](./SETUP.md) for detailed troubleshooting steps.

## Tech Stack

- **Framework:** Express.js 4.18
- **Language:** TypeScript 5.3
- **Blockchain SDK:** @hyperledger/fabric-gateway 1.5.0
- **Logging:** Winston
- **Security:** Helmet, CORS
- **Validation:** Joi (ready to use)

## License

MIT
