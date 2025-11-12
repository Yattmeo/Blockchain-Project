# Multi-Oracle Weather System - Setup Complete

## Overview
We have successfully set up a multi-oracle weather data system with consensus validation to ensure data accuracy and quality.

## Oracle Providers Registered

### 1. ORACLE_WEATHER_001
- **Provider**: Thailand Meteorological Department (TMD)
- **Type**: API
- **Data Sources**: Thailand weather APIs
- **Status**: Active

### 2. ORACLE_SAT_001
- **Provider**: NOAA Satellite Weather Service
- **Type**: Satellite
- **Data Sources**: NOAA-20, GOES-16, Himawari-8
- **Status**: Active

### 3. ORACLE_IOT_001
- **Provider**: AgriTech IoT Sensor Network
- **Type**: IoT
- **Data Sources**: Field Sensor Array, Weather Station Network
- **Status**: Active

### 4. ORACLE_STATION_001
- **Provider**: Bangkok Regional Weather Station
- **Type**: Manual
- **Data Sources**: Ground Station BKK-01, Observation Post
- **Status**: Active

### 5. ORACLE_API_001
- **Provider**: OpenWeatherMap API Service
- **Type**: API
- **Data Sources**: OpenWeatherMap APIs
- **Status**: Active

## Test Scenarios

### Scenario 1: Normal Weather Conditions
- **Location**: Central Bangkok
- **Oracles**: All 5 providers
- **Data**: Rainfall ~75mm, Temperature ~28.5°C
- **Expected**: High consensus (all within 20% variance)
- **Result**: ✓ All data validated

### Scenario 2: Drought Conditions with Outlier
- **Location**: North ChiangMai
- **Oracles**: All 5 providers (1 with anomalous data)
- **Data**: 4 oracles report ~35mm (drought), 1 oracle reports 65mm (outlier)
- **Expected**: 4/5 consensus, 1 anomalous
- **Result**: ✓ Consensus reached, outlier flagged

### Scenario 3: Heavy Rainfall Event
- **Location**: South Songkhla
- **Oracles**: All 5 providers
- **Data**: Rainfall ~225mm (exceeds wheat policy threshold)
- **Expected**: High consensus, should trigger claims
- **Result**: ✓ All data validated

### Scenario 4: Heat Stress Conditions
- **Location**: Central Bangkok
- **Oracles**: All 5 providers
- **Data**: Temperature ~38.5°C (exceeds corn policy threshold)
- **Expected**: High consensus, should trigger claims
- **Result**: ✓ All data validated

## Consensus Validation Mechanism

### How It Works
1. Multiple oracles submit weather data for the same location and time
2. System calculates average values for rainfall, temperature, humidity
3. Each submission is checked against the average (20% variance threshold)
4. Requires 2/3 consensus (67%) to validate data
5. Data within threshold → Status: "Validated", Score: 100
6. Data outside threshold → Status: "Anomalous", Score: 0
7. Oracle reputation scores are adjusted based on anomalous submissions

### Data Status Values
- **Pending**: Initial state, not yet validated
- **Validated**: Passed consensus validation (within 20% of average)
- **Anomalous**: Failed validation (outlier, > 20% variance)

### Validation Score
- **100**: Data validated by consensus
- **0**: Data flagged as anomalous

### Oracle Reputation System
- Starts at 100 for new oracles
- Decreases when oracle submits anomalous data
- Used to assess oracle trustworthiness
- Low reputation oracles may be suspended

## API Endpoints

### Register Oracle Provider
```bash
POST /api/weather-oracle/register-provider
{
  "oracleID": "ORACLE_XXX_001",
  "providerName": "Provider Name",
  "providerType": "API|Satellite|IoT|Manual",
  "dataSources": ["source1", "source2"]
}
```

### Submit Weather Data
```bash
POST /api/weather-oracle
{
  "dataID": "WEATHER_123456_001",
  "oracleID": "ORACLE_XXX_001",
  "location": "Location_Name",
  "latitude": 13.7563,
  "longitude": 100.5018,
  "rainfall": 75.0,
  "temperature": 28.5,
  "humidity": 70,
  "windSpeed": 12.0
}
```

### Validate Consensus
```bash
POST /api/weather-oracle/validate-consensus
{
  "location": "Central_Bangkok",
  "timestamp": "2025-11-11T17:00:00Z",
  "dataIDs": ["WEATHER_001", "WEATHER_002", "WEATHER_003", ...]
}
```

### Get Weather Data
```bash
GET /api/weather-oracle/:dataID
GET /api/weather-oracle/location/:location
```

## Scripts Available

### 1. setup-multiple-oracles.sh
- Registers 5 different oracle providers
- Creates diverse provider types (API, Satellite, IoT, Manual)
- Location: `test-scripts/setup-multiple-oracles.sh`

### 2. simulate-multi-oracle-weather.sh
- Simulates weather data submission from multiple oracles
- Tests 4 different weather scenarios
- Includes consensus and outlier cases
- Location: `test-scripts/simulate-multi-oracle-weather.sh`

### 3. run-consensus-validation.sh
- Validates consensus for all submitted data
- Updates data status to Validated/Anomalous
- Adjusts oracle reputation scores
- Location: `test-scripts/run-consensus-validation.sh`

### 4. validate-consensus.sh
- Checks current status of weather data
- Displays oracle reputation scores
- Location: `test-scripts/validate-consensus.sh`

## Usage Workflow

### Complete Setup and Testing
```bash
# Step 1: Register oracle providers
./test-scripts/setup-multiple-oracles.sh

# Step 2: Simulate weather data submissions
./test-scripts/simulate-multi-oracle-weather.sh

# Step 3: Run consensus validation
./test-scripts/run-consensus-validation.sh

# Step 4: Check validation results
./test-scripts/validate-consensus.sh
```

## Integration with Insurance System

### Claim Triggering
Weather data with "Validated" status should be used by:
1. **Index Calculator**: Calculates weather indices from validated data
2. **Claim Processor**: Triggers claims when validated data exceeds thresholds
3. **Approval Manager**: Processes claim approvals based on validated events

### Policy Template Thresholds
The validated weather data should trigger claims when:
- **Rice Drought**: Validated rainfall < 50mm/30 days → 50% payout
- **Wheat Heavy Rain**: Validated rainfall > 200mm/7 days → 60% payout
- **Corn Heat Stress**: Validated temperature > 35°C/14 days → 40% payout
- **Corn Drought**: Validated rainfall < 30mm/21 days → 35% payout

### Data Quality Assurance
- Only "Validated" weather data should trigger claims
- "Pending" data can be displayed but not used for payouts
- "Anomalous" data is flagged for review
- Oracle reputation ensures continuous data quality

## Next Steps

1. **UI Integration**: Update Weather page to show oracle provider info and validation status
2. **Claim Triggering**: Test automatic claim creation based on validated weather data
3. **Index Calculator**: Process validated data to calculate weather indices
4. **Notification System**: Alert farmers when validated weather triggers claims
5. **Oracle Monitoring**: Dashboard to track oracle performance and reputation

## Benefits

✓ **Data Accuracy**: Multiple oracles provide consensus-based validation
✓ **Fraud Prevention**: Outliers and anomalies are automatically detected
✓ **Trust**: 2/3 consensus requirement ensures reliable data
✓ **Accountability**: Oracle reputation system tracks data quality
✓ **Scalability**: Easy to add more oracle providers
✓ **Transparency**: All validation scores and statuses on blockchain

## Technical Notes

- Consensus requires minimum 2 oracles
- 20% variance threshold is configurable in chaincode
- Reputation scores affect oracle standing
- All data and validations stored immutably on blockchain
- Timestamps use RFC3339 format
- Data IDs must be unique across all submissions
