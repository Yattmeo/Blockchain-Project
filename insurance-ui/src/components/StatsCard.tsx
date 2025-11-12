import { Card, CardContent, Typography, Box, CircularProgress } from '@mui/material';
import type { ReactElement } from 'react';

interface StatsCardProps {
  title: string;
  value: string | number;
  icon?: ReactElement;
  loading?: boolean;
  subtitle?: string;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  color?: 'primary' | 'secondary' | 'success' | 'error' | 'warning' | 'info';
}

export const StatsCard: React.FC<StatsCardProps> = ({
  title,
  value,
  icon,
  loading = false,
  subtitle,
  trend,
  color = 'primary',
}) => {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <Box sx={{ flex: 1 }}>
            <Typography color="text.secondary" gutterBottom variant="body2">
              {title}
            </Typography>
            {loading ? (
              <CircularProgress size={32} sx={{ my: 1 }} />
            ) : (
              <Typography variant="h3" component="div" sx={{ fontWeight: 600, mb: 1 }}>
                {value}
              </Typography>
            )}
            {subtitle && (
              <Typography variant="body2" color="text.secondary">
                {subtitle}
              </Typography>
            )}
            {trend && (
              <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
                <Typography
                  variant="body2"
                  sx={{
                    color: trend.isPositive ? 'success.main' : 'error.main',
                    fontWeight: 500,
                  }}
                >
                  {trend.isPositive ? '↑' : '↓'} {Math.abs(trend.value)}%
                </Typography>
              </Box>
            )}
          </Box>
          {icon && (
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: 56,
                height: 56,
                borderRadius: 2,
                bgcolor: `${color}.main`,
                color: 'white',
              }}
            >
              {icon}
            </Box>
          )}
        </Box>
      </CardContent>
    </Card>
  );
};
