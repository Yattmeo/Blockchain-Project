import { Router } from 'express';
import {
    createApprovalRequest,
    approveRequest,
    rejectRequest,
    executeApprovedRequest,
    getApprovalRequest,
    getPendingApprovals,
    getApprovalsByStatus,
    getApprovalHistory,
    getAllApprovals
} from '../controllers/approval.controller';

const router = Router();

/**
 * Approval Routes
 * Base path: /api/approval
 */

// Create approval request
router.post('/', createApprovalRequest);

// Get all approval requests
router.get('/', getAllApprovals);

// Get pending approvals
router.get('/pending', getPendingApprovals);

// Get approvals by status
router.get('/status/:status', getApprovalsByStatus);

// Get specific approval request
router.get('/:requestId', getApprovalRequest);

// Get approval history
router.get('/:requestId/history', getApprovalHistory);

// Approve request
router.post('/:requestId/approve', approveRequest);

// Reject request
router.post('/:requestId/reject', rejectRequest);

// Execute approved request
router.post('/:requestId/execute', executeApprovedRequest);

export default router;
