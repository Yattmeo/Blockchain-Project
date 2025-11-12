# Approval Components - Quick Reference

## Import Components

```typescript
import { 
  ApprovalCard, 
  ApprovalStatusBadge, 
  ApprovalProgress 
} from '../components';
import { useApprovalActions } from '../hooks';
```

---

## 1. ApprovalStatusBadge

### Basic Usage
```tsx
<ApprovalStatusBadge status="PENDING" />
<ApprovalStatusBadge status="APPROVED" />
<ApprovalStatusBadge status="REJECTED" />
<ApprovalStatusBadge status="EXECUTED" />
```

### Options
```tsx
<ApprovalStatusBadge 
  status="PENDING" 
  size="medium"        // small | medium (default: small)
  showIcon={false}     // Hide icon (default: true)
/>
```

---

## 2. ApprovalProgress

### With ApprovalRequest
```tsx
<ApprovalProgress 
  request={approvalRequest} 
  showLabel={true}     // Show "X of Y orgs" (default: true)
  height={6}           // Bar height in pixels (default: 6)
/>
```

### With Manual Data
```tsx
<ApprovalProgressBar
  approvals={{"CoopMSP": true, "Insurer1MSP": true}}
  requiredOrgs={["CoopMSP", "Insurer1MSP", "Insurer2MSP"]}
  showLabel={true}
  height={8}
/>
```

---

## 3. ApprovalCard

### Full Example
```tsx
<ApprovalCard
  request={approvalRequest}
  // Permissions
  canApprove={canApprove(request)}
  canReject={canReject(request)}
  canExecute={canExecute(request)}
  // Event Handlers
  onApprove={(req) => handleApprove(req)}
  onReject={(req) => handleReject(req)}
  onExecute={(req) => handleExecute(req)}
  onViewDetails={(req) => handleDetails(req)}
  onViewHistory={(req) => handleHistory(req)}
  // Display Options
  compact={true}        // Compact view (default: false)
/>
```

### Grid Layout (Recommended)
```tsx
<Box sx={{ 
  display: 'grid', 
  gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', 
  gap: 2 
}}>
  {approvals.map(approval => (
    <ApprovalCard
      key={approval.requestId}
      request={approval}
      {...handlers}
    />
  ))}
</Box>
```

---

## 4. useApprovalActions Hook

### Setup
```tsx
const {
  loading,              // boolean - action in progress
  error,                // string | null - error message
  success,              // string | null - success message
  clearMessages,        // function - clear error/success
  canApprove,          // function - check if can approve
  canReject,           // function - check if can reject
  canExecute,          // function - check if can execute
  approveRequest,      // async function - approve
  rejectRequest,       // async function - reject
  executeRequest,      // async function - execute
} = useApprovalActions();
```

### Check Permissions
```tsx
if (canApprove(request)) {
  // Show approve button
}

if (canReject(request)) {
  // Show reject button
}

if (canExecute(request)) {
  // Show execute button
}
```

### Perform Actions
```tsx
// Approve
const handleApprove = async (request: ApprovalRequest) => {
  const success = await approveRequest(
    request.requestId, 
    'Optional reason'
  );
  if (success) {
    // Refresh data
  }
};

// Reject
const handleReject = async (request: ApprovalRequest) => {
  const reason = prompt('Rejection reason:');
  if (reason) {
    const success = await rejectRequest(request.requestId, reason);
    if (success) {
      // Refresh data
    }
  }
};

// Execute
const handleExecute = async (request: ApprovalRequest) => {
  if (confirm('Execute this request?')) {
    const success = await executeRequest(request.requestId);
    if (success) {
      // Refresh data
    }
  }
};
```

### Display Messages
```tsx
{success && (
  <Alert severity="success" onClose={clearMessages}>
    {success}
  </Alert>
)}

{error && (
  <Alert severity="error" onClose={clearMessages}>
    {error}
  </Alert>
)}
```

---

## 5. Complete Page Integration

### Pattern 1: Fetch Pending Approvals

```tsx
const [pendingApprovals, setPendingApprovals] = useState<ApprovalRequest[]>([]);

const fetchPendingApprovals = async () => {
  try {
    const response = await approvalService.getPendingApprovals();
    if (response.success && response.data) {
      // Filter by type
      const filtered = response.data.approvals.filter(
        approval => approval.requestType === 'FARMER_REGISTRATION'
      );
      setPendingApprovals(filtered);
    }
  } catch (error) {
    console.error('Failed to fetch approvals:', error);
  }
};

useEffect(() => {
  fetchPendingApprovals();
}, []);
```

### Pattern 2: Display Section

```tsx
{pendingApprovals.length > 0 && (
  <Box sx={{ mb: 3 }}>
    <Typography variant="h6" gutterBottom fontWeight={600}>
      Pending Approvals ({pendingApprovals.length})
    </Typography>
    
    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
      These items require multi-party approval
    </Typography>
    
    <Box sx={{ 
      display: 'grid', 
      gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', 
      gap: 2 
    }}>
      {pendingApprovals.map((approval) => (
        <ApprovalCard
          key={approval.requestId}
          request={approval}
          canApprove={canApprove(approval)}
          canReject={canReject(approval)}
          canExecute={canExecute(approval)}
          onApprove={handleApprove}
          onReject={handleReject}
          onExecute={handleExecute}
          compact
        />
      ))}
    </Box>
  </Box>
)}
```

### Pattern 3: Action Handlers with Refresh

```tsx
const handleApprove = async (request: ApprovalRequest) => {
  const success = await approveRequest(request.requestId, 'Approved via UI');
  if (success) {
    fetchPendingApprovals();  // Refresh approvals
    fetchMainData();           // Refresh main table
  }
};

const handleReject = async (request: ApprovalRequest) => {
  const reason = prompt('Please provide a reason for rejection:');
  if (reason) {
    const success = await rejectRequest(request.requestId, reason);
    if (success) {
      fetchPendingApprovals();
    }
  }
};

const handleExecute = async (request: ApprovalRequest) => {
  if (confirm(`Execute ${request.requestType}?`)) {
    const success = await executeRequest(request.requestId);
    if (success) {
      fetchPendingApprovals();
      fetchMainData();
    }
  }
};
```

---

## 6. Styling & Theming

### Card Grid Layouts

```tsx
// Responsive Grid (min 320px cards)
<Box sx={{ 
  display: 'grid', 
  gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', 
  gap: 2 
}} />

// Fixed 3 Columns
<Box sx={{ 
  display: 'grid', 
  gridTemplateColumns: 'repeat(3, 1fr)', 
  gap: 2 
}} />

// Stack on Mobile
<Box sx={{ 
  display: { xs: 'block', md: 'grid' },
  gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
  gap: 2
}} />
```

### Color Customization

Status colors are automatically applied:
- **PENDING**: `warning` (yellow/orange)
- **APPROVED**: `success` (green)
- **REJECTED**: `error` (red)
- **EXECUTED**: `info` (blue)

These use your theme's color palette automatically.

---

## 7. TypeScript Types

```typescript
import type { 
  ApprovalRequest, 
  ApprovalStatus, 
  ApprovalRequestType 
} from '../types/blockchain';

// Approval Status
type ApprovalStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'EXECUTED';

// Request Types
type ApprovalRequestType = 
  | 'FARMER_REGISTRATION' 
  | 'POLICY_CREATION' 
  | 'CLAIM_APPROVAL' 
  | 'POOL_WITHDRAWAL';

// Full Request Object
interface ApprovalRequest {
  requestId: string;
  requestType: ApprovalRequestType;
  chaincodeName: string;
  functionName: string;
  arguments: string[];
  requiredOrgs: string[];
  status: ApprovalStatus;
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  approvals: Record<string, boolean>;
  rejections: Record<string, string>;
  metadata?: Record<string, any>;
}
```

---

## 8. Common Patterns

### Pattern: Conditionally Show Section
```tsx
{pendingApprovals.length > 0 ? (
  <ApprovalSection />
) : (
  <Alert severity="info">No pending approvals</Alert>
)}
```

### Pattern: Loading State
```tsx
{loading ? (
  <CircularProgress />
) : (
  <ApprovalCard request={request} />
)}
```

### Pattern: Empty State
```tsx
{pendingApprovals.length === 0 && (
  <Box sx={{ textAlign: 'center', py: 4 }}>
    <Typography variant="h6" color="text.secondary">
      No pending approvals
    </Typography>
    <Typography variant="body2" color="text.secondary">
      All items are up to date
    </Typography>
  </Box>
)}
```

### Pattern: Action with Confirmation
```tsx
const handleExecute = async (request: ApprovalRequest) => {
  const confirmed = window.confirm(
    `Execute ${request.requestType} for ${request.requestId}?`
  );
  
  if (confirmed) {
    const success = await executeRequest(request.requestId);
    if (success) {
      // Success handling
    }
  }
};
```

---

## 9. Accessibility

All components include:
- ✅ Proper ARIA labels
- ✅ Keyboard navigation
- ✅ Screen reader support
- ✅ Color contrast compliance
- ✅ Focus indicators

---

## 10. Performance Tips

1. **Use Keys**: Always provide unique `key` prop in lists
   ```tsx
   {approvals.map(approval => (
     <ApprovalCard key={approval.requestId} ... />
   ))}
   ```

2. **Memoize Handlers**: Use `useCallback` for event handlers
   ```tsx
   const handleApprove = useCallback(async (request) => {
     // ...
   }, [dependencies]);
   ```

3. **Filter Early**: Filter data before rendering
   ```tsx
   const farmerApprovals = approvals.filter(
     a => a.requestType === 'FARMER_REGISTRATION'
   );
   ```

4. **Compact Mode**: Use `compact` prop for grid displays
   ```tsx
   <ApprovalCard request={req} compact />
   ```

---

## Quick Copy-Paste Template

```tsx
import { useState, useEffect } from 'react';
import { Box, Typography, Alert } from '@mui/material';
import { approvalService } from '../services';
import { ApprovalCard } from '../components';
import { useApprovalActions } from '../hooks';
import type { ApprovalRequest } from '../types/blockchain';

export const MyPage: React.FC = () => {
  const [pendingApprovals, setPendingApprovals] = useState<ApprovalRequest[]>([]);
  const {
    error,
    success,
    clearMessages,
    canApprove,
    canReject,
    canExecute,
    approveRequest,
    rejectRequest,
    executeRequest,
  } = useApprovalActions();

  useEffect(() => {
    fetchApprovals();
  }, []);

  const fetchApprovals = async () => {
    const response = await approvalService.getPendingApprovals();
    if (response.success && response.data) {
      setPendingApprovals(response.data.approvals);
    }
  };

  const handleApprove = async (request: ApprovalRequest) => {
    if (await approveRequest(request.requestId)) {
      fetchApprovals();
    }
  };

  const handleReject = async (request: ApprovalRequest) => {
    const reason = prompt('Reason:');
    if (reason && await rejectRequest(request.requestId, reason)) {
      fetchApprovals();
    }
  };

  const handleExecute = async (request: ApprovalRequest) => {
    if (confirm('Execute?') && await executeRequest(request.requestId)) {
      fetchApprovals();
    }
  };

  return (
    <Box>
      {success && <Alert severity="success" onClose={clearMessages}>{success}</Alert>}
      {error && <Alert severity="error" onClose={clearMessages}>{error}</Alert>}
      
      {pendingApprovals.length > 0 && (
        <Box sx={{ mb: 3 }}>
          <Typography variant="h6">Pending Approvals</Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 2, mt: 2 }}>
            {pendingApprovals.map(approval => (
              <ApprovalCard
                key={approval.requestId}
                request={approval}
                canApprove={canApprove(approval)}
                canReject={canReject(approval)}
                canExecute={canExecute(approval)}
                onApprove={handleApprove}
                onReject={handleReject}
                onExecute={handleExecute}
                compact
              />
            ))}
          </Box>
        </Box>
      )}
    </Box>
  );
};
```

---

That's it! Copy, paste, and customize as needed. 🚀
