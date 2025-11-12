import axios from 'axios';
import type { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';
import { API_CONFIG, isDevMode } from '../config/api';
import type { ApiResponse } from '../types/blockchain';

class ApiService {
  private api: AxiosInstance;

  constructor() {
    this.api = axios.create({
      baseURL: API_CONFIG.BASE_URL,
      timeout: API_CONFIG.TIMEOUT,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor
    this.api.interceptors.request.use(
      (config) => {
        // Add auth token if available
        const token = localStorage.getItem('authToken');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        
        // Add user role and org ID
        const userRole = localStorage.getItem('userRole');
        const userOrg = localStorage.getItem('userOrg');
        if (userRole) config.headers['X-User-Role'] = userRole;
        if (userOrg) config.headers['X-User-Org'] = userOrg;
        
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor
    this.api.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          // Handle unauthorized
          localStorage.removeItem('authToken');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  /**
   * Execute API call or return mock data based on dev mode
   */
  private async executeMockable<T>(
    apiCall: () => Promise<AxiosResponse<ApiResponse<T>>>,
    mockData: T | null = null
  ): Promise<ApiResponse<T>> {
    // If dev mode and mock data provided, return mock data
    if (isDevMode() && mockData !== null) {
      // Simulate network delay
      await new Promise(resolve => setTimeout(resolve, 300));
      return {
        success: true,
        data: mockData,
      };
    }

    // Otherwise make real API call
    try {
      const response = await apiCall();
      return response.data;
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.error || error.message || 'Request failed',
      };
    }
  }

  async get<T>(url: string, config?: AxiosRequestConfig, mockData: T | null = null): Promise<ApiResponse<T>> {
    return this.executeMockable<T>(
      () => this.api.get(url, config),
      mockData
    );
  }

  async post<T>(url: string, data?: any, config?: AxiosRequestConfig, mockData: T | null = null): Promise<ApiResponse<T>> {
    return this.executeMockable<T>(
      () => this.api.post(url, data, config),
      mockData
    );
  }

  async put<T>(url: string, data?: any, config?: AxiosRequestConfig, mockData: T | null = null): Promise<ApiResponse<T>> {
    return this.executeMockable<T>(
      () => this.api.put(url, data, config),
      mockData
    );
  }

  async delete<T>(url: string, config?: AxiosRequestConfig, mockData: T | null = null): Promise<ApiResponse<T>> {
    return this.executeMockable<T>(
      () => this.api.delete(url, config),
      mockData
    );
  }
}

export default new ApiService();
