import express from 'express';
import * as policyController from '../controllers/policy.controller';

const router = express.Router();

/**
 * @route   POST /api/v1/policies
 * @desc    Create a new policy
 * @access  Public
 */
router.post('/', policyController.createPolicy);

/**
 * @route   GET /api/v1/policies
 * @desc    Get all policies
 * @access  Public
 */
router.get('/', policyController.getAllPolicies);

/**
 * @route   GET /api/v1/policies/:policyId
 * @desc    Get policy by ID
 * @access  Public
 */
router.get('/:policyId', policyController.getPolicy);

/**
 * @route   GET /api/v1/policies/farmer/:farmerId
 * @desc    Get policies by farmer ID
 * @access  Public
 */
router.get('/farmer/:farmerId', policyController.getPoliciesByFarmer);

/**
 * @route   POST /api/v1/policies/:policyId/activate
 * @desc    Activate a policy
 * @access  Public
 */
router.post('/:policyId/activate', policyController.activatePolicy);

/**
 * @route   GET /api/v1/policies/:policyId/history
 * @desc    Get policy history
 * @access  Public
 */
router.get('/:policyId/history', policyController.getPolicyHistory);

export default router;
