#!/bin/bash

echo "============================================"
echo "Testing Claims Frontend Integration"
echo "============================================"
echo ""

echo "1. Checking API endpoint..."
echo "   GET http://localhost:3001/api/claims"
echo ""

RESPONSE=$(curl -s http://localhost:3001/api/claims)
SUCCESS=$(echo $RESPONSE | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('success', False))" 2>/dev/null)
COUNT=$(echo $RESPONSE | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('data', [])))" 2>/dev/null)

if [ "$SUCCESS" = "True" ]; then
    echo "   ✓ API is responding"
    echo "   ✓ Found $COUNT claims"
    echo ""
else
    echo "   ✗ API not responding properly"
    echo ""
    exit 1
fi

echo "2. Sample claim data:"
echo ""
echo $RESPONSE | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('data'):
    claim = data['data'][0]
    print(f\"   Claim ID: {claim.get('claimID')}\")
    print(f\"   Policy ID: {claim.get('policyID')}\")
    print(f\"   Farmer ID: {claim.get('farmerID')}\")
    print(f\"   Index ID: {claim.get('indexID')}\")
    print(f\"   Payout: \${claim.get('payoutAmount'):,} ({claim.get('payoutPercent')}%)\")
    print(f\"   Status: {claim.get('status')}\")
    print(f\"   Triggered: {claim.get('triggerDate')}\")
    print(f\"   Notes: {claim.get('notes', 'N/A')}\")
" 2>/dev/null

echo ""
echo "3. Frontend configuration:"
echo ""

if [ -f "/Users/yattmeo/Desktop/SMU/Code/Blockchain proj/Blockchain-Project/insurance-ui/.env" ]; then
    echo "   .env file found:"
    grep "VITE_DEV_MODE\|VITE_API_BASE_URL" /Users/yattmeo/Desktop/SMU/Code/Blockchain\ proj/Blockchain-Project/insurance-ui/.env | sed 's/^/   /'
else
    echo "   ⚠️  .env file not found"
fi

echo ""
echo "============================================"
echo "Frontend Integration Check Complete"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Rebuild frontend: cd insurance-ui && npm run build"
echo "2. Start dev server: npm run dev"
echo "3. Open http://localhost:5173/claims in browser"
echo "4. Check browser console for any errors"
echo ""
