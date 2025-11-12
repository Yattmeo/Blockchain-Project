# Weather-Triggered Claim Testing - Final Steps

## What We've Done

1. ✅ Created complete test flow:
   - Create policy → Auto-deposit premium ✅ WORKING
   - Submit weather data ✅ WORKING
   - Trigger claim ✅ WORKING
   - Execute payout from pool ⏳ NEEDS API REBUILD

2. ✅ Fixed API controller to use correct chaincode function:
   - Changed from `WithdrawFunds` (doesn't exist) → `ExecutePayout`
   - Added required parameters: txID, farmerID, policyID, claimID, amount

## API Gateway Needs Rebuild

The `withdrawFunds` controller was updated to call `ExecutePayout` with correct parameters.

### Rebuild & Restart:

```bash
# 1. Stop API gateway (Ctrl+C)

# 2. Rebuild
cd api-gateway
npm run build

# 3. Restart
npm start
```

### Then Run Test:

```bash
./test-claim-payout-simple.sh
```

## Expected Flow

```
Initial State:
  Pool Balance: $3,000

Step 1: Submit Weather Data
  - Rainfall: 35.0mm (below 50mm threshold)
  - Triggers Rice Drought condition
  ✓ Weather data stored

Step 2: Trigger Claim
  - ClaimID: CLAIM_SIMPLE_...
  - Policy: POLICY_WEATHER_TEST_1762927939
  - Coverage: $10,000
  - Payout: 50% = $5,000
  ✓ Claim created and approved

Step 3: Execute Payout
  - Calls: ExecutePayout(txID, farmerID, policyID, claimID, $5000)
  - Pool withdraws $5,000
  - Transaction recorded
  ✓ Payout completed

Final State:
  Pool Balance: $3,000 - $5,000 = -$2,000 (NEGATIVE!)
  
⚠️ NOTE: Pool will go negative! We only have $3,000 but claim is $5,000
```

## Solution for Negative Balance

Either:

**Option A: Use existing policy with smaller coverage**
```bash
# Edit test-claim-payout-simple.sh:
COVERAGE=5000   # Instead of 10000
PAYOUT_AMOUNT=2500  # 50% of 5000
```

**Option B: Create new policy with appropriate coverage**
- Run ./test-premium-auto-deposit.sh first to add more funds
- Then run claim test

## Complete Workflow Test

After rebuild, run the full workflow:

```bash
# 1. Check current balance
curl http://localhost:3001/api/premium-pool/balance

# 2. If balance < $5000, create more policies first
./test-premium-auto-deposit.sh  # Adds $500 per policy

# 3. Run claim and payout test
./test-claim-payout-simple.sh

# 4. Verify in UI
open http://localhost:5173/premium-pool
open http://localhost:5173/claims
```

## API Changes Made

**File**: `api-gateway/src/controllers/premiumPool.controller.ts`

**Function**: `withdrawFunds`

**Before**:
```typescript
await fabricGateway.submitTransaction(
  'premium-pool',
  'WithdrawFunds',  // ❌ Function doesn't exist
  amount.toString(),
  recipient || ''
);
```

**After**:
```typescript
const txID = `PAYOUT_${claimID || 'CLAIM'}_${Date.now()}`;

await fabricGateway.submitTransaction(
  'premium-pool',
  'ExecutePayout',  // ✅ Correct function
  txID,
  recipient,  // farmerID
  policyID || '',
  claimID || '',
  amount.toString()
);
```

## Summary

✅ Policy creation + auto-deposit: WORKING
✅ Weather data submission: WORKING
✅ Claim triggering: WORKING
⏳ Payout execution: FIXED, needs rebuild

**Action Required:**
1. Rebuild API gateway: `cd api-gateway && npm run build`
2. Restart: `npm start`
3. Test: `./test-claim-payout-simple.sh`
