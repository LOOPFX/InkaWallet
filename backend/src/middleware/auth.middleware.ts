import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import pool from '../config/database';

export interface AuthRequest extends Request {
  user?: {
    id: number;
    email: string;
    is_admin: boolean;
  };
}

export const authenticateToken = async (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret') as any;
    
    // Check if user is still active in database
    const [users] = await pool.query(
      'SELECT is_active FROM users WHERE id = ?',
      [decoded.id]
    );
    
    const userArray = users as any[];
    if (userArray.length === 0 || !userArray[0].is_active) {
      return res.status(403).json({ error: 'Account has been deactivated' });
    }
    
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
};

export const isAdmin = (req: AuthRequest, res: Response, next: NextFunction) => {
  if (!req.user?.is_admin) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};
