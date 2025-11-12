import { useState } from 'react';
import { approvalService } from '../services';
import type { ApprovalRequest } from '../types/blockchain';
import { useAuth } from '../contexts/AuthContext';

export const useApprovalActions = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const clearMessages = () => {
    setError(null);
    setSuccess(null);
  };

  const canApprove = (request: ApprovalRequest): boolean => {
    if (!user?.orgId || request.status !== 'PENDING') return false;
    const userMSP = `${user.orgId}MSP`;
    return request.requiredOrgs.includes(userMSP) && !request.approvals[userMSP];
  };

  const canReject = (request: ApprovalRequest): boolean => {
    if (!user?.orgId || request.status !== 'PENDING') return false;
    const userMSP = `${user.orgId}MSP`;
    return request.requiredOrgs.includes(userMSP) && !request.rejections[userMSP];
  };

  const canExecute = (request: ApprovalRequest): boolean => {
    if (request.status !== 'APPROVED') return false;
    return user?.role === 'admin' || user?.role === 'insurer';
  };

  const approveRequest = async (requestId: string, reason?: string): Promise<boolean> => {
    try {
      setLoading(true);
      setError(null);
      const response = await approvalService.approveRequest(requestId, { reason });
      
      if (response.success) {
        setSuccess(`Request ${requestId} approved successfully`);
        return true;
      } else {
        setError(response.error || 'Failed to approve request');
        return false;
      }
    } catch (err) {
      setError('Failed to approve request');
      return false;
    } finally {
      setLoading(false);
    }
  };

  const rejectRequest = async (requestId: string, reason: string): Promise<boolean> => {
    try {
      setLoading(true);
      setError(null);
      const response = await approvalService.rejectRequest(requestId, { reason });
      
      if (response.success) {
        setSuccess(`Request ${requestId} rejected`);
        return true;
      } else {
        setError(response.error || 'Failed to reject request');
        return false;
      }
    } catch (err) {
      setError('Failed to reject request');
      return false;
    } finally {
      setLoading(false);
    }
  };

  const executeRequest = async (requestId: string): Promise<boolean> => {
    try {
      setLoading(true);
      setError(null);
      const response = await approvalService.executeRequest(requestId);
      
      if (response.success) {
        setSuccess(`Request ${requestId} executed successfully`);
        return true;
      } else {
        setError(response.error || 'Failed to execute request');
        return false;
      }
    } catch (err) {
      setError('Failed to execute request');
      return false;
    } finally {
      setLoading(false);
    }
  };

  return {
    loading,
    error,
    success,
    clearMessages,
    canApprove,
    canReject,
    canExecute,
    approveRequest,
    rejectRequest,
    executeRequest,
  };
};
