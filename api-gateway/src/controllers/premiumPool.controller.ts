import { Request, Response } from 'express';
import fabricGateway from '../services/fabricGateway';
import { asyncHandler } from '../middleware/errorHandler';
import config from '../config';

/**
 * Get pool balance
 */
export const getPoolBalance = asyncHandler(async (req: Request, res: Response) => {
  try {
    const result = await fabricGateway.evaluateTransaction(
      config.chaincodes.premiumPool,
      'GetPoolBalance'
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error: any) {
    // If pool not initialized, return zero balance
    if (error.message && error.message.includes('pool not initialized')) {
      res.json({
        success: true,
        data: 0,
        message: 'Pool not initialized yet. Make a deposit to initialize.',
      });
    } else {
      throw error;
    }
  }
});

/**
 * Add funds to pool (generic function)
 */
export const addFunds = asyncHandler(async (req: Request, res: Response) => {
  const { amount, source } = req.body;

  const result = await fabricGateway.submitTransaction(
    config.chaincodes.premiumPool,
    'AddFunds',
    amount.toString(),
    source || 'premium'
  );

  res.json({
    success: true,
    message: 'Funds added to pool',
    data: result,
  });
});

/**
 * Deposit premium for a policy
 */
export const depositPremium = asyncHandler(async (req: Request, res: Response) => {
  const { farmerID, policyID, amount } = req.body;

  if (!farmerID || !policyID || !amount) {
    res.status(400).json({
      success: false,
      message: 'farmerID, policyID, and amount are required',
    });
    return;
  }

  if (amount <= 0) {
    res.status(400).json({
      success: false,
      message: 'Premium amount must be positive',
    });
    return;
  }

  // Generate transaction ID
  const txID = `PREMIUM_${policyID}_${Date.now()}`;

  await fabricGateway.submitTransaction(
    config.chaincodes.premiumPool,
    'DepositPremium',
    txID,
    farmerID,
    policyID,
    amount.toString()
  );

  res.json({
    success: true,
    message: 'Premium deposited successfully',
    data: {
      txID,
      farmerID,
      policyID,
      amount,
    },
  });
});

/**
 * Withdraw funds from pool (Execute Payout)
 */
export const withdrawFunds = asyncHandler(async (req: Request, res: Response) => {
  const { amount, recipient, claimID, policyID } = req.body;

  if (!amount || !recipient) {
    res.status(400).json({
      success: false,
      message: 'amount and recipient (farmerID) are required',
    });
    return;
  }

  // Generate transaction ID
  const txID = `PAYOUT_${claimID || 'CLAIM'}_${Date.now()}`;

  const result = await fabricGateway.submitTransaction(
    config.chaincodes.premiumPool,
    'ExecutePayout',
    txID,
    recipient,  // farmerID
    policyID || '',  // policyID
    claimID || '',  // claimID
    amount.toString()
  );

  res.json({
    success: true,
    message: 'Payout executed from pool',
    data: {
      txID,
      amount,
      recipient,
      claimID,
      policyID
    },
  });
});

/**
 * Get transaction history
 */
export const getTransactionHistory = asyncHandler(async (req: Request, res: Response) => {
  const { farmerID } = req.query;

  // If farmerID provided, get farmer-specific history; otherwise get all
  const result = farmerID
    ? await fabricGateway.evaluateTransaction(
        config.chaincodes.premiumPool,
        'GetTransactionHistory',
        farmerID as string
      )
    : await fabricGateway.evaluateTransaction(
        config.chaincodes.premiumPool,
        'GetAllTransactionHistory'
      );

  res.json({
    success: true,
    data: result || [],
  });
});

/**
 * Get pool statistics
 */
export const getPoolStats = asyncHandler(async (req: Request, res: Response) => {
  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.premiumPool,
    'GetPoolDetails'
  );

  res.json({
    success: true,
    data: result,
  });
});

/**
 * Get farmer balance
 */
export const getFarmerBalance = asyncHandler(async (req: Request, res: Response) => {
  const { farmerId } = req.params;

  if (!farmerId) {
    return res.status(400).json({ success: false, message: 'farmerId is required' });
  }

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.premiumPool,
    'GetFarmerBalance',
    farmerId
  );

  res.json({
    success: true,
    data: result || { balance: 0 },
  });
});
