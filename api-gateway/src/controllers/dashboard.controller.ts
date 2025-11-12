import { Request, Response } from 'express';
import { fabricGateway } from '../services/fabricGateway';
import logger from '../utils/logger';

/**
 * Get dashboard statistics
 */
export const getDashboardStats = async (req: Request, res: Response) => {
  const { orgID } = req.query;

  logger.info('Fetching dashboard statistics', { orgID });

  try {
    // Get all active policies
    const policiesResult = await fabricGateway.evaluateTransaction(
      'policy',
      'GetActivePolicies'
    );
    const policies = typeof policiesResult === 'string' ? JSON.parse(policiesResult) : policiesResult;
    const policiesArray = Array.isArray(policies) ? policies : [];

    // Get all policy templates
    const templatesResult = await fabricGateway.evaluateTransaction(
      'policy-template',
      'GetActiveTemplates'
    );
    const templates = typeof templatesResult === 'string' ? JSON.parse(templatesResult) : templatesResult;
    const templatesArray = Array.isArray(templates) ? templates : [];

    // Calculate statistics
    const stats = {
      totalFarmers: 0, // We'll need to implement GetAllFarmers
      activePolicies: policiesArray.length,
      triggeredClaims: 0, // We'll need to implement GetAllClaims
      poolBalance: 0, // We'll need to implement GetPoolBalance
      totalCoverage: policiesArray.reduce((sum: number, p: any) => sum + (p.coverageAmount || 0), 0),
      totalPremiums: policiesArray.reduce((sum: number, p: any) => sum + (p.premiumAmount || 0), 0),
      activeTemplates: templatesArray.length,
    };

    // Try to get farmers count by querying coop members
    try {
      const farmersResult = await fabricGateway.evaluateTransaction(
        'farmer',
        'GetCoopMembers',
        'COOP001'  // Using uppercase as that's what's in the blockchain
      );
      const farmers = typeof farmersResult === 'string' ? JSON.parse(farmersResult) : farmersResult;
      stats.totalFarmers = Array.isArray(farmers) ? farmers.length : 0;
    } catch (err) {
      logger.debug('Could not fetch farmers count', { error: err });
      // Total farmers is 0 if we can't fetch them
      stats.totalFarmers = 0;
    }

    // Try to get claims count (triggered = Approved or Paid status)
    try {
      const claimsResult = await fabricGateway.evaluateTransaction(
        'claim-processor',
        'GetAllClaims'
      );
      const claimsData = typeof claimsResult === 'string' ? JSON.parse(claimsResult) : claimsResult;
      const claimsArray = Array.isArray(claimsData) ? claimsData : [];
      // Count claims that are triggered (Approved, Paid, or Processing)
      stats.triggeredClaims = claimsArray.filter((c: any) => 
        c.status === 'Approved' || c.status === 'Paid' || c.status === 'Processing'
      ).length;
    } catch (err) {
      logger.debug('Could not fetch claims count', { error: err });
      stats.triggeredClaims = 0;
    }

    // Try to get pool balance
    try {
      const poolResult = await fabricGateway.evaluateTransaction(
        'premium-pool',
        'GetPoolBalance'
      );
      // GetPoolBalance returns a float directly, not an object
      const balance = typeof poolResult === 'string' ? parseFloat(poolResult) : poolResult;
      stats.poolBalance = balance || 0;
    } catch (err: any) {
      logger.debug('Could not fetch pool balance (pool may not be initialized)', { error: err.message });
      // Pool not initialized yet, default to 0
      stats.poolBalance = 0;
    }

    res.json({
      success: true,
      data: stats,
      message: 'Dashboard statistics retrieved successfully',
    });
  } catch (error: any) {
    logger.error('Failed to fetch dashboard statistics', { error: error.message });
    res.status(500).json({
      success: false,
      message: 'Failed to fetch dashboard statistics',
      error: error.message,
    });
  }
};

/**
 * Get recent transactions/activities
 */
export const getRecentTransactions = async (req: Request, res: Response) => {
  const limit = parseInt(req.query.limit as string) || 10;

  logger.info('Fetching recent transactions', { limit });

  try {
    // For now, we'll return policy creation history
    const policiesResult = await fabricGateway.evaluateTransaction(
      'policy',
      'GetActivePolicies'
    );
    const policies = typeof policiesResult === 'string' ? JSON.parse(policiesResult) : policiesResult;
    const policiesArray = Array.isArray(policies) ? policies : [];

    // Map policies to transaction format
    const transactions = policiesArray
      .sort((a: any, b: any) => new Date(b.createdDate).getTime() - new Date(a.createdDate).getTime())
      .slice(0, limit)
      .map((policy: any) => ({
        id: policy.policyID,
        type: 'POLICY_CREATION',
        amount: policy.coverageAmount,
        timestamp: policy.createdDate,
        status: policy.status,
        description: `Policy created for farmer ${policy.farmerID}`,
      }));

    res.json({
      success: true,
      data: transactions,
      count: transactions.length,
    });
  } catch (error: any) {
    logger.error('Failed to fetch recent transactions', { error: error.message });
    res.status(500).json({
      success: false,
      message: 'Failed to fetch recent transactions',
      error: error.message,
    });
  }
};
