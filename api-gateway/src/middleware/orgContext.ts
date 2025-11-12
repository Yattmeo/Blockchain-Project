import { Request, Response, NextFunction } from 'express';
import fabricGateway from '../services/fabricGateway';
import logger from '../utils/logger';

/**
 * Middleware to set the Fabric Gateway organization context based on user's organization
 */
export const setOrgContext = (req: Request, res: Response, next: NextFunction) => {
  // Get organization from request header (set by frontend)
  const userOrg = req.headers['x-user-org'] as string;

  logger.info(`orgContext middleware - received X-User-Org header: ${userOrg || 'NONE'}`);

  if (userOrg) {
    // Map frontend org names to Fabric org names
    let fabricOrg = userOrg;
    
    // Handle variations
    if (userOrg.toLowerCase().includes('insurer1') || userOrg === 'insurer1@example.com') {
      fabricOrg = 'Insurer1';
    } else if (userOrg.toLowerCase().includes('insurer2') || userOrg === 'insurer2@example.com') {
      fabricOrg = 'Insurer2';
    } else if (userOrg.toLowerCase().includes('coop') || userOrg === 'coop@example.com') {
      fabricOrg = 'Coop';
    } else if (userOrg.toLowerCase().includes('platform') || userOrg === 'platform@example.com') {
      fabricOrg = 'Platform';
    }

    fabricGateway.setOrganization(fabricOrg);
    logger.info(`Set Fabric context to: ${fabricOrg} (from header: ${userOrg})`);
  } else {
    logger.warn('No X-User-Org header found - using default organization (Insurer1)');
  }

  next();
};
