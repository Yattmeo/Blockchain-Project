import express from 'express';
import { getDashboardStats, getRecentTransactions } from '../controllers/dashboard.controller';

const router = express.Router();

/**
 * @route   GET /api/dashboard/stats
 * @desc    Get dashboard statistics
 * @access  Public
 */
router.get('/stats', getDashboardStats);

/**
 * @route   GET /api/dashboard/transactions
 * @desc    Get recent transactions
 * @access  Public
 */
router.get('/transactions', getRecentTransactions);

export default router;
