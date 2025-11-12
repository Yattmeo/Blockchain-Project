import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  Container,
  Typography,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  Stack,
  Alert,
} from '@mui/material';
import { Business, AccountCircle } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import type { UserRole } from '../types/blockchain';
import { MSP_IDS } from '../config/api';

interface OrgOption {
  id: string;
  name: string;
  mspId: string;
  type: 'Insurer' | 'Coop' | 'Oracle' | 'Validator';
}

const organizations: OrgOption[] = [
  { id: 'insurer1', name: 'Insurance Company 1', mspId: MSP_IDS.INSURER1, type: 'Insurer' },
  { id: 'insurer2', name: 'Insurance Company 2', mspId: MSP_IDS.INSURER2, type: 'Insurer' },
  { id: 'coop', name: 'Farmers Cooperative', mspId: MSP_IDS.COOP, type: 'Coop' },
  { id: 'platform', name: 'Platform Admin', mspId: MSP_IDS.PLATFORM, type: 'Validator' },
];

const roleMapping: Record<string, UserRole> = {
  Insurer: 'insurer',
  Coop: 'coop',
  Oracle: 'oracle',
  Validator: 'admin',
};

export const LoginPage: React.FC = () => {
  const [selectedOrg, setSelectedOrg] = useState<string>('');
  const [userName, setUserName] = useState<string>('');
  const [error, setError] = useState<string>('');
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleLogin = () => {
    if (!selectedOrg || !userName) {
      setError('Please select an organization and enter your name');
      return;
    }

    const org = organizations.find((o) => o.id === selectedOrg);
    if (!org) {
      setError('Invalid organization');
      return;
    }

    // Create mock user with appropriate role
    const user = {
      id: `${org.id}-${Date.now()}`,
      name: userName,
      role: roleMapping[org.type],
      orgId: org.id,
      permissions: getPermissionsForRole(roleMapping[org.type]),
    };

    // Mock token (in production, this would come from backend authentication)
    const token = `mock-token-${user.id}`;

    login(user, token);
    navigate('/dashboard');
  };

  const getPermissionsForRole = (role: UserRole): string[] => {
    switch (role) {
      case 'insurer':
        return [
          'policy:create',
          'policy:approve',
          'claim:approve',
          'claim:reject',
          'pool:view',
          'pool:deposit',
        ];
      case 'coop':
        return [
          'farmer:register',
          'farmer:update',
          'farmer:view',
          'policy:create',
          'policy:view',
        ];
      case 'oracle':
        return ['weather:submit', 'weather:view', 'oracle:register'];
      case 'admin':
        return [
          'org:register',
          'role:assign',
          'farmer:view',
          'policy:view',
          'claim:view',
          'pool:view',
          'weather:view',
        ];
      default:
        return [];
    }
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      }}
    >
      <Container maxWidth="sm">
        <Card sx={{ borderRadius: 3, boxShadow: 4 }}>
          <CardContent sx={{ p: 4 }}>
            <Box sx={{ textAlign: 'center', mb: 4 }}>
              <AccountCircle sx={{ fontSize: 60, color: 'primary.main', mb: 2 }} />
              <Typography variant="h4" component="h1" gutterBottom fontWeight={600}>
                Blockchain Insurance
              </Typography>
              <Typography variant="body1" color="text.secondary">
                Select your organization to access the platform
              </Typography>
            </Box>

            {error && (
              <Alert severity="error" sx={{ mb: 3 }}>
                {error}
              </Alert>
            )}

            <Stack spacing={3}>
              <TextField
                fullWidth
                label="Your Name"
                variant="outlined"
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
                placeholder="Enter your full name"
              />
              <FormControl fullWidth>
                <InputLabel>Organization</InputLabel>
                <Select
                  value={selectedOrg}
                  label="Organization"
                  onChange={(e) => setSelectedOrg(e.target.value)}
                >
                  {organizations.map((org) => (
                    <MenuItem key={org.id} value={org.id}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Business fontSize="small" />
                        {org.name}
                      </Box>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              <Button
                fullWidth
                variant="contained"
                size="large"
                onClick={handleLogin}
                sx={{ py: 1.5, fontSize: '1.1rem' }}
              >
                Access Dashboard
              </Button>
            </Stack>

            <Box sx={{ mt: 4, p: 2, bgcolor: 'background.default', borderRadius: 2 }}>
              <Typography variant="caption" color="text.secondary" display="block">
                <strong>Demo Mode:</strong> This is a demonstration interface for the Hyperledger
                Fabric blockchain insurance platform. Select any organization to explore
                role-based features.
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Container>
    </Box>
  );
};
