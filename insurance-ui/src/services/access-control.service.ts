import apiService from './api.service';
import { ENDPOINTS } from '../config/api';
import type { Organization, ApiResponse } from '../types/blockchain';

export interface RegisterOrganizationDto {
  orgID: string;
  orgName: string;
  orgType: 'Insurer' | 'Coop' | 'Oracle' | 'Validator';
  mspID: string;
  adminEmail: string;
  adminPhone: string;
}

export interface AssignRoleDto {
  userID: string;
  orgID: string;
  role: string;
  permissions: string[];
}

export const accessControlService = {
  /**
   * Register a new organization
   */
  async registerOrganization(data: RegisterOrganizationDto): Promise<ApiResponse<Organization>> {
    return apiService.post<Organization>(ENDPOINTS.ACCESS_CONTROL.REGISTER_ORG, data);
  },

  /**
   * Get organization by ID
   */
  async getOrganization(orgID: string): Promise<ApiResponse<Organization>> {
    return apiService.get<Organization>(`${ENDPOINTS.ACCESS_CONTROL.GET_ORG}/${orgID}`);
  },

  /**
   * Assign role to user
   */
  async assignRole(data: AssignRoleDto): Promise<ApiResponse<void>> {
    return apiService.post<void>(ENDPOINTS.ACCESS_CONTROL.ASSIGN_ROLE, data);
  },

  /**
   * Check if user has permission
   */
  async checkPermission(
    userID: string,
    permission: string
  ): Promise<ApiResponse<{ hasPermission: boolean }>> {
    return apiService.post<{ hasPermission: boolean }>(
      ENDPOINTS.ACCESS_CONTROL.CHECK_PERMISSION,
      {
        userID,
        permission,
      }
    );
  },
};
