import { Request, Response } from 'express';
import fabricGateway from '../services/fabricGateway';
import { asyncHandler, ApiError } from '../middleware/errorHandler';

/**
 * Approval Controller
 * Handles multi-party approval workflow operations
 */

const APPROVAL_MANAGER_CC = 'approval-manager';

/**
 * Helper function to normalize blockchain response field names
 * Converts requestID -> requestId for consistency with frontend
 */
function normalizeApprovalRequest(data: any): any {
    if (!data) return data;
    
    if (Array.isArray(data)) {
        return data.map(normalizeApprovalRequest);
    }
    
    if (typeof data === 'object') {
        const normalized: any = {};
        for (const [key, value] of Object.entries(data)) {
            // Convert requestID to requestId
            const normalizedKey = key === 'requestID' ? 'requestId' : key;
            normalized[normalizedKey] = value;
        }
        return normalized;
    }
    
    return data;
}

// ========================================
// CREATE APPROVAL REQUEST
// ========================================

/**
 * Create a new approval request
 * POST /api/approval
 */
export const createApprovalRequest = asyncHandler(async (req: Request, res: Response) => {
    const {
        requestId,
        requestType,
        chaincodeName,
        functionName,
        arguments: args,
        requiredOrgs,
        metadata = {}
    } = req.body;

    // Validation
    if (!requestId || !requestType || !chaincodeName || !functionName || !args || !requiredOrgs) {
        throw new ApiError(400, 'Missing required fields: requestId, requestType, chaincodeName, functionName, arguments, requiredOrgs');
    }

    if (!Array.isArray(args) || !Array.isArray(requiredOrgs)) {
        throw new ApiError(400, 'arguments and requiredOrgs must be arrays');
    }

    // Prepare arguments
    const argsJSON = JSON.stringify(args);
    const requiredOrgsJSON = JSON.stringify(requiredOrgs);
    const metadataJSON = JSON.stringify(metadata);

    // Submit transaction
    await fabricGateway.submitTransaction(
        APPROVAL_MANAGER_CC,
        'CreateApprovalRequest',
        requestId,
        requestType,
        chaincodeName,
        functionName,
        argsJSON,
        requiredOrgsJSON,
        metadataJSON
    );

    res.status(201).json({
        success: true,
        message: 'Approval request created successfully',
        data: {
            requestId,
            status: 'PENDING'
        }
    });
});

// ========================================
// APPROVE REQUEST
// ========================================

/**
 * Approve an approval request
 * POST /api/approval/:requestId/approve
 */
export const approveRequest = asyncHandler(async (req: Request, res: Response) => {
    const { requestId } = req.params;
    const { approverOrg, reason = 'Approved' } = req.body;

    if (!requestId) {
        throw new ApiError(400, 'Request ID is required');
    }

    if (!approverOrg) {
        throw new ApiError(400, 'approverOrg is required (e.g., "Insurer1MSP")');
    }

    // Extract org name from MSP ID (e.g., "Insurer1MSP" -> "Insurer1")
    const orgName = approverOrg.replace('MSP', '');
    
    // Store current org
    const previousOrg = fabricGateway.getCurrentOrg();
    
    try {
        // Switch to the approver's organization
        fabricGateway.setOrganization(orgName);
        await fabricGateway.connectOrg(orgName);

        // Submit transaction as the approver's organization
        await fabricGateway.submitTransaction(
            APPROVAL_MANAGER_CC,
            'ApproveRequest',
            requestId,
            reason
        );

        res.json({
            success: true,
            message: `Request approved successfully by ${approverOrg}`,
            data: {
                requestId,
                action: 'APPROVE',
                approverOrg
            }
        });
    } finally {
        // Restore previous organization context
        fabricGateway.setOrganization(previousOrg);
    }
});

// ========================================
// REJECT REQUEST
// ========================================

/**
 * Reject an approval request
 * POST /api/approval/:requestId/reject
 */
export const rejectRequest = asyncHandler(async (req: Request, res: Response) => {
    const { requestId } = req.params;
    const { reason } = req.body;

    if (!requestId) {
        throw new ApiError(400, 'Request ID is required');
    }

    if (!reason) {
        throw new ApiError(400, 'Rejection reason is required');
    }

    // Submit transaction
    await fabricGateway.submitTransaction(
        APPROVAL_MANAGER_CC,
        'RejectRequest',
        requestId,
        reason
    );

    res.json({
        success: true,
        message: 'Request rejected successfully',
        data: {
            requestId,
            action: 'REJECT',
            reason
        }
    });
});

// ========================================
// EXECUTE APPROVED REQUEST
// ========================================

/**
 * Execute an approved request
 * POST /api/approval/:requestId/execute
 */
export const executeApprovedRequest = asyncHandler(async (req: Request, res: Response) => {
    const { requestId } = req.params;

    if (!requestId) {
        throw new ApiError(400, 'Request ID is required');
    }

    // First, get the approval request to see what type it is
    const approvalRequest = await fabricGateway.evaluateTransaction(
        APPROVAL_MANAGER_CC,
        'GetApprovalRequest',
        requestId
    );

    // evaluateTransaction already returns a parsed object, no need to JSON.parse again
    const request = normalizeApprovalRequest(approvalRequest);

    // Check if request is approved
    if (request.status !== 'APPROVED') {
        throw new ApiError(400, `Request must be APPROVED before execution. Current status: ${request.status}`);
    }

    // Execute the approved request through the approval-manager chaincode
    // The chaincode will invoke the target chaincode (e.g., farmer.RegisterFarmer)
    // This ensures atomic execution and prevents duplicate execution
    const result = await fabricGateway.submitTransaction(
        APPROVAL_MANAGER_CC,
        'ExecuteApprovedRequest',
        requestId
    );

    // ========================================
    // AUTO-DEPOSIT PREMIUM FOR POLICY CREATION
    // ========================================
    // If this was a policy creation request, automatically deposit the premium
    if (request.requestType === 'POLICY_CREATION' && request.metadata) {
        try {
            const { farmerID, policyID, premiumAmount } = request.metadata;
            
            if (farmerID && policyID && premiumAmount) {
                // Generate transaction ID
                const txID = `PREMIUM_${policyID}_${Date.now()}`;
                
                // Deposit premium to pool
                await fabricGateway.submitTransaction(
                    'premium-pool',
                    'DepositPremium',
                    txID,
                    farmerID,
                    policyID,
                    premiumAmount
                );
                
                console.log(`Auto-deposited premium: ${premiumAmount} for policy ${policyID}`);
            }
        } catch (premiumError: any) {
            // Log error but don't fail the execution
            // Policy is already created, premium deposit failure shouldn't block
            console.error('Premium auto-deposit failed:', premiumError.message);
            // Note: In production, you might want to create a "pending premium" record
            // or notify admins to manually process the deposit
        }
    }

    res.json({
        success: true,
        message: 'Request executed successfully',
        data: {
            requestId,
            status: 'EXECUTED',
            result
        }
    });
});

// ========================================
// QUERY OPERATIONS
// ========================================

/**
 * Get a specific approval request
 * GET /api/approval/:requestId
 */
export const getApprovalRequest = asyncHandler(async (req: Request, res: Response) => {
    const { requestId } = req.params;

    if (!requestId) {
        throw new ApiError(400, 'Request ID is required');
    }

    // Evaluate transaction (query)
    const result = await fabricGateway.evaluateTransaction(
        APPROVAL_MANAGER_CC,
        'GetApprovalRequest',
        requestId
    );

    if (!result) {
        throw new ApiError(404, 'Approval request not found');
    }

    res.json({
        success: true,
        data: normalizeApprovalRequest(result)
    });
});

/**
 * Get all pending approval requests
 * GET /api/approval/pending
 */
export const getPendingApprovals = asyncHandler(async (req: Request, res: Response) => {
    // Evaluate transaction (query)
    const result = await fabricGateway.evaluateTransaction(
        APPROVAL_MANAGER_CC,
        'GetPendingApprovals'
    );

    const requests = result || [];

    res.json({
        success: true,
        data: normalizeApprovalRequest(requests),
        count: Array.isArray(requests) ? requests.length : 0
    });
});

/**
 * Get approval requests by status
 * GET /api/approval/status/:status
 */
export const getApprovalsByStatus = asyncHandler(async (req: Request, res: Response) => {
    const { status } = req.params;

    if (!status) {
        throw new ApiError(400, 'Status is required');
    }

    // Validate status
    const validStatuses = ['PENDING', 'APPROVED', 'REJECTED', 'EXECUTED'];
    if (!validStatuses.includes(status.toUpperCase())) {
        throw new ApiError(400, `Invalid status. Must be one of: ${validStatuses.join(', ')}`);
    }

    // Evaluate transaction (query)
    const result = await fabricGateway.evaluateTransaction(
        APPROVAL_MANAGER_CC,
        'GetApprovalsByStatus',
        status.toUpperCase()
    );

    const requests = result || [];

    res.json({
        success: true,
        data: normalizeApprovalRequest(requests),
        count: Array.isArray(requests) ? requests.length : 0
    });
});

/**
 * Get approval history for a request
 * GET /api/approval/:requestId/history
 */
export const getApprovalHistory = asyncHandler(async (req: Request, res: Response) => {
    const { requestId } = req.params;

    if (!requestId) {
        throw new ApiError(400, 'Request ID is required');
    }

    // Evaluate transaction (query)
    const result = await fabricGateway.evaluateTransaction(
        APPROVAL_MANAGER_CC,
        'GetApprovalHistory',
        requestId
    );

    const history = result || [];

    res.json({
        success: true,
        data: normalizeApprovalRequest(history),
        count: Array.isArray(history) ? history.length : 0
    });
});

/**
 * Get all approval requests (for admin/dashboard view)
 * GET /api/approval
 */
export const getAllApprovals = asyncHandler(async (req: Request, res: Response) => {
    // Get all statuses
    const statuses = ['PENDING', 'APPROVED', 'REJECTED', 'EXECUTED'];
    const allRequests: any[] = [];

    for (const status of statuses) {
        try {
            const result = await fabricGateway.evaluateTransaction(
                APPROVAL_MANAGER_CC,
                'GetApprovalsByStatus',
                status
            );
            
            if (result && Array.isArray(result)) {
                allRequests.push(...result);
            }
        } catch (error) {
            // Continue if a status query fails
            console.warn(`Failed to get ${status} requests:`, error);
        }
    }

    // Sort by createdAt descending (newest first)
    allRequests.sort((a, b) => {
        const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
        const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
        return dateB - dateA;
    });

    res.json({
        success: true,
        data: normalizeApprovalRequest(allRequests),
        count: allRequests.length
    });
});
