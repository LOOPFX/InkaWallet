import { Router, Response } from 'express';
import db from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth.middleware';
import { body, validationResult } from 'express-validator';

const router = Router();

// Get current user profile
router.get('/me', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const [users]: any = await db.query(
      'SELECT id, email, full_name, phone_number, accessibility_enabled, voice_enabled, haptics_enabled, biometric_enabled, is_admin FROM users WHERE id = ?',
      [req.user?.id]
    );

    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(users[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Update accessibility settings
router.put('/accessibility',
  authenticateToken,
  body('accessibility_enabled').isBoolean(),
  body('voice_enabled').isBoolean(),
  body('haptics_enabled').isBoolean(),
  body('biometric_enabled').isBoolean(),
  async (req: AuthRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { accessibility_enabled, voice_enabled, haptics_enabled, biometric_enabled } = req.body;

      await db.query(
        'UPDATE users SET accessibility_enabled = ?, voice_enabled = ?, haptics_enabled = ?, biometric_enabled = ? WHERE id = ?',
        [accessibility_enabled, voice_enabled, haptics_enabled, biometric_enabled, req.user?.id]
      );

      res.json({ message: 'Accessibility settings updated' });
    } catch (error) {
      res.status(500).json({ error: 'Failed to update settings' });
    }
  }
);

export default router;
