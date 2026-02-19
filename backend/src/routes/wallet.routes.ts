import { Router, Response } from 'express';
import db from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth.middleware';

const router = Router();

// Get wallet balance
router.get('/balance', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const [wallets]: any = await db.query(
      'SELECT id, balance, currency, is_locked FROM wallets WHERE user_id = ?',
      [req.user?.id]
    );

    if (wallets.length === 0) {
      return res.status(404).json({ error: 'Wallet not found' });
    }

    res.json(wallets[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch wallet' });
  }
});

// Lock/unlock wallet
router.put('/lock', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { is_locked } = req.body;
    await db.query('UPDATE wallets SET is_locked = ? WHERE user_id = ?', [is_locked ? 1 : 0, req.user?.id]);
    res.json({ message: is_locked ? 'Wallet locked' : 'Wallet unlocked' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update wallet lock status' });
  }
});

export default router;
