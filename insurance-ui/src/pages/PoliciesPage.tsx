import { useState, useEffect } from 'react';
import { Box, Typography, Button, Chip, Alert } from '@mui/material';
import { Add } from '@mui/icons-material';
import { DataTable } from '../components/DataTable';
import type { Column } from '../components/DataTable';
import { PolicyForm } from '../components/forms/PolicyForm';
import { policyService, approvalService } from '../services';
import type { Policy, ApprovalRequest } from '../types/blockchain';
import { ApprovalCard } from '../components/ApprovalCard';
import { useApprovalActions } from '../hooks';

export const PoliciesPage: React.FC = () => {
  const [policies, setPolicies] = useState<Policy[]>([]);
  const [loading, setLoading] = useState(true);
  const [formOpen, setFormOpen] = useState(false);
  const [pendingApprovals, setPendingApprovals] = useState<ApprovalRequest[]>([]);
  
  const {
    error: actionError,
    success: actionSuccess,
    clearMessages,
    canApprove,
    canReject,
    canExecute,
    approveRequest,
    rejectRequest,
    executeRequest,
  } = useApprovalActions();

  const columns: Column<Policy>[] = [
    { id: 'policyID', label: 'Policy ID', minWidth: 120 },
    { id: 'farmerID', label: 'Farmer ID', minWidth: 120 },
    { id: 'templateID', label: 'Template', minWidth: 120 },
    {
      id: 'coverageAmount',
      label: 'Coverage',
      minWidth: 120,
      align: 'right',
      format: (value) => `$${value.toLocaleString()}`,
    },
    {
      id: 'premiumAmount',
      label: 'Premium',
      minWidth: 120,
      align: 'right',
      format: (value) => `$${value.toLocaleString()}`,
    },
    {
      id: 'startDate',
      label: 'Start Date',
      minWidth: 110,
      format: (value) => new Date(value).toLocaleDateString(),
    },
    {
      id: 'endDate',
      label: 'End Date',
      minWidth: 110,
      format: (value) => new Date(value).toLocaleDateString(),
    },
    {
      id: 'status',
      label: 'Status',
      minWidth: 120,
      format: (value) => {
        const colorMap: Record<string, 'success' | 'warning' | 'error' | 'default'> = {
          Active: 'success',
          Pending: 'warning',
          Expired: 'error',
          Claimed: 'default',
        };
        return (
          <Chip
            label={value}
            color={colorMap[value] || 'default'}
            size="small"
          />
        );
      },
    },
  ];

  useEffect(() => {
    fetchPolicies();
    fetchPendingApprovals();
  }, []);

  const fetchPolicies = async () => {
    try {
      setLoading(true);
      const response = await policyService.getActivePolicies();
      if (response.success && response.data) {
        setPolicies(response.data);
      }
    } catch (error) {
      console.error('Failed to fetch policies:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchPendingApprovals = async () => {
    try {
      const response = await approvalService.getPendingApprovals();
      if (response.success && response.data) {
        // Filter for policy creation approvals
        // API returns data directly as array, not nested in approvals property
        const approvals = Array.isArray(response.data) ? response.data : [];
        const policyApprovals = approvals.filter(
          approval => approval.requestType === 'POLICY_CREATION'
        );
        setPendingApprovals(policyApprovals);
      }
    } catch (error) {
      console.error('Failed to fetch pending approvals:', error);
    }
  };

  const handleFormSuccess = () => {
    fetchPolicies();
    fetchPendingApprovals();
  };

  const handleApprove = async (request: ApprovalRequest) => {
    const success = await approveRequest(request.requestId, 'Approved via Policies page');
    if (success) {
      fetchPendingApprovals();
      fetchPolicies();
    }
  };

  const handleReject = async (request: ApprovalRequest) => {
    const reason = prompt('Please provide a reason for rejection:');
    if (reason) {
      const success = await rejectRequest(request.requestId, reason);
      if (success) {
        fetchPendingApprovals();
      }
    }
  };

  const handleExecute = async (request: ApprovalRequest) => {
    if (confirm(`Execute policy creation for ${request.requestId}?`)) {
      const success = await executeRequest(request.requestId);
      if (success) {
        fetchPendingApprovals();
        fetchPolicies();
      }
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" gutterBottom fontWeight={600}>
            Policy Management
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Create policy templates and manage farmer policies
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => setFormOpen(true)}
        >
          Create Policy
        </Button>
      </Box>

      {/* Success/Error Messages */}
      {actionSuccess && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={clearMessages}>
          {actionSuccess}
        </Alert>
      )}
      {actionError && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={clearMessages}>
          {actionError}
        </Alert>
      )}

      {/* Pending Approvals Section */}
      {pendingApprovals.length > 0 && (
        <Box sx={{ mb: 3 }}>
          <Typography variant="h6" gutterBottom fontWeight={600}>
            Pending Policy Approvals ({pendingApprovals.length})
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            These policy creations require multi-party approval before activation
          </Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 2 }}>
            {pendingApprovals.map((approval) => (
              <ApprovalCard
                key={approval.requestId}
                request={approval}
                canApprove={canApprove(approval)}
                canReject={canReject(approval)}
                canExecute={canExecute(approval)}
                onApprove={handleApprove}
                onReject={handleReject}
                onExecute={handleExecute}
                compact
              />
            ))}
          </Box>
        </Box>
      )}

      {/* Active Policies Table */}
      <Typography variant="h6" gutterBottom fontWeight={600} sx={{ mt: 3 }}>
        Active Policies
      </Typography>

      <DataTable
        columns={columns}
        data={policies}
        loading={loading}
        searchPlaceholder="Search policies by ID, farmer..."
        emptyMessage="No policies created yet. Click 'Create Policy' to get started."
      />

      <PolicyForm
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSuccess={handleFormSuccess}
      />
    </Box>
  );
};
