import axios from 'axios';
import type { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';
import { APP_CONFIG, isDevMode } from '../config';

/**
 * API Client with Dev Mode Support
 * 
 * Automatically switches between mock data and real API calls
 * based on APP_CONFIG.DEV_MODE setting
 */
class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: APP_CONFIG.API_BASE_URL,
      timeout: APP_CONFIG.API_TIMEOUT,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor for logging
    this.client.interceptors.request.use(
      (config) => {
        if (APP_CONFIG.LOG_API_CALLS) {
          console.log('📤 API Request:', {
            method: config.method?.toUpperCase(),
            url: config.url,
            data: config.data,
          });
        }
        return config;
      },
      (error) => {
        console.error('❌ API Request Error:', error);
        return Promise.reject(error);
      }
    );

    // Response interceptor for logging
    this.client.interceptors.response.use(
      (response) => {
        if (APP_CONFIG.LOG_API_CALLS) {
          console.log('📥 API Response:', {
            status: response.status,
            url: response.config.url,
            data: response.data,
          });
        }
        return response;
      },
      (error) => {
        console.error('❌ API Response Error:', error.response?.data || error.message);
        return Promise.reject(error);
      }
    );
  }

  /**
   * Execute API call or return mock data based on dev mode
   */
  async execute<T>(
    apiCall: () => Promise<AxiosResponse<T>>,
    mockData: T,
    options: { mockDelay?: number } = {}
  ): Promise<T> {
    if (isDevMode()) {
      // Simulate network delay
      const delay = options.mockDelay ?? APP_CONFIG.MOCK_DELAY;
      await new Promise((resolve) => setTimeout(resolve, delay));

      // Simulate random errors if configured
      if (APP_CONFIG.MOCK_ERROR_RATE > 0) {
        const shouldError = Math.random() * 100 < APP_CONFIG.MOCK_ERROR_RATE;
        if (shouldError) {
          throw new Error('Mock API Error: Simulated failure');
        }
      }

      if (APP_CONFIG.DEBUG_MODE) {
        console.log('🔧 Dev Mode - Returning mock data:', mockData);
      }

      return mockData;
    } else {
      // Production mode - make real API call
      const response = await apiCall();
      return response.data;
    }
  }

  // Standard HTTP methods
  async get<T>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.client.get<T>(url, config);
  }

  async post<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.client.post<T>(url, data, config);
  }

  async put<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.client.put<T>(url, data, config);
  }

  async delete<T>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.client.delete<T>(url, config);
  }

  async patch<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.client.patch<T>(url, data, config);
  }
}

// Export singleton instance
export const apiClient = new ApiClient();

// Export helper for easy mock/real switching
export const withMockFallback = <T>(
  apiCall: () => Promise<AxiosResponse<T>>,
  mockData: T,
  options?: { mockDelay?: number }
) => {
  return apiClient.execute(apiCall, mockData, options);
};
