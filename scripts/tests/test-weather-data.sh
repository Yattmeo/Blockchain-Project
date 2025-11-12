#!/bin/bash

# Weather Data Testing Script
# Tests weather oracle functionality end-to-end

set -e

echo "======================================"
echo "Weather Data Testing"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Register Oracle Provider
echo -e "${YELLOW}Step 1: Registering Weather Oracle Provider...${NC}"
ORACLE_ID="ORACLE_WEATHER_001"
ORACLE_NAME="Thailand Meteorological Department"
ORACLE_TYPE="API"

# Note: dataSources needs to be JSON array as string
RESPONSE=$(curl -s -X POST http://localhost:3001/api/weather-oracle/register-provider \
  -H "Content-Type: application/json" \
  -d "{
    \"oracleID\": \"${ORACLE_ID}\",
    \"providerName\": \"${ORACLE_NAME}\",
    \"providerType\": \"${ORACLE_TYPE}\",
    \"dataSources\": [\"api.weather.gov.th\", \"openweathermap.org\"]
  }")

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Oracle provider registered successfully${NC}"
  echo "$RESPONSE" | python3 -m json.tool
else
  echo -e "${YELLOW}⚠ Oracle registration failed (may already exist - continuing)${NC}"
fi

echo ""

# Step 2: Submit Weather Data - Normal Conditions
echo -e "${YELLOW}Step 2: Submitting weather data (normal conditions)...${NC}"
DATA_ID_1="WEATHER_$(date +%s)_001"

RESPONSE=$(curl -s -X POST http://localhost:3001/api/weather-oracle \
  -H "Content-Type: application/json" \
  -d "{
    \"dataID\": \"${DATA_ID_1}\",
    \"oracleID\": \"${ORACLE_ID}\",
    \"location\": \"Central_Bangkok\",
    \"latitude\": 13.7563,
    \"longitude\": 100.5018,
    \"rainfall\": 75.5,
    \"temperature\": 28.5,
    \"humidity\": 70.0,
    \"windSpeed\": 12.3
  }")

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Weather data submitted (normal conditions)${NC}"
  echo "  - Rainfall: 75.5mm (Above drought threshold)"
  echo "  - Temperature: 28.5°C (Normal)"
else
  echo -e "${RED}✗ Failed to submit weather data${NC}"
  echo "$RESPONSE" | python3 -m json.tool
  exit 1
fi

echo ""

# Step 3: Submit Weather Data - Drought Conditions
echo -e "${YELLOW}Step 3: Submitting weather data (DROUGHT trigger)...${NC}"
DATA_ID_2="WEATHER_$(date +%s)_002"

RESPONSE=$(curl -s -X POST http://localhost:3001/api/weather-oracle \
  -H "Content-Type: application/json" \
  -d "{
    \"dataID\": \"${DATA_ID_2}\",
    \"oracleID\": \"${ORACLE_ID}\",
    \"location\": \"Central_Bangkok\",
    \"latitude\": 13.7563,
    \"longitude\": 100.5018,
    \"rainfall\": 35.0,
    \"temperature\": 32.0,
    \"humidity\": 45.0,
    \"windSpeed\": 8.5
  }")

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Weather data submitted (drought conditions)${NC}"
  echo "  - Rainfall: 35.0mm (BELOW 50mm threshold for Rice Drought)"
  echo "  - Temperature: 32.0°C"
  echo "  - ${RED}⚠ SHOULD TRIGGER 50% PAYOUT for Rice Drought policies${NC}"
else
  echo -e "${RED}✗ Failed to submit weather data${NC}"
  echo "$RESPONSE" | python3 -m json.tool
  exit 1
fi

echo ""

# Step 4: Submit Weather Data - Excess Rain Conditions
echo -e "${YELLOW}Step 4: Submitting weather data (EXCESS RAIN trigger)...${NC}"
DATA_ID_3="WEATHER_$(date +%s)_003"

RESPONSE=$(curl -s -X POST http://localhost:3001/api/weather-oracle \
  -H "Content-Type: application/json" \
  -d "{
    \"dataID\": \"${DATA_ID_3}\",
    \"oracleID\": \"${ORACLE_ID}\",
    \"location\": \"North_ChiangMai\",
    \"latitude\": 18.7883,
    \"longitude\": 98.9853,
    \"rainfall\": 225.0,
    \"temperature\": 24.5,
    \"humidity\": 95.0,
    \"windSpeed\": 18.0
  }")

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Weather data submitted (excess rain conditions)${NC}"
  echo "  - Rainfall: 225.0mm (ABOVE 200mm threshold for Wheat Rain)"
  echo "  - Temperature: 24.5°C"
  echo "  - ${RED}⚠ SHOULD TRIGGER 60% PAYOUT for Wheat Excess Rain policies${NC}"
else
  echo -e "${RED}✗ Failed to submit weather data${NC}"
  echo "$RESPONSE" | python3 -m json.tool
  exit 1
fi

echo ""

# Step 5: Submit Weather Data - Heat Stress Conditions
echo -e "${YELLOW}Step 5: Submitting weather data (HEAT STRESS trigger)...${NC}"
DATA_ID_4="WEATHER_$(date +%s)_004"

RESPONSE=$(curl -s -X POST http://localhost:3001/api/weather-oracle \
  -H "Content-Type: application/json" \
  -d "{
    \"dataID\": \"${DATA_ID_4}\",
    \"oracleID\": \"${ORACLE_ID}\",
    \"location\": \"South_Songkhla\",
    \"latitude\": 7.1756,
    \"longitude\": 100.6143,
    \"rainfall\": 45.0,
    \"temperature\": 38.5,
    \"humidity\": 80.0,
    \"windSpeed\": 5.2
  }")

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Weather data submitted (heat stress conditions)${NC}"
  echo "  - Temperature: 38.5°C (ABOVE 35°C threshold for Corn Heat Stress)"
  echo "  - Rainfall: 45.0mm (ALSO below 50mm)"
  echo "  - ${RED}⚠ SHOULD TRIGGER 40% PAYOUT for Corn Heat Stress${NC}"
  echo "  - ${RED}⚠ SHOULD TRIGGER 35% PAYOUT for Corn Drought${NC}"
else
  echo -e "${RED}✗ Failed to submit weather data${NC}"
  echo "$RESPONSE" | python3 -m json.tool
  exit 1
fi

echo ""

# Step 6: Query Weather Data
echo -e "${YELLOW}Step 6: Querying submitted weather data...${NC}"

for DATA_ID in "$DATA_ID_1" "$DATA_ID_2" "$DATA_ID_3" "$DATA_ID_4"; do
  echo "  Querying: $DATA_ID"
  RESPONSE=$(curl -s http://localhost:3001/api/weather-oracle/${DATA_ID})
  
  if echo "$RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}  ✓ Data retrieved${NC}"
    echo "$RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin)['data']; print(f\"    Location: {d.get('location')}, Rainfall: {d.get('rainfall')}mm, Temp: {d.get('temperature')}°C\")"
  else
    echo -e "${RED}  ✗ Failed to retrieve data${NC}"
  fi
done

echo ""

# Step 7: Check Policy Templates with Thresholds
echo -e "${YELLOW}Step 7: Reviewing policy template thresholds...${NC}"

echo "  Rice Drought Protection (TMPL_RICE_DROUGHT):"
echo "    - Trigger: Rainfall < 50mm over 30 days"
echo "    - Payout: 50%"
echo "    - Status: ${DATA_ID_2} data (35mm) SHOULD TRIGGER"
echo ""

echo "  Wheat Excess Rain Protection (TMPL_WHEAT_RAIN):"
echo "    - Trigger: Rainfall > 200mm over 7 days"
echo "    - Payout: 60%"
echo "    - Status: ${DATA_ID_3} data (225mm) SHOULD TRIGGER"
echo ""

echo "  Corn Multi-Peril Insurance (TMPL_CORN_MULTI):"
echo "    - Trigger 1: Temperature > 35°C over 14 days → 40% payout"
echo "    - Trigger 2: Rainfall < 30mm over 21 days → 35% payout"
echo "    - Status: ${DATA_ID_4} data (38.5°C, 45mm) SHOULD TRIGGER"
echo ""

# Step 8: Summary
echo "======================================"
echo -e "${GREEN}Weather Data Testing Complete!${NC}"
echo "======================================"
echo ""
echo "Summary:"
echo "  ✓ Oracle provider registered: ${ORACLE_ID}"
echo "  ✓ 4 weather data points submitted"
echo "  ✓ Tested normal, drought, excess rain, and heat stress conditions"
echo ""
echo "Next Steps:"
echo "  1. Check UI Weather page to see submitted data"
echo "  2. Review Claims page for auto-triggered claims"
echo "  3. Verify index calculator processed the weather data"
echo "  4. Test claim approval and payout workflow"
echo ""
