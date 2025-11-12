import { Request, Response } from 'express';
import fabricGateway from '../services/fabricGateway';
import { asyncHandler, ApiError } from '../middleware/errorHandler';
import config from '../config';

/**
 * Get all claims (audit trail)
 */
export const getAllClaims = asyncHandler(async (req: Request, res: Response) => {
  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.claimProcessor,
    'GetAllClaims'
  );

  res.json({
    success: true,
    data: result || [],
  });
});

/**
 * Get claim by ID
 */
export const getClaim = asyncHandler(async (req: Request, res: Response) => {
  const { claimId } = req.params;

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.claimProcessor,
    'GetClaim',
    claimId
  );

  if (!result) {
    throw new ApiError(404, `Claim ${claimId} not found`);
  }

  res.json({
    success: true,
    data: result,
  });
});

/**
 * Get claims by farmer ID
 */
export const getClaimsByFarmer = asyncHandler(async (req: Request, res: Response) => {
  const { farmerId } = req.params;

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.claimProcessor,
    'GetClaimHistory',
    farmerId
  );

  res.json({
    success: true,
    data: result || [],
  });
});

/**
 * Get claims by status
 */
export const getClaimsByStatus = asyncHandler(async (req: Request, res: Response) => {
  const { status } = req.params;

  const validStatuses = ['Triggered', 'Processing', 'Paid', 'Failed'];
  if (!validStatuses.includes(status)) {
    throw new ApiError(400, `Invalid status. Must be one of: ${validStatuses.join(', ')}`);
  }

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.claimProcessor,
    'GetClaimsByStatus',
    status
  );

  res.json({
    success: true,
    data: result || [],
  });
});

/**
 * Retry failed payout (only manual action allowed)
 */
export const retryPayout = asyncHandler(async (req: Request, res: Response) => {
  const { claimId } = req.params;

  const result = await fabricGateway.submitTransaction(
    config.chaincodes.claimProcessor,
    'RetryPayout',
    claimId
  );

  res.json({
    success: true,
    message: 'Payout retry initiated',
    data: result,
  });
});

/**
 * Get claim history
 */
export const getClaimHistory = asyncHandler(async (req: Request, res: Response) => {
  const { claimId } = req.params;

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.claimProcessor,
    'GetClaimHistory',
    claimId
  );

  res.json({
    success: true,
    data: result || [],
  });
});

/**
 * Get pending claims
 */
export const getPendingClaims = asyncHandler(async (req: Request, res: Response) => {
  try {
    const result = await fabricGateway.evaluateTransaction(
      config.chaincodes.claimProcessor,
      'GetPendingClaims'
    );

    res.json({
      success: true,
      data: result || [],
    });
  } catch (error: any) {
    // If no pending claims exist, return empty array
    if (error.message && error.message.includes('does not exist')) {
      res.json({
        success: true,
        data: [],
        message: 'No pending claims found',
      });
    } else {
      throw error;
    }
  }
});

/**
 * Trigger a payout/claim based on weather data
 */
export const triggerClaim = asyncHandler(async (req: Request, res: Response) => {
  const {
    claimID,
    policyID,
    farmerID,
    weatherDataID,
    coverageAmount,
    payoutPercent
  } = req.body;

  if (!claimID || !policyID || !farmerID || !weatherDataID) {
    throw new ApiError(400, 'claimID, policyID, farmerID, and weatherDataID are required');
  }

  const coverage = parseFloat(coverageAmount) || 10000;
  const payout = parseFloat(payoutPercent) || 50;

  const result = await fabricGateway.submitTransaction(
    config.chaincodes.claimProcessor,
    'TriggerPayout',
    claimID,
    policyID,
    farmerID,
    weatherDataID,  // Using as indexID
    coverage.toString(),
    payout.toString()
  );

  res.status(201).json({
    success: true,
    message: 'Claim triggered successfully',
    data: {
      claimID,
      policyID,
      farmerID,
      weatherDataID,
      payoutAmount: coverage * (payout / 100),
      payoutPercent: payout
    },
  });
});
