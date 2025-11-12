import {
  Card,
  CardContent,
  CardActions,
  Typography,
  Box,
  Button,
  Chip,
  Divider,
  Stack,
} from '@mui/material';
import {
  ThumbUp,
  ThumbDown,
  PlayArrow,
  Info,
  History,
} from '@mui/icons-material';
import type { ApprovalRequest, ApprovalRequestType } from '../types/blockchain';
import { ApprovalStatusBadge } from './ApprovalStatusBadge';
import { ApprovalProgress } from './ApprovalProgressBar';
import { extractOrgFromIdentity } from '../utils/identity';

interface ApprovalCardProps {
  request: ApprovalRequest;
  canApprove?: boolean;
  canReject?: boolean;
  canExecute?: boolean;
  onApprove?: (request: ApprovalRequest) => void;
  onReject?: (request: ApprovalRequest) => void;
  onExecute?: (request: ApprovalRequest) => void;
  onViewDetails?: (request: ApprovalRequest) => void;
  onViewHistory?: (request: ApprovalRequest) => void;
  compact?: boolean;
}

const typeLabels: Record<ApprovalRequestType, string> = {
  FARMER_REGISTRATION: 'Farmer Registration',
  POLICY_CREATION: 'Policy Creation',
  CLAIM_APPROVAL: 'Claim Approval',
  POOL_WITHDRAWAL: 'Pool Withdrawal',
};

export const ApprovalCard: React.FC<ApprovalCardProps> = ({
  request,
  canApprove = false,
  canReject = false,
  canExecute = false,
  onApprove,
  onReject,
  onExecute,
  onViewDetails,
  onViewHistory,
  compact = false,
}) => {
  const handleApprove = (e: React.MouseEvent) => {
    e.stopPropagation();
    onApprove?.(request);
  };

  const handleReject = (e: React.MouseEvent) => {
    e.stopPropagation();
    onReject?.(request);
  };

  const handleExecute = (e: React.MouseEvent) => {
    e.stopPropagation();
    onExecute?.(request);
  };

  const handleViewDetails = (e: React.MouseEvent) => {
    e.stopPropagation();
    onViewDetails?.(request);
  };

  const handleViewHistory = (e: React.MouseEvent) => {
    e.stopPropagation();
    onViewHistory?.(request);
  };

  return (
    <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <CardContent sx={{ flexGrow: 1 }}>
        {/* Header */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
          <Box sx={{ flex: 1 }}>
            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 0.5 }}>
              Request ID
            </Typography>
            <Typography
              variant="body2"
              fontFamily="monospace"
              sx={{ wordBreak: 'break-all' }}
            >
              {compact ? `${request.requestId.slice(0, 12)}...` : request.requestId}
            </Typography>
          </Box>
          <ApprovalStatusBadge status={request.status} />
        </Box>

        {/* Type */}
        <Box sx={{ mb: 2 }}>
          <Chip
            label={typeLabels[request.requestType]}
            size="small"
            variant="outlined"
            color="primary"
          />
        </Box>

        {/* Progress */}
        <Box sx={{ mb: 2 }}>
          <ApprovalProgress request={request} />
        </Box>

        {/* Metadata */}
        {request.metadata && !compact && (
          <Box sx={{ mb: 2 }}>
            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 0.5 }}>
              Details
            </Typography>
            <Stack spacing={0.5}>
              {Object.entries(request.metadata).slice(0, 3).map(([key, value]) => (
                <Typography key={key} variant="body2" fontSize="0.8rem">
                  <strong>{key}:</strong> {String(value)}
                </Typography>
              ))}
            </Stack>
          </Box>
        )}

        <Divider sx={{ my: 1.5 }} />

        {/* Footer Info */}
        <Box>
          <Typography variant="caption" color="text.secondary">
            Created by {extractOrgFromIdentity(request.createdBy)} • {new Date(request.createdAt).toLocaleDateString()}
          </Typography>
        </Box>

        {/* Rejection Info */}
        {request.status === 'REJECTED' && Object.keys(request.rejections).length > 0 && (
          <Box sx={{ mt: 1.5, p: 1, bgcolor: 'error.lighter', borderRadius: 1 }}>
            <Typography variant="caption" color="error.dark" sx={{ display: 'block', fontWeight: 600 }}>
              Rejection Reason:
            </Typography>
            <Typography variant="caption" color="error.dark">
              {Object.values(request.rejections)[0]}
            </Typography>
          </Box>
        )}
      </CardContent>

      {/* Actions */}
      <CardActions sx={{ p: 2, pt: 0, flexWrap: 'wrap', gap: 0.5 }}>
        {canApprove && request.status === 'PENDING' && (
          <Button
            size="small"
            variant="contained"
            color="success"
            startIcon={<ThumbUp />}
            onClick={handleApprove}
          >
            Approve
          </Button>
        )}
        
        {canReject && request.status === 'PENDING' && (
          <Button
            size="small"
            variant="outlined"
            color="error"
            startIcon={<ThumbDown />}
            onClick={handleReject}
          >
            Reject
          </Button>
        )}
        
        {canExecute && request.status === 'APPROVED' && (
          <Button
            size="small"
            variant="contained"
            color="primary"
            startIcon={<PlayArrow />}
            onClick={handleExecute}
          >
            Execute
          </Button>
        )}
        
        {onViewDetails && (
          <Button
            size="small"
            variant="outlined"
            startIcon={<Info />}
            onClick={handleViewDetails}
          >
            Details
          </Button>
        )}
        
        {onViewHistory && (
          <Button
            size="small"
            variant="outlined"
            startIcon={<History />}
            onClick={handleViewHistory}
          >
            History
          </Button>
        )}
      </CardActions>
    </Card>
  );
};
