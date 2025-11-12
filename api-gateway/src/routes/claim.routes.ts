import express from 'express';
import * as claimController from '../controllers/claim.controller';

const router = express.Router();

/**
 * @route   POST /api/v1/claims
 * @desc    Trigger a new claim/payout
 * @access  Public
 */
router.post('/', claimController.triggerClaim);

/**
 * @route   GET /api/v1/claims
 * @desc    Get all claims (audit trail)
 * @access  Public
 */
router.get('/', claimController.getAllClaims);

/**
 * @route   GET /api/v1/claims/pending
 * @desc    Get pending claims
 * @access  Public
 */
router.get('/pending', claimController.getPendingClaims);

/**
 * @route   GET /api/v1/claims/:claimId
 * @desc    Get claim by ID
 * @access  Public
 */
router.get('/:claimId', claimController.getClaim);

/**
 * @route   GET /api/v1/claims/farmer/:farmerId
 * @desc    Get claims by farmer ID
 * @access  Public
 */
router.get('/farmer/:farmerId', claimController.getClaimsByFarmer);

/**
 * @route   GET /api/v1/claims/status/:status
 * @desc    Get claims by status (Triggered, Processing, Paid, Failed)
 * @access  Public
 */
router.get('/status/:status', claimController.getClaimsByStatus);

/**
 * @route   POST /api/v1/claims/:claimId/retry
 * @desc    Retry failed payout
 * @access  Public
 */
router.post('/:claimId/retry', claimController.retryPayout);

/**
 * @route   GET /api/v1/claims/:claimId/history
 * @desc    Get claim history
 * @access  Public
 */
router.get('/:claimId/history', claimController.getClaimHistory);

export default router;
