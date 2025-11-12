# Endorsement & Multi-Party Approval Architecture

## 📋 Current State Analysis

### What Currently Exists

#### 1. **Network-Level Endorsement (Hyperledger Fabric)**

The system uses Hyperledger Fabric's built-in endorsement policies at the **network configuration level**:

**Organizations in the Network:**
- `Insurer1MSP` - Insurance Company 1
- `Insurer2MSP` - Insurance Company 2  
- `CoopMSP` - Farmers Cooperative
- `PlatformMSP` - Platform Administrator

**Current Default Endorsement:**
```yaml
# From configtx.yaml - each org has:
Endorsement:
  Type: Signature
  Rule: "OR('Insurer1MSP.peer')"  # Any single peer from org can endorse
```

**Problem:** Currently uses **default endorsement** = ANY single peer can approve ANY transaction. This is too permissive for a multi-stakeholder insurance platform.

#### 2. **Identity Tracking (Partial)**

Chaincodes already track **who initiated** transactions:
```go
callerID, err := ctx.GetClientIdentity().GetID()  // Gets caller's certificate
mspID, err := ctx.GetClientIdentity().GetMSPID() // Gets org membership
```

But this is only for **audit logging**, not for **approval workflows**.

#### 3. **Access Control Chaincode**

Basic infrastructure exists in `chaincode/access-control/accesscontrol.go`:
- Organization registration
- Role management  
- Validator tracking
- But **NO multi-party approval logic**

---

## 🎯 What SHOULD Be Implemented

### Required Endorsement Policies by Transaction Type

📊 REQUIRED ENDORSEMENTS BY TRANSACTION TYPE:

  Transaction              | Who Must Approve
  ─────────────────────────┼──────────────────────────────────
  Register Farmer          | Coop + ANY Insurer (1 of 2)
  Create Policy            | Insurer + Coop
  Submit Weather Data      | 2 of 3 Oracle Providers (FINAL)
  Trigger Claim            | Automated (math-based, no approval)
  Withdraw Pool Funds      | Platform + 2 of 2 Insurers
  Emergency Actions        | Platform + ALL Insurers

  ⚠️  Note: Weather data from oracles is FINAL - no additional
      validation needed. Claims are FULLY AUTOMATED - trigger and
      execute automatically when conditions are met.

**Key Clarifications:**
- **Weather Data:** Oracles have final authority. No additional platform validation needed. Consensus achieved through 2-of-3 oracle agreement.
- **Claims:** Fully automated based on weather index triggers. No manual approval needed - if conditions are met, payout executes automatically.

---

## 🏗️ Implementation Architecture

### Level 1: Network-Level Endorsement Policies (Deploy-Time)

**Modify `deploy-network.sh` to specify endorsement policies per chaincode:**

```bash
# Example for weather-oracle chaincode
deploy_chaincode() {
    # ... existing code ...
    
    # Add endorsement policy flag
    local ENDORSEMENT_POLICY=""
    
    case "$CC_NAME" in
        "weather-oracle")
            # Require 2 of 3 oracle submissions
            ENDORSEMENT_POLICY="--signature-policy \"OR('Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')\""
            ;;
        "policy")
            # Require insurer + coop
            ENDORSEMENT_POLICY="--signature-policy \"AND('Insurer1MSP.peer','CoopMSP.peer')\""
            ;;
        "claim-processor")
            # Require 2 insurers for manual approval
            ENDORSEMENT_POLICY="--signature-policy \"AND('Insurer1MSP.peer','Insurer2MSP.peer')\""
            ;;
        "farmer")
            # Require coop + any insurer
            ENDORSEMENT_POLICY="--signature-policy \"AND('CoopMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))\""
            ;;
        *)
            # Default: any peer
            ENDORSEMENT_POLICY="--signature-policy \"OR('Insurer1MSP.peer','Insurer2MSP.peer','CoopMSP.peer','PlatformMSP.peer')\""
            ;;
    esac
    
    # Use in commit command
    docker exec ... peer lifecycle chaincode commit \
        ${ENDORSEMENT_POLICY} \
        # ... rest of flags
}
```

**Pros:** Enforced at protocol level, cannot be bypassed  
**Cons:** Fixed at deploy time, requires chaincode upgrade to change

---

### Level 2: Application-Level Approval Workflows (Chaincode Logic)

**Create new chaincode: `approval-manager`**

This implements **stateful multi-party approval** for transactions requiring human review:

```go
// ApprovalRequest tracks pending approvals
type ApprovalRequest struct {
    RequestID       string            `json:"requestID"`
    RequestType     string            `json:"requestType"` // FarmerRegistration, PolicyCreation, etc.
    TargetID        string            `json:"targetID"`    // ID of entity being approved
    InitiatedBy     string            `json:"initiatedBy"` // Who started the request
    InitiatedByOrg  string            `json:"initiatedByOrg"`
    RequiredApprovals map[string]bool `json:"requiredApprovals"` // Org -> approved?
    ApprovalThreshold int             `json:"approvalThreshold"` // How many needed
    CurrentApprovals  int             `json:"currentApprovals"`
    Status          string            `json:"status"` // Pending, Approved, Rejected
    CreatedDate     time.Time         `json:"createdDate"`
    ExpiryDate      time.Time         `json:"expiryDate"`
    Payload         string            `json:"payload"` // Serialized transaction data
}

// Example: Register Farmer with Approval
func (am *ApprovalManagerChaincode) RequestFarmerRegistration(
    ctx contractapi.TransactionContextInterface,
    farmerID string, farmerData string) (string, error) {
    
    // Get caller org
    callerOrg, _ := ctx.GetClientIdentity().GetMSPID()
    
    // Verify caller is Coop
    if callerOrg != "CoopMSP" {
        return "", fmt.Errorf("only Coop can initiate farmer registration")
    }
    
    // Create approval request
    requestID := "APPROVAL-" + farmerID + "-" + generateUUID()
    request := ApprovalRequest{
        RequestID:      requestID,
        RequestType:    "FarmerRegistration",
        TargetID:       farmerID,
        InitiatedBy:    callerID,
        InitiatedByOrg: callerOrg,
        RequiredApprovals: map[string]bool{
            "Insurer1MSP": false,
            "Insurer2MSP": false,
        },
        ApprovalThreshold: 1, // ANY one insurer
        CurrentApprovals:  0,
        Status:           "Pending",
        CreatedDate:      time.Now(),
        ExpiryDate:       time.Now().Add(72 * time.Hour), // 3 days
        Payload:          farmerData,
    }
    
    // Store request
    requestJSON, _ := json.Marshal(request)
    ctx.GetStub().PutState(requestID, requestJSON)
    
    // Emit event for notification
    ctx.GetStub().SetEvent("ApprovalRequested", requestJSON)
    
    return requestID, nil
}

// Approve a pending request
func (am *ApprovalManagerChaincode) ApproveRequest(
    ctx contractapi.TransactionContextInterface,
    requestID string) error {
    
    // Get request
    requestJSON, _ := ctx.GetStub().GetState(requestID)
    var request ApprovalRequest
    json.Unmarshal(requestJSON, &request)
    
    // Check if expired
    if time.Now().After(request.ExpiryDate) {
        request.Status = "Expired"
        // save and return error
    }
    
    // Get approver org
    approverOrg, _ := ctx.GetClientIdentity().GetMSPID()
    
    // Check if org is required approver
    if _, required := request.RequiredApprovals[approverOrg]; !required {
        return fmt.Errorf("your organization is not required to approve this request")
    }
    
    // Check if already approved
    if request.RequiredApprovals[approverOrg] {
        return fmt.Errorf("your organization has already approved this request")
    }
    
    // Record approval
    request.RequiredApprovals[approverOrg] = true
    request.CurrentApprovals++
    
    // Check if threshold met
    if request.CurrentApprovals >= request.ApprovalThreshold {
        request.Status = "Approved"
        
        // Execute the actual transaction
        err := am.executePendingTransaction(ctx, &request)
        if err != nil {
            request.Status = "Failed"
            return err
        }
        
        // Emit success event
        ctx.GetStub().SetEvent("ApprovalCompleted", requestJSON)
    }
    
    // Save updated request
    requestJSON, _ = json.Marshal(request)
    ctx.GetStub().PutState(requestID, requestJSON)
    
    return nil
}

// Execute approved transaction
func (am *ApprovalManagerChaincode) executePendingTransaction(
    ctx contractapi.TransactionContextInterface,
    request *ApprovalRequest) error {
    
    switch request.RequestType {
    case "FarmerRegistration":
        // Call farmer chaincode to register
        // This is done via cross-chaincode invocation
        response := ctx.GetStub().InvokeChaincode(
            "farmer",
            [][]byte{[]byte("RegisterFarmer"), []byte(request.Payload)},
            "insurance-main")
        
        if response.Status != 200 {
            return fmt.Errorf("failed to register farmer: %s", response.Message)
        }
        
    case "PolicyCreation":
        // Invoke policy chaincode
        // ... similar pattern
        
    // ... other cases
    }
    
    return nil
}
```

---

### Level 3: Frontend Approval Dashboard

**Add to `insurance-ui/src/pages/`:**

#### `ApprovalsDashboard.tsx`

```typescript
export const ApprovalsDashboard: React.FC = () => {
  const [pendingApprovals, setPendingApprovals] = useState<ApprovalRequest[]>([]);
  const { userOrg } = useAuth();
  
  useEffect(() => {
    // Fetch approvals requiring action from user's org
    approvalService.getPendingApprovals(userOrg).then(setPendingApprovals);
  }, [userOrg]);
  
  const handleApprove = async (requestId: string) => {
    await approvalService.approveRequest(requestId);
    // Refresh list
  };
  
  const handleReject = async (requestId: string, reason: string) => {
    await approvalService.rejectRequest(requestId, reason);
  };
  
  return (
    <div>
      <h2>Pending Approvals</h2>
      <ApprovalList 
        approvals={pendingApprovals}
        onApprove={handleApprove}
        onReject={handleReject}
      />
    </div>
  );
};
```

#### Show approval status on entities:

```typescript
// When displaying a farmer
<FarmerCard farmer={farmer}>
  {farmer.approvalStatus === 'Pending' && (
    <Badge color="warning">
      Awaiting Approval ({farmer.currentApprovals}/{farmer.requiredApprovals})
    </Badge>
  )}
  {farmer.approvalStatus === 'Approved' && (
    <Badge color="success">Approved</Badge>
  )}
</FarmerCard>
```

---

### Level 4: API Gateway Support

**Add to `api-gateway/src/controllers/approval.controller.ts`:**

```typescript
export const requestFarmerApproval = asyncHandler(async (req: Request, res: Response) => {
  const { farmerID, farmerData } = req.body;
  
  const result = await fabricGateway.submitTransaction(
    'approval-manager',
    'RequestFarmerRegistration',
    farmerID,
    JSON.stringify(farmerData)
  );
  
  res.status(201).json({
    success: true,
    data: result,
    message: 'Approval request created. Awaiting insurer approval.'
  });
});

export const getPendingApprovals = asyncHandler(async (req: Request, res: Response) => {
  const { orgId } = req.params;
  
  const result = await fabricGateway.evaluateTransaction(
    'approval-manager',
    'GetPendingApprovalsByOrg',
    orgId
  );
  
  res.json({
    success: true,
    data: result || []
  });
});

export const approveRequest = asyncHandler(async (req: Request, res: Response) => {
  const { requestId } = req.params;
  
  const result = await fabricGateway.submitTransaction(
    'approval-manager',
    'ApproveRequest',
    requestId
  );
  
  res.json({
    success: true,
    message: 'Request approved successfully',
    data: result
  });
});
```

---

## 📊 Approval Flow Example: Weather Data Submission

### Current Flow (Insecure):
```
Oracle A → Submit Data → Blockchain ✅ (immediate)
```

### Proposed Flow (Secure):
```
Step 1: Oracle A → Submit Data → Creates "PendingWeatherData" record
Step 2: Oracle B → Submit Data → Validates against Oracle A (2/3 consensus check)
Step 3: Oracle C → Submit Data → Final consensus reached
Step 4: Automated → Weather data marked "Validated" → Available for use
```

**Implementation in `weather-oracle` chaincode:**

```go
type WeatherDataSubmission struct {
    DataID      string             `json:"dataID"`
    Location    string             `json:"location"`
    Temperature float64            `json:"temperature"`
    Rainfall    float64            `json:"rainfall"`
    Submissions map[string]bool    `json:"submissions"` // OracleID -> submitted?
    Threshold   int                `json:"threshold"`   // Required submissions
    Status      string             `json:"status"`      // Pending, Validated
}

func (woc *WeatherOracleChaincode) SubmitWeatherData(
    ctx contractapi.TransactionContextInterface,
    dataID string, location string, temperature float64, rainfall float64) error {
    
    // Get oracle identity
    oracleID, _ := ctx.GetClientIdentity().GetID()
    oracleOrg, _ := ctx.GetClientIdentity().GetMSPID()
    
    // Verify caller is an oracle
    if oracleOrg != "PlatformMSP" && oracleOrg != "Insurer1MSP" && oracleOrg != "Insurer2MSP" {
        return fmt.Errorf("only approved oracles can submit weather data")
    }
    
    // Get or create submission record
    submissionJSON, _ := ctx.GetStub().GetState("WEATHER_PENDING_" + dataID)
    var submission WeatherDataSubmission
    
    if submissionJSON == nil {
        // First submission
        submission = WeatherDataSubmission{
            DataID:      dataID,
            Location:    location,
            Temperature: temperature,
            Rainfall:    rainfall,
            Submissions: make(map[string]bool),
            Threshold:   2, // Require 2 oracle confirmations
            Status:      "Pending",
        }
    } else {
        json.Unmarshal(submissionJSON, &submission)
        
        // Verify data matches (within tolerance)
        if math.Abs(submission.Temperature - temperature) > 2.0 {
            return fmt.Errorf("temperature mismatch: expected ~%.1f, got %.1f", 
                submission.Temperature, temperature)
        }
        if math.Abs(submission.Rainfall - rainfall) > 5.0 {
            return fmt.Errorf("rainfall mismatch")
        }
    }
    
    // Record this oracle's submission
    submission.Submissions[oracleID] = true
    
    // Check if threshold met
    if len(submission.Submissions) >= submission.Threshold {
        submission.Status = "Validated"
        
        // Create final weather data record
        weatherData := WeatherData{
            DataID:      dataID,
            Location:    location,
            Temperature: submission.Temperature,
            Rainfall:    submission.Rainfall,
            Status:      "Validated",
            ValidatedBy: len(submission.Submissions),
        }
        
        weatherJSON, _ := json.Marshal(weatherData)
        ctx.GetStub().PutState("WEATHER_" + dataID, weatherJSON)
        
        // Emit event
        ctx.GetStub().SetEvent("WeatherDataValidated", weatherJSON)
    }
    
    // Save submission record
    submissionJSON, _ = json.Marshal(submission)
    ctx.GetStub().PutState("WEATHER_PENDING_" + dataID, submissionJSON)
    
    return nil
}
```

---

## 🚀 Implementation Roadmap

### Phase 1: Network-Level Policies (Quick Win)
**Time:** 2-3 hours  
**Files to modify:**
1. `deploy-network.sh` - Add `--signature-policy` flags
2. Re-deploy chaincodes with new policies

**Benefits:** Immediate endorsement enforcement at protocol level

---

### Phase 2: Approval Manager Chaincode (Core Feature)
**Time:** 1-2 days  
**New files:**
1. `chaincode/approval-manager/approvalmanager.go`
2. `chaincode/approval-manager/go.mod`

**Modified files:**
1. `deploy-network.sh` - Deploy approval-manager
2. Each chaincode - Integrate with approval manager

---

### Phase 3: Frontend Approvals Dashboard  
**Time:** 1-2 days  
**New files:**
1. `insurance-ui/src/pages/Approvals.tsx`
2. `insurance-ui/src/services/approval.service.ts`
3. `insurance-ui/src/components/ApprovalCard.tsx`

**Modified files:**
1. Navigation - Add "Approvals" link
2. Entity pages - Show approval status

---

### Phase 4: API Gateway Integration
**Time:** 4-6 hours  
**New files:**
1. `api-gateway/src/controllers/approval.controller.ts`
2. `api-gateway/src/routes/approval.routes.ts`

---

### Phase 5: Notification System
**Time:** 1 day  
**Features:**
- Email/webhook when approval needed
- In-app notifications
- Approval deadline reminders

---

## 📈 Endorsement Policy Cheat Sheet

### Fabric Policy Syntax

```bash
# Single org
--signature-policy "OR('Insurer1MSP.peer')"

# Any of multiple orgs
--signature-policy "OR('Insurer1MSP.peer','Insurer2MSP.peer')"

# ALL orgs required
--signature-policy "AND('Insurer1MSP.peer','Insurer2MSP.peer')"

# Complex: 2 of 3
--signature-policy "OutOf(2,'Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')"

# Mixed: Insurer1 + (Coop OR Platform)
--signature-policy "AND('Insurer1MSP.peer',OR('CoopMSP.peer','PlatformMSP.peer'))"
```

---

## 🔐 Security Benefits

1. **Prevents Single-Point Manipulation:**
   - Weather data requires 2+ independent sources
   - Claims require insurer consensus

2. **Auditability:**
   - Every approval is recorded on-chain
   - Can trace who approved what and when

3. **Compliance:**
   - Meets regulatory requirements for multi-party approval
   - Immutable audit trail

4. **Trust:**
   - Farmers see transparent approval process
   - Insurers cannot act unilaterally

---

## 📝 Current vs. Proposed

| Aspect | Current | Proposed |
|--------|---------|----------|
| **Farmer Registration** | Any org can add | Coop + Insurer approval |
| **Policy Creation** | Any insurer | Insurer + Coop + Farmer |
| **Weather Data** | Single oracle | 2 of 3 oracles |
| **Claim Approval** | Automated only | Auto OR 2-insurer manual |
| **Fund Withdrawal** | Any org | Platform + Majority |
| **Approval UI** | None | Dashboard with pending items |
| **Notifications** | None | Email/webhook alerts |

---

## 🎯 Next Steps

1. **Decide on approach:** Network-level only, or full approval workflow?
2. **Prioritize use cases:** Which transactions need approval first?
3. **Implement Phase 1:** Update deployment script with signature policies
4. **Test endorsement:** Verify policies are enforced
5. **Build Phase 2:** Approval manager chaincode
6. **Iterate:** Add UI and notifications

Would you like me to start implementing any of these phases?
