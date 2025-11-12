# API Gateway Setup Guide

## Prerequisites

The API Gateway requires Node.js and npm to be installed on your system.

### Install Node.js

**macOS:**
```bash
# Using Homebrew (recommended)
brew install node

# Or download from: https://nodejs.org/ (LTS version recommended)
```

**Verify Installation:**
```bash
node --version  # Should show v18.x or v20.x
npm --version   # Should show v9.x or v10.x
```

## Installation Steps

### 1. Install Dependencies

From the `api-gateway` directory:

```bash
cd api-gateway
npm install
```

This will install:
- **@hyperledger/fabric-gateway** (1.5.0) - Fabric Gateway SDK
- **@hyperledger/fabric-protos** (0.2.0) - Protobuf definitions
- **express** (4.18.2) - Web framework
- **cors** - CORS middleware
- **helmet** - Security middleware
- **winston** - Logging
- **joi** - Validation
- **dotenv** - Environment variables
- **TypeScript** and development tools

### 2. Configure Environment

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and update these paths to match your Fabric network:

```env
# Update these paths based on your test-network location
CONNECTION_PROFILE_PATH=../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/connection-org1.json
CERTIFICATE_PATH=../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts/cert.pem
PRIVATE_KEY_PATH=../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore/priv_sk
TLS_CERT_PATH=../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
```

### 3. Ensure Fabric Network is Running

Before starting the API Gateway, ensure:

1. **Fabric test-network is running:**
   ```bash
   cd ../fabric-samples/test-network
   ./network.sh up createChannel -ca
   ```

2. **All 8 chaincodes are deployed:**
   ```bash
   # Deploy each chaincode (example for farmer chaincode)
   ./network.sh deployCC -ccn farmer -ccp ../../Blockchain-Project/chaincode/farmer -ccl typescript
   
   # Repeat for: policy, policy-template, claims, weather-oracle, 
   # index-calculator, premium-pool, access-control
   ```

### 4. Build TypeScript

Compile TypeScript to JavaScript:

```bash
npm run build
```

This creates the `dist/` directory with compiled JavaScript files.

### 5. Start API Gateway

**Development mode** (with auto-restart on file changes):
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The API Gateway will:
- Connect to Fabric network on startup
- Start HTTP server on port 3001
- Log connection status

You should see:
```
2025-01-07 10:30:00 [info]: Connecting to Hyperledger Fabric network...
2025-01-07 10:30:02 [info]: Successfully connected to Fabric Gateway
2025-01-07 10:30:02 [info]: API Gateway running on port 3001
2025-01-07 10:30:02 [info]: Environment: development
2025-01-07 10:30:02 [info]: API Prefix: /api/v1
```

## Testing

### Health Check

```bash
curl http://localhost:3001/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-07T10:30:00.000Z",
  "uptime": 123.45
}
```

### API Endpoints

Once routes are implemented:

```bash
# Get all farmers
curl http://localhost:3001/api/v1/farmers

# Get all policies
curl http://localhost:3001/api/v1/policies

# Get all claims (audit trail)
curl http://localhost:3001/api/v1/claims
```

## Project Structure

```
api-gateway/
├── src/
│   ├── config/
│   │   └── index.ts              # Configuration (loaded from .env)
│   ├── services/
│   │   └── fabricGateway.ts      # Fabric Gateway SDK connection
│   ├── controllers/              # Business logic (to be created)
│   ├── routes/                   # Express routes (to be created)
│   ├── middleware/
│   │   └── errorHandler.ts       # Error handling
│   ├── utils/
│   │   └── logger.ts             # Winston logger
│   └── server.ts                 # Express app & startup
├── logs/                         # Log files (created on startup)
├── dist/                         # Compiled JavaScript (after npm run build)
├── package.json
├── tsconfig.json
├── .env                          # Your environment variables
└── .env.example                  # Template

```

## Development Workflow

1. Make changes to TypeScript files in `src/`
2. In dev mode (`npm run dev`), nodemon auto-restarts on changes
3. Test endpoints with curl, Postman, or from React UI
4. Check logs in terminal and `logs/` directory

## Connecting React UI

1. Start API Gateway: `npm run dev` (port 3001)
2. In `insurance-ui`, set `VITE_DEV_MODE=false` in `.env`
3. Start React app: `npm run dev` (port 5173)
4. React will now call API Gateway instead of using mock data

## Troubleshooting

### "Cannot find module" errors
```bash
npm install
```

### "Failed to connect to Fabric Gateway"
- Ensure test-network is running: `./network.sh up`
- Check certificate paths in `.env` match your network
- Verify peer is accessible: `docker ps | grep peer0.org1`

### "Contract not found" errors
- Ensure chaincode is deployed: `./network.sh deployCC -ccn <name>`
- Check chaincode name matches `.env` configuration

### Port 3001 already in use
```bash
# Find process using port 3001
lsof -i :3001

# Kill it
kill -9 <PID>

# Or change PORT in .env
```

## Next Steps

After installation:
1. ✅ Install Node.js and npm (if not done)
2. ✅ Run `npm install`
3. ✅ Configure `.env` with correct paths
4. ✅ Start Fabric network and deploy chaincodes
5. ⏳ Create controllers for each chaincode
6. ⏳ Create routes for each endpoint
7. ⏳ Test with React UI

## Resources

- [Fabric Gateway SDK Docs](https://hyperledger.github.io/fabric-gateway/)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
