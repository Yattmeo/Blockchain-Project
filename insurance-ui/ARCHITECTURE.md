# UI Architecture Overview

## Component Hierarchy

```
App.tsx (Router + Providers)
│
├── ThemeProvider (MUI theming)
│   └── AuthProvider (User state)
│       └── BrowserRouter
│           │
│           ├── LoginPage (Public)
│           │   └── Organization selection
│           │       └── Auto role assignment
│           │
│           ├── UnauthorizedPage (Public)
│           │
│           └── DashboardLayout (Protected)
│               ├── AppBar
│               │   ├── Menu toggle (mobile)
│               │   ├── Page title
│               │   ├── Theme toggle button
│               │   └── User avatar menu
│               │       └── Logout
│               │
│               ├── Drawer (Sidebar)
│               │   └── Navigation Menu (role-filtered)
│               │       ├── Dashboard
│               │       ├── Farmers (coop, admin)
│               │       ├── Policies (insurer, coop, admin)
│               │       ├── Claims (insurer, admin)
│               │       ├── Weather (oracle, admin)
│               │       ├── Pool (insurer, admin)
│               │       └── Settings
│               │
│               └── Main Content (Outlet)
│                   ├── DashboardPage
│                   ├── FarmersPage
│                   ├── PoliciesPage
│                   ├── ClaimsPage
│                   ├── WeatherPage
│                   ├── PremiumPoolPage
│                   └── SettingsPage
```

## Data Flow

```
User Actions
    ↓
Pages/Components
    ↓
Service Layer (7 services)
    ↓
API Service (Axios)
    ↓
[API Gateway] ← Not yet implemented
    ↓
[Fabric Gateway SDK]
    ↓
[Hyperledger Fabric Network]
```

## State Management

```
┌─────────────────────────────────────┐
│         Global State                │
├─────────────────────────────────────┤
│ AuthContext                         │
│  ├── user: User | null              │
│  ├── isAuthenticated: boolean       │
│  ├── login(user, token)             │
│  ├── logout()                       │
│  ├── hasPermission(permission)      │
│  └── isRole(role)                   │
├─────────────────────────────────────┤
│ ThemeContext                        │
│  ├── mode: 'light' | 'dark'         │
│  ├── toggleTheme()                  │
│  └── setTheme(mode)                 │
└─────────────────────────────────────┘
    ↓ Provided to all components
```

## Service Layer Architecture

```
┌──────────────────────────────────────────────────┐
│             Base API Service                     │
│  ├── Axios instance with interceptors            │
│  ├── Request: Add auth headers                   │
│  ├── Response: Handle 401 unauthorized           │
│  └── Generic methods: get, post, put, delete     │
└──────────────────────────────────────────────────┘
              ↓ Extended by
┌──────────────────────────────────────────────────┐
│         Chaincode-Specific Services              │
├──────────────────────────────────────────────────┤
│ AccessControlService                             │
│  ├── registerOrganization()                      │
│  ├── assignRole()                                │
│  └── checkPermission()                           │
├──────────────────────────────────────────────────┤
│ FarmerService                                    │
│  ├── registerFarmer()                            │
│  ├── getFarmer()                                 │
│  ├── updateFarmer()                              │
│  └── getFarmersByCoop()                          │
├──────────────────────────────────────────────────┤
│ PolicyService + PolicyTemplateService            │
│  ├── createTemplate()                            │
│  ├── createPolicy()                              │
│  ├── updatePolicyStatus()                        │
│  └── getClaimHistory()                           │
├──────────────────────────────────────────────────┤
│ WeatherOracleService                             │
│  ├── registerOracle()                            │
│  ├── submitWeatherData()                         │
│  └── validateConsensus()                         │
├──────────────────────────────────────────────────┤
│ ClaimService                                     │
│  ├── triggerPayout()                             │
│  ├── approveClaim()                              │
│  └── getPendingClaims()                          │
├──────────────────────────────────────────────────┤
│ PremiumPoolService                               │
│  ├── deposit()                                   │
│  ├── executePayout()                             │
│  └── getPoolBalance()                            │
├──────────────────────────────────────────────────┤
│ DashboardService                                 │
│  ├── getStats()                                  │
│  └── getRecentTransactions()                    │
└──────────────────────────────────────────────────┘
```

## Route Protection Flow

```
User navigates to route
        ↓
    Is route public?
        ├── Yes → Render page
        └── No → Check ProtectedRoute
                    ↓
            Is user authenticated?
                ├── No → Redirect to /login
                └── Yes → Check role requirements
                            ↓
                    Does user have required role?
                        ├── No → Redirect to /unauthorized
                        └── Yes → Check permissions (if specified)
                                    ↓
                            Has required permission?
                                ├── No → Redirect to /unauthorized
                                └── Yes → Render page
```

## Role-Based Menu Visibility

```
┌─────────────────────────────────────────────────┐
│                Navigation Items                 │
├─────────────────┬───────────────────────────────┤
│ Menu Item       │ Visible to Roles              │
├─────────────────┼───────────────────────────────┤
│ Dashboard       │ insurer, coop, oracle, admin  │
│ Farmers         │ coop, admin                   │
│ Policies        │ insurer, coop, admin          │
│ Claims          │ insurer, admin                │
│ Weather Data    │ oracle, admin                 │
│ Premium Pool    │ insurer, admin                │
│ Settings        │ insurer, coop, oracle, admin  │
└─────────────────┴───────────────────────────────┘
```

## API Endpoint Mapping

```
Frontend Service          →  API Endpoint                    →  Chaincode
────────────────────────────────────────────────────────────────────────────
farmerService            →  /farmer/*                        →  farmer-cc
  .registerFarmer()      →  POST /farmer/register            →  RegisterFarmer
  .getFarmer(id)         →  GET /farmer/:id                  →  GetFarmer
  
policyService            →  /policy/*                        →  policy-cc
  .createPolicy()        →  POST /policy/create              →  CreatePolicy
  .getPolicy(id)         →  GET /policy/:id                  →  GetPolicy
  
policyTemplateService    →  /policy-template/*               →  policy-template-cc
  .createTemplate()      →  POST /policy-template/create     →  CreateTemplate
  
weatherOracleService     →  /weather-oracle/*                →  weather-oracle-cc
  .submitWeatherData()   →  POST /weather-oracle/submit-data →  SubmitWeatherData
  
claimService             →  /claim-processor/*               →  claim-processor-cc
  .approveClaim()        →  POST /claim-processor/approve    →  ApproveClaim
  
premiumPoolService       →  /premium-pool/*                  →  premium-pool-cc
  .deposit()             →  POST /premium-pool/deposit       →  DepositPremium
  
accessControlService     →  /access-control/*                →  access-control-cc
  .registerOrg()         →  POST /access-control/register-org→  RegisterOrganization
```

## Storage Strategy

```
┌───────────────────────────────────────┐
│         LocalStorage                  │
├───────────────────────────────────────┤
│ insurance_user                        │
│  └── JSON: { id, name, role, orgId,   │
│              permissions[] }          │
├───────────────────────────────────────┤
│ insurance_token                       │
│  └── String: "mock-token-{id}"        │
├───────────────────────────────────────┤
│ insurance_theme_mode                  │
│  └── String: "light" | "dark"         │
└───────────────────────────────────────┘
    ↑ Persisted
    ↓ Restored on page load
```

## Build & Deployment Flow

```
Development
    ↓
npm run dev (Vite Dev Server)
    ↓ Hot Module Replacement
Browser (http://localhost:5173)
    ↓ API calls to
API Gateway (http://localhost:3001) ← Not yet implemented
    ↓
Fabric Gateway SDK
    ↓
Blockchain Network

─────────────────────────────

Production
    ↓
npm run build
    ↓
dist/ (Static files)
    ↓
Docker Container or Static Host
    ↓ Reverse proxy to
API Gateway (Same domain/port 3001)
    ↓
Fabric Network
```

## Type Safety Flow

```
blockchain.ts (TypeScript Interfaces)
    ↓
Service Layer (Typed DTOs)
    ↓
API Service (Generic methods with <T>)
    ↓
Returns ApiResponse<T>
    ↓
Components (Typed state)
    ↓
UI Rendering (Type-safe)
```

## Current Implementation Status

```
✅ Complete
├── Authentication system
├── Routing infrastructure
├── Layout system
├── Role-based access control
├── Service layer (all 7 services)
├── Type definitions
├── Theme system
└── All page structures

⏳ In Progress / Planned
├── Data tables with pagination
├── Form components
├── Charts and analytics
├── API Gateway (Express.js)
└── Real blockchain integration
```

---

This architecture provides:
- **Separation of Concerns**: Services, contexts, components isolated
- **Type Safety**: Full TypeScript coverage
- **Scalability**: Easy to add new pages/features
- **Security**: Role-based access at multiple levels
- **Maintainability**: Clear data flow and state management
