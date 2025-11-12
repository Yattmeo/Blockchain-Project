import { Box, Typography } from '@mui/material';

export const SettingsPage: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom fontWeight={600}>
        Settings
      </Typography>
      <Typography variant="body1" color="text.secondary">
        Manage your account and preferences
      </Typography>
    </Box>
  );
};
