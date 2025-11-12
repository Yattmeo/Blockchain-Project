import { useState, useEffect } from 'react';
import { Box, Typography, Chip, Button, Alert, AlertTitle, Tabs, Tab } from '@mui/material';
import { AutoAwesome, Refresh, Info } from '@mui/icons-material';
import { DataTable } from '../components/DataTable';
import type { Column } from '../components/DataTable';
import { claimService } from '../services';
import type { Claim } from '../types/blockchain';

export const ClaimsPage: React.FC = () => {
  const [claims, setClaims] = useState<Claim[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const columns: Column<Claim>[] = [
    { id: 'claimID', label: 'Claim ID', minWidth: 120 },
    { id: 'policyID', label: 'Policy ID', minWidth: 120 },
    { id: 'farmerID', label: 'Farmer ID', minWidth: 120 },
    {
      id: 'indexID',
      label: 'Weather Index',
      minWidth: 200,
    },
    {
      id: 'payoutAmount',
      label: 'Payout Amount',
      minWidth: 150,
      align: 'right',
      format: (value) => `$${value.toLocaleString()}`,
    },
    {
      id: 'payoutPercent',
      label: 'Payout %',
      minWidth: 100,
      align: 'right',
      format: (value) => `${value}%`,
    },
    {
      id: 'triggerDate',
      label: 'Triggered On',
      minWidth: 150,
      format: (value) => new Date(value).toLocaleString(),
    },
    {
      id: 'status',
      label: 'Status',
      minWidth: 120,
      format: (value) => {
        const colorMap: Record<string, 'success' | 'warning' | 'info' | 'error'> = {
          Triggered: 'info',
          Processing: 'warning',
          Approved: 'success',
          Paid: 'success',
          Failed: 'error',
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
    {
      id: 'notes',
      label: 'Notes',
      minWidth: 200,
      format: (value) => value || '-',
    },
    {
      id: 'actions',
      label: 'Actions',
      minWidth: 150,
      format: (_, row) => (
        <Box sx={{ display: 'flex', gap: 1 }}>
          {row.status === 'Failed' && (
            <Button
              size="small"
              variant="contained"
              color="warning"
              startIcon={<Refresh />}
              onClick={(e) => {
                e.stopPropagation();
                handleRetryPayout(row.claimID);
              }}
            >
              Retry Payout
            </Button>
          )}
        </Box>
      ),
    },
  ];

  useEffect(() => {
    fetchClaims();
  }, [statusFilter]);

  const fetchClaims = async () => {
    try {
      setLoading(true);
      const response = statusFilter === 'all' 
        ? await claimService.getAllClaims()
        : await claimService.getClaimsByStatus(statusFilter);
      
      if (response.success && response.data) {
        setClaims(response.data);
      }
    } catch (error) {
      console.error('Failed to fetch claims:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRetryPayout = async (claimID: string) => {
    try {
      const response = await claimService.retryPayout(claimID);
      if (response.success) {
        // Refresh claims list
        fetchClaims();
      }
    } catch (error) {
      console.error('Failed to retry payout:', error);
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Box>
          <Typography variant="h4" gutterBottom fontWeight={600}>
            Claims Audit Trail
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Monitor automatically triggered parametric insurance claims
          </Typography>
        </Box>
        <Chip
          icon={<AutoAwesome />}
          label="Fully Automated"
          color="success"
          variant="outlined"
        />
      </Box>

      <Alert severity="info" icon={<Info />} sx={{ mb: 3 }}>
        <AlertTitle>Automatic Claims Processing</AlertTitle>
        Claims are automatically triggered and approved by smart contracts when weather index 
        thresholds are met. No manual approval required. This page provides an audit trail of 
        all automated claim transactions for transparency and compliance purposes.
      </Alert>

      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={statusFilter} onChange={(_, value) => setStatusFilter(value)}>
          <Tab label="All Claims" value="all" />
          <Tab label="Approved" value="Approved" />
          <Tab label="Pending" value="Pending" />
          <Tab label="Paid" value="Paid" />
          <Tab label="Failed" value="Failed" />
        </Tabs>
      </Box>

      <DataTable
        columns={columns}
        data={claims}
        loading={loading}
        searchPlaceholder="Search claims by ID, policy, farmer..."
        emptyMessage="No claims found. Claims are automatically created when weather conditions trigger policy thresholds."
      />
    </Box>
  );
};
