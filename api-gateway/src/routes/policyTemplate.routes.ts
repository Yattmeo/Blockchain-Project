import express from 'express';
import {
  getAllTemplates,
  getTemplate,
  getTemplateThresholds,
  getTemplatesByCrop,
  getTemplatesByRegion,
  createTemplate,
  activateTemplate,
  setIndexThreshold
} from '../controllers/policyTemplate.controller';

const router = express.Router();

// Create new template
router.post('/', createTemplate);

// Get all active templates
router.get('/', getAllTemplates);

// Get templates by crop type
router.get('/by-crop/:cropType', getTemplatesByCrop);

// Get templates by region
router.get('/by-region/:region', getTemplatesByRegion);

// Get specific template
router.get('/:templateId', getTemplate);

// Set index threshold for template
router.post('/:templateId/thresholds', setIndexThreshold);

// Activate template
router.post('/:templateId/activate', activateTemplate);

// Get weather thresholds for a template
router.get('/:templateId/thresholds', getTemplateThresholds);

export default router;
