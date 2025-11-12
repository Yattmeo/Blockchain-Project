# Fabric Integration Quick Reference

## 🚀 Quick Start

```bash
# 1. Start everything
./start-full-system.sh

# 2. Access UI
# Open: http://localhost:5173

# 3. Test multi-party approval
# Login as: coop@example.com / password
# Register farmer → View approval
# Switch to: insurer1@example.com / password
# Approve request → Execute

# 4. Stop everything
./stop-full-system.sh
```

---

## 📍 Important Ports

| Service | Port | URL |
|---------|------|-----|
| UI | 5173 | http://localhost:5173 |
| API Gateway | 3001 | http://localhost:3001/api |
| Insurer1 Peer | 7051 | peer0.insurer1.insurance.com:7051 |
| Insurer2 Peer | 9051 | peer0.insurer2.insurance.com:9051 |
| Coop Peer | 11051 | peer0.coop.insurance.com:11051 |
| Oracle Peer | 13051 | peer0.oracle.insurance.com:13051 |
| Orderer | 7050 | orderer.insurance.com:7050 |

---

## 🔐 Test Accounts

| Organization | Email | Password |
|-------------|-------|----------|
| Coop | coop@example.com | password |
| Insurer1 | insurer1@example.com | password |
| Insurer2 | insurer2@example.com | password |
| Oracle | oracle@example.com | password |

---

## 🎯 Key Configuration Changes

### UI (.env)
```bash
VITE_DEV_MODE=false          # Was: true
VITE_LOG_API=true            # Was: false
```

### API Gateway (.env)
```bash
CHAINCODE_APPROVAL_MANAGER=approval-manager  # Added
```

### API Gateway (config/index.ts)
```typescript
approvalManager: process.env.CHAINCODE_APPROVAL_MANAGER || 'approval-manager',  // Added
```

---

## 📋 Verification Commands

### Check Network
```bash
docker ps | grep -E "peer|orderer"
```

### Check Chaincode
```bash
docker exec cli peer lifecycle chaincode queryinstalled
```

### Test API
```bash
curl http://localhost:3001/health
curl http://localhost:3001/api/approval/pending
```

### View Logs
```bash
tail -f logs/api-gateway.log
tail -f logs/ui-dev.log
```

---

## 🧪 Testing Checklist

- [ ] System starts without errors
- [ ] 4 peers + orderer running in Docker
- [ ] API health check returns 200
- [ ] UI loads at localhost:5173
- [ ] Can login with test accounts
- [ ] Can create approval request
- [ ] Request appears in Approvals page
- [ ] Correct org sees approve button
- [ ] Approve button works
- [ ] Progress bar updates
- [ ] Second org can approve
- [ ] Status changes to APPROVED
- [ ] Execute button appears
- [ ] Execute works
- [ ] Status changes to EXECUTED
- [ ] Data persists after refresh
- [ ] Different browsers see same data

---

## 🔧 Troubleshooting

### Docker not running
```bash
# macOS: Open Docker Desktop
open -a Docker
```

### Port already in use
```bash
# Kill processes
lsof -ti:3001 | xargs kill -9
lsof -ti:5173 | xargs kill -9
```

### Reset everything
```bash
./stop-full-system.sh
cd network && ./network.sh down && cd ..
./start-full-system.sh
```

### Check Fabric logs
```bash
docker logs peer0.insurer1.insurance.com
docker logs orderer.insurance.com
```

---

## 📊 Expected Response Times

- Query: 100-500ms
- Approve: 2-5 seconds
- Execute: 3-10 seconds

---

## 🎓 Key Concepts

**PENDING** = Waiting for approvals  
**APPROVED** = All orgs approved (not yet executed)  
**EXECUTED** = Operation committed to blockchain  

**Endorsement** = Multi-org signature requirement  
**Consensus** = Agreement before committing  

---

*Full guide: FABRIC_INTEGRATION_GUIDE.md*
