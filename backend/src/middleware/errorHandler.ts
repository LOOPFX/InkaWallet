import { Request, Response, NextFunction } from 'express';
import logger from '../utils/logger';

export interface ApiError extends Error {
  statusCode?: number;
  isOperational?: boolean;
}

/**
 * Error handling middleware
 */
export const errorHandler = (
  err: ApiError,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Log error
  logger.error('Error occurred:', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
  });

  // Set status code
  const statusCode = err.statusCode || 500;
  const isOperational = err.isOperational || false;

  // Send error response
  res.status(statusCode).json({
    success: false,
    message: isOperational ? err.message : 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && {
      stack: err.stack,
      details: err,
    }),
  });
};

/**
 * Create operational error
 */
export class OperationalError extends Error {
  statusCode: number;
  isOperational: boolean;

  constructor(message: string, statusCode: number = 500) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Not found error
 */
export class NotFoundError extends OperationalError {
  constructor(message: string = 'Resource not found') {
    super(message, 404);
  }
}

/**
 * Validation error
 */
export class ValidationError extends OperationalError {
  constructor(message: string = 'Validation failed') {
    super(message, 400);
  }
}

/**
 * Unauthorized error
 */
export class UnauthorizedError extends OperationalError {
  constructor(message: string = 'Unauthorized access') {
    super(message, 401);
  }
}

/**
 * Forbidden error
 */
export class ForbiddenError extends OperationalError {
  constructor(message: string = 'Access forbidden') {
    super(message, 403);
  }
}
