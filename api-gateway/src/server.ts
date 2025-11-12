import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import config from './config';
import logger from './utils/logger';
import { errorHandler } from './middleware/errorHandler';
import { setOrgContext } from './middleware/orgContext';
import fabricGateway from './services/fabricGateway';

// Load environment variables
dotenv.config();

const app = express();

// Middleware
app.use(helmet());
app.use(cors({ origin: config.corsOrigin }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Organization context middleware (before routes)
app.use(setOrgContext);

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    query: req.query,
    body: Object.keys(req.body).length > 0 ? req.body : undefined,
    org: req.headers['x-user-org'],
  });
  next();
});

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Import routes
import farmerRoutes from './routes/farmer.routes';
import policyRoutes from './routes/policy.routes';
import claimRoutes from './routes/claim.routes';
import weatherOracleRoutes from './routes/weatherOracle.routes';
import premiumPoolRoutes from './routes/premiumPool.routes';
import approvalRoutes from './routes/approval.routes';
import policyTemplateRoutes from './routes/policyTemplate.routes';
import dashboardRoutes from './routes/dashboard.routes';

// API Routes
app.get(`${config.apiPrefix}`, (req: Request, res: Response) => {
  res.json({
    message: 'Insurance API Gateway',
    version: '1.0.0',
    endpoints: {
      farmers: `${config.apiPrefix}/farmers`,
      policies: `${config.apiPrefix}/policies`,
      claims: `${config.apiPrefix}/claims`,
      weatherOracle: `${config.apiPrefix}/weather-oracle`,
      premiumPool: `${config.apiPrefix}/premium-pool`,
      approval: `${config.apiPrefix}/approval`,
      policyTemplates: `${config.apiPrefix}/policy-templates`,
      dashboard: `${config.apiPrefix}/dashboard`,
    },
  });
});

// Mount routes
app.use(`${config.apiPrefix}/farmers`, farmerRoutes);
app.use(`${config.apiPrefix}/policies`, policyRoutes);
app.use(`${config.apiPrefix}/claims`, claimRoutes);
app.use(`${config.apiPrefix}/weather-oracle`, weatherOracleRoutes);
app.use(`${config.apiPrefix}/premium-pool`, premiumPoolRoutes);
app.use(`${config.apiPrefix}/approval`, approvalRoutes);
app.use(`${config.apiPrefix}/policy-templates`, policyTemplateRoutes);
app.use(`${config.apiPrefix}/dashboard`, dashboardRoutes);

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    message: `Cannot ${req.method} ${req.path}`,
  });
});

// Error handler (must be last)
app.use(errorHandler);

// Graceful shutdown
const gracefulShutdown = async () => {
  logger.info('Received shutdown signal, closing connections...');
  
  try {
    await fabricGateway.disconnect();
    logger.info('Fabric Gateway disconnected');
    
    process.exit(0);
  } catch (error) {
    logger.error('Error during shutdown:', error);
    process.exit(1);
  }
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

// Start server
const startServer = async () => {
  try {
    // Connect to Fabric network
    await fabricGateway.connect();
    
    // Start HTTP server
    app.listen(config.port, () => {
      logger.info(`API Gateway running on port ${config.port}`);
      logger.info(`Environment: ${config.nodeEnv}`);
      logger.info(`API Prefix: ${config.apiPrefix}`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

export default app;
