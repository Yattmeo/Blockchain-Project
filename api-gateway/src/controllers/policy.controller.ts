import { Request, Response } from 'express';
import fabricGateway from '../services/fabricGateway';
import { asyncHandler, ApiError } from '../middleware/errorHandler';
import config from '../config';

/**
 * Create a new policy - creates an approval request for multi-party approval
 */
export const createPolicy = asyncHandler(async (req: Request, res: Response) => {
  const { 
    policyID, farmerID, templateID, coverageAmount, premiumAmount, 
    startDate, endDate, coopID, insurerID, farmLocation, cropType, farmSize 
  } = req.body;

  if (!policyID || !farmerID || !templateID || !coverageAmount || !premiumAmount) {
    throw new ApiError(400, 'policyID, farmerID, templateID, coverageAmount, and premiumAmount are required');
  }

  // Calculate coverage days from start and end dates
  const start = new Date(startDate || Date.now());
  const end = new Date(endDate || Date.now() + 180 * 24 * 60 * 60 * 1000);
  const coverageDays = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));

  // Generate unique request ID
  const requestID = `POL_REQ_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // Build CreatePolicy arguments array - must match chaincode signature:
  // policyID, farmerID, templateID, coopID, insurerID, coverageAmount, premiumAmount, coverageDays,
  // farmLocation, cropType, farmSize, policyTermsHash
  const createPolicyArgs = [
    policyID,
    farmerID,
    templateID,
    coopID || 'COOP001',
    insurerID || 'INSURER001',
    coverageAmount.toString(),
    premiumAmount.toString(),
    coverageDays.toString(),
    farmLocation || '0,0',
    cropType || 'Rice',
    farmSize?.toString() || '10',
    `0x${Math.random().toString(16).substr(2, 64)}`, // policyTermsHash
  ];

  // Required approvers: Insurer1 and Insurer2
  const requiredOrgs = ['Insurer1MSP', 'Insurer2MSP'];

  // Metadata for the request (must be JSON object as map[string]string)
  const metadata = {
    description: `Policy creation for farmer ${farmerID} using template ${templateID}`,
    policyID: policyID,
    farmerID: farmerID,
    templateID: templateID,
    coverageAmount: coverageAmount.toString(),
    premiumAmount: premiumAmount.toString(),
    coverageDays: coverageDays.toString(),
    startDate: start.toISOString(),
    endDate: end.toISOString(),
  };

  // Create approval request
  const result = await fabricGateway.submitTransaction(
    'approval-manager',
    'CreateApprovalRequest',
    requestID,
    'POLICY_CREATION',
    'policy',
    'CreatePolicy',
    JSON.stringify(createPolicyArgs),
    JSON.stringify(requiredOrgs),
    JSON.stringify(metadata)  // Send as JSON string
  );

  res.status(201).json({
    success: true,
    message: 'Policy creation approval request submitted successfully',
    data: {
      requestID,
      status: 'PENDING',
      policyID,
      farmerID,
      templateID,
      coverageAmount,
      premiumAmount,
      coverageDays,
    },
  });
});

/**
 * Get policy by ID
 */
export const getPolicy = asyncHandler(async (req: Request, res: Response) => {
  const { policyId } = req.params;

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.policy,
    'GetPolicy',
    policyId
  );

  if (!result) {
    throw new ApiError(404, `Policy ${policyId} not found`);
  }

  res.json({
    success: true,
    data: result,
  });
});

/**
 * Get all policies
 * Using GetActivePolicies as default - chaincode doesn't have GetAllPolicies
 */
export const getAllPolicies = asyncHandler(async (req: Request, res: Response) => {
  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.policy,
    'GetActivePolicies'
  );

  res.json({
    success: true,
    data: result || [],
  });
});

/**
 * Get policies by farmer ID
 */
export const getPoliciesByFarmer = asyncHandler(async (req: Request, res: Response) => {
  const { farmerId } = req.params;

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.policy,
    'GetPoliciesByFarmer',
    farmerId
  );

  res.json({
    success: true,
    data: result || [],
  });
});

/**
 * Activate policy
 */
export const activatePolicy = asyncHandler(async (req: Request, res: Response) => {
  const { policyId } = req.params;

  const result = await fabricGateway.submitTransaction(
    config.chaincodes.policy,
    'ActivatePolicy',
    policyId
  );

  res.json({
    success: true,
    message: 'Policy activated successfully',
    data: result,
  });
});

/**
 * Get policy history
 */
export const getPolicyHistory = asyncHandler(async (req: Request, res: Response) => {
  const { policyId } = req.params;

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.policy,
    'GetPolicyHistory',
    policyId
  );

  res.json({
    success: true,
    data: result || [],
  });
});
