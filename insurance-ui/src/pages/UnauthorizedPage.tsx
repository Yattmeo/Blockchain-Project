import { Box, Typography, Button, Container } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { Lock } from '@mui/icons-material';

export const UnauthorizedPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Container maxWidth="sm">
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '60vh',
          textAlign: 'center',
        }}
      >
        <Lock sx={{ fontSize: 80, color: 'error.main', mb: 2 }} />
        <Typography variant="h4" gutterBottom fontWeight={600}>
          Access Denied
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
          You don't have permission to access this page. Please contact your administrator if you
          believe this is an error.
        </Typography>
        <Button variant="contained" onClick={() => navigate('/dashboard')}>
          Return to Dashboard
        </Button>
      </Box>
    </Container>
  );
};
