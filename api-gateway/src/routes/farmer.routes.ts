import express from 'express';
import * as farmerController from '../controllers/farmer.controller';

const router = express.Router();

/**
 * @route   POST /api/v1/farmers
 * @desc    Register a new farmer
 * @access  Public
 */
router.post('/', farmerController.registerFarmer);

/**
 * @route   GET /api/v1/farmers
 * @desc    Get all farmers
 * @access  Public
 */
router.get('/', farmerController.getAllFarmers);

/**
 * @route   GET /api/v1/farmers/by-coop/:coopId
 * @desc    Get farmers by cooperative
 * @access  Public
 */
router.get('/by-coop/:coopId', farmerController.getFarmersByCoop);

/**
 * @route   GET /api/v1/farmers/by-region/:region
 * @desc    Get farmers by region
 * @access  Public
 */
router.get('/by-region/:region', farmerController.getFarmersByRegion);

/**
 * @route   GET /api/v1/farmers/:farmerId
 * @desc    Get farmer by ID
 * @access  Public
 */
router.get('/:farmerId', farmerController.getFarmer);

/**
 * @route   PUT /api/v1/farmers/:farmerId
 * @desc    Update farmer
 * @access  Public
 */
router.put('/:farmerId', farmerController.updateFarmer);

export default router;
