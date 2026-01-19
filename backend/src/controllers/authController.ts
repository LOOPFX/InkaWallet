import { Request, Response } from 'express';
import { validationResult } from 'express-validator';
import { v4 as uuidv4 } from 'uuid';
import db from '../config/database';
import {
  hashPassword,
  comparePassword,
  sanitizeInput,
  generateAccountNumber,
} from '../utils/security';
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
} from '../middleware/auth';
import logger from '../utils/logger';
import { ValidationError, UnauthorizedError } from '../middleware/errorHandler';

/**
 * Register new user
 */
export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array(),
      });
      return;
    }

    const { first_name, last_name, email, phone, password } = req.body;

    // Sanitize inputs
    const sanitizedFirstName = sanitizeInput(first_name);
    const sanitizedLastName = sanitizeInput(last_name);
    const sanitizedEmail = sanitizeInput(email);
    const sanitizedPhone = sanitizeInput(phone);

    // Check if user already exists
    const [existingUsers] = await db.query(
      'SELECT id FROM users WHERE email = ? OR phone = ?',
      [sanitizedEmail, sanitizedPhone]
    );

    if (Array.isArray(existingUsers) && existingUsers.length > 0) {
      res.status(409).json({
        success: false,
        message: 'User with this email or phone already exists',
      });
      return;
    }

    // Hash password
    const passwordHash = await hashPassword(password);

    // Create user
    const userId = uuidv4();
    const walletId = uuidv4();
    const accountNumber = generateAccountNumber();

    await db.query(
      `INSERT INTO users (id, first_name, last_name, email, phone, password_hash) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [userId, sanitizedFirstName, sanitizedLastName, sanitizedEmail, sanitizedPhone, passwordHash]
    );

    // Create wallet for user
    await db.query(
      `INSERT INTO wallets (id, user_id, balance, account_number) 
       VALUES (?, ?, 10000.00, ?)`, // Starting balance for demo
      [walletId, userId, accountNumber]
    );

    // Generate tokens
    const accessToken = generateAccessToken({
      id: userId,
      email: sanitizedEmail,
      phone: sanitizedPhone,
    });

    const refreshTokenValue = generateRefreshToken({
      id: userId,
    });

    // Save refresh token
    const refreshTokenId = uuidv4();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    await db.query(
      `INSERT INTO refresh_tokens (id, user_id, token, expires_at) 
       VALUES (?, ?, ?, ?)`,
      [refreshTokenId, userId, refreshTokenValue, expiresAt]
    );

    // Log activity
    logger.info('User registered successfully', { userId, email: sanitizedEmail });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token: accessToken,
      refreshToken: refreshTokenValue,
      user: {
        id: userId,
        first_name: sanitizedFirstName,
        last_name: sanitizedLastName,
        email: sanitizedEmail,
        phone: sanitizedPhone,
        is_verified: false,
      },
    });
  } catch (error: any) {
    logger.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed',
      error: error.message,
    });
  }
};

/**
 * Login user
 */
export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array(),
      });
      return;
    }

    const { emailOrPhone, password } = req.body;
    const sanitizedInput = sanitizeInput(emailOrPhone);

    // Find user
    const [users] = await db.query(
      'SELECT * FROM users WHERE email = ? OR phone = ?',
      [sanitizedInput, sanitizedInput]
    );

    if (!Array.isArray(users) || users.length === 0) {
      // Log failed attempt
      await db.query(
        `INSERT INTO failed_login_attempts (email_or_phone, ip_address) 
         VALUES (?, ?)`,
        [sanitizedInput, req.ip]
      );

      res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
      return;
    }

    const user: any = users[0];

    // Verify password
    const isPasswordValid = await comparePassword(password, user.password_hash);

    if (!isPasswordValid) {
      await db.query(
        `INSERT INTO failed_login_attempts (email_or_phone, ip_address) 
         VALUES (?, ?)`,
        [sanitizedInput, req.ip]
      );

      res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
      return;
    }

    // Check if user is active
    if (!user.is_active) {
      res.status(403).json({
        success: false,
        message: 'Account is inactive',
      });
      return;
    }

    // Update last login
    await db.query(
      'UPDATE users SET last_login = NOW() WHERE id = ?',
      [user.id]
    );

    // Generate tokens
    const accessToken = generateAccessToken({
      id: user.id,
      email: user.email,
      phone: user.phone,
    });

    const refreshTokenValue = generateRefreshToken({
      id: user.id,
    });

    // Save refresh token
    const refreshTokenId = uuidv4();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await db.query(
      `INSERT INTO refresh_tokens (id, user_id, token, expires_at) 
       VALUES (?, ?, ?, ?)`,
      [refreshTokenId, user.id, refreshTokenValue, expiresAt]
    );

    logger.info('User logged in successfully', { userId: user.id });

    res.json({
      success: true,
      message: 'Login successful',
      token: accessToken,
      refreshToken: refreshTokenValue,
      user: {
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        phone: user.phone,
        is_verified: user.is_verified,
      },
    });
  } catch (error: any) {
    logger.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed',
      error: error.message,
    });
  }
};

/**
 * Logout user
 */
export const logout = async (req: Request, res: Response): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      
      // Delete refresh tokens for this user
      // In production, you'd decode the token to get user ID
      // For now, we'll delete based on token
      await db.query(
        'DELETE FROM refresh_tokens WHERE token = ?',
        [token]
      );
    }

    res.json({
      success: true,
      message: 'Logout successful',
    });
  } catch (error: any) {
    logger.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Logout failed',
    });
  }
};

/**
 * Refresh access token
 */
export const refreshToken = async (req: Request, res: Response): Promise<void> => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      res.status(400).json({
        success: false,
        message: 'Refresh token is required',
      });
      return;
    }

    // Verify refresh token
    const decoded = verifyRefreshToken(refreshToken);

    // Check if refresh token exists in database
    const [tokens] = await db.query(
      `SELECT * FROM refresh_tokens 
       WHERE token = ? AND expires_at > NOW()`,
      [refreshToken]
    );

    if (!Array.isArray(tokens) || tokens.length === 0) {
      res.status(401).json({
        success: false,
        message: 'Invalid or expired refresh token',
      });
      return;
    }

    // Get user
    const [users] = await db.query(
      'SELECT * FROM users WHERE id = ?',
      [decoded.id]
    );

    if (!Array.isArray(users) || users.length === 0) {
      res.status(401).json({
        success: false,
        message: 'User not found',
      });
      return;
    }

    const user: any = users[0];

    // Generate new access token
    const newAccessToken = generateAccessToken({
      id: user.id,
      email: user.email,
      phone: user.phone,
    });

    res.json({
      success: true,
      token: newAccessToken,
    });
  } catch (error: any) {
    logger.error('Token refresh error:', error);
    res.status(401).json({
      success: false,
      message: 'Token refresh failed',
    });
  }
};
