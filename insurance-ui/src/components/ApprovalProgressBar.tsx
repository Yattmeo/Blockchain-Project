import { Box, Typography, LinearProgress, Tooltip } from '@mui/material';
import type { ApprovalRequest } from '../types/blockchain';

interface ApprovalProgressBarProps {
  approvals: Record<string, boolean>;
  requiredOrgs: string[];
  showLabel?: boolean;
  height?: number;
}

export const ApprovalProgressBar: React.FC<ApprovalProgressBarProps> = ({
  approvals,
  requiredOrgs,
  showLabel = true,
  height = 6,
}) => {
  const approvedCount = Object.keys(approvals).length;
  const requiredCount = requiredOrgs.length;
  const progress = (approvedCount / requiredCount) * 100;
  const isComplete = progress === 100;

  const approvedOrgs = Object.keys(approvals).map(org => org.replace('MSP', ''));
  const pendingOrgs = requiredOrgs
    .filter(org => !approvals[org])
    .map(org => org.replace('MSP', ''));

  const tooltipContent = (
    <Box>
      {approvedOrgs.length > 0 && (
        <Box sx={{ mb: 0.5 }}>
          <Typography variant="caption" sx={{ fontWeight: 600 }}>
            Approved:
          </Typography>
          <Typography variant="caption" sx={{ display: 'block' }}>
            {approvedOrgs.join(', ')}
          </Typography>
        </Box>
      )}
      {pendingOrgs.length > 0 && (
        <Box>
          <Typography variant="caption" sx={{ fontWeight: 600 }}>
            Pending:
          </Typography>
          <Typography variant="caption" sx={{ display: 'block' }}>
            {pendingOrgs.join(', ')}
          </Typography>
        </Box>
      )}
    </Box>
  );

  return (
    <Box sx={{ width: '100%' }}>
      {showLabel && (
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
          <Typography variant="caption" color="text.secondary">
            {approvedCount} of {requiredCount} organizations
          </Typography>
          <Typography
            variant="caption"
            color={isComplete ? 'success.main' : 'text.secondary'}
            sx={{ fontWeight: isComplete ? 600 : 400 }}
          >
            {Math.round(progress)}%
          </Typography>
        </Box>
      )}
      <Tooltip title={tooltipContent} arrow placement="top">
        <LinearProgress
          variant="determinate"
          value={progress}
          color={isComplete ? 'success' : 'primary'}
          sx={{
            height,
            borderRadius: 1,
            bgcolor: 'action.hover',
          }}
        />
      </Tooltip>
    </Box>
  );
};

// Simplified version that takes an ApprovalRequest
interface ApprovalProgressProps {
  request: ApprovalRequest;
  showLabel?: boolean;
  height?: number;
}

export const ApprovalProgress: React.FC<ApprovalProgressProps> = ({
  request,
  showLabel = true,
  height = 6,
}) => {
  return (
    <ApprovalProgressBar
      approvals={request.approvals}
      requiredOrgs={request.requiredOrgs}
      showLabel={showLabel}
      height={height}
    />
  );
};
