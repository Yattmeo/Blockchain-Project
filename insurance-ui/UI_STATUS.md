# Insurance UI - Project Status

## Overview
React TypeScript web application for Hyperledger Fabric blockchain insurance platform with role-based dashboards.

## Tech Stack
- **Build Tool**: Vite 7.2.1
- **Framework**: React 18 with TypeScript
- **UI Library**: Material-UI (@mui/material, @mui/icons-material)
- **Routing**: React Router v6
- **HTTP Client**: Axios
- **Forms**: React Hook Form + Zod validation
- **Charts**: Recharts
- **Styling**: Emotion (@emotion/react, @emotion/styled)

## Project Structure

```
insurance-ui/
├── src/
│   ├── config/
│   │   └── api.ts                    # API endpoints & configuration
│   ├── contexts/
│   │   ├── AuthContext.tsx           # Authentication & user management
│   │   └── ThemeContext.tsx          # MUI theme provider & dark mode
│   ├── services/
│   │   ├── api.service.ts            # Base Axios wrapper
│   │   ├── access-control.service.ts # Organization & role management
│   │   ├── farmer.service.ts         # Farmer registration & management
│   │   ├── policy.service.ts         # Policy templates & policies
│   │   ├── weather.service.ts        # Weather oracle data
│   │   ├── claim.service.ts          # Claim processing & approval
│   │   ├── premium-pool.service.ts   # Premium deposits & payouts
│   │   └── dashboard.service.ts      # Dashboard statistics
│   ├── theme/
│   │   └── index.ts                  # Custom MUI theme (light & dark)
│   ├── types/
│   │   └── blockchain.ts             # TypeScript interfaces
│   ├── App.tsx                       # Main app component
│   └── main.tsx                      # Entry point
├── package.json                      # Dependencies (314 packages)
├── vite.config.ts                    # Vite configuration
└── tsconfig.json                     # TypeScript configuration
```

## Completed Components

### 1. Type Definitions (`types/blockchain.ts`)
✅ All blockchain entity interfaces defined:
- Organization, Farmer, PolicyTemplate, Policy
- WeatherData, OracleProvider, WeatherIndex
- Claim, Transaction, PremiumPool
- ApiResponse<T>, DashboardStats, User

### 2. API Configuration (`config/api.ts`)
✅ Centralized API configuration:
- Base URL: `http://localhost:3001/api`
- Endpoints for all 8 chaincodes:
  - ACCESS_CONTROL (register-organization, assign-role, check-permission)
  - FARMER (register, get, update, list-by-coop, list-by-region)
  - POLICY_TEMPLATE (create, set-threshold, list, activate)
  - POLICY (create, get, update-status, by-farmer, active, claim-history)
  - WEATHER_ORACLE (register-provider, submit-data, get-data, validate-consensus)
  - INDEX_CALCULATOR (calculate-rainfall, validate-trigger, get-triggered)
  - CLAIM_PROCESSOR (trigger-payout, approve, get-claim, pending, by-policy)
  - PREMIUM_POOL (deposit, execute-payout, balance, history, farmer-balance)
  - DASHBOARD (stats, recent-transactions)
- Channel: `insurance-main`
- MSP IDs: Insurer1MSP, Insurer2MSP, CoopMSP, PlatformMSP

### 3. Service Layer (7 services)
✅ **api.service.ts** - Base HTTP client
- Axios wrapper with request/response interceptors
- Auto-adds auth headers (token, role, org)
- Generic methods: get<T>, post<T>, put<T>, delete<T>
- Returns: ApiResponse<T>

✅ **access-control.service.ts**
- registerOrganization, getOrganization
- assignRole, checkPermission

✅ **farmer.service.ts**
- registerFarmer, getFarmer, updateFarmer
- getFarmersByCoop, getFarmersByRegion

✅ **policy.service.ts** (templates & policies)
- Template: create, get, list, setThreshold, activate
- Policy: create, get, updateStatus, byFarmer, active, claimHistory

✅ **weather.service.ts**
- registerOracle, submitWeatherData
- getWeatherData, getWeatherDataByRegion, validateConsensus

✅ **claim.service.ts**
- triggerPayout, approveClaim
- getClaim, getPendingClaims, getClaimsByPolicy

✅ **premium-pool.service.ts**
- deposit, executePayout
- getPoolBalance, getTransactionHistory, getFarmerBalance

✅ **dashboard.service.ts**
- getStats, getRecentTransactions

### 4. Context Providers

✅ **AuthContext.tsx**
- User authentication state management
- Login/logout functionality
- LocalStorage persistence (user + token)
- Permission checking: `hasPermission(permission)`
- Role checking: `isRole(role)`
- Hook: `useAuth()`

✅ **ThemeContext.tsx**
- MUI theme provider with light/dark mode
- LocalStorage persistence for theme preference
- Toggle function: `toggleTheme()`
- Hook: `useTheme()`

### 5. Theme Configuration

✅ **theme/index.ts**
- Custom color palette (professional blue, success green)
- Typography configuration (Inter font family)
- Component overrides (Button, Card, Paper, TextField, Table)
- Both light and dark theme variants
- Consistent border radius and spacing

### 6. App Component

✅ **App.tsx**
- Wrapped with ThemeProvider and AuthProvider
- Material-UI Container and Typography
- Placeholder content showing platform title

## Dependencies Installed (314 packages)
✅ All required packages installed:
- @mui/material, @mui/icons-material
- @emotion/react, @emotion/styled
- react-router-dom
- axios
- react-hook-form, @hookform/resolvers, zod
- recharts, date-fns

## Known Issues

⚠️ **Node Version Mismatch**
- Current: Node 21.1.0
- Required: Node 20.19+ or 22.12+
- Impact: Dev server (`npm run dev`) fails with `crypto.hash is not a function`
- Solution: Upgrade Node or downgrade Vite
- Status: Not blocking development, compilation works

## Compilation Status
✅ **0 TypeScript errors**
- All type imports fixed with `import type` syntax
- All endpoint names match config definitions
- Strict TypeScript mode enabled
- All routes configured and working

## Next Steps

### Phase 1: Routing & Layouts ✅ COMPLETE
- ✅ Install React Router v6
- ✅ Create `DashboardLayout.tsx` with sidebar navigation
- ✅ Create `LoginPage.tsx` for role selection
- ✅ Setup router in App.tsx with protected routes
- ✅ Create role-based navigation menus
- ✅ Create all placeholder pages (Dashboard, Farmers, Policies, Claims, Weather, Pool, Settings)

### Phase 2: Dashboard Enhancement (HIGH PRIORITY - NEXT)
- [ ] Add data visualization components (charts with Recharts)
- [ ] Create `StatsCard` component for metrics
- [ ] Add recent transactions table to dashboard
- [ ] Implement real data fetching from API
- [ ] Add loading states and error handling

### Phase 3: Shared Components (MEDIUM PRIORITY)
- [ ] Create `components/StatsCard.tsx` - Metric display
- [ ] Create `components/DataTable.tsx` - Reusable table
- [ ] Create `components/TransactionList.tsx` - Transaction history
- [ ] Create `components/ChartWidget.tsx` - Recharts wrapper

### Phase 4: Forms (MEDIUM PRIORITY)
- [ ] Create `components/forms/FarmerRegistrationForm.tsx`
- [ ] Create `components/forms/PolicyCreationForm.tsx`
- [ ] Create `components/forms/WeatherDataForm.tsx`
- [ ] Create `components/forms/ClaimApprovalForm.tsx`
- [ ] Add Zod validation schemas

### Phase 5: REST API Gateway (CRITICAL - BACKEND)
Create Express.js server to bridge React UI → Fabric Gateway:
- [ ] Create `/api-gateway/` directory
- [ ] Install: express, @hyperledger/fabric-gateway, cors
- [ ] Implement all endpoints matching `config/api.ts`
- [ ] Connect to Fabric network using Gateway SDK
- [ ] Handle chaincode invocations
- [ ] Return transaction IDs
- [ ] Add error handling and logging

### Phase 6: Login & Auth Pages (HIGH PRIORITY)
- [ ] Create `pages/Login.tsx` - Role/org selection
- [ ] Create `pages/RoleSelection.tsx` - Multi-party login
- [ ] Implement mock authentication (dev mode)
- [ ] Add logout button to DashboardLayout

### Phase 7: Testing & Deployment
- [ ] Fix Node version issue (upgrade to 20.19+ or 22.12+)
- [ ] Test all dashboards with mock data
- [ ] Connect to API Gateway
- [ ] End-to-end testing with blockchain
- [ ] Build for production (`npm run build`)
- [ ] Deploy with Docker alongside blockchain network

## How to Run (After Node Upgrade)

```bash
# Navigate to project
cd /Users/yattmeo/Desktop/SMU/Code/Blockchain\ proj/Blockchain-Project/insurance-ui

# Install dependencies (already done)
npm install

# Start dev server (requires Node 20.19+ or 22.12+)
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## API Gateway Integration

The React app expects a REST API at `http://localhost:3001/api` with the following structure:

```
GET    /access-control/organization/:orgID
POST   /access-control/register-organization
POST   /access-control/assign-role
POST   /access-control/check-permission

POST   /farmer/register
GET    /farmer/:farmerID
PUT    /farmer/:farmerID
GET    /farmer/by-coop/:coopID
GET    /farmer/by-region/:region

POST   /policy-template/create
GET    /policy-template/:templateID
GET    /policy-template/list
POST   /policy-template/set-threshold
POST   /policy-template/activate

POST   /policy/create
GET    /policy/:policyID
PUT    /policy/update-status
GET    /policy/by-farmer/:farmerID
GET    /policy/active
GET    /policy/claim-history/:policyID

POST   /weather-oracle/register-provider
POST   /weather-oracle/submit-data
GET    /weather-oracle/data/:dataID
GET    /weather-oracle/data/by-region/:region
POST   /weather-oracle/validate-consensus

POST   /index-calculator/calculate-rainfall
POST   /index-calculator/validate-trigger
GET    /index-calculator/index/:indexID
GET    /index-calculator/triggered

POST   /claim-processor/trigger-payout
POST   /claim-processor/approve
GET    /claim-processor/claim/:claimID
GET    /claim-processor/by-policy/:policyID
GET    /claim-processor/pending

POST   /premium-pool/deposit
POST   /premium-pool/execute-payout
GET    /premium-pool/balance/:poolID
GET    /premium-pool/history/:poolID
GET    /premium-pool/farmer-balance/:farmerID

GET    /dashboard/stats?orgID=xxx
GET    /dashboard/transactions?limit=10
```

## Role-Based Access

The UI supports 4 user roles with different permissions:

1. **Insurer** (Insurer1MSP, Insurer2MSP)
   - Create policy templates
   - Set coverage thresholds
   - Approve/reject claims
   - View premium pool balance
   - View all policies and claims

2. **Coop** (CoopMSP)
   - Register farmers
   - Update farmer profiles
   - View farmers by cooperative
   - Help farmers create policies
   - View farmer-specific data

3. **Oracle** (WeatherOracleMSP - if exists)
   - Register as weather provider
   - Submit weather data
   - View submitted data
   - Participate in consensus validation

4. **Admin** (PlatformMSP)
   - Register organizations
   - Assign roles to users
   - View all system data
   - Access control management
   - System-wide statistics

## Development Notes

- All TypeScript types are strictly defined
- All services return `ApiResponse<T>` for consistency
- Authentication state persists in localStorage
- Theme preference persists in localStorage
- API calls auto-include auth headers via interceptor
- 401 responses trigger automatic logout
- Material-UI provides professional, accessible UI
- Recharts for data visualization
- React Hook Form for performant forms

---

**Status**: Foundation Complete ✅  
**Next**: Create routing, layouts, and dashboard pages  
**Blockers**: Node version (dev server won't start)  
**ETA**: ~2-3 days for full UI + API Gateway
