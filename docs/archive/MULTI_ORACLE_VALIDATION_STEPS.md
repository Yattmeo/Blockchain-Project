# Manual Multi-Oracle Consensus Validation Steps

## Current Status

✅ **5 Oracle Providers Registered:**
- ORACLE_WEATHER_001 (Thailand Meteorological Department - API)
- ORACLE_SAT_001 (NOAA Satellite - Satellite)
- ORACLE_IOT_001 (AgriTech IoT - IoT)
- ORACLE_STATION_001 (Bangkok Weather Station - Manual)
- ORACLE_API_001 (OpenWeatherMap - API) - **Note: May be inactive due to anomalous submissions**

✅ **Multi-Oracle Weather Data Submitted:**
- 20 weather observations across 4 scenarios
- Data includes: normal weather, drought, heavy rainfall, and heat stress conditions

✅ **Consensus Validation Endpoint Implemented:**
- POST /api/weather-oracle/validate-consensus
- Takes location, timestamp, and array of dataIDs
- Updates status to "Validated" or "Anomalous"

✅ **One Consensus Validation Completed:**
- Scenario 1 (Normal Weather - Central Bangkok): 5 data points validated
- Status changed from "Pending" to "Validated"
- Validation scores updated to 100

## Next Steps to Complete

### 1. Restart API Gateway

The API gateway needs to be restarted to pick up the latest controller changes:

```bash
# In a terminal with Node.js in PATH:
cd api-gateway
npm run dev
```

**Or use the start script:**
```bash
./start-full-system.sh
```

### 2. Validate Remaining Scenarios

Once API gateway is running, validate the remaining weather data:

#### Scenario 2: Drought Conditions (North ChiangMai)

```bash
# Get the drought data IDs
curl -s "http://localhost:3001/api/weather-oracle/location/North_ChiangMai" | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
if data['success']:
    drought = [d for d in data['data'] if 30 < d['rainfall'] < 70][-5:]
    ids = [d['dataID'] for d in drought]
    print('DataIDs:', ids)
"

# Validate consensus (replace IDs with actual values from above)
curl -X POST "http://localhost:3001/api/weather-oracle/validate-consensus" \
  -H "Content-Type: application/json" \
  -d '{
    "location": "North_ChiangMai",
    "timestamp": "2025-11-11T17:00:00Z",
    "dataIDs": ["WEATHER_XXX_006", "WEATHER_XXX_007", "WEATHER_XXX_008", "WEATHER_XXX_009", "WEATHER_XXX_010"]
  }'
```

**Expected Result:** 4/5 consensus (one outlier - the 65mm reading should be flagged as anomalous)

#### Scenario 3: Heavy Rainfall (South Songkhla)

```bash
# Get the heavy rainfall data IDs
curl -s "http://localhost:3001/api/weather-oracle/location/South_Songkhla" | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
if data['success']:
    heavy_rain = [d for d in data['data'] if d['rainfall'] > 200][-5:]
    ids = [d['dataID'] for d in heavy_rain]
    print('DataIDs:', ids)
"

# Validate consensus
curl -X POST "http://localhost:3001/api/weather-oracle/validate-consensus" \
  -H "Content-Type: application/json" \
  -d '{
    "location": "South_Songkhla",
    "timestamp": "2025-11-11T17:00:00Z",
    "dataIDs": ["WEATHER_XXX_011", "WEATHER_XXX_012", "WEATHER_XXX_013", "WEATHER_XXX_014", "WEATHER_XXX_015"]
  }'
```

**Expected Result:** High consensus - all 5 oracles agree (220-228mm range)

#### Scenario 4: Heat Stress (Central Bangkok)

```bash
# Get the heat stress data IDs
curl -s "http://localhost:3001/api/weather-oracle/location/Central_Bangkok" | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
if data['success']:
    heat = [d for d in data['data'] if d['temperature'] > 35][-5:]
    ids = [d['dataID'] for d in heat]
    print('DataIDs:', ids)
"

# Validate consensus
curl -X POST "http://localhost:3001/api/weather-oracle/validate-consensus" \
  -H "Content-Type: application/json" \
  -d '{
    "location": "Central_Bangkok",
    "timestamp": "2025-11-11T17:30:00Z",
    "dataIDs": ["WEATHER_XXX_016", "WEATHER_XXX_017", "WEATHER_XXX_018", "WEATHER_XXX_019", "WEATHER_XXX_020"]
  }'
```

**Expected Result:** High consensus - all oracles agree (38.2-38.8°C range)

### 3. Verify Validation Results

After running consensus validation, check the status of the data:

```bash
# Check a specific weather data point
curl -s "http://localhost:3001/api/weather-oracle/WEATHER_XXX_001" | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
if data['success']:
    d = data['data']
    print(f\"Data ID: {d['dataID']}\")
    print(f\"Oracle: {d['oracleID']}\")
    print(f\"Status: {d['status']}\")
    print(f\"Validation Score: {d['validationScore']}\")
    print(f\"Rainfall: {d['rainfall']}mm\")
    print(f\"Temperature: {d['temperature']}°C\")
"
```

### 4. Check Oracle Reputation Scores

After validation, check if any oracle's reputation was affected:

```bash
# Check each oracle's reputation
for oracle in ORACLE_WEATHER_001 ORACLE_SAT_001 ORACLE_IOT_001 ORACLE_STATION_001 ORACLE_API_001; do
  echo "Checking $oracle:"
  curl -s "http://localhost:3001/api/weather-oracle/oracle/$oracle" 2>/dev/null | \
    python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('success'):
        o = data['data']
        print(f\"  Reputation: {o['reputationScore']}\")
        print(f\"  Status: {o['status']}\")
        print(f\"  Total Submissions: {o.get('totalSubmissions', 0)}\")
        print(f\"  Anomalous Count: {o.get('anomalousCount', 0)}\")
except:
    print('  Error or not found')
"
  echo ""
done
```

### 5. View All Weather Data Summary

Get an overview of all weather data and their validation status:

```bash
for location in Central_Bangkok North_ChiangMai South_Songkhla; do
  echo "$location:"
  curl -s "http://localhost:3001/api/weather-oracle/location/$location" | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
if data['success']:
    records = data['data']
    validated = [d for d in records if d['status'] == 'Validated']
    pending = [d for d in records if d['status'] == 'Pending']
    anomalous = [d for d in records if d['status'] == 'Anomalous']
    
    print(f'  Total: {len(records)} | Validated: {len(validated)} | Pending: {len(pending)} | Anomalous: {len(anomalous)}')
"
  echo ""
done
```

### 6. Test Claim Triggering

After weather data is validated, check if claims are automatically triggered:

```bash
# Check if any claims were created
curl -s "http://localhost:3001/api/claims" | python3 -m json.tool

# Or check claims for specific policy
curl -s "http://localhost:3001/api/claims/policy/1234556" | python3 -m json.tool
```

## Expected Final State

After completing all validations:

**Central Bangkok:**
- Normal Weather: 5 validated (75-77mm rainfall, 28.2-28.8°C) ✅ DONE
- Heat Stress: 5 validated (44.5-46mm rainfall, 38.2-38.8°C) ⏳ PENDING

**North ChiangMai:**
- Drought: 4 validated, 1 anomalous (outlier at 65mm) ⏳ PENDING
- Should trigger Rice Drought claim (validated rainfall < 50mm)

**South Songkhla:**
- Heavy Rain: 5 validated (220-228mm rainfall) ⏳ PENDING
- Should trigger Wheat Excess Rain claim (validated rainfall > 200mm)

**Oracle Reputation:**
- ORACLE_API_001: Likely decreased reputation due to anomalous 65mm reading
- Other oracles: Should maintain high reputation (100 or close to it)

## Troubleshooting

### API Gateway Not Responding

If the API returns connection errors:

1. Check if API gateway is running: `ps aux | grep "npm run dev" | grep api-gateway`
2. If not running, start it from terminal with Node.js in PATH
3. Check logs: `tail -f api-gateway/logs/*.log`

### Weather Data Not Found

If weather data queries return empty:
- Verify chaincode is deployed: `./verify-chaincode-installation.sh`
- Check if data was submitted successfully during simulation
- Try querying by specific dataID instead of location

### Consensus Validation Fails

If validation returns errors:
- Ensure at least 2 data points are provided
- Check that all dataIDs exist and are for the same location
- Verify timestamp is in RFC3339 format
- Check that oracles are in "Active" status

## Success Criteria

✅ All weather data has status "Validated" or "Anomalous" (none "Pending")
✅ Anomalous data identified (expected: 1 outlier in drought scenario)
✅ Oracle reputation scores updated correctly
✅ Claims auto-triggered for validated weather events exceeding thresholds
✅ Weather page UI displays all data with correct validation status

## Next Phase

Once consensus validation is complete:
1. Test automatic claim creation based on validated weather data
2. Verify index calculator processes validated data only
3. Test claim approval workflow with multi-oracle validated triggers
4. Update UI to show oracle provider information and consensus status
