# API Gateway Restart Required

## Current Issue

The Premium Pool balance is still showing $1,000 even though the test says it succeeded. The new $500 transaction is not appearing.

## Root Cause

The **API gateway server needs to be restarted** to load the updated code. We've made several critical changes that are compiled but not yet running:

### 1. Multi-Org Approval Fix (COMPILED, NOT RUNNING)
**File**: `api-gateway/src/controllers/approval.controller.ts`
- Added `approverOrg` parameter handling
- Organization context switching for proper approval recording
- **Status**: ✅ Compiled to dist/ but ⚠️ server hasn't loaded it

### 2. Auto-Deposit Logic (COMPILED, NOT RUNNING)
**File**: `api-gateway/src/controllers/approval.controller.ts` (executeApprovedRequest)
- Automatically calls `DepositPremium` after policy execution
- **Status**: ✅ Code exists in dist/controllers/approval.controller.js but ⚠️ never executed (no logs found)

### 3. PolicyID Missing from Metadata (JUST FIXED, NEEDS BUILD)
**File**: `api-gateway/src/controllers/policy.controller.ts`
- Metadata was missing `policyID` field
- Auto-deposit code requires: `{ farmerID, policyID, premiumAmount }`
- **Status**: ⚠️ Just added, needs rebuild and restart

## Evidence

### From Logs Analysis:
```bash
# No auto-deposit logs found at all:
grep "Auto-deposited premium" api-gateway/logs/combined.log
# Returns: (empty)

# Execution happened but no deposit:
2025-11-12 13:52:23 - Transaction ExecuteApprovedRequest submitted successfully
# Expected next: "Auto-deposited premium: 500 for policy POLICY_TEST_1762926736"
# Actual: (nothing)
```

### From Blockchain State:
```bash
curl http://localhost:3001/api/premium-pool/history | jq '.data | length'
# Returns: 5 transactions (4 valid + 1 empty)

# Only old transactions exist:
- PREMIUM_1234556_1762878285332 | $250 | FARM001
- PREMIUM_1234556_1762878295748 | $250 | FARM001  
- PREMIUM_1234556_1762878318016 | $250 | FARM001
- PREMIUM_1234556_1762878355349 | $250 | FARM001

# Missing:
- PREMIUM_POLICY_TEST_1762926736_* | $500 | FARMER001 ❌
```

## How Auto-Deposit Should Work

```
Step 1: Create Policy Approval Request
  POST /api/policies
  ├─ Creates approval request with metadata:
  │  {
  │    policyID: "POLICY_TEST_...",     ✅ NOW INCLUDED
  │    farmerID: "FARMER001",           ✅ Already included
  │    premiumAmount: "500"             ✅ Already included
  │  }
  └─ Status: PENDING

Step 2: Approve by Insurer1
  POST /api/approval/:id/approve { approverOrg: "Insurer1MSP" }
  ├─ Switches to Insurer1 identity     ✅ CODE READY
  └─ Records: approvals[Insurer1MSP] = true

Step 3: Approve by Insurer2  
  POST /api/approval/:id/approve { approverOrg: "Insurer2MSP" }
  ├─ Switches to Insurer2 identity     ✅ CODE READY
  └─ Records: approvals[Insurer2MSP] = true
  └─ Status changes: PENDING → APPROVED

Step 4: Execute Request
  POST /api/approval/:id/execute
  ├─ Calls policy.CreatePolicy()
  ├─ Policy created successfully
  └─ Auto-deposit logic runs:          ⚠️ NOT RUNNING
      if (requestType === 'POLICY_CREATION' && metadata) {
        const { farmerID, policyID, premiumAmount } = metadata;
        if (farmerID && policyID && premiumAmount) {   ← policyID was missing!
          await DepositPremium(txID, farmerID, policyID, premiumAmount);
          console.log('Auto-deposited premium: ...'); ← Never logged
        }
      }

Step 5: Premium in Pool
  ├─ Transaction recorded in blockchain
  ├─ Pool balance updated
  └─ Visible in UI
```

## Required Actions

### 1. Stop API Gateway
In the terminal where API gateway is running:
```bash
# Press Ctrl+C to stop the server
```

### 2. Rebuild with Latest Changes
```bash
cd api-gateway
npm run build
```

This will compile the `policyID` fix into the dist/ folder.

### 3. Restart API Gateway
```bash
npm start
# or
npm run dev
```

### 4. Verify Server Started
You should see:
```
🚀 Insurance API Gateway running on port 3001
Connected to Fabric Gateway
```

### 5. Run Test Again
```bash
./test-premium-auto-deposit.sh
```

### Expected Output After Restart:

```bash
============================================
TEST 2: Auto-Deposit Premium Flow
============================================

Step 1: Creating policy approval request...
✓ Created approval request: POL_REQ_...

Step 2: Approving by Insurer1...
✓ Approved by Insurer1

Step 3: Approving by Insurer2...
✓ Approved by Insurer2

Step 4: Executing approved request (auto-deposits premium)...
✓ Executed: Policy created and premium auto-deposited!

Step 5: Verifying premium deposit in transaction history...
✓ VERIFIED: Premium transaction found in history!     ← Should succeed now
TxID: PREMIUM_POLICY_TEST_..._1762927...
Amount: $500
Type: Premium
Status: Completed

Step 6: Checking pool balance...
Pool balance: $1500                                    ← Should increase!
```

### 6. Verify in API Gateway Logs
```bash
tail -f api-gateway/logs/combined.log | grep "Auto-deposited"
```

You should see:
```
Auto-deposited premium: 500 for policy POLICY_TEST_...
```

### 7. Check Premium Pool API
```bash
curl http://localhost:3001/api/premium-pool/history | \
  jq '.data | map(select(.amount > 0)) | .[] | {txID, amount, farmerID}'
```

Should now show 5 transactions:
```json
{ "txID": "PREMIUM_1234556_...", "amount": 250, "farmerID": "FARM001" }
{ "txID": "PREMIUM_1234556_...", "amount": 250, "farmerID": "FARM001" }
{ "txID": "PREMIUM_1234556_...", "amount": 250, "farmerID": "FARM001" }
{ "txID": "PREMIUM_1234556_...", "amount": 250, "farmerID": "FARM001" }
{ "txID": "PREMIUM_POLICY_TEST_...", "amount": 500, "farmerID": "FARMER001" } ← NEW!
```

### 8. Check UI
Open http://localhost:5173/premium-pool

Should show:
- **Pool Balance**: $1,500 (was $1,000)
- **Total Deposits**: $1,500 (was $1,000)
- **5 transactions** in table (was 4)
- New row with FARMER001 and $500

## Why This Happened

1. **Server caching**: Node.js loads code into memory. Changes to source files don't affect running process.
2. **Build vs Runtime**: `npm run build` compiles TypeScript → JavaScript in dist/, but running server still uses old version in memory.
3. **Missing field**: Even with restart, auto-deposit wouldn't work because `policyID` wasn't in metadata - now fixed.

## Summary

**Current State:**
- ✅ Multi-org approval code: COMPILED
- ✅ Auto-deposit code: COMPILED  
- ✅ PolicyID in metadata: JUST FIXED
- ⚠️ API Gateway: NEEDS RESTART
- ⚠️ Premium deposit: NOT HAPPENING YET

**After Restart:**
- ✅ Multi-org approvals will work
- ✅ Auto-deposit will trigger
- ✅ Pool balance will update
- ✅ UI will show new transactions
- ✅ Complete workflow operational

## Quick Command Sequence

```bash
# 1. Stop API gateway (Ctrl+C in its terminal)

# 2. Rebuild
cd api-gateway && npm run build

# 3. Restart
npm start

# 4. In another terminal, test
cd .. && ./test-premium-auto-deposit.sh

# 5. Check result
curl http://localhost:3001/api/premium-pool/balance
# Should show: 1500

# 6. View in UI
open http://localhost:5173/premium-pool
```

🔄 **ACTION REQUIRED: Restart API Gateway to activate all fixes!**
