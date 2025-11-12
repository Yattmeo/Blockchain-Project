import express from 'express';
import * as weatherOracleController from '../controllers/weatherOracle.controller';

const router = express.Router();

/**
 * @route   POST /api/v1/weather-oracle
 * @desc    Submit weather data
 * @access  Public
 */
// Register provider
router.post('/register-provider', weatherOracleController.registerProvider);

/**
 * @route   POST /api/v1/weather-oracle
 * @desc    Submit weather data
 * @access  Public
 */
router.post('/', weatherOracleController.submitWeatherData);

/**
 * @route   GET /api/v1/weather-oracle/:dataId
 * @desc    Get weather data by ID
 * @access  Public
 */
router.get('/:dataId', weatherOracleController.getWeatherData);

/**
 * @route   GET /api/v1/weather-oracle/location/:location
 * @desc    Get weather data by location
 * @access  Public
 */
router.get('/location/:location', weatherOracleController.getWeatherDataByLocation);

/**
 * @route   GET /api/v1/weather-oracle/provider/:oracleID
 * @desc    Get oracle provider by ID
 * @access  Public
 */
router.get('/provider/:oracleID', weatherOracleController.getOracleProvider);

/**
 * @route   POST /api/v1/weather-oracle/validate-consensus
 * @desc    Validate consensus for multiple oracle submissions
 * @access  Public
 */
router.post('/validate-consensus', weatherOracleController.validateConsensus);

export default router;
