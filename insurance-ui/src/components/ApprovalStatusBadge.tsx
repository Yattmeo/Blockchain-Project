import { Chip } from '@mui/material';
import {
  Pending,
  CheckCircle,
  Cancel,
  PlayArrow,
} from '@mui/icons-material';
import type { ApprovalStatus } from '../types/blockchain';

interface ApprovalStatusBadgeProps {
  status: ApprovalStatus;
  size?: 'small' | 'medium';
  showIcon?: boolean;
}

const statusConfig: Record<ApprovalStatus, {
  color: 'warning' | 'success' | 'error' | 'info';
  icon: React.ReactElement;
  label: string;
}> = {
  PENDING: {
    color: 'warning',
    icon: <Pending />,
    label: 'Pending Approval',
  },
  APPROVED: {
    color: 'success',
    icon: <CheckCircle />,
    label: 'Approved',
  },
  REJECTED: {
    color: 'error',
    icon: <Cancel />,
    label: 'Rejected',
  },
  EXECUTED: {
    color: 'info',
    icon: <PlayArrow />,
    label: 'Executed',
  },
};

export const ApprovalStatusBadge: React.FC<ApprovalStatusBadgeProps> = ({
  status,
  size = 'small',
  showIcon = true,
}) => {
  const config = statusConfig[status];

  return (
    <Chip
      icon={showIcon ? config.icon : undefined}
      label={config.label}
      color={config.color}
      size={size}
    />
  );
};
