import apiService from './api.service';
import { ENDPOINTS } from '../config/api';
import type { Policy, PolicyTemplate, ApiResponse } from '../types/blockchain';
import { mockPolicyTemplates, mockPolicies } from '../data/mockData';

export interface CreatePolicyTemplateDto {
  templateID: string;
  cropType: string;
  coverageType: string;
  basePrice: number;
  durationMonths: number;
  maxCoverageAmount: number;
  rainfallThreshold?: number;
  temperatureThreshold?: number;
}

export interface CreatePolicyDto {
  policyID: string;
  farmerID: string;
  templateID: string;
  coverageAmount: number;
  premiumAmount: number;
  startDate: string;
  endDate: string;
}

export const policyTemplateService = {
  /**
   * Create a new policy template
   */
  async createTemplate(data: CreatePolicyTemplateDto): Promise<ApiResponse<PolicyTemplate>> {
    const mockTemplate: PolicyTemplate = {
      ...data,
      templateName: `Template ${data.templateID}`,
      description: `Template for ${data.cropType}`,
      minCoverage: 5000,
      maxCoverage: data.maxCoverageAmount,
      duration: data.durationMonths,
      status: 'Active',
      createdDate: new Date().toISOString(),
      createdBy: 'ADMIN001',
      version: 1,
    };
    return apiService.post<PolicyTemplate>(ENDPOINTS.POLICY_TEMPLATE.CREATE, data, undefined, mockTemplate);
  },

  /**
   * Get policy template by ID
   */
  async getTemplate(templateID: string): Promise<ApiResponse<PolicyTemplate>> {
    const mockTemplate = mockPolicyTemplates.find(t => t.templateID === templateID) || mockPolicyTemplates[0];
    return apiService.get<PolicyTemplate>(`${ENDPOINTS.POLICY_TEMPLATE.GET}/${templateID}`, undefined, mockTemplate);
  },

  /**
   * List all policy templates
   */
  async listTemplates(): Promise<ApiResponse<PolicyTemplate[]>> {
    return apiService.get<PolicyTemplate[]>(ENDPOINTS.POLICY_TEMPLATE.LIST, undefined, mockPolicyTemplates);
  },

  /**
   * Set weather threshold for template
   */
  async setThreshold(templateID: string, rainfallThreshold: number): Promise<ApiResponse<void>> {
    return apiService.post<void>(ENDPOINTS.POLICY_TEMPLATE.SET_THRESHOLD, {
      templateID,
      rainfallThreshold,
    }, undefined, undefined);
  },

  /**
   * Activate a policy template
   */
  async activateTemplate(templateID: string): Promise<ApiResponse<void>> {
    return apiService.post<void>(ENDPOINTS.POLICY_TEMPLATE.ACTIVATE, { templateID }, undefined, undefined);
  },
};

export const policyService = {
  /**
   * Create a new policy for a farmer
   */
  async createPolicy(data: CreatePolicyDto): Promise<ApiResponse<Policy>> {
    const mockPolicy: Policy = {
      ...data,
      coopID: 'COOP001',
      insurerID: 'INS001',
      status: 'Active',
      farmLocation: '1.3521,103.8198',
      cropType: 'Rice',
      farmSize: 25,
      policyTermsHash: `0x${Math.random().toString(16).substr(2, 64)}`,
      createdDate: new Date().toISOString(),
    };
    return apiService.post<Policy>(ENDPOINTS.POLICY.CREATE, data, undefined, mockPolicy);
  },

  /**
   * Get policy by ID
   */
  async getPolicy(policyID: string): Promise<ApiResponse<Policy>> {
    const mockPolicy = mockPolicies.find(p => p.policyID === policyID) || mockPolicies[0];
    return apiService.get<Policy>(`${ENDPOINTS.POLICY.GET}/${policyID}`, undefined, mockPolicy);
  },

  /**
   * Update policy status
   */
  async updatePolicyStatus(policyID: string, status: string): Promise<ApiResponse<Policy>> {
    const mockPolicy = mockPolicies.find(p => p.policyID === policyID) || mockPolicies[0];
    return apiService.put<Policy>(ENDPOINTS.POLICY.UPDATE_STATUS, { policyID, status }, undefined, { ...mockPolicy, status: status as any });
  },

  /**
   * Get policies by farmer
   */
  async getPoliciesByFarmer(farmerID: string): Promise<ApiResponse<Policy[]>> {
    const filtered = mockPolicies.filter(p => p.farmerID === farmerID);
    return apiService.get<Policy[]>(`${ENDPOINTS.POLICY.LIST_BY_FARMER}/${farmerID}`, undefined, filtered);
  },

  /**
   * Get all active policies
   */
  async getActivePolicies(): Promise<ApiResponse<Policy[]>> {
    const filtered = mockPolicies.filter(p => p.status === 'Active');
    return apiService.get<Policy[]>(ENDPOINTS.POLICY.LIST_ACTIVE, undefined, filtered);
  },

  /**
   * Get claim history for a policy
   */
  async getClaimHistory(policyID: string): Promise<ApiResponse<any[]>> {
    const mockHistory: any[] = [];
    return apiService.get<any[]>(`${ENDPOINTS.POLICY.GET_CLAIM_HISTORY}/${policyID}`, undefined, mockHistory);
  },
};
