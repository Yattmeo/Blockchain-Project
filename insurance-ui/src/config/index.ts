// Application Configuration

/**
 * Development Mode Configuration
 * 
 * When DEV_MODE is true:
 * - Uses mock data instead of API calls
 * - Simulates blockchain responses
 * - Enables additional debugging features
 * - No backend connection required
 * 
 * When DEV_MODE is false:
 * - Connects to actual API Gateway
 * - Makes real blockchain transactions
 * - Requires backend to be running
 */
export const APP_CONFIG = {
  // Toggle dev mode - set to false when API Gateway is ready
  DEV_MODE: import.meta.env.VITE_DEV_MODE === 'true',
  
  // API Gateway configuration
  API_BASE_URL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3001/api',
  API_TIMEOUT: 30000, // 30 seconds for blockchain transactions
  
  // Mock data settings (only used in dev mode)
  MOCK_DELAY: 500, // Simulate network delay in ms
  MOCK_ERROR_RATE: 0, // Percentage of mock requests that should fail (0-100)
  
  // Debugging
  DEBUG_MODE: import.meta.env.VITE_DEBUG === 'true' || false,
  LOG_API_CALLS: import.meta.env.VITE_LOG_API === 'true' || false,
  
  // UI Settings
  ITEMS_PER_PAGE: 10,
  DEBOUNCE_DELAY: 300, // ms for search inputs
};

// Export for backward compatibility
export const API_CONFIG = {
  BASE_URL: APP_CONFIG.API_BASE_URL,
  TIMEOUT: APP_CONFIG.API_TIMEOUT,
};

// Helper function to check if in dev mode
export const isDevMode = () => APP_CONFIG.DEV_MODE;

// Helper function to get API base URL
export const getApiBaseUrl = () => APP_CONFIG.API_BASE_URL;

// Log current mode on load
if (APP_CONFIG.DEBUG_MODE) {
  console.log('🔧 App Configuration:', {
    mode: APP_CONFIG.DEV_MODE ? 'DEVELOPMENT (Mock Data)' : 'PRODUCTION (Live API)',
    apiUrl: APP_CONFIG.API_BASE_URL,
    timeout: `${APP_CONFIG.API_TIMEOUT}ms`,
  });
}
