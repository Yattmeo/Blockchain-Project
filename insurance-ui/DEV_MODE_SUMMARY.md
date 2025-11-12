# Dev Mode Configuration - Implementation Summary

## Files Created

### 1. `/src/config/index.ts` - Main Configuration
**Purpose:** Central configuration with dev mode toggle
**Key Features:**
- `APP_CONFIG.DEV_MODE` - Toggle between mock and live data
- Environment variable support (VITE_DEV_MODE, VITE_API_BASE_URL, etc.)
- Helper functions: `isDevMode()`, `getApiBaseUrl()`
- Auto-logging of current mode when DEBUG enabled

### 2. `/src/utils/apiClient.ts` - Smart API Client
**Purpose:** Handles automatic switching between mock and real API calls
**Key Features:**
- `apiClient.execute()` - Main method that switches based on dev mode
- Request/response interceptors for logging
- Mock delay simulation (500ms default)
- Error simulation support
- Standard HTTP methods (get, post, put, delete, patch)

### 3. `/src/utils/mockData.ts` - Mock Data Generators
**Purpose:** Generate realistic mock data matching blockchain types
**Key Features:**
- `generateMockFarmers(count)` - Complete farmer records
- `generateMockPolicies(count)` - Policy records with proper status
- `generateMockClaims(count)` - Claim records with workflow states
- `generateMockWeatherData(count)` - Weather oracle data
- `generateMockTransactions(count)` - Transaction history
- `generateMockDashboardStats()` - Dashboard metrics

### 4. `.env` and `.env.example` - Environment Configuration
**Purpose:** Environment-specific settings
**Variables:**
```bash
VITE_DEV_MODE=true              # Toggle dev mode
VITE_API_BASE_URL=http://localhost:3001/api
VITE_DEBUG=true                 # Enable debug logging
VITE_LOG_API=false              # Log API calls
```

### 5. `DEV_MODE.md` - Documentation
**Purpose:** Complete guide for using dev mode
**Sections:**
- Configuration options
- Usage examples
- Code implementation patterns
- Mock data customization
- Troubleshooting guide

## Configuration Updated

### `/src/config/api.ts`
- Now imports and re-exports from `/src/config/index.ts`
- Maintains backward compatibility
- All existing imports still work

### `.gitignore`
- Added `.env` and `.env.local` to prevent committing secrets
- `.env.example` is tracked for documentation

## How to Use

### For Frontend Development (No Backend Needed)
```bash
# 1. Ensure .env has DEV_MODE=true
echo "VITE_DEV_MODE=true" > .env

# 2. Start dev server
npm run dev

# 3. All data is mocked automatically!
```

### For Integration Testing (With Backend)
```bash
# 1. Start API Gateway first
cd ../api-gateway && npm start

# 2. Disable dev mode
echo "VITE_DEV_MODE=false" > insurance-ui/.env

# 3. Start UI
cd insurance-ui && npm run dev

# 4. App connects to real blockchain!
```

### In Service Code
```typescript
import { apiClient } from '../utils/apiClient';
import { generateMockFarmers } from '../utils/mockData';

export const farmerService = {
  async getAllFarmers() {
    return apiClient.execute(
      () => apiClient.get('/farmer/list'),  // Real API
      generateMockFarmers(10),               // Mock data
      { mockDelay: 500 }                     // Optional config
    );
  }
};
```

## Benefits

1. **Faster Development** - No backend required for UI work
2. **Reliable Testing** - Consistent mock data for testing
3. **Demo Ready** - Works standalone for demos
4. **Easy Switching** - One environment variable toggles everything
5. **Type Safety** - Mock data matches real blockchain types
6. **Debugging** - Built-in logging and error simulation

## Next Steps

When building the API Gateway:
1. Services are already structured to use `apiClient.execute()`
2. Just implement the real API endpoint logic
3. Mock data fallback is automatic
4. No code changes needed in UI components

## Current Status

✅ Configuration system implemented
✅ API client with dev mode support
✅ Mock data generators for all types
✅ Environment file templates
✅ Complete documentation
✅ Backward compatibility maintained

Ready to proceed with API Gateway development!
