# Development Mode Configuration

## Overview

The insurance UI includes a **Dev Mode** toggle that allows you to develop and test the frontend without requiring the API Gateway backend to be running. This is useful for:

- Frontend development without backend dependencies
- UI/UX testing and iteration
- Demo purposes
- Offline development

## Configuration

### Environment Variables

Create a `.env` file in the `insurance-ui` directory (copy from `.env.example`):

```bash
# Development Mode - Uses mock data instead of API calls
VITE_DEV_MODE=true

# API Gateway URL (used when DEV_MODE=false)
VITE_API_BASE_URL=http://localhost:3001/api

# Debug Settings
VITE_DEBUG=true
VITE_LOG_API=false
```

### Configuration Options

#### `VITE_DEV_MODE`
- **Type:** `boolean` (string 'true' or 'false')
- **Default:** `true`
- **Description:** When `true`, the app uses mock data instead of making real API calls

#### `VITE_API_BASE_URL`
- **Type:** `string`
- **Default:** `http://localhost:3001/api`
- **Description:** Base URL for the API Gateway (used when DEV_MODE=false)

#### `VITE_DEBUG`
- **Type:** `boolean` (string 'true' or 'false')
- **Default:** `false`
- **Description:** Enables additional console logging for debugging

#### `VITE_LOG_API`
- **Type:** `boolean` (string 'true' or 'false')
- **Default:** `false`
- **Description:** Logs all API requests and responses to console

## Usage

### Development Mode (Mock Data)

1. Set `VITE_DEV_MODE=true` in `.env`
2. Start the dev server:
   ```bash
   npm run dev
   ```
3. All data will be mocked - no backend required!

### Production Mode (Live API)

1. Ensure API Gateway is running on `http://localhost:3001`
2. Set `VITE_DEV_MODE=false` in `.env`
3. Start the dev server:
   ```bash
   npm run dev
   ```
4. App will connect to the real blockchain backend

## Code Implementation

### Using Dev Mode in Services

The `apiClient` utility automatically handles dev mode switching:

```typescript
import { apiClient } from '../utils/apiClient';
import { generateMockFarmers } from '../utils/mockData';

export const farmerService = {
  async getAllFarmers() {
    return apiClient.execute(
      // Real API call (used when DEV_MODE=false)
      () => apiClient.get('/farmer/list'),
      // Mock data (used when DEV_MODE=true)
      generateMockFarmers(10)
    );
  }
};
```

### Checking Dev Mode

```typescript
import { isDevMode } from '../config';

if (isDevMode()) {
  console.log('Running in development mode with mock data');
} else {
  console.log('Running in production mode with live API');
}
```

## Mock Data

Mock data generators are available in `/src/utils/mockData.ts`:

- `generateMockFarmers(count)` - Generate farmer records
- `generateMockPolicies(count)` - Generate policy records
- `generateMockClaims(count)` - Generate claim records
- `generateMockWeatherData(count)` - Generate weather data
- `generateMockTransactions(count)` - Generate transactions
- `generateMockDashboardStats()` - Generate dashboard statistics

### Customizing Mock Data

You can modify the mock data generators to suit your testing needs:

```typescript
// src/utils/mockData.ts
export const generateMockFarmers = (count: number = 10): Farmer[] => {
  // Customize the mock data generation here
  return Array.from({ length: count }, (_, i) => ({
    farmerID: `F${i+1}`,
    firstName: `Farmer`,
    lastName: `${i+1}`,
    // ... other fields
  }));
};
```

## Switching Between Modes

### Quick Toggle (No Restart Required)

While the `.env` file sets the default, you can override it programmatically:

```typescript
// src/config/index.ts
export const APP_CONFIG = {
  DEV_MODE: import.meta.env.VITE_DEV_MODE === 'true' || true, // ← Change this
  // ...
};
```

### Runtime Configuration

The app logs its current mode when DEBUG_MODE is enabled. Check the browser console on load:

```
🔧 App Configuration: {
  mode: 'DEVELOPMENT (Mock Data)',
  apiUrl: 'http://localhost:3001/api',
  timeout: '30000ms'
}
```

## Best Practices

1. **Always use Dev Mode for UI development** - Faster iteration without backend dependencies
2. **Test with Production Mode before deployment** - Ensure real API integration works
3. **Keep mock data realistic** - Helps identify UI/UX issues early
4. **Use DEBUG_MODE during development** - Helps track data flow
5. **Commit `.env.example` but not `.env`** - Prevents exposing secrets

## Deployment

For production deployment:

1. Set `VITE_DEV_MODE=false`
2. Set `VITE_API_BASE_URL` to your production API Gateway URL
3. Build the app:
   ```bash
   npm run build
   ```
4. Deploy the `dist/` folder

## Troubleshooting

### App still shows mock data after setting DEV_MODE=false

1. Restart the dev server (Vite caches environment variables)
2. Clear browser cache
3. Check browser console for mode confirmation

### API calls failing in production mode

1. Verify API Gateway is running
2. Check `VITE_API_BASE_URL` is correct
3. Enable `VITE_LOG_API=true` to see request details
4. Check browser console for network errors

### Mock data not realistic enough

1. Modify generators in `/src/utils/mockData.ts`
2. Add more variety to the random data
3. Consider loading from JSON files for complex scenarios
