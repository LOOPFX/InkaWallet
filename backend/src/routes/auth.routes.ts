import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import db from '../config/database';
import { body, validationResult } from 'express-validator';

const router = Router();

// Register
router.post('/register',
  body('email').isEmail(),
  body('password').isLength({ min: 6 }),
  body('full_name').notEmpty(),
  body('phone_number').notEmpty(),
  async (req: Request, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password, full_name, phone_number, accessibility_enabled = true } = req.body;

      // Check if user exists
      const [existing]: any = await db.query('SELECT id FROM users WHERE email = ? OR phone_number = ?', [email, phone_number]);
      if (existing.length > 0) {
        return res.status(400).json({ error: 'User already exists' });
      }

      // Hash password
      const password_hash = await bcrypt.hash(password, 10);

      // Create user
      const [result]: any = await db.query(
        'INSERT INTO users (email, password_hash, full_name, phone_number, accessibility_enabled) VALUES (?, ?, ?, ?, ?)',
        [email, password_hash, full_name, phone_number, accessibility_enabled]
      );

      const userId = result.insertId;

      // Create wallet with default 100,000 MKW
      await db.query('INSERT INTO wallets (user_id, balance) VALUES (?, 100000.00)', [userId]);

      // Generate token
      const token = jwt.sign(
        { id: userId, email, is_admin: false },
        process.env.JWT_SECRET || 'secret',
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      res.status(201).json({
        message: 'Registration successful',
        token,
        user: { id: userId, email, full_name, accessibility_enabled }
      });
    } catch (error: any) {
      console.error('Registration error:', error);
      res.status(500).json({ error: 'Registration failed' });
    }
  }
);

// Login
router.post('/login',
  body('email').isEmail(),
  body('password').notEmpty(),
  async (req: Request, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password } = req.body;

      // Get user
      const [users]: any = await db.query(
        'SELECT id, email, password_hash, full_name, is_admin, is_active, accessibility_enabled FROM users WHERE email = ?',
        [email]
      );

      if (users.length === 0) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const user = users[0];

      if (!user.is_active) {
        return res.status(403).json({ error: 'Account is deactivated' });
      }

      // Verify password
      const isValid = await bcrypt.compare(password, user.password_hash);
      if (!isValid) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Generate token
      const token = jwt.sign(
        { id: user.id, email: user.email, is_admin: user.is_admin },
        process.env.JWT_SECRET || 'secret',
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      res.json({
        message: 'Login successful',
        token,
        user: {
          id: user.id,
          email: user.email,
          full_name: user.full_name,
          is_admin: user.is_admin,
          accessibility_enabled: user.accessibility_enabled
        }
      });
    } catch (error: any) {
      console.error('Login error:', error);
      res.status(500).json({ error: 'Login failed' });
    }
  }
);

// Google OAuth (simplified for now)
router.post('/google', async (req: Request, res: Response) => {
  try {
    const { google_id, email, full_name } = req.body;

    // Check if user exists
    let [users]: any = await db.query('SELECT id, email, full_name, is_admin FROM users WHERE google_id = ? OR email = ?', [google_id, email]);

    let userId;
    if (users.length === 0) {
      // Create new user
      const [result]: any = await db.query(
        'INSERT INTO users (email, google_id, full_name, phone_number) VALUES (?, ?, ?, ?)',
        [email, google_id, full_name, `+265${Math.floor(Math.random() * 900000000 + 100000000)}`]
      );
      userId = result.insertId;

      // Create wallet
      await db.query('INSERT INTO wallets (user_id, balance) VALUES (?, 100000.00)', [userId]);
    } else {
      userId = users[0].id;
    }

    // Generate token
    const token = jwt.sign(
      { id: userId, email, is_admin: false },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      message: 'Google authentication successful',
      token,
      user: { id: userId, email, full_name }
    });
  } catch (error: any) {
    console.error('Google auth error:', error);
    res.status(500).json({ error: 'Google authentication failed' });
  }
});

export default router;
