import { Card, CardContent, Typography, Box, CircularProgress } from '@mui/material';
import type { ReactElement } from 'react';

interface ChartCardProps {
  title: string;
  subtitle?: string;
  loading?: boolean;
  chart: ReactElement;
  height?: number;
}

export const ChartCard: React.FC<ChartCardProps> = ({
  title,
  subtitle,
  loading = false,
  chart,
  height = 300,
}) => {
  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom fontWeight={600}>
          {title}
        </Typography>
        {subtitle && (
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            {subtitle}
          </Typography>
        )}
        {loading ? (
          <Box
            sx={{
              height,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <CircularProgress />
          </Box>
        ) : (
          <Box sx={{ height }}>{chart}</Box>
        )}
      </CardContent>
    </Card>
  );
};
