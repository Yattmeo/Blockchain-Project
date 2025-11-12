import apiService from './api.service';
import { ENDPOINTS } from '../config/api';
import type { PremiumPool, Transaction, ApiResponse } from '../types/blockchain';
import { generateMockTransactions } from '../utils/mockData';

export interface DepositDto {
  poolID: string;
  farmerID: string;
  amount: number;
  policyID: string;
}

export interface ExecutePayoutDto {
  poolID: string;
  claimID: string;
  payoutAmount: number;
  recipientID: string;
}

export const premiumPoolService = {
  /**
   * Deposit premium to pool
   */
  async deposit(data: DepositDto): Promise<ApiResponse<PremiumPool>> {
    const mockPool: PremiumPool = {
      poolID: data.poolID,
      totalBalance: 500000 + data.amount,
      totalPremiums: 750000 + data.amount,
      totalPayouts: 250000,
      reserves: 100000,
      lastUpdated: new Date().toISOString(),
    };
    return apiService.post<PremiumPool>(ENDPOINTS.PREMIUM_POOL.DEPOSIT, data, undefined, mockPool);
  },

  /**
   * Execute payout from pool
   */
  async executePayout(data: ExecutePayoutDto): Promise<ApiResponse<Transaction>> {
    const mockTransaction: Transaction = {
      txID: `TX${Date.now()}`,
      type: 'Claim Payout',
      policyID: undefined,
      farmerID: data.recipientID,
      amount: data.payoutAmount,
      timestamp: new Date().toISOString(),
      status: 'Confirmed',
      blockNumber: Math.floor(Math.random() * 100000) + 10000,
    };
    return apiService.post<Transaction>(ENDPOINTS.PREMIUM_POOL.EXECUTE_PAYOUT, data, undefined, mockTransaction);
  },

  /**
   * Get pool balance
   */
  async getPoolBalance(poolID?: string): Promise<ApiResponse<PremiumPool>> {
    const mockPool: PremiumPool = {
      poolID: poolID || 'default-pool',
      totalBalance: 500000,
      totalPremiums: 750000,
      totalPayouts: 250000,
      reserves: 100000,
      lastUpdated: new Date().toISOString(),
    };
    // Gateway exposes GET /api/premium-pool/balance (no poolId param currently)
    return apiService.get<PremiumPool>(ENDPOINTS.PREMIUM_POOL.GET_BALANCE, undefined, mockPool);
  },

  /**
   * Get transaction history
   */
  async getTransactionHistory(poolID?: string): Promise<ApiResponse<Transaction[]>> {
    const mockTransactions = generateMockTransactions(20);
    return apiService.get<Transaction[]>(
      // Gateway exposes GET /api/premium-pool/history (global or filtered by query)
      ENDPOINTS.PREMIUM_POOL.GET_TRANSACTION_HISTORY,
      undefined,
      mockTransactions
    );
  },

  /**
   * Get farmer balance
   */
  async getFarmerBalance(farmerID: string): Promise<ApiResponse<{ balance: number }>> {
    const mockBalance = { balance: Math.floor(Math.random() * 50000) + 10000 };
    return apiService.get<{ balance: number }>(
      `${ENDPOINTS.PREMIUM_POOL.GET_FARMER_BALANCE}/${farmerID}`,
      undefined,
      mockBalance
    );
  },
};
