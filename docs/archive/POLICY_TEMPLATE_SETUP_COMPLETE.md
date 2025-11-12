# Policy Template Setup - Complete ✅

## Overview
Successfully created and configured the policy template system with weather-based payout triggers. This enables farmers to see the exact weather conditions that trigger insurance payouts before purchasing policies.

## What Was Accomplished

### 1. Created Policy Templates on Blockchain
Created three policy templates covering different crops and regions:

#### TMPL_RICE_DROUGHT (Central Region)
- **Crop**: Rice
- **Region**: Central
- **Risk Level**: Medium
- **Coverage Period**: 180 days
- **Max Coverage**: $100,000
- **Min Premium**: $500
- **Weather Triggers**:
  - Rainfall < 50mm over 30 days → 50% payout (Moderate drought)

#### TMPL_WHEAT_RAIN (North Region)
- **Crop**: Wheat
- **Region**: North
- **Risk Level**: High
- **Coverage Period**: 120 days
- **Max Coverage**: $80,000
- **Min Premium**: $600
- **Weather Triggers**:
  - Rainfall > 200mm over 7 days → 60% payout (Severe flooding)

#### TMPL_CORN_MULTI (South Region)
- **Crop**: Corn
- **Region**: South
- **Risk Level**: Medium
- **Coverage Period**: 150 days
- **Max Coverage**: $120,000
- **Min Premium**: $700
- **Weather Triggers**:
  - Temperature > 35°C for 14 days → 40% payout (Moderate heat stress)
  - Rainfall < 30mm over 21 days → 35% payout (Mild drought)

### 2. Created API Endpoints
Implemented full REST API for policy templates:

**Base URL**: `http://localhost:3001/api/policy-templates`

#### Endpoints:
- **GET /** - Get all active policy templates
  ```bash
  curl http://localhost:3001/api/policy-templates
  ```

- **GET /:templateId** - Get specific template details
  ```bash
  curl http://localhost:3001/api/policy-templates/TMPL_RICE_DROUGHT
  ```

- **GET /:templateId/thresholds** - Get weather thresholds for a template
  ```bash
  curl http://localhost:3001/api/policy-templates/TMPL_RICE_DROUGHT/thresholds
  ```

- **GET /by-region/:region** - Filter templates by region
  ```bash
  curl http://localhost:3001/api/policy-templates/by-region/Central
  ```

- **GET /by-crop/:cropType** - Filter templates by crop
  ```bash
  curl http://localhost:3001/api/policy-templates/by-crop/Rice
  ```

### 3. Files Created/Modified

#### New Files:
- `network/create-policy-templates.sh` - Script to create templates on blockchain
- `network/add-weather-thresholds.sh` - Script to add weather triggers
- `api-gateway/src/controllers/policyTemplate.controller.ts` - API controller
- `api-gateway/src/routes/policyTemplate.routes.ts` - Route definitions

#### Modified Files:
- `api-gateway/src/server.ts` - Added policy template routes

## How Templates Work

### Weather Threshold Structure
Each template can have multiple weather-based triggers:
```json
{
  "indexType": "Rainfall",        // Type: Rainfall, Temperature, Drought, Humidity
  "metric": "mm",                  // Unit of measurement
  "thresholdValue": 50,            // Trigger value
  "operator": "<",                 // Comparison: <, >, <=, >=, ==
  "measurementDays": 30,           // Period to measure over
  "payoutPercent": 50,             // % of coverage paid when triggered
  "severity": "Moderate"           // Mild, Moderate, Severe
}
```

### Example: Rice Drought Template
**Condition**: "If rainfall is less than 50mm over a 30-day period"
**Action**: "Farmer receives 50% of their policy coverage amount"
**Severity**: "Moderate drought condition"

This means if a farmer has a $10,000 policy and rainfall drops below 50mm for 30 days, they automatically receive $5,000 (50% payout).

## Testing the API

### Get All Templates:
```bash
curl http://localhost:3001/api/policy-templates | python3 -m json.tool
```

### Get Templates for Central Region:
```bash
curl http://localhost:3001/api/policy-templates/by-region/Central | python3 -m json.tool
```

### Get Weather Thresholds for Corn Template:
```bash
curl http://localhost:3001/api/policy-templates/TMPL_CORN_MULTI/thresholds | python3 -m json.tool
```

## Next Steps

### UI Integration
1. **Create PolicyTemplateCard Component**
   - Display template details (crop, region, coverage)
   - Show weather requirements in clear, readable format
   - Example:
     ```
     Weather Trigger Conditions:
     🌡️ Heat Stress: Temperature > 35°C for 14 days → 40% payout
     💧 Drought: Rainfall < 30mm over 21 days → 35% payout
     ```

2. **Update Policy Creation Page**
   - Fetch templates from API: `GET /api/policy-templates`
   - Display templates for farmer to select
   - Show full weather requirements before purchase
   - Calculate premium based on farm size

3. **Policy Creation Workflow**
   - Farmer selects template matching their crop/region
   - Reviews weather trigger conditions
   - Enters farm size for premium calculation
   - Submits policy creation request
   - Request goes through approval workflow
   - Approved policy stored on blockchain

### Template Management (Admin Features)
- Create new templates through admin interface
- Add/modify weather thresholds
- Activate/deactivate templates
- View template usage statistics

## Key Achievements ✅

1. **Transparency**: Farmers can now see exact weather conditions that trigger payouts
2. **Automation Ready**: Weather thresholds enable automated claim processing
3. **Flexibility**: Multiple thresholds per template (mild/moderate/severe conditions)
4. **Regional Coverage**: Templates specific to regions and crop types
5. **API Complete**: Full REST API for template management
6. **Multi-Peril Support**: Templates can combine multiple weather conditions (e.g., Corn has both temperature and rainfall triggers)

## Technical Details

### Chaincode Functions Used:
- `CreateTemplate` - Create new policy template
- `SetIndexThreshold` - Add weather trigger condition
- `GetActiveTemplates` - Query all active templates
- `GetTemplate` - Get specific template with all details
- `GetIndexThresholds` - Get weather conditions for template
- `ActivateTemplate` - Change template status from Draft to Active

### Data Flow:
1. Admin creates template on blockchain (via CLI/API)
2. Admin adds weather thresholds to template
3. Admin activates template
4. Frontend fetches templates via API
5. Farmer sees templates with weather requirements
6. Farmer selects template and creates policy
7. Policy references template ID
8. Weather oracle checks thresholds
9. Automatic payout if conditions met

## Status
✅ **COMPLETE**: Policy templates with weather thresholds are fully functional and accessible via API.

**Ready for UI integration** to display templates to farmers during policy creation.
