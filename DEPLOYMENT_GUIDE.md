# Deployment Guide - Updated with All Fixes

## Overview
This document describes the complete deployment process with all recent fixes integrated.

## What's Been Fixed

### 1. Template Activation
- **Issue**: Templates were created but remained in "Draft" status
- **Fix**: Added threshold configuration and activation steps
- **Impact**: Templates now appear in UI after deployment

### 2. Approval System
- **Issue**: Approve/Reject buttons failed with "approverOrg required" error
- **Fix**: Updated API calls to include `approverOrg` field in request body
- **Impact**: Approval workflow now works correctly

### 3. Farmer CoopID Case Sensitivity
- **Issue**: UI queried with lowercase 'coop', blockchain had uppercase 'COOP001'
- **Fix**: Updated all queries to use 'COOP001'
- **Impact**: Farmers now display correctly in UI

### 4. Dashboard Statistics
- **Issue**: Dashboard showed 0 farmers and 0 claims
- **Fix**: Updated dashboard to query 'COOP001' instead of 'coop'
- **Impact**: Dashboard now shows accurate statistics

### 5. Premium Deposit
- **Issue**: No automatic premium deposit after policy execution
- **Fix**: Added explicit premium deposit call after policy execution
- **Impact**: Premium pool is properly funded

## Updated Deployment Script

The `deploy-complete-system.sh` script now includes:

### Template Creation (Lines 268-297)
```bash
# Create template
curl -X POST http://localhost:3001/api/policy-templates \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer1" \
    -d '{ "templateID": "TEMPLATE_RICE_DROUGHT_001", ... }'

# Add threshold
curl -X POST "http://localhost:3001/api/policy-templates/TEMPLATE_RICE_DROUGHT_001/thresholds" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer1" \
    -d '{ "indexType": "Drought", "metric": "rainfall", ... }'

# Activate template
curl -X POST "http://localhost:3001/api/policy-templates/TEMPLATE_RICE_DROUGHT_001/activate" \
    -H "X-User-Org: Insurer1"
```

### Approval Process (Lines 350-385)
```bash
# Approve with Insurer1
curl -X POST "http://localhost:3001/api/approval/${APPROVAL_ID}/approve" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer1" \
    -d '{ "approverOrg": "Insurer1MSP", "reason": "..." }'

# Approve with Insurer2
curl -X POST "http://localhost:3001/api/approval/${APPROVAL_ID}/approve" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer2" \
    -d '{ "approverOrg": "Insurer2MSP", "reason": "..." }'

# Execute policy
curl -X POST "http://localhost:3001/api/approval/${APPROVAL_ID}/execute" \
    -H "X-User-Org: Insurer1"

# Deposit premium
curl -X POST "http://localhost:3001/api/premium-pool/deposit-premium" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer1" \
    -d '{ "amount": 500, "policyID": "...", "farmerID": "..." }'
```

## Deployment Steps

### 1. Clean Environment
```bash
# Remove old deployment
./teardown-complete-system.sh

# Clean temporary files
./cleanup-temp-files.sh
```

### 2. Deploy System
```bash
# Deploy entire system
./deploy-complete-system.sh
```

This script will:
1. Start Fabric network (3 organizations)
2. Deploy 11 chaincodes
3. Start API Gateway on port 3001
4. Start UI on port 5173
5. Create demo data:
   - 1 active policy template (with thresholds)
   - 2 farmers (FARMER_DEMO_001, FARMER_DEMO_002)
   - 1 active policy (approved and executed)
   - Premium pool funded with $500

### 3. Validate Deployment
```bash
# Run validation checks
./validate-deployment.sh
```

Expected output:
- ✓ All components running
- ✓ Template in "Active" status
- ✓ 2 farmers registered
- ✓ 1 active policy
- ✓ Pool balance > 0
- ✓ Dashboard showing statistics
- ✓ UI accessible

### 4. Run E2E Tests
```bash
# Optional: Run full test suite
./test-e2e-complete.sh
```

Expected results: 48-49/49 tests passing

## Accessing the System

### UI Access
- URL: http://localhost:5173
- Login: admin / admin123
- Features:
  - View dashboard (farmers, policies, templates)
  - Manage farmers
  - Create policies
  - Approve/reject requests
  - Process claims
  - View pool statistics

### API Access
- URL: http://localhost:3001/api
- Health check: http://localhost:3001/health
- Endpoints:
  - `/farmers` - Farmer management
  - `/policy-templates` - Template management
  - `/policies` - Policy management
  - `/approval` - Approval workflow
  - `/claims` - Claims processing
  - `/premium-pool` - Pool operations
  - `/dashboard` - Statistics

## Troubleshooting

### Templates Not Showing
**Symptom**: UI shows "No policy templates"
**Cause**: Template not activated
**Fix**:
```bash
# Add threshold
curl -X POST "http://localhost:3001/api/policy-templates/TEMPLATE_RICE_DROUGHT_001/thresholds" \
    -H "Content-Type: application/json" \
    -H "X-User-Org: Insurer1" \
    -d '{"indexType":"Drought","metric":"rainfall","thresholdValue":50,"operator":"<","measurementDays":30,"payoutPercent":75,"severity":"Severe"}'

# Activate
curl -X POST "http://localhost:3001/api/policy-templates/TEMPLATE_RICE_DROUGHT_001/activate" \
    -H "X-User-Org: Insurer1"
```

### Farmers Not Showing
**Symptom**: UI shows "No farmers registered"
**Cause**: CoopID mismatch
**Fix**: Ensure farmers are registered with `cooperativeID: "COOP001"` (uppercase)

### Approval Buttons Not Working
**Symptom**: "approverOrg is required" error
**Cause**: Missing approverOrg in request
**Fix**: Update already applied in UI code (ApprovalsPage.tsx)

### Dashboard Shows Zero Stats
**Symptom**: Dashboard displays 0 farmers, 0 claims
**Cause**: Dashboard querying wrong coopID
**Fix**: Rebuild API Gateway (already applied in dashboard.controller.ts)

## Maintenance

### Clean Temporary Files
```bash
# Remove old logs
./cleanup-temp-files.sh

# Deep clean (includes node_modules)
./cleanup-temp-files.sh --deep
```

### Restart Services
```bash
# Stop system
./teardown-complete-system.sh

# Redeploy
./deploy-complete-system.sh
```

### Check Logs
```bash
# API Gateway logs
tail -f api-gateway/logs/api-gateway.log

# Network logs
docker logs peer0.insurer1.insurance.com

# UI logs (if running in background)
tail -f insurance-ui/ui.log
```

## System Requirements

- Docker Desktop 4.0+
- Node.js 18+
- Go 1.20+
- 8GB RAM minimum
- 10GB free disk space

## Architecture Changes

### API Gateway (TypeScript/Express)
- Added `setIndexThreshold` endpoint for template thresholds
- Updated `dashboard.controller.ts` to use COOP001
- Updated `errorHandler.ts` to expose chaincode errors

### UI (React/TypeScript)
- Fixed `ApprovalsPage.tsx` to send approverOrg field
- Fixed `FarmersPage.tsx` to query COOP001
- Fixed `PoliciesPage.tsx` approvals data structure

### Chaincode (Go)
- Premium Pool v3: Fixed GetAllTransactionHistory range query
- All chaincodes: No breaking changes

## Next Steps

After successful deployment:

1. **Explore UI**: Navigate through all pages
2. **Test Workflows**: Create policy, approve, execute
3. **Run Tests**: Execute E2E test suite
4. **Review Logs**: Check for any warnings
5. **Monitor System**: Use dashboard statistics

## Support

For issues or questions:
1. Check logs: `api-gateway/logs/api-gateway.log`
2. Run validation: `./validate-deployment.sh`
3. Review docs: `docs/QUICKSTART.md`
4. Check test results: `./test-e2e-complete.sh`

