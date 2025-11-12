import { useState, useEffect } from 'react';
import { Box, Typography, Button, Chip, Alert } from '@mui/material';
import { Add, CheckCircle, Cancel } from '@mui/icons-material';
import { DataTable } from '../components/DataTable';
import type { Column } from '../components/DataTable';
import { FarmerForm } from '../components/forms/FarmerForm';
import { farmerService, approvalService } from '../services';
import type { Farmer, ApprovalRequest } from '../types/blockchain';
import { useAuth } from '../contexts/AuthContext';
import { ApprovalCard } from '../components/ApprovalCard';
import { useApprovalActions } from '../hooks';

export const FarmersPage: React.FC = () => {
  const { user } = useAuth();
  const [farmers, setFarmers] = useState<Farmer[]>([]);
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

  const columns: Column<Farmer>[] = [
    { id: 'farmerID', label: 'Farmer ID', minWidth: 120 },
    {
      id: 'name',
      label: 'Name',
      minWidth: 150,
      format: (_, row) => `${row.firstName} ${row.lastName}`,
    },
    { 
      id: 'phoneNumber', 
      label: 'Phone', 
      minWidth: 120,
    },
    { id: 'email', label: 'Email', minWidth: 180 },
    { 
      id: 'region', 
      label: 'Region', 
      minWidth: 100,
      format: (_, row) => row.farmLocation?.region || '-',
    },
    { 
      id: 'district', 
      label: 'District', 
      minWidth: 100,
      format: (_, row) => row.farmLocation?.district || '-',
    },
    {
      id: 'farmSize',
      label: 'Farm Size (ha)',
      minWidth: 120,
      align: 'right',
      format: (value) => `${value} ha`,
    },
    {
      id: 'cropTypes',
      label: 'Crops',
      minWidth: 200,
      format: (value: string[]) => (
        <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
          {value.map((crop) => (
            <Chip key={crop} label={crop} size="small" />
          ))}
        </Box>
      ),
    },
    {
      id: 'status',
      label: 'Status',
      minWidth: 100,
      format: (value) => (
        <Chip
          icon={value === 'Active' ? <CheckCircle /> : <Cancel />}
          label={value}
          color={value === 'Active' ? 'success' : 'default'}
          size="small"
        />
      ),
    },
  ];

  useEffect(() => {
    fetchFarmers();
    fetchPendingApprovals();
  }, [user?.orgId]);

  const fetchFarmers = async () => {
    try {
      setLoading(true);
      
      // For admin or platform users, fetch all farmers from the 'COOP001' organization
      // For coop users, use their orgId
      let response;
      
      if (user?.role === 'admin' || !user?.orgId) {
        // Admin or no orgId - fetch from default 'COOP001'
        response = await farmerService.getFarmersByCoop('COOP001');
      } else {
        // Try with user's orgId (uppercase)
        const coopId = user.orgId.toUpperCase();
        response = await farmerService.getFarmersByCoop(coopId);
        
        // If no farmers found and not already 'COOP001', try fallback
        if (response.success && (!response.data || response.data.length === 0) && coopId !== 'COOP001') {
          response = await farmerService.getFarmersByCoop('COOP001');
        }
      }
      
      if (response.success && response.data) {
        setFarmers(response.data);
      }
    } catch (error) {
      console.error('Failed to fetch farmers:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchPendingApprovals = async () => {
    try {
      const response = await approvalService.getPendingApprovals();
      if (response.success && response.data) {
        // Filter for farmer registration approvals
        // API returns data directly as array, not nested in approvals property
        const approvals = Array.isArray(response.data) ? response.data : [];
        const farmerApprovals = approvals.filter(
          approval => approval.requestType === 'FARMER_REGISTRATION'
        );
        setPendingApprovals(farmerApprovals);
      }
    } catch (error) {
      console.error('Failed to fetch pending approvals:', error);
    }
  };

  const handleFormSuccess = () => {
    // Refresh farmers list and approvals
    fetchFarmers();
    fetchPendingApprovals();
  };

  const handleApprove = async (request: ApprovalRequest) => {
    const success = await approveRequest(request.requestId, 'Approved via Farmers page');
    if (success) {
      fetchPendingApprovals();
      fetchFarmers();
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
    if (confirm(`Execute farmer registration for ${request.requestId}?`)) {
      const success = await executeRequest(request.requestId);
      if (success) {
        fetchPendingApprovals();
        fetchFarmers();
      }
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" gutterBottom fontWeight={600}>
            Farmer Management
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Register and manage farmers in your cooperative
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => setFormOpen(true)}
        >
          Register Farmer
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
            Pending Farmer Registrations ({pendingApprovals.length})
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            These farmer registrations require multi-party approval before being registered
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

      {/* Registered Farmers Table */}
      <Typography variant="h6" gutterBottom fontWeight={600} sx={{ mt: 3 }}>
        Registered Farmers
      </Typography>

      <DataTable
        columns={columns}
        data={farmers}
        loading={loading}
        searchPlaceholder="Search farmers by name, ID, region..."
        emptyMessage="No farmers registered yet. Click 'Register Farmer' to get started."
      />

      <FarmerForm
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSuccess={handleFormSuccess}
      />
    </Box>
  );
};
