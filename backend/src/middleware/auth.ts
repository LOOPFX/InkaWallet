import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';
import dotenv from 'dotenv';

dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_change_in_production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your_refresh_secret_change_in_production';

export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    phone: string;
  };
}

/**
 * Generate JWT access token
 */
export const generateAccessToken = (payload: any): string => {
  const expiresIn = (process.env.JWT_EXPIRY || '1h') as string;
  return jwt.sign(payload, JWT_SECRET, {
    expiresIn,
  } as jwt.SignOptions);
};

/**
 * Generate JWT refresh token
 */
export const generateRefreshToken = (payload: any): string => {
  const expiresIn = (process.env.JWT_REFRESH_EXPIRY || '7d') as string;
  return jwt.sign(payload, JWT_REFRESH_SECRET, {
    expiresIn,
  } as jwt.SignOptions);
};

/**
 * Verify JWT token
 */
export const verifyToken = (token: string): any => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

/**
 * Verify refresh token
 */
export const verifyRefreshToken = (token: string): any => {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET);
  } catch (error) {
    throw new Error('Invalid or expired refresh token');
  }
};

/**
 * Authentication middleware
 */
export const authenticate = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): void => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        message: 'No token provided',
      });
      return;
    }

    const token = authHeader.substring(7);
    const decoded = verifyToken(token);

    req.user = {
      id: decoded.id,
      email: decoded.email,
      phone: decoded.phone,
    };

    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Invalid or expired token',
    });
  }
};

/**
 * Admin authentication middleware
 */
export const authenticateAdmin = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    authenticate(req, res, async () => {
      // Check if user is admin (implement your admin check logic)
      // This is a placeholder - implement proper admin verification
      const isAdmin = true; // Replace with actual admin check
      
      if (!isAdmin) {
        res.status(403).json({
          success: false,
          message: 'Access denied. Admin privileges required.',
        });
        return;
      }
      
      next();
    });
  } catch (error) {
    res.status(403).json({
      success: false,
      message: 'Access denied',
    });
  }
};
