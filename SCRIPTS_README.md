# Scripts Overview

This document provides an overview of all scripts in the project.

## Directory Structure

```
Blockchain-Project/
├── cleanup-temp-files.sh         # Clean up temporary files and logs
├── deploy-complete-system.sh     # Main deployment script
├── start-full-system.sh          # Start all services
├── stop-full-system.sh           # Stop all services
├── teardown-complete-system.sh   # Complete teardown
├── test-e2e-complete.sh          # Comprehensive E2E tests
├── validate-deployment.sh        # Validate deployment
└── scripts/
    ├── deployment/               # Individual chaincode deployment scripts
    └── tests/                    # Individual feature test scripts
```

## Main Scripts (Root Directory)

These are the primary scripts you should use for normal operations:

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `deploy-complete-system.sh` | Deploy entire system from scratch | First-time setup or fresh deployment |
| `teardown-complete-system.sh` | Stop and clean up entire system | When stopping the system |
| `start-full-system.sh` | Start all services | Restart after stopping |
| `stop-full-system.sh` | Stop all services | Temporary stop without cleanup |
| `test-e2e-complete.sh` | Run comprehensive E2E test suite | Validate system functionality |
| `validate-deployment.sh` | Validate deployment is working | After deployment to verify |
| `cleanup-temp-files.sh` | Clean up temporary files and logs | Regular maintenance |

## Secondary Scripts (`scripts/` directory)

### Deployment Scripts (`scripts/deployment/`)

Individual chaincode deployment scripts (14 scripts):
- Network and infrastructure deployment
- Individual chaincode deployments (policy, farmer, premium-pool, etc.)
- API Gateway startup script

**See**: `scripts/README.md` for detailed list

### Test Scripts (`scripts/tests/`)

Individual feature test scripts (9 scripts):
- API integration tests
- Workflow-specific tests
- Feature validation tests

**See**: `scripts/README.md` for detailed list

## Quick Start

### 1. Deploy Everything
```bash
./deploy-complete-system.sh
```

### 2. Validate Deployment
```bash
./validate-deployment.sh
```

### 3. Run Tests
```bash
./test-e2e-complete.sh
```

### 4. Stop System
```bash
./teardown-complete-system.sh
```

## Development Workflow

### For Normal Operations
Always use the main scripts in the root directory:
```bash
./deploy-complete-system.sh    # Deploy
./validate-deployment.sh        # Validate
./test-e2e-complete.sh          # Test
./teardown-complete-system.sh  # Cleanup
```

### For Advanced/Debugging Operations
Use scripts in `scripts/` directory:
```bash
# Deploy a specific chaincode
cd scripts/deployment
./deploy-claim-processor.sh

# Test a specific feature
cd scripts/tests
./test-policy-creation.sh
```

## Script Categories

### 🚀 Deployment (1 main + 14 secondary)
- **Main**: `deploy-complete-system.sh`
- **Secondary**: Located in `scripts/deployment/`

### 🧪 Testing (1 main + 9 secondary)
- **Main**: `test-e2e-complete.sh`
- **Secondary**: Located in `scripts/tests/`

### ⚙️ System Control (4)
- `start-full-system.sh`
- `stop-full-system.sh`
- `teardown-complete-system.sh`
- `cleanup-temp-files.sh`

### ✅ Validation (1)
- `validate-deployment.sh`

## Common Tasks

### Deploy from Scratch
```bash
./teardown-complete-system.sh   # Clean up any existing deployment
./cleanup-temp-files.sh          # Remove old logs
./deploy-complete-system.sh      # Deploy fresh system
./validate-deployment.sh         # Verify deployment
```

### Quick Restart
```bash
./stop-full-system.sh
./start-full-system.sh
```

### Full System Validation
```bash
./validate-deployment.sh         # Quick validation
./test-e2e-complete.sh           # Comprehensive testing
```

### Maintenance
```bash
./cleanup-temp-files.sh          # Regular cleanup
./cleanup-temp-files.sh --deep   # Deep cleanup (includes node_modules)
```

## Documentation

- **README.md** - Project overview and quick start
- **DEPLOYMENT_GUIDE.md** - Complete deployment documentation
- **DEPLOYMENT_SUMMARY.md** - Summary of all recent changes
- **scripts/README.md** - Detailed documentation for secondary scripts
- **docs/** - Additional documentation

## Notes

- Always run scripts from the project root directory
- Main scripts handle all dependencies and prerequisites
- Secondary scripts in `scripts/` are for advanced use
- Check script output for any errors or warnings
- Use `validate-deployment.sh` after any deployment

## Support

For issues:
1. Check logs: `api-gateway/logs/api-gateway.log`
2. Run validation: `./validate-deployment.sh`
3. Review docs: `DEPLOYMENT_GUIDE.md`
4. Run tests: `./test-e2e-complete.sh`



### Start/Stop System
```bash
./start-full-system.sh    # Start everything
./stop-full-system.sh     # Stop everything
```

### Run Tests
```bash
./test-e2e-complete.sh    # Run full E2E test suite
```

### Deploy Individual Chaincode
```bash
./deploy-<chaincode-name>.sh
```

## Removed Scripts (Cleaned Up)

The following redundant scripts were removed:
- `set-anchor-peer-*.sh` (3 files) - Now handled in setup.sh
- `update-anchor-peers.sh` - Automated in deployment
- `verify-*.sh` (4 files) - Redundant verification scripts
- `test-endorsement-policies.sh` - Duplicate of test-endorsement-validation.sh
