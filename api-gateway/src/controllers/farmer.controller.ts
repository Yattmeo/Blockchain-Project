import { Request, Response } from 'express';
import fabricGateway from '../services/fabricGateway';
import { asyncHandler, ApiError } from '../middleware/errorHandler';
import config from '../config';

/**
 * Register a new farmer - creates an approval request for multi-party approval
 */
export const registerFarmer = asyncHandler(async (req: Request, res: Response) => {
  const {
    farmerID,
    firstName,
    lastName,
    coopID,
    phone,
    email,
    walletAddress,
    latitude,
    longitude,
    region,
    district,
    farmSize,
    cropTypes,
    kycHash
  } = req.body;

  // Validation
  if (!farmerID || !firstName || !lastName || !coopID) {
    throw new ApiError(400, 'farmerID, firstName, lastName, and coopID are required');
  }

  // Convert string values to appropriate types
  const lat = parseFloat(latitude) || 0;
  const lon = parseFloat(longitude) || 0;
  const size = parseFloat(farmSize) || 0;

  // Ensure cropTypes is an array
  const crops = Array.isArray(cropTypes) ? cropTypes : [cropTypes].filter(Boolean);

  // Create approval request for farmer registration
  // The actual farmer registration will happen when the request is executed after approval
  const requestID = `FARMER_REG_${farmerID}_${Date.now()}`;
  
  // Prepare arguments for the RegisterFarmer function
  const registerFarmerArgs = [
    farmerID,
    firstName,
    lastName,
    coopID,
    phone || '',
    email || '',
    walletAddress || '',
    lat.toString(),
    lon.toString(),
    region || '',
    district || '',
    size.toString(),
    JSON.stringify(crops),
    kycHash || ''
  ];

  // Required organizations for approval (2 insurers)
  const requiredOrgs = ['Insurer1MSP', 'Insurer2MSP'];

  // Metadata about the request
  const metadata = {
    description: `Farmer registration for ${firstName} ${lastName}`,
    farmerID,
    coopID,
    submittedBy: req.headers['x-user-org'] || 'unknown'
  };

  const result = await fabricGateway.submitTransaction(
    config.chaincodes.approvalManager,
    'CreateApprovalRequest',
    requestID,
    'FARMER_REGISTRATION',
    'farmer', // chaincodeName
    'RegisterFarmer', // functionName
    JSON.stringify(registerFarmerArgs), // argumentsJSON
    JSON.stringify(requiredOrgs), // requiredOrgsJSON
    JSON.stringify(metadata) // metadataJSON
  );

  res.status(201).json({
    success: true,
    message: 'Farmer registration request created successfully',
    data: {
      requestID,
      farmerID,
      status: 'PENDING'
    }
  });
});

/**
 * Get farmer by ID
 */
export const getFarmer = asyncHandler(async (req: Request, res: Response) => {
  const { farmerId } = req.params;

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.farmer,
    'GetFarmer',
    farmerId
  );

  if (!result) {
    throw new ApiError(404, `Farmer ${farmerId} not found`);
  }

  res.json({
    success: true,
    data: result,
  });
});

/**
 * Get all farmers
 * Note: Farmer chaincode doesn't have GetAllFarmers, using GetFarmersByRegion with empty region
 * or alternatively could query all coop members
 */
export const getAllFarmers = asyncHandler(async (req: Request, res: Response) => {
  // Option 1: Get by region (empty = all regions)
  // Option 2: Return empty array with message to use specific queries
  // For now, we'll use GetActivePolicies pattern and return guidance
  
  res.json({
    success: true,
    data: [],
    message: 'Use /farmers/by-coop/:coopId or /farmers/by-region/:region to query farmers'
  });
});

/**
 * Update farmer
 */
export const updateFarmer = asyncHandler(async (req: Request, res: Response) => {
  const { farmerId } = req.params;
  const { name, location, contactInfo } = req.body;

  const result = await fabricGateway.submitTransaction(
    config.chaincodes.farmer,
    'UpdateFarmer',
    farmerId,
    name || '',
    location || '',
    contactInfo || ''
  );

  res.json({
    success: true,
    message: 'Farmer updated successfully',
    data: result,
  });
});

/**
 * Get farmers by cooperative
 */
export const getFarmersByCoop = asyncHandler(async (req: Request, res: Response) => {
  const { coopId } = req.params;

  // First get the list of farmer IDs
  const farmerList = await fabricGateway.evaluateTransaction(
    config.chaincodes.farmer,
    'GetCoopMembers',
    coopId
  );

  // Then get full details for each farmer
  const farmers = [];
  if (Array.isArray(farmerList)) {
    for (const farmerSummary of farmerList) {
      try {
        const fullFarmer = await fabricGateway.evaluateTransaction(
          config.chaincodes.farmer,
          'GetFarmer',
          farmerSummary.farmerID
        );
        farmers.push(fullFarmer);
      } catch (error) {
        // If GetFarmer fails, use the summary data we have
        console.warn(`Failed to get full details for farmer ${farmerSummary.farmerID}:`, error);
        farmers.push(farmerSummary);
      }
    }
  }

  res.json({
    success: true,
    data: farmers,
  });
});

/**
 * Get farmers by region
 */
export const getFarmersByRegion = asyncHandler(async (req: Request, res: Response) => {
  const { region } = req.params;

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.farmer,
    'GetFarmersByRegion',
    region
  );

  res.json({
    success: true,
    data: result,
  });
});

