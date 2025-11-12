import { Request, Response } from 'express';
import fabricGateway from '../services/fabricGateway';
import { asyncHandler, ApiError } from '../middleware/errorHandler';
import config from '../config';

/**
 * Get all active policy templates
 */
export const getAllTemplates = asyncHandler(async (req: Request, res: Response) => {
  // Get all active templates from blockchain
  const result = await fabricGateway.evaluateTransaction(
    'policy-template',
    'GetActiveTemplates'
  );

  res.status(200).json({
    success: true,
    data: result,
    count: Array.isArray(result) ? result.length : 0
  });
});

/**
 * Get a specific policy template by ID
 */
export const getTemplate = asyncHandler(async (req: Request, res: Response) => {
  const { templateId } = req.params;

  // Get template details
  const result = await fabricGateway.evaluateTransaction(
    'policy-template',
    'GetTemplate',
    templateId
  );

  if (!result) {
    throw new ApiError(404, 'Policy template not found');
  }

  res.status(200).json({
    success: true,
    data: result
  });
});

/**
 * Get weather thresholds for a specific template
 */
export const getTemplateThresholds = asyncHandler(async (req: Request, res: Response) => {
  const { templateId } = req.params;

  // Get index thresholds (weather conditions)
  const result = await fabricGateway.evaluateTransaction(
    'policy-template',
    'GetIndexThresholds',
    templateId
  );

  res.status(200).json({
    success: true,
    data: result,
    count: Array.isArray(result) ? result.length : 0
  });
});

/**
 * Get templates by crop type
 */
export const getTemplatesByCrop = asyncHandler(async (req: Request, res: Response) => {
  const { cropType } = req.params;

  // Get all active templates and filter by crop
  const result = await fabricGateway.evaluateTransaction(
    'policy-template',
    'GetActiveTemplates'
  );

  const templates = Array.isArray(result) 
    ? result.filter((template: any) => template.cropType.toLowerCase() === cropType.toLowerCase())
    : [];

  res.status(200).json({
    success: true,
    data: templates,
    count: templates.length
  });
});

/**
 * Get templates by region
 */
export const getTemplatesByRegion = asyncHandler(async (req: Request, res: Response) => {
  const { region } = req.params;

  // Get all active templates and filter by region
  const result = await fabricGateway.evaluateTransaction(
    'policy-template',
    'GetActiveTemplates'
  );

  const templates = Array.isArray(result)
    ? result.filter((template: any) => template.region.toLowerCase() === region.toLowerCase())
    : [];

  res.status(200).json({
    success: true,
    data: templates,
    count: templates.length
  });
});

/**
 * Create a new policy template
 */
export const createTemplate = asyncHandler(async (req: Request, res: Response) => {
  const { templateID, templateName, cropType, region, riskLevel, coveragePeriod, maxCoverage, minPremium } = req.body;

  // Validate required fields
  if (!templateID || !templateName || !cropType || !region || !riskLevel || !coveragePeriod || !maxCoverage || !minPremium) {
    throw new ApiError(400, 'Missing required fields');
  }

  // Submit transaction to create template
  await fabricGateway.submitTransaction(
    'policy-template',
    'CreateTemplate',
    templateID,
    templateName,
    cropType,
    region,
    riskLevel,
    coveragePeriod.toString(),
    maxCoverage.toString(),
    minPremium.toString()
  );

  res.status(201).json({
    success: true,
    message: 'Template created successfully',
    data: { templateID }
  });
});

/**
 * Activate a policy template
 */
export const activateTemplate = asyncHandler(async (req: Request, res: Response) => {
  const { templateId } = req.params;

  // Submit transaction to activate template
  await fabricGateway.submitTransaction(
    'policy-template',
    'ActivateTemplate',
    templateId
  );

  res.status(200).json({
    success: true,
    message: 'Template activated successfully',
    data: { templateID: templateId, status: 'Active' }
  });
});

/**
 * Set index threshold for a template
 */
export const setIndexThreshold = asyncHandler(async (req: Request, res: Response) => {
  const { templateId } = req.params;
  const { indexType, metric, thresholdValue, operator, measurementDays, payoutPercent, severity } = req.body;

  if (!indexType || !metric || thresholdValue === undefined || !operator || !measurementDays || !payoutPercent || !severity) {
    throw new ApiError(400, 'indexType, metric, thresholdValue, operator, measurementDays, payoutPercent, and severity are required');
  }

  // Submit transaction to set threshold
  await fabricGateway.submitTransaction(
    'policy-template',
    'SetIndexThreshold',
    templateId,
    indexType,
    metric,
    thresholdValue.toString(),
    operator,
    measurementDays.toString(),
    payoutPercent.toString(),
    severity
  );

  res.status(201).json({
    success: true,
    message: 'Index threshold set successfully',
    data: {
      templateID: templateId,
      indexType,
      metric,
      thresholdValue,
      operator,
      measurementDays,
      payoutPercent,
      severity
    }
  });
});
