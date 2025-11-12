# ⛓️ Chaincode Documentation

Complete reference for all smart contracts (chaincode) in the Weather Index Insurance Platform.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Endorsement Policies](#endorsement-policies)
4. [Policy Chaincode](#policy-chaincode)
5. [Approval Manager Chaincode](#approval-manager-chaincode)
6. [Premium Pool Chaincode](#premium-pool-chaincode)
7. [Claim Processor Chaincode](#claim-processor-chaincode)
8. [Weather Oracle Chaincode](#weather-oracle-chaincode)
9. [Farmer Chaincode](#farmer-chaincode)
10. [Development Guide](#development-guide)

---

## Overview

All smart contracts are written in **Go** using the Hyperledger Fabric Contract API.

### Chaincode List

| Chaincode | Version | Purpose |
|-----------|---------|---------|
| **policy** | v3 | Policy lifecycle management |
| **approval-manager** | v3 | Multi-org approval workflow |
| **premium-pool** | v3 | Financial operations (deposits/payouts) |
| **claim-processor** | v3 | Claims and payout processing |
| **weather-oracle** | v3 | Weather data management |
| **farmer** | v3 | Farmer registry |

---

## Architecture

### Data Flow

```
Policy Creation
     ↓
Approval Manager (2 insurers approve)
     ↓
Policy Activated
     ↓
Premium Auto-Deposit → Premium Pool
     ↓
Weather Data Submitted → Weather Oracle
     ↓
Claim Triggered → Claim Processor
     ↓
Payout Executed → Premium Pool (withdraw)
```

### World State Storage

Each chaincode maintains its own state in the blockchain:

```
Key Format: <TYPE>_<ID>

Examples:
- POLICY_POLICY_001
- APPROVAL_POL_REQ_123
- CLAIM_CLAIM_001
- WEATHER_WEATHER_001
- FARMER_FARMER_001
```

---

## Endorsement Policies

### Overview

Endorsement policies define which organizations must approve a transaction.

### Policy Definitions

#### Policy Operations
```
OR('Insurer1MSP.peer', 'Insurer2MSP.peer', 'CoopMSP.peer')
```
**Meaning**: Any ONE of the three organizations can endorse policy transactions.

#### Approval Operations
```
AND('Insurer1MSP.peer', 'Insurer2MSP.peer')
```
**Meaning**: BOTH Insurer1 AND Insurer2 must endorse approval transactions.

#### Premium Pool Operations
```
OR('Insurer1MSP.peer', 'Insurer2MSP.peer')
```
**Meaning**: Either insurer can endorse pool operations.

#### Claim Processing
```
OR('Insurer1MSP.peer', 'Insurer2MSP.peer')
```
**Meaning**: Either insurer can endorse claims.

#### Weather Oracle
```
OR('Insurer1MSP.peer', 'Insurer2MSP.peer', 'CoopMSP.peer')
```
**Meaning**: Any organization can submit weather data.

#### Farmer Management
```
OR('CoopMSP.peer', 'Insurer1MSP.peer')
```
**Meaning**: Cooperative or Insurer1 can manage farmers.

---

## Policy Chaincode

**Package**: `policy`  
**Version**: v3  
**File**: `chaincode/policy/policy.go`

### Data Structures

#### Policy
```go
type Policy struct {
    PolicyID        string    `json:"policyID"`
    FarmerID        string    `json:"farmerID"`
    TemplateID      string    `json:"templateID"`
    CoopID          string    `json:"coopID"`
    InsurerID       string    `json:"insurerID"`
    CoverageAmount  float64   `json:"coverageAmount"`
    PremiumAmount   float64   `json:"premiumAmount"`
    CoverageDays    int       `json:"coverageDays"`
    FarmLocation    string    `json:"farmLocation"`
    CropType        string    `json:"cropType"`
    FarmSize        float64   `json:"farmSize"`
    Status          string    `json:"status"` // Pending, Active, Expired, Cancelled
    CreatedAt       time.Time `json:"createdAt"`
    ActivatedAt     time.Time `json:"activatedAt"`
    ExpiresAt       time.Time `json:"expiresAt"`
}
```

### Functions

#### CreatePolicy
**Purpose**: Create a new insurance policy

**Signature**:
```go
func CreatePolicy(ctx, policyID, farmerID, templateID, coopID, insurerID string,
    coverageAmount, premiumAmount float64, coverageDays int,
    farmLocation, cropType string, farmSize float64, policyTermsHash string) error
```

**Parameters**:
- `policyID`: Unique policy identifier
- `farmerID`: Farmer's ID
- `templateID`: Policy template ID
- `coopID`: Cooperative ID
- `insurerID`: Insurer ID
- `coverageAmount`: Coverage amount in currency
- `premiumAmount`: Premium to pay
- `coverageDays`: Duration in days
- `farmLocation`: GPS coordinates
- `cropType`: Type of crop (Rice, Vegetables, etc.)
- `farmSize`: Farm size in hectares
- `policyTermsHash`: Hash of policy terms

**Returns**: Error if validation fails

**World State**: Stores policy with key `POLICY_{policyID}`

---

#### GetPolicy
**Purpose**: Retrieve policy by ID

**Signature**:
```go
func GetPolicy(ctx, policyID string) (*Policy, error)
```

**Returns**: Policy object or error

---

#### GetAllPolicies
**Purpose**: Get all policies

**Signature**:
```go
func GetAllPolicies(ctx) ([]*Policy, error)
```

**Returns**: Array of all policies

---

#### UpdatePolicyStatus
**Purpose**: Update policy status

**Signature**:
```go
func UpdatePolicyStatus(ctx, policyID, status string) error
```

**Valid Statuses**:
- `Pending` - Awaiting approval
- `Active` - Coverage in effect
- `Expired` - Coverage ended
- `Cancelled` - Policy cancelled

---

#### GetPoliciesByFarmer
**Purpose**: Get all policies for a farmer

**Signature**:
```go
func GetPoliciesByFarmer(ctx, farmerID string) ([]*Policy, error)
```

---

## Approval Manager Chaincode

**Package**: `approval-manager`  
**Version**: v3  
**File**: `chaincode/approval-manager/approvalmanager.go`

### Data Structures

#### ApprovalRequest
```go
type ApprovalRequest struct {
    RequestID         string                  `json:"requestID"`
    RequestType       string                  `json:"requestType"`
    TargetChaincode   string                  `json:"targetChaincode"`
    TargetFunction    string                  `json:"targetFunction"`
    FunctionArgs      []string                `json:"functionArgs"`
    RequiredOrgs      []string                `json:"requiredOrgs"`
    Approvals         map[string]Approval     `json:"approvals"`
    Status            string                  `json:"status"` // PENDING, APPROVED, REJECTED, EXECUTED
    Metadata          map[string]string       `json:"metadata"`
    CreatedAt         time.Time               `json:"createdAt"`
    UpdatedAt         time.Time               `json:"updatedAt"`
}
```

#### Approval
```go
type Approval struct {
    OrganizationID string    `json:"organizationID"`
    ApproverID     string    `json:"approverID"`
    Decision       string    `json:"decision"` // APPROVED, REJECTED
    Timestamp      time.Time `json:"timestamp"`
    Comments       string    `json:"comments"`
}
```

### Functions

#### CreateApprovalRequest
**Purpose**: Create a new approval request

**Signature**:
```go
func CreateApprovalRequest(ctx, requestID, requestType, targetChaincode,
    targetFunction, functionArgsJSON, requiredOrgsJSON, metadataJSON string) error
```

**Parameters**:
- `requestID`: Unique request identifier
- `requestType`: Type of request (e.g., "POLICY_CREATION")
- `targetChaincode`: Chaincode to execute after approval
- `targetFunction`: Function to call after approval
- `functionArgsJSON`: JSON array of function arguments
- `requiredOrgsJSON`: JSON array of required organizations
- `metadataJSON`: JSON object with additional data

**Example**:
```go
CreateApprovalRequest(
    ctx,
    "POL_REQ_123",
    "POLICY_CREATION",
    "policy",
    "CreatePolicy",
    `["POLICY_001", "FARMER_001", ...]`,
    `["Insurer1MSP", "Insurer2MSP"]`,
    `{"policyID": "POLICY_001", "farmerID": "FARMER_001"}`
)
```

---

#### ApproveRequest
**Purpose**: Approve a request

**Signature**:
```go
func ApproveRequest(ctx, requestID, organizationID, approverID, comments string) error
```

**Logic**:
1. Validates request exists and is PENDING
2. Verifies caller is from specified organization
3. Records approval with timestamp
4. If all required orgs approved → Status = APPROVED
5. Returns error if already approved by this org

---

#### RejectRequest
**Purpose**: Reject a request

**Signature**:
```go
func RejectRequest(ctx, requestID, organizationID, approverID, reason string) error
```

**Result**: Sets status to REJECTED, request cannot be executed

---

#### ExecuteApprovedRequest
**Purpose**: Execute the approved action

**Signature**:
```go
func ExecuteApprovedRequest(ctx, requestID, executorID string) error
```

**Logic**:
1. Validates request status is APPROVED
2. Calls target chaincode function with stored args
3. If target is policy creation → Triggers auto-deposit
4. Sets status to EXECUTED
5. Returns error if execution fails

**Auto-Deposit Trigger**:
```go
// If policy creation, trigger premium deposit
if request.TargetChaincode == "policy" && request.TargetFunction == "CreatePolicy" {
    // Extract policyID and premium from metadata
    // Call premium-pool.DepositPremium
}
```

---

#### GetApprovalRequest
**Purpose**: Get approval request details

**Signature**:
```go
func GetApprovalRequest(ctx, requestID string) (*ApprovalRequest, error)
```

---

#### GetAllApprovalRequests
**Purpose**: Get all approval requests

**Signature**:
```go
func GetAllApprovalRequests(ctx) ([]*ApprovalRequest, error)
```

---

#### GetPendingApprovals
**Purpose**: Get requests with PENDING status

**Signature**:
```go
func GetPendingApprovals(ctx) ([]*ApprovalRequest, error)
```

---

#### GetApprovalHistory
**Purpose**: Get approval history for a request

**Signature**:
```go
func GetApprovalHistory(ctx, requestID string) ([]*ApprovalAction, error)
```

---

## Premium Pool Chaincode

**Package**: `premium-pool`  
**Version**: v3  
**File**: `chaincode/premium-pool/premiumpool.go`

### Data Structures

#### PremiumPool
```go
type PremiumPool struct {
    PoolID         string    `json:"poolID"`
    TotalBalance   float64   `json:"totalBalance"`
    TotalPremiums  float64   `json:"totalPremiums"`
    TotalPayouts   float64   `json:"totalPayouts"`
    ReserveAmount  float64   `json:"reserveAmount"`
    ActivePolicies int       `json:"activePolicies"`
    LastUpdated    time.Time `json:"lastUpdated"`
}
```

#### Transaction
```go
type Transaction struct {
    TxID          string    `json:"txID"`
    Type          string    `json:"type"` // Premium, Payout
    FarmerID      string    `json:"farmerID"`
    PolicyID      string    `json:"policyID"`
    Amount        float64   `json:"amount"`
    BalanceBefore float64   `json:"balanceBefore"`
    BalanceAfter  float64   `json:"balanceAfter"`
    Status        string    `json:"status"` // Completed, Pending, Failed
    Timestamp     time.Time `json:"timestamp"`
    InitiatedBy   string    `json:"initiatedBy"`
    Notes         string    `json:"notes"`
}
```

### Functions

#### DepositPremium
**Purpose**: Deposit premium to pool

**Signature**:
```go
func DepositPremium(ctx, txID, farmerID, policyID string, amount float64) error
```

**Logic**:
1. Validates amount > 0
2. Gets current pool state
3. Creates transaction record with type "Premium"
4. Updates pool balance: `balance += amount`
5. Updates totalPremiums
6. Stores transaction in ledger

**World State Keys**:
- Pool: `POOL_MAIN_POOL`
- Transaction: `TRANSACTION_{txID}`

---

#### ExecutePayout
**Purpose**: Execute payout for claim

**Signature**:
```go
func ExecutePayout(ctx, txID, farmerID, policyID, claimID string, amount float64) error
```

**Logic**:
1. Validates amount > 0
2. Gets current pool state
3. **Validates sufficient balance**: `pool.TotalBalance >= amount`
4. If insufficient → Returns error
5. Creates transaction record with type "Payout"
6. Updates pool balance: `balance -= amount`
7. Updates totalPayouts
8. Stores transaction in ledger

**Validation Example**:
```go
if pool.TotalBalance < amount {
    return fmt.Errorf("insufficient pool balance: have %.2f, need %.2f", 
                     pool.TotalBalance, amount)
}
```

---

#### GetPoolBalance
**Purpose**: Get current pool balance

**Signature**:
```go
func GetPoolBalance(ctx) (float64, error)
```

**Returns**: Current balance as float64

---

#### GetPoolStats
**Purpose**: Get pool statistics

**Signature**:
```go
func GetPoolStats(ctx) (*PremiumPool, error)
```

**Returns**: Complete pool state with all metrics

---

#### GetTransactionHistory
**Purpose**: Get all transactions

**Signature**:
```go
func GetTransactionHistory(ctx) ([]*Transaction, error)
```

**Returns**: Array of all transactions sorted by timestamp

---

## Claim Processor Chaincode

**Package**: `claim-processor`  
**Version**: v3  
**File**: `chaincode/claim-processor/claimprocessor.go`

### Data Structures

#### Claim
```go
type Claim struct {
    ClaimID         string    `json:"claimID"`
    PolicyID        string    `json:"policyID"`
    FarmerID        string    `json:"farmerID"`
    IndexDataID     string    `json:"indexDataID"`
    CoverageAmount  float64   `json:"coverageAmount"`
    PayoutPercent   int       `json:"payoutPercent"`
    PayoutAmount    float64   `json:"payoutAmount"`
    Status          string    `json:"status"` // Pending, Approved, Rejected, Paid
    CreatedAt       time.Time `json:"createdAt"`
    ProcessedAt     time.Time `json:"processedAt"`
    Notes           string    `json:"notes"`
}
```

### Functions

#### TriggerPayout
**Purpose**: Trigger automatic payout based on weather index

**Signature**:
```go
func TriggerPayout(ctx, claimID, policyID, farmerID, indexDataID string,
    coverageAmount float64, payoutPercent int) error
```

**Parameters**:
- `claimID`: Unique claim identifier
- `policyID`: Associated policy
- `farmerID`: Farmer receiving payout
- `indexDataID`: Weather data that triggered claim
- `coverageAmount`: Total coverage amount
- `payoutPercent`: Percentage to payout (e.g., 50 = 50%)

**Logic**:
1. Validates inputs
2. Calculates payout: `amount = (coverageAmount * payoutPercent) / 100`
3. Creates claim with status "Approved"
4. Stores claim in ledger
5. Returns claim details

**Example**:
```go
TriggerPayout(ctx, "CLAIM_001", "POLICY_001", "FARMER_001", "WEATHER_001", 5000, 50)
// Calculates: 5000 * 0.50 = 2500 payout
```

---

#### ProcessClaim
**Purpose**: Manually approve/reject claim

**Signature**:
```go
func ProcessClaim(ctx, claimID string, approved bool, payoutAmount float64) error
```

**Logic**:
- If approved → Status = "Approved", records payout amount
- If rejected → Status = "Rejected", no payout

---

#### GetClaim
**Purpose**: Get claim by ID

**Signature**:
```go
func GetClaim(ctx, claimID string) (*Claim, error)
```

---

#### GetAllClaims
**Purpose**: Get all claims

**Signature**:
```go
func GetAllClaims(ctx) ([]*Claim, error)
```

---

#### GetClaimsByFarmer
**Purpose**: Get claims for a farmer

**Signature**:
```go
func GetClaimsByFarmer(ctx, farmerID string) ([]*Claim, error)
```

---

#### GetClaimsByStatus
**Purpose**: Get claims by status

**Signature**:
```go
func GetClaimsByStatus(ctx, status string) ([]*Claim, error)
```

**Valid Statuses**: Pending, Approved, Rejected, Paid

---

## Weather Oracle Chaincode

**Package**: `weather-oracle`  
**Version**: v3  
**File**: `chaincode/weather-oracle/weatheroracle.go`

### Data Structures

#### WeatherData
```go
type WeatherData struct {
    DataID      string    `json:"dataID"`
    OracleID    string    `json:"oracleID"`
    Location    string    `json:"location"`
    Latitude    string    `json:"latitude"`
    Longitude   string    `json:"longitude"`
    Rainfall    float64   `json:"rainfall"`    // mm
    Temperature float64   `json:"temperature"` // Celsius
    Humidity    float64   `json:"humidity"`    // %
    WindSpeed   float64   `json:"windSpeed"`   // km/h
    Timestamp   time.Time `json:"timestamp"`
    RecordedAt  time.Time `json:"recordedAt"`
}
```

#### OracleProvider
```go
type OracleProvider struct {
    OracleID    string  `json:"oracleID"`
    Name        string  `json:"name"`
    DataSource  string  `json:"dataSource"`
    Location    string  `json:"location"`
    TrustScore  int     `json:"trustScore"` // 0-100
    IsActive    bool    `json:"isActive"`
}
```

### Functions

#### SubmitWeatherData
**Purpose**: Submit weather data

**Signature**:
```go
func SubmitWeatherData(ctx, dataID, oracleID, location, latitude, longitude string,
    rainfall, temperature, humidity, windSpeed float64, recordedAt string) error
```

**Logic**:
1. Validates all fields present
2. Parses recordedAt timestamp
3. Creates WeatherData object
4. Stores in ledger with key `WEATHER_{dataID}`

---

#### RegisterProvider
**Purpose**: Register oracle provider

**Signature**:
```go
func RegisterProvider(ctx, oracleID, name, dataSource, location string, trustScore int) error
```

**Validation**:
- Trust score must be 0-100
- OracleID must be unique

---

#### GetWeatherData
**Purpose**: Get weather data by ID

**Signature**:
```go
func GetWeatherData(ctx, dataID string) (*WeatherData, error)
```

---

#### GetWeatherDataByLocation
**Purpose**: Get all weather data for a location

**Signature**:
```go
func GetWeatherDataByLocation(ctx, location string) ([]*WeatherData, error)
```

---

#### GetOracleProvider
**Purpose**: Get oracle provider details

**Signature**:
```go
func GetOracleProvider(ctx, oracleID string) (*OracleProvider, error)
```

---

## Farmer Chaincode

**Package**: `farmer`  
**Version**: v3  
**File**: `chaincode/farmer/farmer.go`

### Data Structures

#### Farmer
```go
type Farmer struct {
    FarmerID       string    `json:"farmerID"`
    Name           string    `json:"name"`
    Email          string    `json:"email"`
    Phone          string    `json:"phone"`
    Location       string    `json:"location"`
    FarmSize       float64   `json:"farmSize"` // hectares
    CropTypes      []string  `json:"cropTypes"`
    CooperativeID  string    `json:"cooperativeID"`
    RegisteredAt   time.Time `json:"registeredAt"`
    IsActive       bool      `json:"isActive"`
}
```

### Functions

#### RegisterFarmer
**Purpose**: Register new farmer

**Signature**:
```go
func RegisterFarmer(ctx, farmerID, name, email, phone, location string,
    farmSize float64, cropTypesJSON, cooperativeID string) error
```

**Parameters**:
- `cropTypesJSON`: JSON array of crop types, e.g., `["Rice", "Vegetables"]`

---

#### GetFarmer
**Purpose**: Get farmer by ID

**Signature**:
```go
func GetFarmer(ctx, farmerID string) (*Farmer, error)
```

---

#### GetAllFarmers
**Purpose**: Get all farmers

**Signature**:
```go
func GetAllFarmers(ctx) ([]*Farmer, error)
```

---

#### GetFarmersByCoop
**Purpose**: Get farmers by cooperative

**Signature**:
```go
func GetFarmersByCoop(ctx, coopID string) ([]*Farmer, error)
```

---

#### UpdateFarmer
**Purpose**: Update farmer details

**Signature**:
```go
func UpdateFarmer(ctx, farmerID, updatesJSON string) error
```

**Parameters**:
- `updatesJSON`: JSON object with fields to update

---

## Development Guide

### Building Chaincode

#### Prerequisites
- Go 1.20 or higher
- Fabric binaries

#### Build Steps

```bash
cd chaincode/policy
go mod tidy
go build
```

### Testing Chaincode

#### Unit Testing
```go
// policy_test.go
func TestCreatePolicy(t *testing.T) {
    ctx := &mockTransactionContext{}
    pc := new(PolicyChaincode)
    
    err := pc.CreatePolicy(ctx, "POLICY_001", ...)
    assert.Nil(t, err)
}
```

#### Running Tests
```bash
go test ./...
```

### Deploying Chaincode

#### Package Chaincode
```bash
peer lifecycle chaincode package policy.tar.gz \
  --path ./chaincode/policy \
  --lang golang \
  --label policy_1
```

#### Install on Peer
```bash
peer lifecycle chaincode install policy.tar.gz
```

#### Approve for Organization
```bash
peer lifecycle chaincode approveformyorg \
  --channelID insurance-channel \
  --name policy \
  --version 1.0 \
  --package-id policy_1:hash... \
  --sequence 1
```

#### Commit to Channel
```bash
peer lifecycle chaincode commit \
  --channelID insurance-channel \
  --name policy \
  --version 1.0 \
  --sequence 1
```

### Adding New Functions

1. **Define function** in chaincode file:
```go
func (pc *PolicyChaincode) MyNewFunction(
    ctx contractapi.TransactionContextInterface,
    arg1 string, arg2 int) error {
    
    // Validation
    if arg1 == "" {
        return fmt.Errorf("arg1 required")
    }
    
    // Business logic
    // ...
    
    // Store in ledger
    dataJSON, _ := json.Marshal(data)
    return ctx.GetStub().PutState(key, dataJSON)
}
```

2. **Update version** and redeploy

3. **Update API Gateway** controller to call new function

### Best Practices

1. **Always validate inputs**
```go
if amount <= 0 {
    return fmt.Errorf("amount must be positive")
}
```

2. **Use composite keys for queries**
```go
key, _ := ctx.GetStub().CreateCompositeKey("POLICY", []string{policyID})
```

3. **Handle errors gracefully**
```go
data, err := ctx.GetStub().GetState(key)
if err != nil {
    return fmt.Errorf("failed to read from world state: %v", err)
}
```

4. **Use deterministic timestamps**
```go
txTimestamp, _ := ctx.GetStub().GetTxTimestamp()
timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))
```

---

## Additional Resources

- **Fabric Contract API**: https://godoc.org/github.com/hyperledger/fabric-contract-api-go
- **Fabric Chaincode Tutorials**: https://hyperledger-fabric.readthedocs.io

---

**Version**: 1.0.0  
**Last Updated**: November 2025
