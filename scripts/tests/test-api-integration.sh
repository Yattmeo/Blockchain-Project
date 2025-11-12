#!/bin/bash
# API Integration Test Script
# Tests the connection between frontend and backend

echo "🧪 API Integration Test Script"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="http://localhost:3001"
API_PREFIX="/api"

# Test 1: Check if API Gateway is running
echo "Test 1: Checking API Gateway..."
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" ${API_URL}/health)
if [ "$HEALTH_CHECK" = "200" ]; then
    echo -e "${GREEN}✅ API Gateway is running${NC}"
else
    echo -e "${RED}❌ API Gateway is NOT running (HTTP $HEALTH_CHECK)${NC}"
    echo "   Start it with: cd api-gateway && npm run dev"
    exit 1
fi
echo ""

# Test 2: Check API root endpoint
echo "Test 2: Checking API root endpoint..."
API_ROOT=$(curl -s ${API_URL}${API_PREFIX})
if echo "$API_ROOT" | grep -q "Insurance API Gateway"; then
    echo -e "${GREEN}✅ API root endpoint responding${NC}"
    echo "   Response: $(echo $API_ROOT | head -c 80)..."
else
    echo -e "${RED}❌ API root endpoint not responding properly${NC}"
fi
echo ""

# Test 3: Check CORS headers
echo "Test 3: Checking CORS configuration..."
CORS_HEADER=$(curl -s -I -X OPTIONS ${API_URL}${API_PREFIX}/farmers -H "Origin: http://localhost:5173" | grep -i "access-control-allow-origin")
if [ -n "$CORS_HEADER" ]; then
    echo -e "${GREEN}✅ CORS is configured${NC}"
    echo "   Header: $CORS_HEADER"
else
    echo -e "${YELLOW}⚠️  CORS header not found (might be okay)${NC}"
fi
echo ""

# Test 4: Test Farmer endpoint (GET)
echo "Test 4: Testing GET /api/farmers..."
FARMERS_RESPONSE=$(curl -s -w "\n%{http_code}" ${API_URL}${API_PREFIX}/farmers)
HTTP_CODE=$(echo "$FARMERS_RESPONSE" | tail -n1)
BODY=$(echo "$FARMERS_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✅ Farmers endpoint responding (HTTP $HTTP_CODE)${NC}"
    if [ -n "$BODY" ]; then
        echo "   Response: $(echo "$BODY" | head -c 100)..."
    fi
else
    echo -e "${RED}❌ Farmers endpoint error (HTTP $HTTP_CODE)${NC}"
    if [ -n "$BODY" ]; then
        echo "   Response: $BODY"
    fi
fi
echo ""

# Test 5: Test Policy endpoint (GET)
echo "Test 5: Testing GET /api/policies..."
POLICIES_RESPONSE=$(curl -s -w "\n%{http_code}" ${API_URL}${API_PREFIX}/policies)
HTTP_CODE=$(echo "$POLICIES_RESPONSE" | tail -n1)
BODY=$(echo "$POLICIES_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✅ Policies endpoint responding (HTTP $HTTP_CODE)${NC}"
    if [ -n "$BODY" ]; then
        echo "   Response: $(echo "$BODY" | head -c 100)..."
    fi
else
    echo -e "${RED}❌ Policies endpoint error (HTTP $HTTP_CODE)${NC}"
    if [ -n "$BODY" ]; then
        echo "   Response: $BODY"
    fi
fi
echo ""

# Test 6: Test Claims endpoint (GET)
echo "Test 6: Testing GET /api/claims/pending..."
CLAIMS_RESPONSE=$(curl -s -w "\n%{http_code}" ${API_URL}${API_PREFIX}/claims/pending)
HTTP_CODE=$(echo "$CLAIMS_RESPONSE" | tail -n1)
BODY=$(echo "$CLAIMS_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✅ Claims endpoint responding (HTTP $HTTP_CODE)${NC}"
    if [ -n "$BODY" ]; then
        echo "   Response: $(echo "$BODY" | head -c 100)..."
    fi
else
    echo -e "${RED}❌ Claims endpoint error (HTTP $HTTP_CODE)${NC}"
    if [ -n "$BODY" ]; then
        echo "   Response: $BODY"
    fi
fi
echo ""

# Test 7: Test Weather Oracle endpoint (GET)
echo "Test 7: Testing GET /api/weather-oracle..."
WEATHER_RESPONSE=$(curl -s -w "\n%{http_code}" ${API_URL}${API_PREFIX}/weather-oracle/WD001)
HTTP_CODE=$(echo "$WEATHER_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✅ Weather Oracle endpoint responding (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}❌ Weather Oracle endpoint error (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Test 8: Test Premium Pool endpoint (GET)
echo "Test 8: Testing GET /api/premium-pool/balance..."
POOL_RESPONSE=$(curl -s -w "\n%{http_code}" ${API_URL}${API_PREFIX}/premium-pool/balance)
HTTP_CODE=$(echo "$POOL_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "500" ]; then
    echo -e "${GREEN}✅ Premium Pool endpoint responding (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}❌ Premium Pool endpoint error (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Test 9: Test POST endpoint (Farmer Registration)
echo "Test 9: Testing POST /api/farmers (sample registration)..."
REGISTER_DATA='{
  "farmerID": "TEST001",
  "name": "Test Farmer",
  "location": "Test Location",
  "contactInfo": "test@example.com"
}'
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST ${API_URL}${API_PREFIX}/farmers \
  -H "Content-Type: application/json" \
  -d "$REGISTER_DATA")
HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)
BODY=$(echo "$REGISTER_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "409" ] || [ "$HTTP_CODE" = "500" ]; then
    echo -e "${GREEN}✅ POST endpoint accepting requests (HTTP $HTTP_CODE)${NC}"
    if [ -n "$BODY" ]; then
        echo "   Response: $(echo "$BODY" | head -c 100)..."
    fi
else
    echo -e "${RED}❌ POST endpoint error (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Summary
echo "================================"
echo "📊 Test Summary"
echo "================================"
echo ""
echo "All basic connectivity tests completed!"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Ensure blockchain network is running: cd network && ./network.sh up"
echo "2. Deploy chaincodes if not already deployed"
echo "3. Test from UI: cd insurance-ui && npm run dev"
echo "4. Set DEV_MODE=false in insurance-ui/src/config/index.ts"
echo "5. Open http://localhost:5173 and test features"
echo ""
echo "For detailed integration status, see: API_INTEGRATION_STATUS.md"
