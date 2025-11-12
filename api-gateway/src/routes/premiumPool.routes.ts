import express from 'express';
import * as premiumPoolController from '../controllers/premiumPool.controller';

const router = express.Router();

/**
 * @route   GET /api/v1/premium-pool/balance
 * @desc    Get pool balance
 * @access  Public
 */
router.get('/balance', premiumPoolController.getPoolBalance);

/**
 * @route   GET /api/v1/premium-pool/stats
 * @desc    Get pool statistics
 * @access  Public
 */
router.get('/stats', premiumPoolController.getPoolStats);

/**
 * @route   GET /api/v1/premium-pool/history
 * @desc    Get transaction history
 * @access  Public
 */
router.get('/history', premiumPoolController.getTransactionHistory);

/**
 * @route   POST /api/v1/premium-pool/add
 * @desc    Add funds to pool
 * @access  Public
 */
router.post('/add', premiumPoolController.addFunds);

/**
 * @route   POST /api/v1/premium-pool/deposit
 * @desc    Deposit premium for a policy
 * @access  Public
 */
router.post('/deposit', premiumPoolController.depositPremium);

/**
 * @route   POST /api/v1/premium-pool/withdraw
 * @desc    Withdraw funds from pool
 * @access  Public
 */
router.post('/withdraw', premiumPoolController.withdrawFunds);

/**
 * @route   GET /api/v1/premium-pool/farmer-balance/:farmerId
 * @desc    Get farmer balance
 * @access  Public
 */
router.get('/farmer-balance/:farmerId', premiumPoolController.getFarmerBalance);

export default router;
