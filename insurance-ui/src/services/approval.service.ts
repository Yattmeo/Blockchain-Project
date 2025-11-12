import apiService from './api.service';
import { ENDPOINTS } from '../config/api';
import type { ApprovalRequest, ApprovalHistory, ApprovalStatus, ApprovalRequestType, ApiResponse } from '../types/blockchain';
import { 
  mockApprovalRequests, 
  getMockApprovalsByStatus,
  getMockPendingApprovals,
  getMockApprovalHistory
} from '../data/mockData';

export interface CreateApprovalRequestDto {
  requestId: string;
  requestType: ApprovalRequestType;
  chaincodeName: string;
  functionName: string;
  arguments: string[];
  requiredOrgs: string[];
  metadata?: Record<string, any>;
}

export interface ApproveRequestDto {
  approverOrg: string;
  reason?: string;
}

export interface RejectRequestDto {
  approverOrg: string;
  reason: string;
}

export const approvalService = {
  /**
   * Create a new approval request
   */
  async createApprovalRequest(data: CreateApprovalRequestDto): Promise<ApiResponse<ApprovalRequest>> {
    // Mock data for development
    const mockApproval: ApprovalRequest = {
      ...data,
      status: 'PENDING',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      createdBy: 'CurrentUserMSP',
      approvals: {},
      rejections: {},
    };
    return apiService.post<ApprovalRequest>(ENDPOINTS.APPROVAL.CREATE, data, undefined, mockApproval);
  },

  /**
   * Get approval request by ID
   */
  async getApprovalRequest(requestId: string): Promise<ApiResponse<ApprovalRequest>> {
    const mockApproval: ApprovalRequest = {
      requestId,
      requestType: 'FARMER_REGISTRATION',
      chaincodeName: 'farmer',
      functionName: 'RegisterFarmer',
      arguments: ['FARMER123', 'John', 'Doe', 'COOP001', '555-0000', 'john@example.com', '0x123', '1.23', '4.56', 'North', 'District1', '5.0', '["Rice","Wheat"]', 'kychash123'],
      requiredOrgs: ['CoopMSP', 'Insurer1MSP'],
      status: 'PENDING',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      createdBy: 'CoopMSP',
      approvals: { 'CoopMSP': true },
      rejections: {},
      metadata: { farmerName: 'John Doe' },
    };
    return apiService.get<ApprovalRequest>(`${ENDPOINTS.APPROVAL.GET}/${requestId}`, undefined, mockApproval);
  },

  /**
   * Get all approval requests
   */
  async getAllApprovals(): Promise<ApiResponse<ApprovalRequest[]>> {
    return apiService.get<ApprovalRequest[]>(ENDPOINTS.APPROVAL.GET_ALL, undefined, mockApprovalRequests);
  },

  /**
   * Get pending approval requests
   */
  async getPendingApprovals(): Promise<ApiResponse<{ approvals: ApprovalRequest[]; count: number }>> {
    const pending = getMockPendingApprovals();
    return apiService.get<{ approvals: ApprovalRequest[]; count: number }>(
      ENDPOINTS.APPROVAL.GET_PENDING,
      undefined,
      { approvals: pending, count: pending.length }
    );
  },

  /**
   * Get approval requests by status
   */
  async getApprovalsByStatus(status: ApprovalStatus): Promise<ApiResponse<{ approvals: ApprovalRequest[]; count: number }>> {
    const filtered = getMockApprovalsByStatus(status);
    return apiService.get<{ approvals: ApprovalRequest[]; count: number }>(
      `${ENDPOINTS.APPROVAL.GET_BY_STATUS}/${status}`,
      undefined,
      { approvals: filtered, count: filtered.length }
    );
  },

  /**
   * Get approval history for a request
   */
  async getApprovalHistory(requestId: string): Promise<ApiResponse<ApprovalHistory[]>> {
    const history = getMockApprovalHistory(requestId);
    return apiService.get<ApprovalHistory[]>(
      `${ENDPOINTS.APPROVAL.GET_HISTORY}/${requestId}/history`,
      undefined,
      history
    );
  },

  /**
   * Approve an approval request
   */
  async approveRequest(requestId: string, data: ApproveRequestDto): Promise<ApiResponse<{ requestId: string; action: string }>> {
    // In dev mode, update the mock data directly
    const approval = mockApprovalRequests.find(a => a.requestId === requestId);
    if (approval && data.approverOrg) {
      // Add approval
      approval.approvals[data.approverOrg] = true;
      approval.updatedAt = new Date().toISOString();
      
      // Check if all required orgs have approved
      const allApproved = approval.requiredOrgs.every(org => approval.approvals[org] === true);
      if (allApproved) {
        approval.status = 'APPROVED';
      }
    }
    
    const mockResponse = { requestId, action: 'APPROVE' };
    return apiService.post<{ requestId: string; action: string }>(
      `${ENDPOINTS.APPROVAL.APPROVE}/${requestId}/approve`,
      data,
      undefined,
      mockResponse
    );
  },

  /**
   * Reject an approval request
   */
  async rejectRequest(requestId: string, data: RejectRequestDto): Promise<ApiResponse<{ requestId: string; action: string }>> {
    // In dev mode, update the mock data directly
    const approval = mockApprovalRequests.find(a => a.requestId === requestId);
    if (approval && data.approverOrg) {
      // Add rejection
      approval.rejections[data.approverOrg] = data.reason;
      approval.status = 'REJECTED';
      approval.updatedAt = new Date().toISOString();
    }
    
    const mockResponse = { requestId, action: 'REJECT' };
    return apiService.post<{ requestId: string; action: string }>(
      `${ENDPOINTS.APPROVAL.REJECT}/${requestId}/reject`,
      data,
      undefined,
      mockResponse
    );
  },

  /**
   * Execute an approved request
   */
  async executeRequest(requestId: string): Promise<ApiResponse<{ requestId: string; txID: string; result: any }>> {
    // In dev mode, update the mock data directly
    const approval = mockApprovalRequests.find(a => a.requestId === requestId);
    if (approval) {
      approval.status = 'EXECUTED';
      approval.updatedAt = new Date().toISOString();
      approval.executedAt = new Date().toISOString();
      approval.executedBy = 'CurrentUserMSP'; // In real app, this would be the actual user
      approval.executedTxID = `tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
    
    const mockResponse = { requestId, txID: 'tx789', result: { success: true } };
    return apiService.post<{ requestId: string; txID: string; result: any }>(
      `${ENDPOINTS.APPROVAL.EXECUTE}/${requestId}/execute`,
      undefined,
      undefined,
      mockResponse
    );
  },
};
