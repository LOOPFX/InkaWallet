import { Router, Response } from 'express';
import db from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth.middleware';

const router = Router();

// Generate QR code data for user
router.get('/me', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const [users]: any = await db.query(
      `SELECT full_name, account_number, phone_number FROM users WHERE id = ?`,
      [req.user?.id]
    );

    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const qrData = {
      type: 'inkawallet',
      name: users[0].full_name,
      account_number: users[0].account_number,
      phone_number: users[0].phone_number,
      version: '1.0'
    };

    // Return as JSON string for QR encoding
    res.json({ qr_data: JSON.stringify(qrData) });
  } catch (error) {
    console.error('QR generation error:', error);
    res.status(500).json({ error: 'Failed to generate QR' });
  }
});

// Decode and validate scanned QR
router.post('/validate', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { qr_data } = req.body;

    if (!qr_data) {
      return res.status(400).json({ error: 'QR data required' });
    }

    // Parse QR data
    let parsed;
    try {
      parsed = JSON.parse(qr_data);
    } catch {
      return res.status(400).json({ error: 'Invalid QR code format' });
    }

    // Validate InkaWallet QR
    if (parsed.type !== 'inkawallet') {
      return res.status(400).json({ error: 'Not an InkaWallet QR code' });
    }

    // Verify account exists
    const [users]: any = await db.query(
      `SELECT id, full_name, account_number, phone_number, is_active FROM users WHERE account_number = ?`,
      [parsed.account_number]
    );

    if (users.length === 0) {
      return res.status(404).json({ error: 'Account not found' });
    }

    if (!users[0].is_active) {
      return res.status(403).json({ error: 'Account is deactivated' });
    }

    // Don't allow sending to self
    if (users[0].id === req.user?.id) {
      return res.status(400).json({ error: 'Cannot send money to yourself' });
    }

    res.json({
      valid: true,
      recipient: {
        name: users[0].full_name,
        account_number: users[0].account_number,
        phone_number: users[0].phone_number
      }
    });
  } catch (error) {
    console.error('QR validation error:', error);
    res.status(500).json({ error: 'Validation failed' });
  }
});

export default router;
