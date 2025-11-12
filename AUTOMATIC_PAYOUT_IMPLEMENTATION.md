# Automatic Payout System Implementation

## Overview

The automatic payout system is a **core feature** of the Weather Index Insurance Platform that automatically triggers claims and executes payouts when weather conditions breach policy thresholds after multi-oracle consensus validation.

## Architecture

### Event-Driven Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                   AUTOMATIC PAYOUT FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Multiple Oracles Submit Weather Data                        │
│     ↓                                                           │
│  2. Consensus Validation (2/3 majority)                         │
│     ↓                                                           │
│  3. 🎯 AUTOMATIC TRIGGER                                        │
│     │                                                           │
│     ├──→ Query Active Policies in Region                       │
│     │                                                           │
│     ├──→ Check Each Policy's Thresholds                        │
│     │    (Compare weather data vs threshold values)            │
│     │                                                           │
│     ├──→ If Threshold Breached:                                │
│     │    ├─ Calculate Payout Amount                            │
│     │    ├─ Create Automatic Claim                             │
│     │    └─ Execute Payout from Premium Pool                   │
│     │                                                           │
│     └──→ Return Summary of Actions Taken                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Implementation Components

### 1. Weather Oracle Chaincode Enhancement

**File**: `chaincode/weather-oracle/weatheroracle.go`

**Function**: `ValidateDataConsensus`

**Enhancement**: Emits `ConsensusReached` event when validation succeeds

```go
if consensusReached {
    err = ctx.GetStub().SetEvent("ConsensusReached", []byte(fmt.Sprintf(
        `{"location":"%s","timestamp":"%s","rainfall":%.2f,"temperature":%.2f,"humidity":%.2f}`,
        location, timestamp.Format(time.RFC3339), avgRainfall, avgTemp, avgHumidity,
    )))
}
```

### 2. Automatic Payout Service

**File**: `api-gateway/src/services/automaticPayout.service.ts`

**Main Function**: `processConsensusAndTriggerPayouts()`

**Responsibilities**:
- Query all active policies
- Filter policies by location
- Check thresholds for each policy
- Trigger automatic claims
- Execute payouts

**Key Functions**:

#### `getActivePolicies()`
Retrieves all policies with status "Active" from the blockchain.

#### `filterPoliciesByLocation()`
Matches policy locations with consensus location using normalized comparison.

#### `getPolicyTemplate()`
Retrieves policy template including index thresholds.

#### `checkThreshold()`
Compares actual weather values against threshold conditions:
- Supports operators: `<`, `>`, `<=`, `>=`, `==`
- Checks rainfall, temperature, humidity
- Returns boolean: threshold breached or not

#### `triggerAutomaticClaim()`
Creates a claim in the claim-processor chaincode when threshold is breached.

#### `executeAutomaticPayout()`
Executes payout from premium-pool chaincode to farmer.

### 3. API Gateway Controller Enhancement

**File**: `api-gateway/src/controllers/weatherOracle.controller.ts`

**Function**: `validateConsensus`

**Enhancement**: Automatically calls payout service after consensus validation

```typescript
if (consensusReached) {
    payoutResult = await automaticPayoutService.processConsensusAndTriggerPayouts({
        location,
        timestamp,
        rainfall: weather.rainfall,
        temperature: weather.temperature,
        humidity: weather.humidity,
    });
}
```

**API Response** now includes automatic payout information:

```json
{
  "success": true,
  "message": "Consensus validation successful",
  "data": {
    "consensusReached": true,
    "location": "Central_Bangkok",
    "timestamp": "2025-11-13T10:00:00Z",
    "validatedDataPoints": 3,
    "automaticPayouts": {
      "enabled": true,
      "policiesChecked": 2,
      "thresholdsBreached": 1,
      "claimsTriggered": ["CLAIM_AUTO_POLICY_DEMO_001_1699876805123"],
      "errors": []
    }
  }
}
```

## Demo Configuration

### Policy Template Threshold

**Template**: `TEMPLATE_RICE_DROUGHT_001`

**Threshold Configuration**:
```json
{
  "indexType": "Drought",
  "metric": "rainfall",
  "thresholdValue": 50,
  "operator": "<",
  "measurementDays": 30,
  "payoutPercent": 75,
  "severity": "Severe"
}
```

**Interpretation**: If rainfall < 50mm, trigger automatic payout of 75% of coverage amount.

### Demo Policy

**Policy ID**: `POLICY_DEMO_001`
- **Farmer**: `FARMER_DEMO_001`
- **Location**: `Central_Bangkok`
- **Coverage**: $5,000
- **Premium**: $500
- **Expected Payout**: $3,750 (75% of $5,000)

### Demo Weather Data (Drought Condition)

**Central Bangkok Consensus**:
- Oracle 1: 35.0mm rainfall
- Oracle 2: 38.5mm rainfall
- Oracle 3: 33.0mm rainfall
- **Average**: ~35.5mm (BELOW 50mm threshold ✓)

### Automatic Trigger Flow

1. **Consensus Validated**: 3 oracles agree on ~35mm rainfall
2. **Threshold Check**: 35mm < 50mm ✓ BREACHED
3. **Automatic Actions**:
   ```
   → Query active policies in Central_Bangkok
   → Find POLICY_DEMO_001
   → Check threshold: rainfall (35mm) < 50mm ✓
   → Calculate payout: $5,000 × 75% = $3,750
   → Create claim: CLAIM_AUTO_POLICY_DEMO_001_xxx
   → Execute payout: $3,750 from premium pool → FARMER_DEMO_001
   ```

## Logging and Monitoring

### Automatic Payout Service Logs

**Success Logs**:
```
🔍 Checking policies for automatic payout triggers in location: Central_Bangkok
Found 2 active policies to check
1 policies in affected location
⚠️  THRESHOLD BREACHED: Policy POLICY_DEMO_001, Drought < 50
✅ Automatic claim triggered: CLAIM_AUTO_POLICY_DEMO_001_xxx
✅ Payout executed successfully: TX_PAYOUT_CLAIM_AUTO_xxx
```

**Summary Log**:
```
╔════════════════════════════════════════════════════════════╗
║           Automatic Payout Processing Complete             ║
╠════════════════════════════════════════════════════════════╣
║ Location:           Central_Bangkok                        ║
║ Policies Checked:   1                                      ║
║ Thresholds Breached: 1                                     ║
║ Claims Triggered:   1                                      ║
║ Errors:             0                                      ║
╚════════════════════════════════════════════════════════════╝
```

## Testing

### E2E Test Enhancement

**Test 5.3b**: Verify automatic payout system responded
```bash
PAYOUT_ENABLED=$(echo "$CONSENSUS_RESULT" | jq -r '.data.automaticPayouts.enabled')
assert_equals "Automatic payout enabled" "true" "$PAYOUT_ENABLED"
```

### Deployment Test

Run `./deploy-complete-system.sh`:
```bash
Validating Central Bangkok consensus (DROUGHT - will trigger automatic payout)...
✓ Consensus validated - 1 automatic claim(s) triggered!
  → Claim: CLAIM_AUTO_POLICY_DEMO_001_1699876805123
```

## Verification

### Check Claim Created
```bash
curl http://localhost:3001/api/claims | jq '.data[] | select(.policyID == "POLICY_DEMO_001")'
```

**Expected**:
```json
{
  "claimID": "CLAIM_AUTO_POLICY_DEMO_001_xxx",
  "policyID": "POLICY_DEMO_001",
  "farmerID": "FARMER_DEMO_001",
  "status": "Approved",
  "payoutAmount": 3750,
  "payoutPercent": 75
}
```

### Check Payout Executed
```bash
curl http://localhost:3001/api/premium-pool/transactions | jq '.data[] | select(.type == "Payout")'
```

**Expected**:
```json
{
  "txID": "TX_PAYOUT_CLAIM_AUTO_xxx",
  "type": "Payout",
  "farmerID": "FARMER_DEMO_001",
  "policyID": "POLICY_DEMO_001",
  "amount": 3750,
  "status": "Completed"
}
```

### Check Premium Pool Balance
```bash
curl http://localhost:3001/api/premium-pool/balance
```

**Expected**: Balance decreased by $3,750

## Configuration

### Threshold Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `<` | Less than | `rainfall < 50` (drought) |
| `>` | Greater than | `rainfall > 300` (flood) |
| `<=` | Less than or equal | `temperature <= 0` (freeze) |
| `>=` | Greater than or equal | `temperature >= 40` (heatwave) |
| `==` | Equal to | `humidity == 100` (specific condition) |

### Location Matching

The system uses **normalized location matching**:
- Removes underscores, spaces, hyphens
- Case-insensitive comparison
- Supports partial matches

**Examples**:
- `"Central_Bangkok"` matches `"Central Bangkok"`
- `"North_ChiangMai"` matches `"north chiangmai"`
- `"Singapore, North Region"` matches `"singapore north"`

## Error Handling

### Non-Critical Errors

Automatic payout errors **do not fail** consensus validation:
- Consensus validation always succeeds if 2/3 oracles agree
- Payout errors are logged but returned in response
- System continues processing other policies

### Error Response
```json
{
  "automaticPayouts": {
    "enabled": true,
    "policiesChecked": 5,
    "thresholdsBreached": 2,
    "claimsTriggered": ["CLAIM_1"],
    "errors": [
      "Error processing policy POLICY_002: Insufficient pool balance"
    ]
  }
}
```

## Benefits

1. **Immediate Response**: Payouts triggered within seconds of consensus validation
2. **No Manual Intervention**: Fully automated claim creation and payout execution
3. **Transparent**: All actions logged and returned in API response
4. **Fair**: Multi-oracle consensus ensures accurate weather data
5. **Efficient**: Batch processing of multiple policies in single transaction
6. **Resilient**: Error handling ensures one policy failure doesn't affect others

## Future Enhancements

1. **Background Monitoring**: Scheduled jobs to check historical weather data
2. **Partial Payouts**: Progressive payouts based on severity levels
3. **Notification System**: Alert farmers when automatic payout is triggered
4. **Dispute Resolution**: Allow farmers to challenge automatic decisions
5. **Machine Learning**: Predict potential payouts based on weather forecasts

## Status: ✅ FULLY IMPLEMENTED

All components deployed and tested:
- ✅ Weather oracle event emission
- ✅ Automatic payout service
- ✅ API gateway orchestration
- ✅ Demo data with drought conditions
- ✅ E2E test verification
- ✅ Logging and monitoring
- ✅ Error handling
- ✅ Documentation complete
