# Phase 1: Network-Level Endorsement Policies - Implementation Complete

## Overview
Phase 1 implements chaincode-level endorsement policies at network deployment time. This ensures that transactions require signatures from specific organizations based on the transaction type.

## Implementation Details

### Modified File: `deploy-network.sh`

Added endorsement policy definitions in the `deploy_chaincode()` function. Each chaincode now has a specific signature policy that defines which organizations must endorse transactions.

### Endorsement Policies by Chaincode

#### 1. Farmer Chaincode
**Policy:** `AND('CoopMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))`
- **Meaning:** Coop + ANY Insurer (at least 1 of 2)
- **Use Case:** Farmer registration requires cooperative approval plus at least one insurer
- **Example Transaction:** RegisterFarmer

#### 2. Policy Chaincode
**Policy:** `AND(OR('Insurer1MSP.peer','Insurer2MSP.peer'),'CoopMSP.peer')`
- **Meaning:** ANY Insurer + Coop
- **Use Case:** Policy creation requires insurer approval plus cooperative verification
- **Example Transaction:** CreatePolicy

#### 3. Weather Oracle Chaincode
**Policy:** `OutOf(2,'Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')`
- **Meaning:** 2 of 3 oracle providers
- **Use Case:** Weather data requires consensus from at least 2 oracle providers (FINAL authority)
- **Note:** Weather oracles are the final say - no additional validation required
- **Example Transaction:** SubmitWeatherData

#### 4. Claim Processor Chaincode
**Policy:** `OR('Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')`
- **Meaning:** ANY authorized peer
- **Use Case:** Claims are fully automated - any peer can trigger based on index calculation
- **Note:** No manual approval needed - triggered automatically when conditions are met
- **Example Transaction:** TriggerClaim (automated)

#### 5. Premium Pool Chaincode
**Policy:** `AND('PlatformMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))`
- **Meaning:** Platform + ANY Insurer
- **Use Case:** Pool operations require platform oversight plus insurer approval
- **Example Transaction:** AddFunds, WithdrawFunds

#### 6. Index Calculator Chaincode
**Policy:** `OR('Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')`
- **Meaning:** ANY Insurer or Platform
- **Use Case:** Automated index calculation - any authorized peer can compute
- **Example Transaction:** CalculateIndex

#### 7. Access Control Chaincode
**Policy:** `OR('PlatformMSP.peer')`
- **Meaning:** Platform only
- **Use Case:** Critical access control operations restricted to platform
- **Example Transaction:** GrantRole, RevokeRole

#### 8. Policy Template Chaincode
**Policy:** `OR('Insurer1MSP.peer','Insurer2MSP.peer','PlatformMSP.peer')`
- **Meaning:** ANY Insurer or Platform
- **Use Case:** Template creation available to insurers and platform
- **Example Transaction:** CreateTemplate

## Code Changes

### 1. Endorsement Policy Definition (Lines 140-190)
```bash
# Define endorsement policies per chaincode
local ENDORSEMENT_POLICY=""

case "$CC_NAME" in
    "farmer")
        ENDORSEMENT_POLICY="--signature-policy \"AND('CoopMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))\""
        echo "    - Policy: Coop + ANY Insurer (1 of 2)"
        ;;
    "policy")
        ENDORSEMENT_POLICY="--signature-policy \"AND(OR('Insurer1MSP.peer','Insurer2MSP.peer'),'CoopMSP.peer')\""
        echo "    - Policy: ANY Insurer + Coop"
        ;;
    # ... (see deploy-network.sh for complete implementation)
esac
```

### 2. Approve Command Update (Lines 225-265)
Modified all `approveformyorg` commands to include `${ENDORSEMENT_POLICY}`:
```bash
cli bash -c "peer lifecycle chaincode approveformyorg \
    --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
    --package-id ${PKG_ID} --sequence 1 ${COLLECTIONS_ARG} ${ENDORSEMENT_POLICY} --tls \
    --cafile ..."
```

### 3. Commit Command Update (Lines 270-285)
Modified commit command to include `${ENDORSEMENT_POLICY}`:
```bash
cli bash -c "peer lifecycle chaincode commit \
    --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} \
    --sequence 1 ${COLLECTIONS_ARG} ${ENDORSEMENT_POLICY} --tls \
    --cafile ... \
    --peerAddresses ... \
    --tlsRootCertFiles ..."
```

## Testing

### Test Script: `test-endorsement-policies.sh`

Created comprehensive test script to verify endorsement policy enforcement:

#### Test Cases:
1. **Farmer Registration (FAIL)** - Only Insurer1 signature → Should FAIL
2. **Farmer Registration (PASS)** - Coop + Insurer1 signatures → Should SUCCEED
3. **Weather Data (FAIL)** - Only 1 oracle signature → Should FAIL
4. **Weather Data (PASS)** - 2 of 3 oracle signatures → Should SUCCEED
5. **Policy Creation (FAIL)** - Only Platform signature → Should FAIL

### Running Tests:
```bash
# Deploy network with new endorsement policies
./deploy-network.sh

# Run endorsement policy tests
./test-endorsement-policies.sh
```

### Expected Test Results:
- ✓ Test 1: FAIL - Single org cannot register farmers
- ✓ Test 2: PASS - Coop + Insurer can register farmers
- ✓ Test 3: FAIL - Single oracle cannot submit weather
- ✓ Test 4: PASS - 2 of 3 oracles can submit weather
- ✓ Test 5: FAIL - Platform alone cannot create policies

## Deployment Instructions

### First-Time Deployment:
```bash
# 1. Clean any existing network
cd /Users/yattmeo/Desktop/SMU/Code/Blockchain\ proj/Blockchain-Project
./network/network.sh down

# 2. Deploy with new endorsement policies
./deploy-network.sh

# 3. Verify endorsement policies
./test-endorsement-policies.sh
```

### Upgrading Existing Network:
```bash
# 1. Note: Endorsement policies require chaincode upgrade (sequence increment)
# 2. Use network/upgrade-claim-processor.sh as template
# 3. Increment sequence number and add --signature-policy flag

# Example for upgrading farmer chaincode:
peer lifecycle chaincode approveformyorg \
    --channelID insurance-main \
    --name farmer \
    --version 2 \
    --package-id <PKG_ID> \
    --sequence 2 \
    --signature-policy "AND('CoopMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))" \
    --tls --cafile ...

peer lifecycle chaincode commit \
    --channelID insurance-main \
    --name farmer \
    --version 2 \
    --sequence 2 \
    --signature-policy "AND('CoopMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))" \
    --tls --cafile ... \
    --peerAddresses ... \
    --tlsRootCertFiles ...
```

## Verification

### Check Committed Chaincode Definition:
```bash
docker exec cli peer lifecycle chaincode querycommitted \
    --channelID insurance-main \
    --name farmer
```

### Expected Output:
```
Committed chaincode definition for chaincode 'farmer' on channel 'insurance-main':
Version: 2, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc
Signature Policy: AND('CoopMSP.peer',OR('Insurer1MSP.peer','Insurer2MSP.peer'))
```

## Impact on API Gateway

### No Changes Required
The API Gateway continues to work as-is because:
1. Gateway connects to a single peer (peer0.insurer1.insurance.com)
2. Fabric Gateway SDK automatically collects required endorsements
3. SDK queries discovery service to find which peers need to endorse
4. SDK contacts multiple peers transparently

### How It Works:
```
API Gateway → Fabric Gateway SDK → Discovery Service
                                     ↓
                    [Insurer1 Peer] [Coop Peer] [Platform Peer]
                                     ↓
                    Collects required signatures
                                     ↓
                    Submits to Orderer → Validates → Commits
```

## Design Decisions

### 1. Weather Oracle Authority
- **Decision:** Weather oracles are FINAL authority
- **Rationale:** No additional platform validation needed
- **Policy:** 2 of 3 consensus ensures data accuracy
- **Note:** Removed "validate weather" from endorsement requirements

### 2. Automated Claims
- **Decision:** Claims are fully automated
- **Rationale:** Triggered automatically when index conditions are met
- **Policy:** Lenient (any peer) since it's rule-based, not discretionary
- **Note:** No manual approval workflow required

### 3. Farmer Registration
- **Decision:** Requires Coop + at least 1 Insurer
- **Rationale:** Cooperative verifies farmer identity, insurer assesses risk
- **Policy:** AND('CoopMSP.peer', OR('Insurer1MSP.peer','Insurer2MSP.peer'))

### 4. Premium Pool
- **Decision:** Platform + any Insurer
- **Rationale:** Platform manages pool, insurer provides oversight
- **Policy:** AND('PlatformMSP.peer', OR('Insurer1MSP.peer','Insurer2MSP.peer'))
- **Note:** May need stricter policy for withdrawals in Phase 2

## Known Limitations

### 1. Function-Level Policies Not Implemented
- **Current:** All functions in a chaincode use the same policy
- **Future (Phase 2):** Different policies per function (e.g., strict for withdrawals, lenient for deposits)

### 2. Dynamic Policy Updates
- **Current:** Policies require chaincode upgrade (redeployment)
- **Future (Phase 2):** Approval Manager chaincode for on-chain governance

### 3. Emergency Override
- **Current:** No emergency mechanism
- **Future (Phase 5):** Emergency Management with unanimous consent for critical actions

## Next Steps (Phase 2)

### Approval Manager Chaincode
1. Create `chaincode/approval-manager/` directory
2. Implement ApprovalRequest struct:
   ```go
   type ApprovalRequest struct {
       RequestID     string
       ChaincodeName string
       FunctionName  string
       Arguments     []string
       RequiredOrgs  []string
       Approvals     map[string]bool
       Status        string
       Timestamp     time.Time
   }
   ```
3. Add workflow functions:
   - `CreateApprovalRequest()`
   - `ApproveRequest()`
   - `RejectRequest()`
   - `ExecuteApprovedRequest()`
4. Deploy to network
5. Test multi-step approval workflow

## Troubleshooting

### Issue: Endorsement Policy Failure
**Symptom:** `ENDORSEMENT_POLICY_FAILURE` error
**Solution:** Ensure transaction includes endorsements from all required orgs

### Issue: Policy Not Applied
**Symptom:** Transactions succeed with insufficient endorsements
**Solution:** 
1. Check committed chaincode definition: `peer lifecycle chaincode querycommitted`
2. Verify sequence number was incremented
3. Ensure all orgs approved with same policy

### Issue: Discovery Service Error
**Symptom:** SDK can't find required peers
**Solution:**
1. Check network connectivity: `docker ps`
2. Verify all peers are running
3. Check discovery service config in connection profile

## References

- **Hyperledger Fabric Docs:** [Endorsement Policies](https://hyperledger-fabric.readthedocs.io/en/latest/endorsement-policies.html)
- **Project Docs:** `ENDORSEMENT_ARCHITECTURE.md`
- **Deployment Script:** `deploy-network.sh`
- **Test Script:** `test-endorsement-policies.sh`

## Status

✅ **Phase 1 Complete** - Network-level endorsement policies implemented and ready for testing

**Next:** Phase 2 - Approval Manager Chaincode (1-2 days)
