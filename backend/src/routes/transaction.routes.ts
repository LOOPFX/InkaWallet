import { Router, Response } from 'express';
import db from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth.middleware';
import { body, validationResult } from 'express-validator';

const router = Router();

const generateTxId = () => `TX-${Date.now()}-${Math.floor(Math.random() * 100000)}`;

// Send money
router.post('/send',
  authenticateToken,
  body('receiver_phone').notEmpty(),
  body('amount').isFloat({ min: 1 }),
  async (req: AuthRequest, res: Response) => {
    const connection = await db.getConnection();
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        connection.release();
        return res.status(400).json({ errors: errors.array() });
      }

      const { receiver_phone, amount, description, payment_method = 'inkawallet' } = req.body;

      await connection.beginTransaction();

      // Get sender wallet
      const [senderWallets]: any = await connection.query(
        'SELECT id, balance, is_locked FROM wallets WHERE user_id = ?',
        [req.user?.id]
      );

      if (senderWallets.length === 0) {
        await connection.rollback();
        connection.release();
        return res.status(404).json({ error: 'Sender wallet not found' });
      }

      const senderWallet = senderWallets[0];

      if (senderWallet.is_locked) {
        await connection.rollback();
        connection.release();
        return res.status(403).json({ error: 'Wallet is locked' });
      }

      if (parseFloat(senderWallet.balance) < parseFloat(amount)) {
        await connection.rollback();
        connection.release();
        return res.status(400).json({ error: 'Insufficient balance' });
      }

      // Get receiver
      const [receivers]: any = await connection.query(
        'SELECT id FROM users WHERE phone_number = ?',
        [receiver_phone]
      );

      if (receivers.length === 0) {
        await connection.rollback();
        connection.release();
        return res.status(404).json({ error: 'Receiver not found' });
      }

      const receiverId = receivers[0].id;

      // Update balances
      await connection.query('UPDATE wallets SET balance = balance - ? WHERE user_id = ?', [amount, req.user?.id]);
      await connection.query('UPDATE wallets SET balance = balance + ? WHERE user_id = ?', [amount, receiverId]);

      // Record transaction
      const txId = generateTxId();
      await connection.query(
        'INSERT INTO transactions (transaction_id, sender_id, receiver_id, amount, transaction_type, payment_method, status, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [txId, req.user?.id, receiverId, amount, 'send', payment_method, 'completed', description || '']
      );

      await connection.commit();
      connection.release();

      res.json({ message: 'Transfer successful', transaction_id: txId });
    } catch (error) {
      await connection.rollback();
      connection.release();
      res.status(500).json({ error: 'Transfer failed' });
    }
  }
);

// Receive (mock incoming)
router.post('/receive',
  authenticateToken,
  body('amount').isFloat({ min: 1 }),
  body('payment_method').isString(),
  async (req: AuthRequest, res: Response) => {
    const connection = await db.getConnection();
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        connection.release();
        return res.status(400).json({ errors: errors.array() });
      }

      const { amount, payment_method = 'mpamba', description } = req.body;

      await connection.beginTransaction();

      await connection.query('UPDATE wallets SET balance = balance + ? WHERE user_id = ?', [amount, req.user?.id]);

      const txId = generateTxId();
      await connection.query(
        'INSERT INTO transactions (transaction_id, sender_id, receiver_id, amount, transaction_type, payment_method, status, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [txId, null, req.user?.id, amount, 'receive', payment_method, 'completed', description || 'Incoming transfer']
      );

      await connection.commit();
      connection.release();

      res.json({ message: 'Funds received', transaction_id: txId });
    } catch (error) {
      await connection.rollback();
      connection.release();
      res.status(500).json({ error: 'Receive failed' });
    }
  }
);

// Transaction history
router.get('/history', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const [rows]: any = await db.query(
      'SELECT * FROM transactions WHERE sender_id = ? OR receiver_id = ? ORDER BY created_at DESC',
      [req.user?.id, req.user?.id]
    );

    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch history' });
  }
});

export default router;
