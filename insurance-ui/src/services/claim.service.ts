import apiService from './api.service';
import { ENDPOINTS } from '../config/api';
import type { Claim, ApiResponse } from '../types/blockchain';
import { generateMockClaims } from '../utils/mockData';

// Note: In parametric insurance, claims are automatically triggered
// by smart contracts when index thresholds are met. No manual approval needed.

export const claimService = {
  /**
   * Get claim by ID - For audit and tracking purposes
   */
  async getClaim(claimID: string): Promise<ApiResponse<Claim>> {
    const mockClaim = generateMockClaims(1)[0];
    return apiService.get<Claim>(`${ENDPOINTS.CLAIM_PROCESSOR.GET_CLAIM}/${claimID}`, undefined, mockClaim);
  },

  /**
   * Get all claims - For audit dashboard
   * Claims are automatically triggered by smart contract when weather index meets threshold
   */
  async getAllClaims(): Promise<ApiResponse<Claim[]>> {
    const mockClaims = generateMockClaims(20);
    return apiService.get<Claim[]>(ENDPOINTS.CLAIM_PROCESSOR.LIST_ALL, undefined, mockClaims);
  },

  /**
   * Get claims by policy - For policy history and audit trail
   */
  async getClaimsByPolicy(policyID: string): Promise<ApiResponse<Claim[]>> {
    const mockClaims = generateMockClaims(5);
    return apiService.get<Claim[]>(`${ENDPOINTS.CLAIM_PROCESSOR.LIST_BY_POLICY}/${policyID}`, undefined, mockClaims);
  },

  /**
   * Get claims by farmer - For farmer's claim history
   */
  async getClaimsByFarmer(farmerID: string): Promise<ApiResponse<Claim[]>> {
    const mockClaims = generateMockClaims(8);
    return apiService.get<Claim[]>(`${ENDPOINTS.CLAIM_PROCESSOR.LIST_BY_FARMER}/${farmerID}`, undefined, mockClaims);
  },

  /**
   * Get claims by status - For monitoring and reporting
   * Status: 'Triggered' (just created), 'Processing' (payout in progress), 'Paid' (completed), 'Failed' (payout failed)
   */
  async getClaimsByStatus(status: string): Promise<ApiResponse<Claim[]>> {
    const mockClaims = generateMockClaims(15).filter(c => c.status === status);
    return apiService.get<Claim[]>(`${ENDPOINTS.CLAIM_PROCESSOR.LIST_BY_STATUS}/${status}`, undefined, mockClaims);
  },

  /**
   * Retry failed payout - Only for claims where automatic payout failed
   * This is the only "manual" intervention - retrying failed payments
   */
  async retryPayout(claimID: string): Promise<ApiResponse<Claim>> {
    const mockClaim: Claim = {
      ...generateMockClaims(1)[0],
      claimID,
      status: 'Processing',
      notes: 'Payout retry initiated',
    };
    return apiService.post<Claim>(`${ENDPOINTS.CLAIM_PROCESSOR.TRIGGER_PAYOUT}/${claimID}/retry`, {}, undefined, mockClaim);
  },
};
