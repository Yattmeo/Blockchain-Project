import { Request, Response } from 'express';
import fabricGateway from '../services/fabricGateway';
import { asyncHandler, ApiError } from '../middleware/errorHandler';
import config from '../config';
import automaticPayoutService from '../services/automaticPayout.service';
import logger from '../utils/logger';

/**
 * Submit weather data
 */
export const submitWeatherData = asyncHandler(async (req: Request, res: Response) => {
  const { dataID, oracleID, location, latitude, longitude, rainfall, temperature, humidity, windSpeed } = req.body;

  if (!dataID || !oracleID || !location) {
    throw new ApiError(400, 'dataID, oracleID, and location are required');
  }

  // Generate data hash
  const dataHash = `0x${Math.random().toString(16).substr(2, 64)}`;

  const result = await fabricGateway.submitTransaction(
    config.chaincodes.weatherOracle,
    'SubmitWeatherData',
    dataID,
    oracleID,
    location,
    (latitude || 0).toString(),
    (longitude || 0).toString(),
    (rainfall || 0).toString(),
    (temperature || 0).toString(),
    (humidity || 0).toString(),
    (windSpeed || 0).toString(),
    dataHash
  );

  res.status(201).json({
    success: true,
    message: 'Weather data submitted successfully',
    data: {
      dataID,
      oracleID,
      location,
      rainfall,
      temperature,
      humidity,
      windSpeed
    },
  });
});

/**
 * Get weather data by ID
 */
export const getWeatherData = asyncHandler(async (req: Request, res: Response) => {
  const { dataId } = req.params;

  try {
    const result = await fabricGateway.evaluateTransaction(
      config.chaincodes.weatherOracle,
      'GetWeatherData',
      dataId
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error: any) {
    // If weather data doesn't exist, return 404
    if (error.message && error.message.includes('does not exist')) {
      throw new ApiError(404, `Weather data ${dataId} not found`);
    } else {
      throw error;
    }
  }
});

/**
 * Get weather data by location
 */
export const getWeatherDataByLocation = asyncHandler(async (req: Request, res: Response) => {
  const { location } = req.params;
  
  // Get date range from query params or default to last 30 days
  const endDate = new Date();
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - 30); // Last 30 days
  
  const startDateStr = req.query.startDate as string || startDate.toISOString();
  const endDateStr = req.query.endDate as string || endDate.toISOString();

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.weatherOracle,
    'GetWeatherByRegion',
    location,
    startDateStr,
    endDateStr
  );

  // result is already parsed by fabricGateway
  const weatherData = result || [];

  res.json({
    success: true,
    data: weatherData,
  });
});

/**
 * Validate oracle consensus
 */
export const validateConsensus = asyncHandler(async (req: Request, res: Response) => {
  const { location, timestamp, dataIDs } = req.body;

  if (!location || !timestamp || !Array.isArray(dataIDs) || dataIDs.length < 2) {
    throw new ApiError(400, 'location, timestamp, and dataIDs array (min 2) are required');
  }

  const result = await fabricGateway.submitTransaction(
    config.chaincodes.weatherOracle,
    'ValidateDataConsensus',
    location,
    timestamp,
    JSON.stringify(dataIDs)
  );

  const consensusReached = result === 'true' || result === true;

  // If consensus reached, trigger automatic payout checking
  let payoutResult = null;
  if (consensusReached) {
    logger.info(`🎯 Consensus reached for ${location} - checking for automatic payout triggers...`);
    
    try {
      // Get the first validated weather data to extract consensus values
      const weatherData = await fabricGateway.evaluateTransaction(
        config.chaincodes.weatherOracle,
        'GetWeatherData',
        dataIDs[0]
      );
      const weather = JSON.parse(weatherData.toString());

      // Trigger automatic payout checking
      payoutResult = await automaticPayoutService.processConsensusAndTriggerPayouts({
        location,
        timestamp,
        rainfall: weather.rainfall,
        temperature: weather.temperature,
        humidity: weather.humidity,
      });

      logger.info(`✅ Automatic payout processing complete: ${payoutResult.claimsTriggered.length} claims triggered`);
    } catch (error: any) {
      // Log but don't fail the consensus validation
      logger.error(`Error during automatic payout processing: ${error.message}`);
      // Include error in response but don't throw
    }
  }

  res.json({
    success: true,
    message: consensusReached ? 'Consensus validation successful' : 'Consensus not reached',
    data: {
      consensusReached,
      location,
      timestamp,
      validatedDataPoints: dataIDs.length,
      automaticPayouts: consensusReached ? {
        enabled: true,
        policiesChecked: payoutResult?.policiesChecked || 0,
        thresholdsBreached: payoutResult?.thresholdsBreached || 0,
        claimsTriggered: payoutResult?.claimsTriggered || [],
        errors: payoutResult?.errors || [],
      } : {
        enabled: false,
        reason: 'Consensus not reached',
      }
    }
  });
});

/**
 * Get oracle provider by ID
 */
export const getOracleProvider = asyncHandler(async (req: Request, res: Response) => {
  const { oracleID } = req.params;

  if (!oracleID) {
    throw new ApiError(400, 'oracleID is required');
  }

  const result = await fabricGateway.evaluateTransaction(
    config.chaincodes.weatherOracle,
    'GetOracleProvider',
    oracleID
  );

  // result is already parsed by fabricGateway
  const provider = result;

  res.json({
    success: true,
    data: provider,
  });
});

/**
 * Register an oracle provider
 */
export const registerProvider = asyncHandler(async (req: Request, res: Response) => {
  const { oracleID, providerName, providerType, dataSources } = req.body;

  if (!oracleID || !providerName || !providerType) {
    throw new ApiError(400, 'oracleID, providerName, and providerType are required');
  }

  // Validate providerType
  const validTypes = ['API', 'Satellite', 'IoT', 'Manual'];
  if (!validTypes.includes(providerType)) {
    throw new ApiError(400, `Invalid providerType. Must be one of: ${validTypes.join(', ')}`);
  }

  // Ensure dataSources is an array
  const sources = Array.isArray(dataSources) ? dataSources : [dataSources].filter(Boolean);

  const result = await fabricGateway.submitTransaction(
    config.chaincodes.weatherOracle,
    'RegisterOracleProvider',
    oracleID,
    providerName,
    providerType,
    JSON.stringify(sources)
  );

  res.status(201).json({
    success: true,
    message: 'Oracle provider registered successfully',
    data: {
      oracleID,
      providerName,
      providerType,
      dataSources: sources
    },
  });
});
