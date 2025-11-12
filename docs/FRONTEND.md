# 🎨 Frontend Documentation

Complete guide to the Weather Index Insurance Platform UI built with React and TypeScript.

---

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Project Structure](#project-structure)
4. [Pages](#pages)
5. [Components](#components)
6. [State Management](#state-management)
7. [API Integration](#api-integration)
8. [Styling](#styling)
9. [Development Guide](#development-guide)
10. [Testing](#testing)

---

## Overview

The frontend is a **React 18** application with **TypeScript** that provides a user-friendly interface for interacting with the blockchain-based insurance platform.

### Key Features
- ✅ Real-time blockchain data display
- ✅ Multi-organization role-based UI
- ✅ Responsive design (mobile-friendly)
- ✅ Material-UI components
- ✅ TypeScript for type safety
- ✅ Context-based state management

---

## Technology Stack

| Technology | Version | Purpose |
|-----------|---------|---------|
| **React** | 18.2.0 | UI framework |
| **TypeScript** | 5.0.0 | Type safety |
| **Material-UI** | 5.14.0 | Component library |
| **Vite** | 4.4.0 | Build tool |
| **Axios** | 1.5.0 | HTTP client |
| **React Router** | 6.15.0 | Navigation |
| **date-fns** | 2.30.0 | Date formatting |

---

## Project Structure

```
insurance-ui/
├── src/
│   ├── components/          # Reusable components
│   │   ├── ApprovalCard.tsx
│   │   ├── StatsCard.tsx
│   │   ├── DataTable.tsx
│   │   └── forms/           # Form components
│   ├── pages/               # Page components
│   │   ├── DashboardPage.tsx
│   │   ├── PoliciesPage.tsx
│   │   ├── ClaimsPage.tsx
│   │   ├── ApprovalsPage.tsx
│   │   ├── PremiumPoolPage.tsx
│   │   ├── FarmersPage.tsx
│   │   └── WeatherPage.tsx
│   ├── contexts/            # React contexts
│   │   └── AuthContext.tsx
│   ├── services/            # API service layer
│   │   ├── api.ts
│   │   ├── policyService.ts
│   │   ├── claimService.ts
│   │   ├── approvalService.ts
│   │   ├── premiumPoolService.ts
│   │   ├── weatherService.ts
│   │   └── farmerService.ts
│   ├── types/               # TypeScript definitions
│   │   └── blockchain.ts
│   ├── utils/               # Utility functions
│   ├── App.tsx              # Root component
│   └── main.tsx             # Entry point
├── public/                  # Static assets
├── package.json
├── vite.config.ts
└── tsconfig.json
```

---

## Pages

### 1. Dashboard (`/`)

**Purpose**: System overview and key metrics

**Features**:
- Total farmers count
- Active policies count
- Triggered claims count
- Premium pool balance
- Recent transactions
- Quick action buttons

**Code Location**: `src/pages/DashboardPage.tsx`

**State Management**:
```typescript
const [stats, setStats] = useState<DashboardStats | null>(null);

useEffect(() => {
  const fetchStats = async () => {
    const response = await dashboardService.getStats();
    setStats(response.data);
  };
  fetchStats();
}, []);
```

---

### 2. Policies (`/policies`)

**Purpose**: View and manage insurance policies

**Features**:
- View all policies (table view)
- Filter by status (Active, Pending, Expired)
- Create new policy (modal form)
- View policy details
- Export to CSV

**Code Location**: `src/pages/PoliciesPage.tsx`

**Key Components**:
```typescript
<DataTable
  columns={policyColumns}
  data={policies}
  loading={loading}
/>

<PolicyForm
  open={showForm}
  onClose={() => setShowForm(false)}
  onSubmit={handleCreatePolicy}
/>
```

**Table Columns**:
- Policy ID
- Farmer Name
- Crop Type
- Coverage Amount
- Premium
- Status
- Start Date
- End Date
- Actions

---

### 3. Approvals (`/approvals`)

**Purpose**: Multi-organization approval workflow

**Features**:
- Pending approval requests
- Approve/Reject buttons (role-based)
- Approval progress indicator
- Approval history timeline
- Filter by status

**Code Location**: `src/pages/ApprovalsPage.tsx`

**Key Components**:
```typescript
<ApprovalCard
  approval={approval}
  onApprove={handleApprove}
  onReject={handleReject}
  userOrg={user.orgId}
/>

<ApprovalProgressBar
  current={approval.approvalCount}
  required={approval.requiredApprovals}
/>
```

**Approval Flow**:
```typescript
const handleApprove = async (requestId: string) => {
  await approvalService.approve(requestId, {
    organizationID: user.orgId,
    approverID: user.id,
    comments: comments
  });
  // Refresh approvals
  fetchApprovals();
};
```

---

### 4. Claims (`/claims`)

**Purpose**: View and manage insurance claims

**Features**:
- View all claims
- Submit new claim (modal form)
- Track claim status
- View payout history
- Filter by status (Pending, Approved, Rejected)

**Code Location**: `src/pages/ClaimsPage.tsx`

**Claim Form Fields**:
```typescript
interface ClaimFormData {
  claimID: string;
  policyID: string;
  farmerID: string;
  weatherDataID: string;
  payoutPercent: number;
}
```

**Status Badge**:
```typescript
<Chip
  label={claim.status}
  color={getStatusColor(claim.status)}
  size="small"
/>
```

---

### 5. Premium Pool (`/premium-pool`)

**Purpose**: View shared insurance pool

**Features**:
- Current pool balance (large display)
- Total deposits/payouts stats
- Transaction history table
- Filter by type (Premium, Payout)
- Real-time balance updates

**Code Location**: `src/pages/PremiumPoolPage.tsx`

**Data Fetching**:
```typescript
useEffect(() => {
  const fetchData = async () => {
    // Fetch pool balance
    const balanceResponse = await premiumPoolService.getPoolBalance();
    setPoolBalance(balanceResponse.data);

    // Fetch transaction history
    const historyResponse = await premiumPoolService.getTransactionHistory();
    const validTransactions = historyResponse.data.filter(
      tx => tx.txID && tx.txID.trim() !== '' && tx.amount > 0
    );
    setTransactions(validTransactions);
  };
  fetchData();
}, []);
```

**Stats Calculation**:
```typescript
const totalPremiums = transactions
  .filter(tx => tx.type === 'Premium')
  .reduce((sum, tx) => sum + tx.amount, 0);

const totalPayouts = transactions
  .filter(tx => tx.type === 'Payout' || tx.type === 'Claim Payout')
  .reduce((sum, tx) => sum + tx.amount, 0);
```

---

### 6. Farmers (`/farmers`)

**Purpose**: Manage farmer registrations

**Features**:
- Farmer directory (card/table view)
- Register new farmer (modal form)
- View farmer details
- Search by name/location
- View farmer's policies and claims

**Code Location**: `src/pages/FarmersPage.tsx`

**Farmer Form**:
```typescript
interface FarmerFormData {
  farmerID: string;
  name: string;
  email: string;
  phone: string;
  location: string;
  farmSize: number;
  cropTypes: string[];
  cooperativeID: string;
}
```

---

### 7. Weather (`/weather`)

**Purpose**: View and submit weather data

**Features**:
- Submit weather data (oracle role)
- View weather history
- Location-based filtering
- Weather data visualization
- Oracle provider management

**Code Location**: `src/pages/WeatherPage.tsx`

**Weather Form**:
```typescript
interface WeatherFormData {
  dataID: string;
  oracleID: string;
  location: string;
  latitude: string;
  longitude: string;
  rainfall: number;
  temperature: number;
  humidity: number;
  windSpeed: number;
}
```

---

## Components

### Reusable Components

#### StatsCard
**Purpose**: Display metric cards on dashboard

```typescript
<StatsCard
  title="Total Farmers"
  value={stats.totalFarmers}
  icon={<People />}
  loading={loading}
  color="primary"
/>
```

**Props**:
- `title`: Card title
- `value`: Numeric value to display
- `icon`: Material-UI icon
- `loading`: Loading state
- `color`: Theme color (primary, info, success, error)
- `subtitle`: Optional subtitle

---

#### DataTable
**Purpose**: Generic table component for displaying data

```typescript
<DataTable
  columns={columns}
  data={data}
  loading={loading}
  onRowClick={handleRowClick}
/>
```

**Props**:
- `columns`: Array of column definitions
- `data`: Array of row data
- `loading`: Loading state
- `onRowClick`: Optional row click handler

**Column Definition**:
```typescript
interface Column {
  id: string;
  label: string;
  minWidth?: number;
  align?: 'left' | 'right' | 'center';
  format?: (value: any) => string;
}
```

---

#### ApprovalCard
**Purpose**: Display approval request with actions

```typescript
<ApprovalCard
  approval={approval}
  onApprove={handleApprove}
  onReject={handleReject}
  userOrg={user.orgId}
/>
```

**Features**:
- Shows approval status
- Approve/Reject buttons (conditional)
- Approval history timeline
- Progress indicator

---

#### ApprovalProgressBar
**Purpose**: Visual progress of approvals

```typescript
<ApprovalProgressBar
  current={2}
  required={2}
/>
```

**Display**: `2 / 2 Approvals` with progress bar

---

### Form Components

Located in `src/components/forms/`

- **PolicyForm** - Create/edit policies
- **ClaimForm** - Submit claims
- **FarmerForm** - Register farmers
- **WeatherForm** - Submit weather data

**Common Pattern**:
```typescript
interface FormProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (data: FormData) => Promise<void>;
  initialData?: FormData;
}
```

---

## State Management

### Context-Based Architecture

#### AuthContext

**Purpose**: Manage user authentication and organization

```typescript
interface AuthContextType {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
}

// Usage
const { user, login, logout } = useAuth();
```

**User Object**:
```typescript
interface User {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'insurer' | 'coop' | 'oracle';
  orgId: string;
}
```

---

### Component-Level State

**Pattern**: Use `useState` for component-specific data

```typescript
const [data, setData] = useState<DataType[]>([]);
const [loading, setLoading] = useState(true);
const [error, setError] = useState<string>('');
```

**Data Fetching Pattern**:
```typescript
useEffect(() => {
  const fetchData = async () => {
    try {
      setLoading(true);
      const response = await service.getData();
      if (response.success) {
        setData(response.data);
      } else {
        setError(response.error || 'Failed to load data');
      }
    } catch (err) {
      setError('An error occurred');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };
  fetchData();
}, [dependency]);
```

---

## API Integration

### Service Layer Architecture

All API calls go through service layer in `src/services/`

#### Base API Configuration

**File**: `src/services/api.ts`

```typescript
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3001/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Response interceptor for error handling
api.interceptors.response.use(
  response => response,
  error => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

export default api;
```

---

### Service Examples

#### Policy Service

**File**: `src/services/policyService.ts`

```typescript
import api from './api';
import { Policy, ApiResponse } from '../types/blockchain';

export const policyService = {
  // Get all policies
  getAllPolicies: async (): Promise<ApiResponse<Policy[]>> => {
    const response = await api.get('/policies');
    return response.data;
  },

  // Get policy by ID
  getPolicy: async (policyId: string): Promise<ApiResponse<Policy>> => {
    const response = await api.get(`/policies/${policyId}`);
    return response.data;
  },

  // Create policy
  createPolicy: async (policyData: Partial<Policy>): Promise<ApiResponse<any>> => {
    const response = await api.post('/policies', policyData);
    return response.data;
  },

  // Get policies by farmer
  getPoliciesByFarmer: async (farmerId: string): Promise<ApiResponse<Policy[]>> => {
    const response = await api.get(`/policies/farmer/${farmerId}`);
    return response.data;
  }
};
```

---

#### Premium Pool Service

**File**: `src/services/premiumPoolService.ts`

```typescript
export const premiumPoolService = {
  // Get pool balance
  getPoolBalance: async (): Promise<ApiResponse<number>> => {
    const response = await api.get('/premium-pool/balance');
    return response.data;
  },

  // Get transaction history
  getTransactionHistory: async (): Promise<ApiResponse<Transaction[]>> => {
    const response = await api.get('/premium-pool/history');
    return response.data;
  },

  // Deposit premium
  depositPremium: async (data: {
    amount: number;
    policyID: string;
    farmerID: string;
  }): Promise<ApiResponse<any>> => {
    const response = await api.post('/premium-pool/deposit', data);
    return response.data;
  },

  // Execute payout
  withdrawFunds: async (data: {
    amount: number;
    recipient: string;
    claimID: string;
    policyID: string;
  }): Promise<ApiResponse<any>> => {
    const response = await api.post('/premium-pool/withdraw', data);
    return response.data;
  }
};
```

---

### API Response Type

```typescript
interface ApiResponse<T> {
  success: boolean;
  data: T;
  error?: string;
  message?: string;
}
```

---

## Styling

### Material-UI Theme

**File**: `src/theme.ts`

```typescript
import { createTheme } from '@mui/material/styles';

export const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
    success: {
      main: '#4caf50',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    h4: {
      fontWeight: 600,
    },
  },
});
```

### Component Styling

**Inline Styles with `sx` prop**:
```typescript
<Box sx={{ 
  display: 'grid', 
  gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', 
  gap: 3 
}}>
  {/* Content */}
</Box>
```

**Styled Components** (if needed):
```typescript
import { styled } from '@mui/material/styles';

const StyledCard = styled(Card)(({ theme }) => ({
  padding: theme.spacing(3),
  borderRadius: theme.shape.borderRadius,
}));
```

---

## Development Guide

### Setup

```bash
cd insurance-ui
npm install
```

### Environment Variables

Create `.env` file:
```env
VITE_API_URL=http://localhost:3001/api
```

### Run Development Server

```bash
npm run dev
```

Access at: http://localhost:5173

### Build for Production

```bash
npm run build
```

Output: `dist/` directory

### Preview Production Build

```bash
npm run preview
```

---

### Adding a New Page

1. **Create page component** in `src/pages/`:
```typescript
// src/pages/NewPage.tsx
export const NewPage: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4">New Page</Typography>
      {/* Content */}
    </Box>
  );
};
```

2. **Add route** in `src/App.tsx`:
```typescript
<Route path="/new-page" element={<NewPage />} />
```

3. **Add navigation** (if needed):
```typescript
<MenuItem onClick={() => navigate('/new-page')}>
  New Page
</MenuItem>
```

---

### Adding a New Service

1. **Create service file** in `src/services/`:
```typescript
// src/services/newService.ts
import api from './api';

export const newService = {
  getData: async () => {
    const response = await api.get('/new-endpoint');
    return response.data;
  }
};
```

2. **Export from index**:
```typescript
// src/services/index.ts
export * from './newService';
```

3. **Use in component**:
```typescript
import { newService } from '../services';

const data = await newService.getData();
```

---

### TypeScript Types

**File**: `src/types/blockchain.ts`

**Adding New Types**:
```typescript
export interface NewType {
  id: string;
  name: string;
  createdAt: string;
}
```

**Using Types**:
```typescript
import { NewType } from '../types/blockchain';

const [data, setData] = useState<NewType | null>(null);
```

---

## Testing

### Manual Testing Checklist

- [ ] All pages load without errors
- [ ] Data displays correctly from API
- [ ] Forms submit successfully
- [ ] Error states display properly
- [ ] Loading states work
- [ ] Navigation works
- [ ] Responsive on mobile
- [ ] No console errors

### Testing with Mock Data

```typescript
// Enable mock mode when API unavailable
const useMockData = !import.meta.env.VITE_API_URL;

if (useMockData) {
  setData(mockData);
} else {
  const response = await service.getData();
  setData(response.data);
}
```

### Browser Testing

Test in:
- Chrome
- Firefox
- Safari
- Mobile browsers

---

## Best Practices

### 1. Component Structure

```typescript
// Imports
import { useState, useEffect } from 'react';
import { Box, Typography } from '@mui/material';

// Types
interface Props {
  data: DataType;
}

// Component
export const MyComponent: React.FC<Props> = ({ data }) => {
  // State
  const [loading, setLoading] = useState(false);
  
  // Effects
  useEffect(() => {
    // ...
  }, []);
  
  // Handlers
  const handleClick = () => {
    // ...
  };
  
  // Render
  return (
    <Box>
      {/* JSX */}
    </Box>
  );
};
```

### 2. Error Handling

```typescript
try {
  setLoading(true);
  const response = await service.getData();
  if (response.success) {
    setData(response.data);
  } else {
    setError(response.error || 'Operation failed');
  }
} catch (err) {
  setError('An unexpected error occurred');
  console.error('Error:', err);
} finally {
  setLoading(false);
}
```

### 3. Loading States

```typescript
if (loading) {
  return (
    <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
      <CircularProgress />
    </Box>
  );
}
```

### 4. Empty States

```typescript
if (!data || data.length === 0) {
  return (
    <Alert severity="info">
      No data available. Create your first item to get started.
    </Alert>
  );
}
```

---

## Performance Optimization

### 1. Memoization

```typescript
import { useMemo } from 'react';

const filteredData = useMemo(() => {
  return data.filter(item => item.status === 'active');
}, [data]);
```

### 2. Lazy Loading

```typescript
import { lazy, Suspense } from 'react';

const HeavyComponent = lazy(() => import('./HeavyComponent'));

<Suspense fallback={<CircularProgress />}>
  <HeavyComponent />
</Suspense>
```

### 3. Debouncing

```typescript
import { debounce } from 'lodash';

const debouncedSearch = useMemo(
  () => debounce((value) => {
    // Search logic
  }, 300),
  []
);
```

---

## Common Patterns

### Fetch Data on Mount

```typescript
useEffect(() => {
  const fetchData = async () => {
    const response = await service.getData();
    setData(response.data);
  };
  fetchData();
}, []);
```

### Conditional Rendering

```typescript
{user.role === 'insurer' && (
  <Button onClick={handleApprove}>Approve</Button>
)}
```

### Modal Forms

```typescript
const [open, setOpen] = useState(false);

<Button onClick={() => setOpen(true)}>Create</Button>

<Dialog open={open} onClose={() => setOpen(false)}>
  <Form onSubmit={handleSubmit} />
</Dialog>
```

---

## Troubleshooting

### Issue: API calls fail with CORS error

**Solution**: Ensure API Gateway has CORS enabled:
```typescript
// api-gateway/src/index.ts
app.use(cors({
  origin: 'http://localhost:5173'
}));
```

### Issue: Data not updating

**Solution**: Check dependencies in `useEffect`:
```typescript
useEffect(() => {
  fetchData();
}, [dependency]); // Add all dependencies
```

### Issue: Type errors

**Solution**: Ensure types are properly defined:
```typescript
// Explicit typing
const [data, setData] = useState<DataType[]>([]);

// Type assertion if needed
const response = await api.get('/data') as ApiResponse<DataType>;
```

---

## Additional Resources

- **React Docs**: https://react.dev
- **TypeScript Docs**: https://www.typescriptlang.org
- **Material-UI Docs**: https://mui.com
- **Vite Docs**: https://vitejs.dev

---

**Version**: 1.0.0  
**Last Updated**: November 2025
