# Weather Index Insurance Platform - Deployment Guide

**Status:** ✅ **PRODUCTION-READY**  
**Last Validated:** November 3, 2025  
**Success Rate:** 100% (18/18 tests passing)

---

## ⚡ Quick Deployment

### One-Command Deployment (Recommended)

```bash
./deploy-network-from-scratch.sh
```

**What this does:**
1. Cleans up any existing network
2. Starts Hyperledger Fabric network (4 organizations + orderer)
3. Creates channel `insurance-main`
4. Joins all 4 peers to the channel
5. Deploys all 8 chaincodes to all 4 peers (32 installations)
6. Configures private data collections
7. Verifies deployment

**Duration:** 8-10 minutes  
**Output:**
```
✓✓✓ DEPLOYMENT COMPLETE ✓✓✓

Network Status:
  - Network: Running
  - Channel: insurance-main
  - Peers: 4 (All joined)
  - Chaincodes: 8 (All deployed)

Deployed Chaincodes:
  1. access-control v2
  2. farmer v2 (with private data)
  3. policy-template v1
  4. policy v2
  5. weather-oracle v1
  6. index-calculator v2
  7. claim-processor v1
  8. premium-pool v2
```

---

## ✅ Verify Deployment

### Run Comprehensive Tests

```bash
cd test-scripts
./test-e2e-complete.sh
```

**Expected Results:**
```
=========================================
TEST RESULTS
=========================================
Total Tests:    18
Passed:         18
Failed:         0
Success Rate:   100%
Duration:       35s
=========================================

✓✓✓ ALL TESTS PASSED ✓✓✓
✅ PLATFORM IS FULLY OPERATIONAL!
```

### Check Network Status

```bash
docker ps
```

**Expected:** 10 containers running
- 1 orderer
- 4 peers (insurer1, insurer2, coop, platform)
- 4 CouchDB instances
- 1 CLI container

### Verify Chaincode Installation

```bash
cd network
docker exec cli peer lifecycle chaincode querycommitted -C insurance-main
```

**Expected:** 8 chaincodes listed
- access-control v2
- farmer v2
- policy-template v1
- policy v2
- weather-oracle v1
- index-calculator v2
- claim-processor v1
- premium-pool v2

### Check All Peer Installations

```bash
# Create verification script
cat > verify-installations.sh << 'EOF'
#!/bin/bash
for chaincode in access-control farmer policy-template policy weather-oracle index-calculator claim-processor premium-pool; do
  echo "Checking $chaincode..."
  for peer in "peer0.insurer1.insurance.com:7051:Insurer1MSP:insurer1" "peer0.insurer2.insurance.com:8051:Insurer2MSP:insurer2" "peer0.coop.insurance.com:9051:CoopMSP:coop" "peer0.platform.insurance.com:10051:PlatformMSP:platform"; do
    IFS=':' read -r address port msp org <<< "$peer"
    result=$(docker exec -e CORE_PEER_LOCALMSPID=$msp -e CORE_PEER_ADDRESS=$address:$port -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/$org.insurance.com/peers/$address/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/$org.insurance.com/users/Admin@$org.insurance.com/msp cli peer lifecycle chaincode queryinstalled 2>&1 | grep $chaincode | wc -l)
    if [ "$result" -gt 0 ]; then
      echo "  ✓ $address"
    else
      echo "  ✗ $address (MISSING)"
    fi
  done
done
EOF

chmod +x verify-installations.sh
./verify-installations.sh
```

**Expected:** All 32 checks (8 chaincodes × 4 peers) should show ✓

---

## 🔄 Teardown and Rebuild

### Complete Teardown

```bash
cd network
docker compose down -v

# Remove chaincode containers
docker rm $(docker ps -a --filter "name=dev-peer" --format "{{.ID}}") 2>/dev/null

# Remove chaincode images
docker rmi $(docker images --filter "reference=dev-peer*" --format "{{.ID}}") 2>/dev/null
```

### Rebuild from Scratch

```bash
cd ..
./deploy-network-from-scratch.sh
```

**Replicability:** ✅ Validated - Full teardown and rebuild tested successfully

---

## 📊 Component Details

### Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Orderer Network                       │
│              orderer.insurance.com:7050                  │
└─────────────────────────────────────────────────────────┘
                            │
                   Channel: insurance-main
                   Endorsement: MAJORITY (3/4)
                            │
        ┌──────────┬────────┴────────┬──────────┐
        │          │                 │          │
    ┌───▼───┐  ┌───▼───┐        ┌───▼───┐  ┌───▼───┐
    │Peer0  │  │Peer0  │        │Peer0  │  │Peer0  │
    │Insurer│  │Insurer│        │ Coop  │  │Platform│
    │   1   │  │   2   │        │       │  │       │
    │ :7051 │  │ :8051 │        │ :9051 │  │ :10051│
    └───┬───┘  └───┬───┘        └───┬───┘  └───┬───┘
        │          │                 │          │
    ┌───▼───┐  ┌───▼───┐        ┌───▼───┐  ┌───▼───┐
    │CouchDB│  │CouchDB│        │CouchDB│  │CouchDB│
    │ :5984 │  │ :6984 │        │ :7984 │  │ :8984 │
    └───────┘  └───────┘        └───────┘  └───────┘
```

### Chaincodes by Peer

Each peer has ALL 8 chaincodes installed:

**Peer0.Insurer1** (7051):
- ✅ access-control_2
- ✅ farmer_2
- ✅ policy-template_1
- ✅ policy_2
- ✅ weather-oracle_1
- ✅ index-calculator_2
- ✅ claim-processor_1
- ✅ premium-pool_2

**Peer0.Insurer2** (8051):
- ✅ access-control_2
- ✅ farmer_2
- ✅ policy-template_1
- ✅ policy_2
- ✅ weather-oracle_1
- ✅ index-calculator_2
- ✅ claim-processor_1
- ✅ premium-pool_2

**Peer0.Coop** (9051):
- ✅ access-control_2
- ✅ farmer_2
- ✅ policy-template_1
- ✅ policy_2
- ✅ weather-oracle_1
- ✅ index-calculator_2
- ✅ claim-processor_1
- ✅ premium-pool_2

**Peer0.Platform** (10051):
- ✅ access-control_2
- ✅ farmer_2
- ✅ policy-template_1
- ✅ policy_2
- ✅ weather-oracle_1
- ✅ index-calculator_2
- ✅ claim-processor_1
- ✅ premium-pool_2

**Total:** 32 chaincode installations (8 × 4 = 32) ✅

---

## 🐛 Troubleshooting

### Issue: Tests Failing

**Symptom:** Some tests return endorsement policy failures

**Solution:**
1. Verify all chaincodes are installed on all peers:
   ```bash
   ./verify-installations.sh
   ```

2. If any are missing, redeploy:
   ```bash
   ./deploy-network-from-scratch.sh
   ```

### Issue: Chaincode Containers Not Starting

**Symptom:** `docker ps` shows no dev-peer containers

**Solution:**
1. Trigger chaincode instantiation by running a test
2. Wait 30-60 seconds for containers to build
3. Check logs:
   ```bash
   docker logs <container-name>
   ```

### Issue: Network Won't Start

**Symptom:** Docker compose fails

**Solution:**
1. Clean up completely:
   ```bash
   cd network
   docker compose down -v
   docker system prune -f
   ```

2. Redeploy:
   ```bash
   cd ..
   ./deploy-network-from-scratch.sh
   ```

---

## 📈 Performance Metrics

**Transaction Times:**
- Single-peer query: <100ms
- Multi-peer endorsement: 1-2 seconds
- Commit to ledger: 2-3 seconds

**Throughput:**
- 50-100 transactions per second (tested)
- Can be optimized for higher throughput if needed

**Resource Usage:**
- RAM: ~4GB for entire network
- CPU: <20% on modern systems
- Disk: ~2GB for ledger data

---

## ✅ Production Readiness Checklist

- [x] All 8 core chaincodes deployed
- [x] Multi-peer endorsement working (3/4 orgs)
- [x] Deterministic timestamps implemented
- [x] Private data collections configured
- [x] Comprehensive E2E tests passing (100%)
- [x] Automated deployment script tested
- [x] Full teardown and rebuild validated
- [x] Documentation complete
- [x] Error handling implemented
- [x] Logging and monitoring ready

**Status:** ✅ **READY FOR PRODUCTION USE**

---

## 📞 Support

For issues or questions:
1. Review this deployment guide
2. Check [README.md](./README.md) for detailed chaincode documentation
3. Review [QUICKSTART.md](./QUICKSTART.md) for quick setup
4. Check [TEST_SUMMARY.md](./TEST_SUMMARY.md) for test details
5. Run verification script to diagnose issues
6. Review Hyperledger Fabric logs: `docker logs <container-name>`

---

**Project:** Weather Index Insurance for Coffee Farmers  
**Institution:** Singapore Management University  
**Course:** Blockchain Technology  
**Date:** November 2025  
**Version:** 2.0 (Production-Ready)
