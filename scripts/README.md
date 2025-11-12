# Scripts Directory

This directory contains secondary scripts used by the main deployment and testing scripts.

## Directory Structure

```
scripts/
├── deployment/      # Individual chaincode deployment scripts
└── tests/          # Individual feature test scripts
```

## Deployment Scripts (`deployment/`)

Individual chaincode deployment scripts used by `deploy-complete-system.sh`:

- `deploy-network.sh` - Deploy Fabric network infrastructure
- `deploy-policy.sh` - Deploy policy chaincode
- `deploy-policy-template.sh` - Deploy policy template chaincode
- `deploy-farmer.sh` - Deploy farmer chaincode
- `deploy-premium-pool.sh` - Deploy premium pool chaincode
- `deploy-claim-processor.sh` - Deploy claim processor chaincode
- `deploy-weather-oracle.sh` - Deploy weather oracle chaincode
- `deploy-approval-manager.sh` - Deploy approval manager chaincode
- `deploy-access-control.sh` - Deploy access control chaincode
- `deploy-audit-log.sh` - Deploy audit log chaincode
- `deploy-emergency-management.sh` - Deploy emergency management chaincode
- `deploy-notification.sh` - Deploy notification chaincode
- `deploy-index-calculator.sh` - Deploy index calculator chaincode
- `start-api-gateway.sh` - Start API Gateway service

### Usage

These scripts are typically called by `deploy-complete-system.sh`. To deploy a single chaincode:

```bash
cd scripts/deployment
./deploy-policy.sh
```

**Note**: Individual chaincode deployment requires the network to be running.

## Test Scripts (`tests/`)

Individual feature test scripts used for targeted testing:

- `test-api-integration.sh` - Test API Gateway integration
- `test-approval-api.sh` - Test approval workflow API
- `test-claim-payout-simple.sh` - Test simple claim payout
- `test-claims-frontend.sh` - Test claims UI functionality
- `test-endorsement-validation.sh` - Test endorsement policies
- `test-policy-creation.sh` - Test policy creation workflow
- `test-premium-auto-deposit.sh` - Test automatic premium deposit
- `test-weather-claim-autopayout.sh` - Test weather-triggered payouts
- `test-weather-data.sh` - Test weather data submission

### Usage

These scripts test individual features. To run a specific test:

```bash
cd scripts/tests
./test-policy-creation.sh
```

**Note**: Tests require the complete system to be running. Use `test-e2e-complete.sh` from the root directory for comprehensive testing.

## Main Scripts (Root Directory)

The primary scripts in the root directory should be used for normal operations:

| Script | Purpose |
|--------|---------|
| `deploy-complete-system.sh` | Deploy entire system from scratch |
| `teardown-complete-system.sh` | Stop and clean up entire system |
| `start-full-system.sh` | Start all services |
| `stop-full-system.sh` | Stop all services |
| `test-e2e-complete.sh` | Run comprehensive E2E test suite |
| `validate-deployment.sh` | Validate deployment is working |
| `cleanup-temp-files.sh` | Clean up temporary files and logs |

## Development Workflow

### For Normal Use
Use the main scripts in the root directory:
```bash
./deploy-complete-system.sh    # Deploy everything
./test-e2e-complete.sh          # Test everything
./validate-deployment.sh        # Validate everything
./teardown-complete-system.sh  # Clean up everything
```

### For Development/Debugging
Use scripts in this directory for targeted operations:
```bash
# Deploy a specific chaincode
cd scripts/deployment
./deploy-claim-processor.sh

# Test a specific feature
cd scripts/tests
./test-claim-payout-simple.sh
```

## Notes

- All scripts should be run from their respective directories
- Scripts in `deployment/` require the Fabric network to be running
- Scripts in `tests/` require the complete system to be running
- For full system operations, always use the main scripts in the root directory

