# Weather Index Insurance Platform - Quick Start Guide

## Prerequisites

Before you begin, ensure you have the following installed:

- Docker Engine 20.10+
- Docker Compose 2.0+
- Go 1.20+
- Git

## Installation Steps

### 1. Clone the Repository

```bash
cd /Users/yattmeo/Desktop/SMU/Code/
cd "Blockchain proj"
```

### 2. Set Permissions

```bash
chmod +x network/network.sh
chmod +x scripts/*.sh
```

### 3. Start the Network

```bash
cd network
./network.sh up
```

This will start:
- 1 Orderer node (Raft consensus)
- 4 Peer nodes (Insurer1, Insurer2, Coop, Platform)
- 4 CouchDB instances (for state database)
- 1 CLI container (for interaction)

### 4. Create the Channel

```bash
./network.sh createChannel -c insurance-main
```

### 5. Deploy and Test All Chaincodes

```bash
cd ..
./test-e2e-complete.sh
```

This comprehensive test script will:
- Deploy all 8 core chaincodes in the correct order
- Run 20 automated tests across all modules
- Verify multi-peer endorsement
- Test complete policy lifecycle

**Chaincodes Deployed:**
1. access-control v2.0 (with deterministic timestamps)
2. farmer v2.0 (with private data collections)
3. policy-template v1.0
4. policy v2.0 (with fixed function signatures)
5. weather-oracle v1.0
6. index-calculator v2.0 (with fixed function signatures)
7. claim-processor v1.0
8. premium-pool v2.0 (with fixed function signatures)

**Test Coverage:**
- ✅ Access Control: Organization registration and retrieval
- ✅ Farmer Management: Registration with array parameters
- ✅ Policy Templates: Creation and threshold configuration
- ✅ Policy Issuance: Full policy creation workflow
- ✅ Weather Oracle: Data provider registration and submission
- ✅ Index Calculator: Rainfall index computation
- ✅ Claim Processing: Automated payout triggers
- ✅ Premium Pool: Financial transactions

**Expected Results:**
- Total Tests: 20
- Success Rate: 100% (all tests pass)
- Duration: ~30-35 seconds

## Verification

### Check Network Status

```bash
docker ps
```

You should see 9 containers running:
- orderer.insurance.com
- peer0.insurer1.insurance.com
- peer0.insurer2.insurance.com
- peer0.coop.insurance.com
- peer0.platform.insurance.com
- couchdb.insurer1
- couchdb.insurer2
- couchdb.coop
- couchdb.platform
- cli

### Check Deployed Chaincodes

```bash
# Check installed packages
docker exec cli peer lifecycle chaincode queryinstalled

# Check committed chaincodes
docker exec cli peer lifecycle chaincode querycommitted -C insurance-main
```

**You should see 8 chaincodes committed with v1.0 or v2.0 versions.**

### Access CouchDB UI

Open your browser and navigate to:
- Insurer1: http://localhost:5984/_utils
- Insurer2: http://localhost:6984/_utils
- Coop: http://localhost:7984/_utils

Username: `admin`
Password: `adminpw`

**Note:** Platform peer (peer0.platform) is configured but not required for the current 3/4 endorsement policy.

## Common Operations

### Invoke a Chaincode Function

```bash
docker exec cli peer chaincode invoke \
  -o orderer.insurance.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
  -C insurance-main \
  -n access-control \
  -c '{"function":"GetOrganization","Args":["ORG_INSURER_001"]}'
```

### Query a Chaincode

```bash
docker exec cli peer chaincode query \
  -C insurance-main \
  -n farmer \
  -c '{"function":"GetFarmerPublic","Args":["FARMER_001"]}'
```

### View Container Logs

```bash
docker logs peer0.insurer1.insurance.com
docker logs orderer.insurance.com
```

### Stop the Network

```bash
cd network
./network.sh down
```

### Restart the Network

```bash
cd network
./network.sh restart
```

## Troubleshooting

### Issue: Containers fail to start

**Solution**: Check Docker resources
```bash
docker system prune -a
docker volume prune
```

### Issue: Chaincode deployment fails

**Solution**: Check chaincode dependencies
```bash
cd chaincode/access-control
go mod tidy
go mod vendor
```

### Issue: Permission denied on scripts

**Solution**: Set execute permissions
```bash
chmod +x network/*.sh
chmod +x scripts/*.sh
```

### Issue: Port conflicts

**Solution**: Check if ports are already in use
```bash
lsof -i :7050  # Orderer
lsof -i :7051  # Peer1
lsof -i :5984  # CouchDB
```

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Ordering Service                        │
│                  orderer.insurance.com                      │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐  ┌────────▼────────┐  ┌────────▼────────┐
│  Insurer1 Org  │  │  Insurer2 Org   │  │   Coop Org      │
│  peer0:7051    │  │  peer0:8051     │  │  peer0:9051     │
│  couchdb:5984  │  │  couchdb:6984   │  │  couchdb:7984   │
└────────────────┘  └─────────────────┘  └─────────────────┘

        ┌────────────────────┐
        │  Platform Org      │
        │  peer0:10051       │
        │  couchdb:8984      │
        └────────────────────┘
```

## Channel Configuration

**insurance-main**: Public channel for policies and weather data
- Participants: All organizations
- Chaincodes: policy, weather-oracle, index-calculator, audit-log

**Future Channels** (to be configured):
- **financial**: Private financial transactions
- **identity**: Protected farmer identity data
- **governance**: Platform administration

## Next Steps

1. **Customize Templates**: Modify policy templates for your region
2. **Integrate Oracles**: Connect real weather data APIs
3. **Add Organizations**: Onboard more insurers and cooperatives
4. **Configure Channels**: Set up private channels for sensitive data
5. **Deploy Frontend**: Build mobile app or web dashboard
6. **Set Up Monitoring**: Configure Prometheus and Grafana

## Support

For issues or questions:
1. Check logs: `docker logs <container_name>`
2. Review chaincode source code
3. Consult Hyperledger Fabric documentation
4. Test with the provided test script

## Security Notes

⚠️ **This is a development/academic setup. For production:**
- Generate proper certificates using Fabric CA
- Configure TLS properly for all components
- Set up proper access control and endorsement policies
- Implement backup and disaster recovery
- Configure monitoring and alerting
- Harden network security
- Use hardware security modules (HSM) for key management

---

**Ready to test!** Run `./scripts/test-platform.sh` to see the platform in action.
