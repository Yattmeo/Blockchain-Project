import apiService from './api.service';
import { ENDPOINTS } from '../config/api';
import type { DashboardStats, Transaction, ApiResponse } from '../types/blockchain';
import { generateMockDashboardStats, generateMockTransactions } from '../utils/mockData';

export const dashboardService = {
  /**
   * Get dashboard statistics
   */
  async getStats(orgID?: string): Promise<ApiResponse<DashboardStats>> {
    const url = orgID ? `${ENDPOINTS.DASHBOARD.STATS}?orgID=${orgID}` : ENDPOINTS.DASHBOARD.STATS;
    const mockStats = generateMockDashboardStats();
    return apiService.get<DashboardStats>(url, undefined, mockStats);
  },

  /**
   * Get recent transactions
   */
  async getRecentTransactions(limit: number = 10): Promise<ApiResponse<Transaction[]>> {
    const mockTransactions = generateMockTransactions(limit);
    return apiService.get<Transaction[]>(
      `${ENDPOINTS.DASHBOARD.RECENT_TRANSACTIONS}?limit=${limit}`,
      undefined,
      mockTransactions
    );
  },
};
