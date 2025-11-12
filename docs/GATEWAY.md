# 🔌 API Gateway Documentation

Complete reference for the REST API Gateway that interfaces with the Hyperledger Fabric blockchain.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Getting Started](#getting-started)
4. [Authentication](#authentication)
5. [API Endpoints](#api-endpoints)
6. [Error Handling](#error-handling)
7. [Fabric Integration](#fabric-integration)
8. [Development](#development)

---

## Overview

The API Gateway is a **Node.js/Express** application that provides a RESTful interface to the Hyperledger Fabric blockchain network.

### Key Features
- ✅ RESTful API design
- ✅ Fabric SDK integration
- ✅ Transaction submission and queries
- ✅ Error handling middleware
- ✅ CORS support
- ✅ Request validation

### Base URL
```
http://localhost:3001/api
```

---

## Architecture

```
┌─────────────────────┐
│   React Frontend    │
└──────────┬──────────┘
           │ HTTP/REST
           ▼
┌─────────────────────┐
│   Express Server    │
│   (Port 3001)       │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Routes  │ │Services │
└────┬────┘ └────┬────┘
     │           │
     └─────┬─────┘
           │
           ▼
    ┌─────────────┐
    │ Fabric SDK  │
    └──────┬──────┘
           │ gRPC
           ▼
┌──────────────────────┐
│ Fabric Network       │
│ (Smart Contracts)    │
└──────────────────────┘
```

### Components

| Component | Purpose |
|-----------|---------|
| **Routes** | Define API endpoints |
| **Controllers** | Handle business logic |
| **Services** | Interact with Fabric |
| **Middleware** | Error handling, validation |
| **Config** | Environment configuration |

---

## Getting Started

### Prerequisites
- Node.js 18+
- Access to running Fabric network
- Environment variables configured

### Installation

```bash
cd api-gateway
npm install
```

### Configuration

Create `.env` file:
```env
PORT=3001
FABRIC_NETWORK_PATH=../network
CHANNEL_NAME=insurance-channel
NODE_ENV=development
```

### Start Server

**Development**:
```bash
npm run dev
```

**Production**:
```bash
npm run build
npm start
```

### Health Check

```bash
curl http://localhost:3001/api/health
```

Expected response:
```json
{
  "success": true,
  "message": "API Gateway is healthy"
}
```

---

## Authentication

### Current Implementation

**Note**: Currently, authentication is not enforced. All endpoints are public.

### Future Implementation

Planned authentication methods:
- JWT tokens
- Organization-based access control
- Role-based permissions

---

## API Endpoints

### Overview

| Category | Base Path | Endpoints |
|----------|-----------|-----------|
| **Policies** | `/policies` | 5 endpoints |
| **Approvals** | `/approvals` | 8 endpoints |
| **Claims** | `/claims` | 7 endpoints |
| **Premium Pool** | `/premium-pool` | 6 endpoints |
| **Weather** | `/weather-oracle` | 6 endpoints |
| **Farmers** | `/farmers` | 6 endpoints |
| **Dashboard** | `/dashboard` | 2 endpoints |
| **Templates** | `/policy-templates` | 5 endpoints |

---

## Policies API

### Create Policy

Creates an approval request for a new policy (requires multi-org approval).

**Endpoint**: `POST /api/policies`

**Request Body**:
```json
{
  "policyID": "POLICY_001",
  "farmerID": "FARMER_001",
  "templateID": "TEMPLATE_RICE_DROUGHT_001",
  "coverageAmount": 5000,
  "premiumAmount": 500,
  "startDate": "2025-01-01",
  "endDate": "2025-12-31",
  "cropType": "Rice",
  "farmLocation": "1.3521,103.8198",
  "farmSize": 5.5,
  "coopID": "COOP001",
  "insurerID": "INSURER001"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Policy creation approval request submitted successfully",
  "data": {
    "requestID": "POL_REQ_1699876543_abc123",
    "status": "PENDING",
    "policyID": "POLICY_001",
    "farmerID": "FARMER_001",
    "coverageAmount": 5000,
    "premiumAmount": 500
  }
}
```

**Chaincode**: `approval-manager.CreateApprovalRequest`

---

### Get All Policies

**Endpoint**: `GET /api/policies`

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "policyID": "POLICY_001",
      "farmerID": "FARMER_001",
      "status": "Active",
      "coverageAmount": 5000,
      "premiumAmount": 500,
      "startDate": "2025-01-01T00:00:00Z",
      "endDate": "2025-12-31T23:59:59Z"
    }
  ]
}
```

**Chaincode**: `policy.GetAllPolicies`

---

### Get Policy by ID

**Endpoint**: `GET /api/policies/:policyId`

**Response**:
```json
{
  "success": true,
  "data": {
    "policyID": "POLICY_001",
    "farmerID": "FARMER_001",
    "templateID": "TEMPLATE_RICE_DROUGHT_001",
    "status": "Active",
    "coverageAmount": 5000,
    "premiumAmount": 500,
    "cropType": "Rice",
    "startDate": "2025-01-01T00:00:00Z",
    "endDate": "2025-12-31T23:59:59Z"
  }
}
```

**Chaincode**: `policy.GetPolicy`

---

### Get Policies by Farmer

**Endpoint**: `GET /api/policies/farmer/:farmerId`

**Response**: Array of policies for the farmer

**Chaincode**: `policy.GetPoliciesByFarmer`

---

### Activate Policy

**Endpoint**: `POST /api/policies/:policyId/activate`

**Response**:
```json
{
  "success": true,
  "message": "Policy activated successfully"
}
```

**Chaincode**: `policy.UpdatePolicyStatus`

---

## Approvals API

### Create Approval Request

**Endpoint**: `POST /api/approvals`

**Request Body**:
```json
{
  "requestType": "POLICY_CREATION",
  "targetChaincode": "policy",
  "targetFunction": "CreatePolicy",
  "functionArgs": ["arg1", "arg2"],
  "requiredOrgs": ["Insurer1MSP", "Insurer2MSP"],
  "metadata": {
    "description": "Policy for farmer FARM001"
  }
}
```

**Chaincode**: `approval-manager.CreateApprovalRequest`

---

### Get All Approvals

**Endpoint**: `GET /api/approvals`

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "requestID": "POL_REQ_123",
      "requestType": "POLICY_CREATION",
      "status": "PENDING",
      "approvalCount": 1,
      "requiredApprovals": 2,
      "createdAt": "2025-11-12T10:00:00Z"
    }
  ]
}
```

**Chaincode**: `approval-manager.GetAllApprovalRequests`

---

### Get Pending Approvals

**Endpoint**: `GET /api/approvals/pending`

**Chaincode**: `approval-manager.GetPendingApprovals`

---

### Get Approval by ID

**Endpoint**: `GET /api/approvals/:requestId`

**Chaincode**: `approval-manager.GetApprovalRequest`

---

### Approve Request

**Endpoint**: `POST /api/approvals/:requestId/approve`

**Request Body**:
```json
{
  "organizationID": "Insurer1MSP",
  "approverID": "insurer1.admin",
  "comments": "Approved after verification"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Approval submitted successfully",
  "data": {
    "approvalCount": 2,
    "status": "APPROVED"
  }
}
```

**Chaincode**: `approval-manager.ApproveRequest`

---

### Reject Request

**Endpoint**: `POST /api/approvals/:requestId/reject`

**Request Body**:
```json
{
  "organizationID": "Insurer1MSP",
  "approverID": "insurer1.admin",
  "reason": "Insufficient documentation"
}
```

**Chaincode**: `approval-manager.RejectRequest`

---

### Execute Approved Request

Executes the approved policy/action and triggers auto-deposit.

**Endpoint**: `POST /api/approvals/:requestId/execute`

**Request Body**:
```json
{
  "executorID": "system.admin"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Approval executed successfully"
}
```

**Chaincode**: `approval-manager.ExecuteApprovedRequest`

**Side Effects**: Triggers premium auto-deposit to pool

---

### Get Approval History

**Endpoint**: `GET /api/approvals/:requestId/history`

**Chaincode**: `approval-manager.GetApprovalHistory`

---

## Claims API

### Trigger Claim

Creates a claim and triggers payout based on weather conditions.

**Endpoint**: `POST /api/claims`

**Request Body**:
```json
{
  "claimID": "CLAIM_001",
  "policyID": "POLICY_001",
  "farmerID": "FARMER_001",
  "weatherDataID": "WEATHER_001",
  "coverageAmount": 5000,
  "payoutPercent": 50
}
```

**Response**:
```json
{
  "success": true,
  "message": "Claim triggered successfully",
  "data": {
    "claimID": "CLAIM_001",
    "status": "Approved",
    "payoutAmount": 2500
  }
}
```

**Chaincode**: `claim-processor.TriggerPayout`

---

### Get All Claims

**Endpoint**: `GET /api/claims`

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "claimID": "CLAIM_001",
      "policyID": "POLICY_001",
      "farmerID": "FARMER_001",
      "status": "Approved",
      "payoutAmount": 2500,
      "createdAt": "2025-11-12T10:00:00Z"
    }
  ]
}
```

**Chaincode**: `claim-processor.GetAllClaims`

---

### Get Pending Claims

**Endpoint**: `GET /api/claims/pending`

**Chaincode**: `claim-processor.GetClaimsByStatus("Pending")`

---

### Get Claim by ID

**Endpoint**: `GET /api/claims/:claimId`

**Chaincode**: `claim-processor.GetClaim`

---

### Get Claims by Farmer

**Endpoint**: `GET /api/claims/farmer/:farmerId`

**Chaincode**: `claim-processor.GetClaimsByFarmer`

---

### Get Claims by Status

**Endpoint**: `GET /api/claims/status/:status`

**Parameters**: status = `Pending` | `Approved` | `Rejected`

**Chaincode**: `claim-processor.GetClaimsByStatus`

---

### Get Claim History

**Endpoint**: `GET /api/claims/:claimId/history`

**Chaincode**: `claim-processor.GetClaimHistory`

---

## Premium Pool API

### Get Pool Balance

**Endpoint**: `GET /api/premium-pool/balance`

**Response**:
```json
{
  "success": true,
  "data": 15000.50
}
```

**Chaincode**: `premium-pool.GetPoolBalance`

---

### Get Pool Stats

**Endpoint**: `GET /api/premium-pool/stats`

**Response**:
```json
{
  "success": true,
  "data": {
    "totalBalance": 15000.50,
    "totalDeposits": 20000.00,
    "totalPayouts": 4999.50,
    "transactionCount": 25,
    "lastUpdated": "2025-11-12T10:00:00Z"
  }
}
```

**Chaincode**: `premium-pool.GetPoolStats`

---

### Get Transaction History

**Endpoint**: `GET /api/premium-pool/history`

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "txID": "PREMIUM_POLICY_001_123",
      "type": "Premium",
      "policyID": "POLICY_001",
      "farmerID": "FARMER_001",
      "amount": 500,
      "balanceBefore": 14500.50,
      "balanceAfter": 15000.50,
      "status": "Completed",
      "timestamp": "2025-11-12T10:00:00Z"
    }
  ]
}
```

**Chaincode**: `premium-pool.GetTransactionHistory`

---

### Deposit Premium

**Endpoint**: `POST /api/premium-pool/deposit`

**Request Body**:
```json
{
  "amount": 500,
  "policyID": "POLICY_001",
  "farmerID": "FARMER_001"
}
```

**Chaincode**: `premium-pool.DepositPremium`

---

### Withdraw Funds (Execute Payout)

**Endpoint**: `POST /api/premium-pool/withdraw`

**Request Body**:
```json
{
  "amount": 2500,
  "recipient": "FARMER_001",
  "claimID": "CLAIM_001",
  "policyID": "POLICY_001"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Payout executed successfully",
  "data": {
    "txID": "PAYOUT_CLAIM_001_456",
    "amount": 2500,
    "newBalance": 12500.50
  }
}
```

**Chaincode**: `premium-pool.ExecutePayout`

**Validation**: Checks pool has sufficient balance

---

### Get Farmer Balance

**Endpoint**: `GET /api/premium-pool/farmer-balance/:farmerId`

**Chaincode**: `premium-pool.GetFarmerBalance`

---

## Weather Oracle API

### Submit Weather Data

**Endpoint**: `POST /api/weather-oracle`

**Request Body**:
```json
{
  "dataID": "WEATHER_001",
  "oracleID": "ORACLE_001",
  "location": "Singapore",
  "latitude": "1.3521",
  "longitude": "103.8198",
  "rainfall": 35.0,
  "temperature": 32.5,
  "humidity": 65.0,
  "windSpeed": 12.5,
  "recordedAt": "2025-11-12T10:00:00Z"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Weather data submitted successfully",
  "data": {
    "dataID": "WEATHER_001",
    "location": "Singapore"
  }
}
```

**Chaincode**: `weather-oracle.SubmitWeatherData`

---

### Get Weather Data by ID

**Endpoint**: `GET /api/weather-oracle/:dataId`

**Response**:
```json
{
  "success": true,
  "data": {
    "dataID": "WEATHER_001",
    "oracleID": "ORACLE_001",
    "location": "Singapore",
    "rainfall": 35.0,
    "temperature": 32.5,
    "timestamp": "2025-11-12T10:00:00Z"
  }
}
```

**Chaincode**: `weather-oracle.GetWeatherData`

---

### Get Weather by Location

**Endpoint**: `GET /api/weather-oracle/location/:location`

**Chaincode**: `weather-oracle.GetWeatherDataByLocation`

---

### Register Oracle Provider

**Endpoint**: `POST /api/weather-oracle/register-provider`

**Request Body**:
```json
{
  "oracleID": "ORACLE_001",
  "name": "Singapore Meteorological Service",
  "dataSource": "Official Weather Station",
  "location": "Singapore",
  "trustScore": 95
}
```

**Chaincode**: `weather-oracle.RegisterProvider`

---

### Get Oracle Provider

**Endpoint**: `GET /api/weather-oracle/provider/:oracleID`

**Chaincode**: `weather-oracle.GetOracleProvider`

---

### Validate Consensus

**Endpoint**: `POST /api/weather-oracle/validate-consensus`

**Request Body**:
```json
{
  "location": "Singapore",
  "dataIDs": ["WEATHER_001", "WEATHER_002"]
}
```

**Chaincode**: `weather-oracle.ValidateConsensus`

---

## Farmers API

### Register Farmer

**Endpoint**: `POST /api/farmers`

**Request Body**:
```json
{
  "farmerID": "FARMER_001",
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+65-9876-5432",
  "location": "Singapore",
  "farmSize": 5.5,
  "cropTypes": ["Rice", "Vegetables"],
  "cooperativeID": "COOP001"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Farmer registered successfully",
  "data": {
    "farmerID": "FARMER_001",
    "name": "John Doe"
  }
}
```

**Chaincode**: `farmer.RegisterFarmer`

---

### Get All Farmers

**Endpoint**: `GET /api/farmers`

**Chaincode**: `farmer.GetAllFarmers`

---

### Get Farmer by ID

**Endpoint**: `GET /api/farmers/:farmerId`

**Chaincode**: `farmer.GetFarmer`

---

### Get Farmers by Cooperative

**Endpoint**: `GET /api/farmers/by-coop/:coopId`

**Chaincode**: `farmer.GetFarmersByCoop`

---

### Get Farmers by Region

**Endpoint**: `GET /api/farmers/by-region/:region`

**Chaincode**: `farmer.GetFarmersByRegion`

---

### Update Farmer

**Endpoint**: `PUT /api/farmers/:farmerId`

**Request Body**: Partial farmer object

**Chaincode**: `farmer.UpdateFarmer`

---

## Dashboard API

### Get Dashboard Stats

**Endpoint**: `GET /api/dashboard/stats`

**Response**:
```json
{
  "success": true,
  "data": {
    "totalFarmers": 150,
    "activePolicies": 89,
    "triggeredClaims": 23,
    "poolBalance": 15000.50,
    "totalDeposits": 45000.00,
    "totalPayouts": 29999.50
  }
}
```

**Aggregates data from multiple chaincodes**

---

### Get Recent Transactions

**Endpoint**: `GET /api/dashboard/transactions`

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "type": "Premium",
      "amount": 500,
      "timestamp": "2025-11-12T10:00:00Z"
    },
    {
      "type": "Payout",
      "amount": 2500,
      "timestamp": "2025-11-12T09:30:00Z"
    }
  ]
}
```

---

## Policy Templates API

### Get All Templates

**Endpoint**: `GET /api/policy-templates`

**Chaincode**: `policy-template.GetAllTemplates`

---

### Get Template by ID

**Endpoint**: `GET /api/policy-templates/:templateId`

**Chaincode**: `policy-template.GetTemplate`

---

### Get Templates by Crop

**Endpoint**: `GET /api/policy-templates/by-crop/:cropType`

**Chaincode**: `policy-template.GetTemplatesByCrop`

---

### Get Templates by Region

**Endpoint**: `GET /api/policy-templates/by-region/:region`

**Chaincode**: `policy-template.GetTemplatesByRegion`

---

### Get Template Thresholds

**Endpoint**: `GET /api/policy-templates/:templateId/thresholds`

**Chaincode**: `policy-template.GetTemplateThresholds`

---

## Error Handling

### Error Response Format

```json
{
  "success": false,
  "error": "Error message",
  "details": "Detailed error information"
}
```

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| **200** | Success |
| **201** | Created |
| **400** | Bad Request (validation error) |
| **404** | Not Found |
| **500** | Internal Server Error |

### Common Errors

#### 1. Validation Error (400)
```json
{
  "success": false,
  "error": "policyID, farmerID, and coverageAmount are required"
}
```

#### 2. Not Found (404)
```json
{
  "success": false,
  "error": "Policy POLICY_001 not found"
}
```

#### 3. Chaincode Error (500)
```json
{
  "success": false,
  "error": "Failed to submit transaction",
  "details": "insufficient pool balance: have 3000.00, need 5000.00"
}
```

#### 4. Endorsement Policy Failure (500)
```json
{
  "success": false,
  "error": "Endorsement policy failure",
  "details": "failed to endorse transaction, see attached details for more info"
}
```

---

## Fabric Integration

### Fabric Gateway Service

**File**: `src/services/fabricGateway.ts`

#### Submit Transaction (Write)
```typescript
await fabricGateway.submitTransaction(
  'premium-pool',           // Chaincode name
  'ExecutePayout',          // Function name
  txID,                     // Arg 1
  farmerID,                 // Arg 2
  policyID,                 // Arg 3
  claimID,                  // Arg 4
  amount.toString()         // Arg 5
);
```

#### Evaluate Transaction (Read)
```typescript
const result = await fabricGateway.evaluateTransaction(
  'policy',                 // Chaincode name
  'GetPolicy',              // Function name
  policyId                  // Arg 1
);

const policy = JSON.parse(result.toString());
```

### Connection Profile

**Location**: `network/connection-profile.json`

**Contains**:
- Peer endpoints
- Orderer endpoints
- CA endpoints
- TLS certificates
- Organization configurations

### Identity Management

**Wallet Location**: `network/wallets/`

**Organizations**:
- CoopMSP
- Insurer1MSP
- Insurer2MSP

---

## Development

### Project Structure

```
api-gateway/
├── src/
│   ├── controllers/       # Route handlers
│   │   ├── policy.controller.ts
│   │   ├── approval.controller.ts
│   │   ├── claim.controller.ts
│   │   └── ...
│   ├── routes/           # Route definitions
│   │   ├── policy.routes.ts
│   │   ├── approval.routes.ts
│   │   └── ...
│   ├── services/         # Business logic
│   │   └── fabricGateway.ts
│   ├── middleware/       # Express middleware
│   │   └── errorHandler.ts
│   ├── config/           # Configuration
│   │   └── index.ts
│   └── index.ts          # Entry point
├── package.json
├── tsconfig.json
└── .env
```

### Adding a New Endpoint

1. **Create controller** in `src/controllers/`:
```typescript
// myController.ts
export const myFunction = async (req: Request, res: Response) => {
  const result = await fabricGateway.submitTransaction(
    'chaincode-name',
    'FunctionName',
    ...args
  );
  
  res.json({
    success: true,
    data: JSON.parse(result.toString())
  });
};
```

2. **Create route** in `src/routes/`:
```typescript
// myRoutes.ts
import * as controller from '../controllers/myController';

router.post('/my-endpoint', controller.myFunction);
```

3. **Register route** in `src/index.ts`:
```typescript
import myRoutes from './routes/myRoutes';
app.use('/api/my-resource', myRoutes);
```

### Testing Endpoints

```bash
# Using curl
curl -X POST http://localhost:3001/api/policies \
  -H "Content-Type: application/json" \
  -d '{"policyID": "TEST_001", ...}'

# Using httpie
http POST localhost:3001/api/policies policyID=TEST_001 ...

# Using Postman
Import the API collection (if available)
```

### Debugging

**Enable debug logs**:
```bash
DEBUG=* npm run dev
```

**Check Fabric logs**:
```bash
docker logs peer0.insurer1.example.com
```

---

## Best Practices

### 1. Always Validate Input
```typescript
if (!policyID || !farmerID) {
  throw new ApiError(400, 'Required fields missing');
}
```

### 2. Use asyncHandler for Error Handling
```typescript
export const myFunction = asyncHandler(async (req, res) => {
  // Your code - errors automatically caught
});
```

### 3. Parse Blockchain Responses
```typescript
const result = await fabricGateway.evaluateTransaction(...);
const data = JSON.parse(result.toString());
```

### 4. Return Consistent Responses
```typescript
res.json({
  success: true,
  data: result,
  message: 'Operation successful'
});
```

---

## Additional Resources

- **Hyperledger Fabric Docs**: https://hyperledger-fabric.readthedocs.io
- **Express Docs**: https://expressjs.com
- **TypeScript Docs**: https://www.typescriptlang.org

---

**Version**: 1.0.0  
**Last Updated**: November 2025
