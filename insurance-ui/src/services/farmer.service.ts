import apiService from './api.service';
import { ENDPOINTS } from '../config/api';
import type { Farmer, ApiResponse } from '../types/blockchain';
import { mockFarmers } from '../data/mockData';

export interface RegisterFarmerDto {
  farmerID: string;
  firstName: string;
  lastName: string;
  coopID: string;
  phone: string;  // Will be mapped to phoneNumber in API
  email: string;
  walletAddress: string;
  latitude: number;  // Will be nested in farmLocation
  longitude: number;  // Will be nested in farmLocation
  region: string;  // Will be nested in farmLocation
  district: string;  // Will be nested in farmLocation
  farmSize: number;
  cropTypes: string[];
  kycHash: string;
}

export const farmerService = {
  /**
   * Register a new farmer
   */
  async registerFarmer(data: RegisterFarmerDto): Promise<ApiResponse<Farmer>> {
    const mockFarmer: Farmer = {
      ...data,
      status: 'Active',
      registrationDate: new Date().toISOString(),
    };
    return apiService.post<Farmer>(ENDPOINTS.FARMER.REGISTER, data, undefined, mockFarmer);
  },

  /**
   * Get farmer by ID
   */
  async getFarmer(farmerID: string): Promise<ApiResponse<Farmer>> {
    const mockFarmer = generateMockFarmers(1)[0];
    return apiService.get<Farmer>(`${ENDPOINTS.FARMER.GET}/${farmerID}`, undefined, mockFarmer);
  },

  /**
   * Update farmer profile
   */
  async updateFarmer(farmerID: string, data: Partial<Farmer>): Promise<ApiResponse<Farmer>> {
    const mockFarmer = { ...generateMockFarmers(1)[0], ...data };
    return apiService.put<Farmer>(`${ENDPOINTS.FARMER.UPDATE}/${farmerID}`, data, undefined, mockFarmer);
  },

  /**
   * Get farmers by cooperative
   */
  async getFarmersByCoop(coopID: string): Promise<ApiResponse<Farmer[]>> {
    const filtered = mockFarmers.filter(f => f.coopID === coopID);
    return apiService.get<Farmer[]>(`${ENDPOINTS.FARMER.LIST_BY_COOP}/${coopID}`, undefined, filtered);
  },

  /**
   * Get farmers by region
   */
  async getFarmersByRegion(region: string): Promise<ApiResponse<Farmer[]>> {
    const filtered = mockFarmers.filter(f => f.region === region);
    return apiService.get<Farmer[]>(`${ENDPOINTS.FARMER.LIST_BY_REGION}/${region}`, undefined, filtered);
  },
};
