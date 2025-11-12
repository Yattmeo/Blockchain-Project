import { Request, Response, NextFunction } from 'express';
import logger from '../utils/logger';

export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public isOperational = true
  ) {
    super(message);
    Object.setPrototypeOf(this, ApiError.prototype);
  }
}

export const errorHandler = (
  err: Error | ApiError,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (err instanceof ApiError) {
    logger.error(`API Error: ${err.message}`, {
      statusCode: err.statusCode,
      path: req.path,
      method: req.method,
    });

    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    });
  }

  // Unknown errors
  logger.error('Unhandled error:', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  // For Fabric Gateway errors, try to extract more details
  const fabricError = err as any;
  let errorDetails = err.message;
  
  // If it's a Fabric endorsement error with details, include the chaincode message
  if (fabricError.details && Array.isArray(fabricError.details) && fabricError.details.length > 0) {
    const chaincodeMessage = fabricError.details[0].message;
    if (chaincodeMessage) {
      errorDetails = chaincodeMessage;
    }
  }

  return res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: errorDetails,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

export const asyncHandler = (fn: Function) => (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};
