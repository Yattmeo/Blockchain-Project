import { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  CircularProgress,
  Alert,
} from '@mui/material';
import {
  People,
  Description,
  AutoAwesome,
  AccountBalance,
} from '@mui/icons-material';
import type { DashboardStats } from '../types/blockchain';
import { dashboardService } from '../services';
import { useAuth } from '../contexts/AuthContext';
import { StatsCard } from '../components/StatsCard';

export const DashboardPage: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const { user } = useAuth();

  useEffect(() => {
    const fetchStats = async () => {
      try {
        setLoading(true);
        const response = await dashboardService.getStats(user?.orgId);
        if (response.success && response.data) {
          setStats(response.data);
        } else {
          setError(response.error || 'Failed to load statistics');
        }
      } catch (err) {
        setError('An error occurred while loading dashboard data');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, [user?.orgId]);

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom fontWeight={600}>
        Welcome, {user?.name}
      </Typography>
      <Typography variant="body1" color="text.secondary" gutterBottom sx={{ mb: 4 }}>
        {user?.role === 'insurer' && 'Monitor automated parametric insurance operations and premium pool'}
        {user?.role === 'coop' && 'Register farmers, create policies, and manage your cooperative'}
        {user?.role === 'oracle' && 'Submit weather data for automated claim triggering'}
        {user?.role === 'admin' && 'Oversee the automated blockchain insurance platform'}
      </Typography>

      {error && (
        <Alert severity="info" sx={{ mb: 3 }}>
          {error} - Using demo mode. Connect API Gateway to see live data.
        </Alert>
      )}

      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 3, mb: 4 }}>
        <StatsCard
          title="Total Farmers"
          value={stats?.totalFarmers || 0}
          icon={<People sx={{ fontSize: 32 }} />}
          loading={loading}
          color="primary"
        />

        <StatsCard
          title="Active Policies"
          value={stats?.activePolicies || 0}
          icon={<Description sx={{ fontSize: 32 }} />}
          loading={loading}
          color="info"
        />

        <StatsCard
          title="Triggered Claims"
          value={stats?.triggeredClaims || 0}
          icon={<AutoAwesome sx={{ fontSize: 32 }} />}
          loading={loading}
          color="success"
          subtitle="Auto-triggered by smart contracts"
        />

        <StatsCard
          title="Pool Balance"
          value={stats?.poolBalance ? `$${stats.poolBalance.toLocaleString()}` : '$0'}
          icon={<AccountBalance sx={{ fontSize: 32 }} />}
          loading={loading}
          color="success"
        />
      </Box>

      <Box sx={{ mt: 4 }}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom fontWeight={600}>
              Quick Actions
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {user?.role === 'insurer' && 'Create policy templates, approve claims, manage premium pool'}
              {user?.role === 'coop' && 'Register new farmers, create farmer policies, view cooperative statistics'}
              {user?.role === 'oracle' && 'Submit weather data, view data history, validate consensus'}
              {user?.role === 'admin' && 'Register organizations, assign roles, view system-wide analytics'}
            </Typography>
          </CardContent>
        </Card>
      </Box>
    </Box>
  );
};
