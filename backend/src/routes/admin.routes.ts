import { Router, Response } from 'express';
import db from '../config/database';
import { authenticateToken, isAdmin, AuthRequest } from '../middleware/auth.middleware';

const router = Router();

// Dashboard stats
router.get('/stats', authenticateToken, isAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const [userCount]: any = await db.query('SELECT COUNT(*) as total_users FROM users');
    const [txCount]: any = await db.query('SELECT COUNT(*) as total_transactions FROM transactions');
    const [totalBalance]: any = await db.query('SELECT SUM(balance) as total_balance FROM wallets');

    res.json({
      total_users: userCount[0]?.total_users || 0,
      total_transactions: txCount[0]?.total_transactions || 0,
      total_balance: totalBalance[0]?.total_balance || 0
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to load stats' });
  }
});

// List users
router.get('/users', authenticateToken, isAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const [rows]: any = await db.query('SELECT id, email, full_name, phone_number, is_active, accessibility_enabled FROM users');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// List transactions
router.get('/transactions', authenticateToken, isAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const [rows]: any = await db.query('SELECT * FROM transactions ORDER BY created_at DESC');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch transactions' });
  }
});

// Deactivate user
router.put('/users/:id/deactivate', authenticateToken, isAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    await db.query('UPDATE users SET is_active = FALSE WHERE id = ?', [id]);
    res.json({ message: 'User deactivated' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to deactivate user' });
  }
});

export default router;
