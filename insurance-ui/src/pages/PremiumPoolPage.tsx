import { useState, useEffect } from 'react';
import { Box, Typography, Chip, Alert, AlertTitle } from '@mui/material';
import {
  AccountBalance,
  TrendingUp,
  TrendingDown,
  SwapHoriz,
} from '@mui/icons-material';
import { DataTable } from '../components/DataTable';
import { StatsCard } from '../components/StatsCard';
import type { Column } from '../components/DataTable';
import type { Transaction } from '../types/blockchain';
import { premiumPoolService } from '../services';

export const PremiumPoolPage: React.FC = () => {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [poolBalance, setPoolBalance] = useState<number>(0);
  const [error, setError] = useState<string | null>(null);

  // Fetch pool balance and transaction history on mount
  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        setError(null);

        // Fetch pool balance
        const balanceResponse = await premiumPoolService.getPoolBalance();
        if (balanceResponse.success) {
          // API returns just a number
          const balance = typeof balanceResponse.data === 'number' 
            ? balanceResponse.data 
            : (balanceResponse.data as any)?.totalBalance || 0;
          setPoolBalance(balance);
        }

        // Fetch transaction history
        const historyResponse = await premiumPoolService.getTransactionHistory();
        if (historyResponse.success && historyResponse.data) {
          // Filter out empty/invalid transactions
          const validTransactions = historyResponse.data.filter(
            (tx) => tx.txID && tx.txID.trim() !== '' && tx.amount > 0
          );
          setTransactions(validTransactions);
        }
      } catch (err: any) {
        console.error('Failed to fetch premium pool data:', err);
        setError(err.message || 'Failed to load premium pool data');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  // Calculate stats from transactions
  const totalPremiums = transactions
    .filter(tx => tx.type === 'Premium')
    .reduce((sum, tx) => sum + tx.amount, 0);

  const totalPayouts = transactions
    .filter(tx => tx.type === 'Payout' || tx.type === 'Claim Payout')
    .reduce((sum, tx) => sum + tx.amount, 0);

  const columns: Column<Transaction>[] = [
    { id: 'txID', label: 'Transaction ID', minWidth: 150 },
    {
      id: 'type',
      label: 'Type',
      minWidth: 120,
      format: (value) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          {value === 'Premium' ? <TrendingUp color="success" /> : <TrendingDown color="error" />}
          <Chip
            label={value}
            color={value === 'Premium' ? 'success' : 'error'}
            size="small"
          />
        </Box>
      ),
    },
    { id: 'farmerID', label: 'Farmer', minWidth: 120 },
    { id: 'policyID', label: 'Policy', minWidth: 120 },
    {
      id: 'amount',
      label: 'Amount',
      minWidth: 120,
      align: 'right',
      format: (value, row) => (
        <Typography
          color={row.type === 'Premium' ? 'success.main' : 'error.main'}
          fontWeight={600}
        >
          {row.type === 'Premium' ? '+' : '-'}${Number(value).toLocaleString()}
        </Typography>
      ),
    },
    {
      id: 'timestamp',
      label: 'Timestamp',
      minWidth: 150,
      format: (value) => new Date(value).toLocaleString(),
    },
    {
      id: 'status',
      label: 'Status',
      minWidth: 100,
      format: (value) => (
        <Chip
          label={value}
          color={value === 'Completed' ? 'success' : value === 'Pending' ? 'warning' : 'default'}
          size="small"
        />
      ),
    },
  ];

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" gutterBottom fontWeight={600}>
          Premium Pool Management
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Monitor premium pool balance and transaction history
        </Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          <AlertTitle>Error Loading Data</AlertTitle>
          {error}
        </Alert>
      )}

      {poolBalance === 0 && !loading && !error && transactions.length === 0 && (
        <Alert severity="warning" sx={{ mb: 3 }}>
          <AlertTitle>No Pool Data</AlertTitle>
          The premium pool has not been initialized yet. Premium deposits will initialize and fund the pool when policies are activated.
        </Alert>
      )}

      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 3, mb: 3 }}>
        <StatsCard
          title="Total Pool Balance"
          value={`$${poolBalance.toLocaleString()}`}
          icon={<AccountBalance />}
          color="success"
        />
        <StatsCard
          title="Total Deposits"
          value={`$${totalPremiums.toLocaleString()}`}
          icon={<TrendingUp />}
          color="info"
        />
        <StatsCard
          title="Total Payouts"
          value={`$${totalPayouts.toLocaleString()}`}
          icon={<TrendingDown />}
          color="warning"
        />
      </Box>

      <Alert severity="info" icon={<SwapHoriz />} sx={{ mb: 3 }}>
        <AlertTitle>Premium Pool Mechanism</AlertTitle>
        Farmers' premiums are pooled together. When a claim is approved and triggers a payout,
        funds are automatically distributed from the pool to the farmer's wallet address on the blockchain.
      </Alert>

      <DataTable
        columns={columns}
        data={transactions}
        loading={loading}
        searchPlaceholder="Search transactions by ID, type, or participant..."
        emptyMessage="No transactions recorded yet. Premium deposits and payouts will appear here."
      />
    </Box>
  );
};
