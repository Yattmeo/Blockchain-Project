import { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Chip,
  Button,
  IconButton,
  Tooltip,
  TextField,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Card,
  CardContent,
  LinearProgress,
  Alert,
  Stack,
} from '@mui/material';
import {
  CheckCircle,
  Cancel,
  Pending,
  PlayArrow,
  ThumbUp,
  ThumbDown,
  Refresh,
  History,
  Info,
} from '@mui/icons-material';
import { DataTable } from '../components/DataTable';
import type { Column } from '../components/DataTable';
import { approvalService } from '../services';
import type { ApprovalRequest, ApprovalStatus, ApprovalRequestType, ApprovalHistory } from '../types/blockchain';
import { useAuth } from '../contexts/AuthContext';
import { extractOrgFromIdentity } from '../utils/identity';

export const ApprovalsPage: React.FC = () => {
  const { user } = useAuth();
  const [approvals, setApprovals] = useState<ApprovalRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<ApprovalStatus | 'ALL'>('ALL');
  const [typeFilter, setTypeFilter] = useState<ApprovalRequestType | 'ALL'>('ALL');
  
  // Dialog states
  const [rejectDialogOpen, setRejectDialogOpen] = useState(false);
  const [historyDialogOpen, setHistoryDialogOpen] = useState(false);
  const [detailsDialogOpen, setDetailsDialogOpen] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState<ApprovalRequest | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [history, setHistory] = useState<ApprovalHistory[]>([]);
  const [actionLoading, setActionLoading] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  const statusColors: Record<ApprovalStatus, 'warning' | 'success' | 'error' | 'info'> = {
    PENDING: 'warning',
    APPROVED: 'success',
    REJECTED: 'error',
    EXECUTED: 'info',
  };

  const statusIcons: Record<ApprovalStatus, React.ReactElement> = {
    PENDING: <Pending />,
    APPROVED: <CheckCircle />,
    REJECTED: <Cancel />,
    EXECUTED: <PlayArrow />,
  };

  const typeLabels: Record<ApprovalRequestType, string> = {
    FARMER_REGISTRATION: 'Farmer Registration',
    POLICY_CREATION: 'Policy Creation',
    CLAIM_APPROVAL: 'Claim Approval',
    POOL_WITHDRAWAL: 'Pool Withdrawal',
  };

  const columns: Column<ApprovalRequest>[] = [
    { 
      id: 'requestId', 
      label: 'Request ID', 
      minWidth: 150,
      format: (value) => (
        <Typography variant="body2" fontFamily="monospace">
          {String(value).slice(0, 12)}...
        </Typography>
      ),
    },
    {
      id: 'requestType',
      label: 'Type',
      minWidth: 150,
      format: (value: ApprovalRequestType) => (
        <Chip label={typeLabels[value]} size="small" variant="outlined" />
      ),
    },
    {
      id: 'status',
      label: 'Status',
      minWidth: 120,
      format: (value: ApprovalStatus) => (
        <Chip
          icon={statusIcons[value]}
          label={value}
          color={statusColors[value]}
          size="small"
        />
      ),
    },
    {
      id: 'approvals',
      label: 'Progress',
      minWidth: 200,
      format: (_, row) => {
        const approved = Object.keys(row.approvals).length;
        const required = row.requiredOrgs.length;
        const progress = (approved / required) * 100;
        
        return (
          <Box sx={{ width: '100%' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <Typography variant="caption">
                {approved} of {required} orgs
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {Math.round(progress)}%
              </Typography>
            </Box>
            <LinearProgress 
              variant="determinate" 
              value={progress} 
              color={progress === 100 ? 'success' : 'primary'}
              sx={{ height: 6, borderRadius: 1 }}
            />
          </Box>
        );
      },
    },
    {
      id: 'createdBy',
      label: 'Created By',
      minWidth: 120,
      format: (value) => (
        <Chip label={extractOrgFromIdentity(String(value))} size="small" />
      ),
    },
    {
      id: 'createdAt',
      label: 'Created',
      minWidth: 150,
      format: (value) => new Date(String(value)).toLocaleString(),
    },
    {
      id: 'actions',
      label: 'Actions',
      minWidth: 200,
      align: 'center',
      format: (_, row) => (
        <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center' }}>
          <Tooltip title="View Details">
            <IconButton size="small" onClick={() => handleViewDetails(row)}>
              <Info fontSize="small" />
            </IconButton>
          </Tooltip>
          
          {row.status === 'PENDING' && canApprove(row) && (
            <>
              <Tooltip title="Approve">
                <IconButton 
                  size="small" 
                  color="success"
                  onClick={() => handleApprove(row)}
                  disabled={actionLoading}
                >
                  <ThumbUp fontSize="small" />
                </IconButton>
              </Tooltip>
              <Tooltip title="Reject">
                <IconButton 
                  size="small" 
                  color="error"
                  onClick={() => handleRejectDialog(row)}
                  disabled={actionLoading}
                >
                  <ThumbDown fontSize="small" />
                </IconButton>
              </Tooltip>
            </>
          )}
          
          {row.status === 'PENDING' && !canApprove(row) && canReject(row) && (
            <Tooltip title="Reject">
              <IconButton 
                size="small" 
                color="error"
                onClick={() => handleRejectDialog(row)}
                disabled={actionLoading}
              >
                <ThumbDown fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
          
          {row.status === 'APPROVED' && canExecute(row) && (
            <Tooltip title="Execute">
              <IconButton 
                size="small" 
                color="primary"
                onClick={() => handleExecute(row)}
                disabled={actionLoading}
              >
                <PlayArrow fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
          
          <Tooltip title="View History">
            <IconButton size="small" onClick={() => handleViewHistory(row)}>
              <History fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      ),
    },
  ];

  useEffect(() => {
    fetchApprovals();
  }, [statusFilter]);

  const fetchApprovals = async () => {
    try {
      setLoading(true);
      setErrorMessage('');
      
      let response;
      if (statusFilter === 'ALL') {
        response = await approvalService.getAllApprovals();
      } else if (statusFilter === 'PENDING') {
        response = await approvalService.getPendingApprovals();
      } else {
        response = await approvalService.getApprovalsByStatus(statusFilter);
      }
      
      if (response.success && response.data) {
        // API returns data directly as an array, not nested in data.approvals
        const approvals = Array.isArray(response.data) ? response.data : [];
        setApprovals(approvals);
      } else {
        setErrorMessage(response.error || 'Failed to fetch approvals');
      }
    } catch (error) {
      console.error('Failed to fetch approvals:', error);
      setErrorMessage('Failed to fetch approvals');
    } finally {
      setLoading(false);
    }
  };

  const canApprove = (request: ApprovalRequest): boolean => {
    if (!user?.orgId) return false;
    // Map orgId to proper MSP format: insurer1 -> Insurer1MSP, coop -> CoopMSP
    const orgIdCapitalized = user.orgId.charAt(0).toUpperCase() + user.orgId.slice(1);
    const userMSP = `${orgIdCapitalized}MSP`;
    
    // Check if user's org is required and hasn't approved yet
    const isRequired = request.requiredOrgs.includes(userMSP);
    const hasApproved = request.approvals[userMSP] === true;
    
    return isRequired && !hasApproved && request.status === 'PENDING';
  };

  const canReject = (request: ApprovalRequest): boolean => {
    if (!user?.orgId) return false;
    const orgIdCapitalized = user.orgId.charAt(0).toUpperCase() + user.orgId.slice(1);
    const userMSP = `${orgIdCapitalized}MSP`;
    
    // Check if user's org is required and hasn't rejected yet
    const isRequired = request.requiredOrgs.includes(userMSP);
    const hasRejected = !!request.rejections[userMSP];
    
    return isRequired && !hasRejected && request.status === 'PENDING';
  };

  const canExecute = (request: ApprovalRequest): boolean => {
    // Only admin or insurer can execute, and request must be fully approved
    return (user?.role === 'admin' || user?.role === 'insurer') && request.status === 'APPROVED';
  };

  const handleApprove = async (request: ApprovalRequest) => {
    try {
      setActionLoading(true);
      setErrorMessage('');
      
      // Get user's MSP ID
      const orgIdCapitalized = user?.orgId ? user.orgId.charAt(0).toUpperCase() + user.orgId.slice(1) : '';
      const userMSP = `${orgIdCapitalized}MSP`;
      
      const response = await approvalService.approveRequest(request.requestId, {
        approverOrg: userMSP,
        reason: 'Approved via UI',
      });
      
      if (response.success) {
        setSuccessMessage(`Request ${request.requestId} approved successfully`);
        fetchApprovals();
      } else {
        setErrorMessage(response.error || 'Failed to approve request');
      }
    } catch (error) {
      console.error('Failed to approve:', error);
      setErrorMessage('Failed to approve request');
    } finally {
      setActionLoading(false);
    }
  };

  const handleRejectDialog = (request: ApprovalRequest) => {
    setSelectedRequest(request);
    setRejectReason('');
    setRejectDialogOpen(true);
  };

  const handleReject = async () => {
    if (!selectedRequest || !rejectReason.trim()) return;
    
    try {
      setActionLoading(true);
      setErrorMessage('');
      
      // Get user's MSP ID
      const orgIdCapitalized = user?.orgId ? user.orgId.charAt(0).toUpperCase() + user.orgId.slice(1) : '';
      const userMSP = `${orgIdCapitalized}MSP`;
      
      const response = await approvalService.rejectRequest(selectedRequest.requestId, {
        approverOrg: userMSP,
        reason: rejectReason,
      });
      
      if (response.success) {
        setSuccessMessage(`Request ${selectedRequest.requestId} rejected`);
        setRejectDialogOpen(false);
        fetchApprovals();
      } else {
        setErrorMessage(response.error || 'Failed to reject request');
      }
    } catch (error) {
      console.error('Failed to reject:', error);
      setErrorMessage('Failed to reject request');
    } finally {
      setActionLoading(false);
    }
  };

  const handleExecute = async (request: ApprovalRequest) => {
    if (!confirm(`Execute approved request ${request.requestId}? This will perform the actual operation.`)) {
      return;
    }
    
    try {
      setActionLoading(true);
      setErrorMessage('');
      const response = await approvalService.executeRequest(request.requestId);
      
      if (response.success) {
        setSuccessMessage(`Request ${request.requestId} executed successfully`);
        fetchApprovals();
      } else {
        setErrorMessage(response.error || 'Failed to execute request');
      }
    } catch (error) {
      console.error('Failed to execute:', error);
      setErrorMessage('Failed to execute request');
    } finally {
      setActionLoading(false);
    }
  };

  const handleViewDetails = (request: ApprovalRequest) => {
    setSelectedRequest(request);
    setDetailsDialogOpen(true);
  };

  const handleViewHistory = async (request: ApprovalRequest) => {
    setSelectedRequest(request);
    setHistoryDialogOpen(true);
    
    try {
      const response = await approvalService.getApprovalHistory(request.requestId);
      if (response.success && response.data) {
        setHistory(response.data);
      }
    } catch (error) {
      console.error('Failed to fetch history:', error);
    }
  };

  const filteredApprovals = approvals.filter(approval => {
    if (typeFilter !== 'ALL' && approval.requestType !== typeFilter) {
      return false;
    }
    return true;
  });

  const actionableApprovals = filteredApprovals.filter(approval => 
    canApprove(approval) || canReject(approval)
  );

  const stats = {
    pending: approvals.filter(a => a.status === 'PENDING').length,
    approved: approvals.filter(a => a.status === 'APPROVED').length,
    rejected: approvals.filter(a => a.status === 'REJECTED').length,
    executed: approvals.filter(a => a.status === 'EXECUTED').length,
    actionable: actionableApprovals.length,
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" gutterBottom fontWeight={600}>
            Approval Management
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Review and manage multi-party approval requests
          </Typography>
        </Box>
        <Button
          variant="outlined"
          startIcon={<Refresh />}
          onClick={fetchApprovals}
          disabled={loading}
        >
          Refresh
        </Button>
      </Box>

      {/* Statistics Cards */}
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2, mb: 3 }}>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography color="text.secondary" variant="body2">
                  Pending
                </Typography>
                <Typography variant="h4">{stats.pending}</Typography>
              </Box>
              <Pending sx={{ fontSize: 40, color: 'warning.main' }} />
            </Box>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography color="text.secondary" variant="body2">
                  Approved
                </Typography>
                <Typography variant="h4">{stats.approved}</Typography>
              </Box>
              <CheckCircle sx={{ fontSize: 40, color: 'success.main' }} />
            </Box>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography color="text.secondary" variant="body2">
                  Rejected
                </Typography>
                <Typography variant="h4">{stats.rejected}</Typography>
              </Box>
              <Cancel sx={{ fontSize: 40, color: 'error.main' }} />
            </Box>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography color="text.secondary" variant="body2">
                  Executed
                </Typography>
                <Typography variant="h4">{stats.executed}</Typography>
              </Box>
              <PlayArrow sx={{ fontSize: 40, color: 'info.main' }} />
            </Box>
          </CardContent>
        </Card>
      </Box>

      {/* Success/Error Messages */}
      {successMessage && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccessMessage('')}>
          {successMessage}
        </Alert>
      )}
      {errorMessage && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setErrorMessage('')}>
          {errorMessage}
        </Alert>
      )}

      {/* User Organization Info */}
      {user && (
        <Alert 
          severity={stats.actionable > 0 ? "warning" : "info"} 
          sx={{ mb: 2 }}
          icon={stats.actionable > 0 ? <Pending /> : undefined}
        >
          <Typography variant="body2">
            <strong>Your Organization:</strong> {user.orgId.charAt(0).toUpperCase() + user.orgId.slice(1)}MSP
            {' • '}
            <strong>Role:</strong> {user.role}
            {' • '}
            <strong>Awaiting Your Action:</strong> {stats.actionable} {stats.actionable === 1 ? 'request' : 'requests'}
            {stats.actionable > 0 && ' - Look for 👍 Approve and 👎 Reject buttons in the Actions column'}
          </Typography>
        </Alert>
      )}

      {/* Filters */}
      <Paper sx={{ p: 2, mb: 2 }}>
        <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 2 }}>
          <TextField
            select
            fullWidth
            label="Status"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as ApprovalStatus | 'ALL')}
            size="small"
          >
            <MenuItem value="ALL">All Statuses</MenuItem>
            <MenuItem value="PENDING">Pending</MenuItem>
            <MenuItem value="APPROVED">Approved</MenuItem>
            <MenuItem value="REJECTED">Rejected</MenuItem>
            <MenuItem value="EXECUTED">Executed</MenuItem>
          </TextField>
          <TextField
            select
            fullWidth
            label="Type"
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value as ApprovalRequestType | 'ALL')}
            size="small"
          >
            <MenuItem value="ALL">All Types</MenuItem>
            <MenuItem value="FARMER_REGISTRATION">Farmer Registration</MenuItem>
            <MenuItem value="POLICY_CREATION">Policy Creation</MenuItem>
            <MenuItem value="CLAIM_APPROVAL">Claim Approval</MenuItem>
            <MenuItem value="POOL_WITHDRAWAL">Pool Withdrawal</MenuItem>
          </TextField>
        </Box>
      </Paper>

      {/* Approvals Table */}
      <DataTable
        columns={columns as Column<Record<string, any>>[]}
        data={filteredApprovals as Record<string, any>[]}
        loading={loading}
        emptyMessage="No approval requests found"
      />

      {/* Reject Dialog */}
      <Dialog open={rejectDialogOpen} onClose={() => !actionLoading && setRejectDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Reject Approval Request</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Please provide a reason for rejecting this request:
          </Typography>
          <TextField
            fullWidth
            multiline
            rows={4}
            label="Rejection Reason"
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            placeholder="Enter the reason for rejection..."
            required
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRejectDialogOpen(false)} disabled={actionLoading}>
            Cancel
          </Button>
          <Button 
            onClick={handleReject} 
            color="error" 
            variant="contained"
            disabled={!rejectReason.trim() || actionLoading}
          >
            {actionLoading ? 'Rejecting...' : 'Reject Request'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Details Dialog */}
      <Dialog open={detailsDialogOpen} onClose={() => setDetailsDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Approval Request Details</DialogTitle>
        <DialogContent>
          {selectedRequest && (
            <Stack spacing={2}>
              <Box>
                <Typography variant="subtitle2" color="text.secondary">Request ID</Typography>
                <Typography variant="body2" fontFamily="monospace">{selectedRequest.requestId}</Typography>
              </Box>
              <Box>
                <Typography variant="subtitle2" color="text.secondary">Type</Typography>
                <Chip label={typeLabels[selectedRequest.requestType]} size="small" />
              </Box>
              <Box>
                <Typography variant="subtitle2" color="text.secondary">Status</Typography>
                <Chip 
                  icon={statusIcons[selectedRequest.status]}
                  label={selectedRequest.status}
                  color={statusColors[selectedRequest.status]}
                  size="small"
                />
              </Box>
              <Box>
                <Typography variant="subtitle2" color="text.secondary">Target Chaincode</Typography>
                <Typography variant="body2">{selectedRequest.chaincodeName}</Typography>
              </Box>
              <Box>
                <Typography variant="subtitle2" color="text.secondary">Function</Typography>
                <Typography variant="body2" fontFamily="monospace">{selectedRequest.functionName}</Typography>
              </Box>
              <Box>
                <Typography variant="subtitle2" color="text.secondary">Arguments</Typography>
                <Paper variant="outlined" sx={{ p: 1, bgcolor: 'grey.50' }}>
                  <Typography variant="body2" fontFamily="monospace" component="pre" sx={{ whiteSpace: 'pre-wrap', wordBreak: 'break-all' }}>
                    {JSON.stringify(selectedRequest.arguments, null, 2)}
                  </Typography>
                </Paper>
              </Box>
              <Box>
                <Typography variant="subtitle2" color="text.secondary">Required Organizations</Typography>
                <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mt: 0.5 }}>
                  {selectedRequest.requiredOrgs.map(org => (
                    <Chip 
                      key={org} 
                      label={org.replace('MSP', '')} 
                      size="small"
                      color={selectedRequest.approvals[org] ? 'success' : 'default'}
                      icon={selectedRequest.approvals[org] ? <CheckCircle /> : undefined}
                    />
                  ))}
                </Box>
              </Box>
              {Object.keys(selectedRequest.rejections).length > 0 && (
                <Box>
                  <Typography variant="subtitle2" color="text.secondary">Rejections</Typography>
                  {Object.entries(selectedRequest.rejections).map(([org, reason]) => (
                    <Alert key={org} severity="error" sx={{ mt: 1 }}>
                      <Typography variant="body2">
                        <strong>{org.replace('MSP', '')}:</strong> {reason}
                      </Typography>
                    </Alert>
                  ))}
                </Box>
              )}
              {selectedRequest.metadata && (
                <Box>
                  <Typography variant="subtitle2" color="text.secondary">Metadata</Typography>
                  <Paper variant="outlined" sx={{ p: 1, bgcolor: 'grey.50' }}>
                    <Typography variant="body2" fontFamily="monospace" component="pre">
                      {JSON.stringify(selectedRequest.metadata, null, 2)}
                    </Typography>
                  </Paper>
                </Box>
              )}
              <Box>
                <Typography variant="subtitle2" color="text.secondary">Created</Typography>
                <Typography variant="body2">{new Date(selectedRequest.createdAt).toLocaleString()}</Typography>
              </Box>
              <Box>
                <Typography variant="subtitle2" color="text.secondary">Last Updated</Typography>
                <Typography variant="body2">{new Date(selectedRequest.updatedAt).toLocaleString()}</Typography>
              </Box>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailsDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* History Dialog */}
      <Dialog open={historyDialogOpen} onClose={() => setHistoryDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Approval History</DialogTitle>
        <DialogContent>
          {history.length === 0 ? (
            <Typography variant="body2" color="text.secondary">No history available</Typography>
          ) : (
            <Stack spacing={2}>
              {history.map((entry, index) => (
                <Paper key={index} variant="outlined" sx={{ p: 2 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Chip label={entry.action} size="small" color="primary" />
                    <Typography variant="caption" color="text.secondary">
                      {new Date(entry.timestamp).toLocaleString()}
                    </Typography>
                  </Box>
                  <Typography variant="body2">
                    <strong>Actor:</strong> {entry.actor}
                  </Typography>
                  {entry.reason && (
                    <Typography variant="body2">
                      <strong>Reason:</strong> {entry.reason}
                    </Typography>
                  )}
                  {entry.txID && (
                    <Typography variant="body2" fontFamily="monospace" fontSize="0.75rem">
                      <strong>TX:</strong> {entry.txID}
                    </Typography>
                  )}
                </Paper>
              ))}
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setHistoryDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};
