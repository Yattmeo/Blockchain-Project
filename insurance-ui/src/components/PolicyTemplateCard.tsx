import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
  Divider,
  Stack,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import type { PolicyTemplate, IndexThreshold } from '../types/blockchain';

interface PolicyTemplateCardProps {
  template: PolicyTemplate;
  onSelect?: (template: PolicyTemplate) => void;
  selected?: boolean;
}

const getWeatherIcon = (indexType: string) => {
  switch (indexType) {
    case 'Rainfall':
      return '💧';
    case 'Temperature':
      return '🌡️';
    case 'Drought':
      return '🏜️';
    case 'Humidity':
      return '💨';
    default:
      return '🌦️';
  }
};

const formatOperator = (operator: string) => {
  switch (operator) {
    case '<':
      return 'less than';
    case '>':
      return 'greater than';
    case '<=':
      return 'less than or equal to';
    case '>=':
      return 'greater than or equal to';
    case '==':
      return 'equal to';
    default:
      return operator;
  }
};

const formatThresholdDescription = (threshold: IndexThreshold) => {
  const { indexType, metric, thresholdValue, operator, measurementDays, payoutPercent } = threshold;
  
  return `${indexType} ${formatOperator(operator)} ${thresholdValue}${metric} over ${measurementDays} days → ${payoutPercent}% payout`;
};

export const PolicyTemplateCard: React.FC<PolicyTemplateCardProps> = ({
  template,
  onSelect,
  selected = false,
}) => {
  const handleClick = () => {
    if (onSelect) {
      onSelect(template);
    }
  };

  return (
    <Card
      sx={{
        cursor: 'pointer',
        transition: 'all 0.2s',
        '&:hover': {
          boxShadow: 6,
        },
        border: selected ? 2 : 1,
        borderColor: selected ? 'primary.main' : 'divider',
        height: '100%',
      }}
      onClick={handleClick}
    >
      <CardContent>
        <Stack spacing={2}>
          {/* Header */}
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <Box sx={{ flex: 1 }}>
              <Typography variant="h6" component="h3" gutterBottom>
                {template.templateName}
              </Typography>
              <Stack direction="row" spacing={1} alignItems="center">
                <Typography variant="body2" color="text.secondary">
                  {template.cropType} • {template.region}
                </Typography>
                <Chip
                  label={`${template.riskLevel} Risk`}
                  size="small"
                  color={
                    template.riskLevel === 'Low'
                      ? 'success'
                      : template.riskLevel === 'High'
                      ? 'error'
                      : 'warning'
                  }
                />
              </Stack>
            </Box>
            {selected && (
              <CheckCircleIcon color="primary" sx={{ ml: 1 }} />
            )}
          </Box>

          <Divider />

          {/* Coverage Details */}
          <Box
            sx={{
              display: 'grid',
              gridTemplateColumns: 'repeat(2, 1fr)',
              gap: 2,
            }}
          >
            <Box>
              <Typography variant="caption" color="text.secondary">
                Coverage Period
              </Typography>
              <Typography variant="body2" fontWeight="medium">
                {template.coveragePeriod} days
              </Typography>
            </Box>
            <Box>
              <Typography variant="caption" color="text.secondary">
                Max Coverage
              </Typography>
              <Typography variant="body2" fontWeight="medium">
                ${template.maxCoverage.toLocaleString()}
              </Typography>
            </Box>
            <Box>
              <Typography variant="caption" color="text.secondary">
                Min Premium
              </Typography>
              <Typography variant="body2" fontWeight="medium">
                ${template.minPremium.toLocaleString()}
              </Typography>
            </Box>
            <Box>
              <Typography variant="caption" color="text.secondary">
                Base Rate
              </Typography>
              <Typography variant="body2" fontWeight="medium">
                {(template.pricingModel.baseRate * 100).toFixed(1)}%
              </Typography>
            </Box>
          </Box>

          <Divider />

          {/* Weather Trigger Conditions */}
          <Box>
            <Typography variant="subtitle2" gutterBottom fontWeight="bold">
              Weather Trigger Conditions
            </Typography>
            {template.indexThresholds && template.indexThresholds.length > 0 ? (
              <Stack spacing={1}>
                {template.indexThresholds.map((threshold: IndexThreshold, index: number) => (
                  <Box
                    key={index}
                    sx={{
                      p: 1.5,
                      borderRadius: 1,
                      bgcolor:
                        threshold.severity === 'Mild'
                          ? 'warning.light'
                          : threshold.severity === 'Moderate'
                          ? 'warning.main'
                          : 'error.light',
                      color:
                        threshold.severity === 'Mild'
                          ? 'warning.dark'
                          : threshold.severity === 'Moderate'
                          ? 'warning.contrastText'
                          : 'error.contrastText',
                      border: 1,
                      borderColor: 'divider',
                    }}
                  >
                    <Stack direction="row" spacing={1} alignItems="flex-start">
                      <Typography variant="body2" sx={{ fontSize: '1.2em' }}>
                        {getWeatherIcon(threshold.indexType)}
                      </Typography>
                      <Box sx={{ flex: 1 }}>
                        <Typography variant="body2" fontWeight="medium">
                          {formatThresholdDescription(threshold)}
                        </Typography>
                        <Typography variant="caption">
                          {threshold.severity} severity
                        </Typography>
                      </Box>
                    </Stack>
                  </Box>
                ))}
              </Stack>
            ) : (
              <Typography variant="body2" color="text.secondary" fontStyle="italic">
                No weather conditions defined
              </Typography>
            )}
          </Box>

          <Divider />

          {/* Footer Info */}
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="caption" color="text.secondary">
              ID: {template.templateID}
            </Typography>
            <Chip label={template.status} size="small" color="success" />
          </Box>
        </Stack>
      </CardContent>
    </Card>
  );
};
