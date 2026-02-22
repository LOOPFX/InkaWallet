import { Router, Response } from 'express';
import db from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth.middleware';
import { body, validationResult } from 'express-validator';

const router = Router();

const generateTxId = () => `TX-${Date.now()}-${Math.floor(Math.random() * 100000)}`;

// Malawian banks list
const MALAWIAN_BANKS = [
  'National Bank of Malawi',
  'Standard Bank Malawi',
  'FMB (First Merchant Bank)',
  'NBS Bank',
  'CDH Investment Bank',
  'MyBucks Banking Corporation',
  'Ecobank Malawi',
  'Opportunity Bank Malawi'
];

// Validate phone number against payment method
const validatePhoneForMethod = (phone: string, method: string): { valid: boolean; error?: string } => {
  const cleaned = phone.replace(/\s+/g, '');
  
  if (method === 'airtel_money') {
    // Airtel: 09, 099, 0999, +2659
    if (!/^(\+2659|09|099|0999)\d{6,7}$/.test(cleaned)) {
      return { valid: false, error: 'Invalid Airtel number. Must start with 09/099/0999 or +2659' };
    }
  } else if (method === 'mpamba') {
    // TNM: 08, 088, 0888, +2658
    if (!/^(\+2658|08|088|0888)\d{6,7}$/.test(cleaned)) {
      return { valid: false, error: 'Invalid TNM number. Must start with 08/088/0888 or +2658' };
    }
  }
  
  return { valid: true };
};

// Send money
router.post('/send',
  authenticateToken,
  body('receiver_identifier').notEmpty().withMessage('Receiver identifier required'),
  body('amount').isFloat({ min: 1 }).withMessage('Amount must be at least 1'),
  body('payment_method').isIn(['inkawallet', 'airtel_money', 'mpamba', 'bank']).withMessage('Invalid payment method'),
  body('password').notEmpty().withMessage('Password required for confirmation'),
  async (req: AuthRequest, res: Response) => {
    const connection = await db.getConnection();
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        connection.release();
        return res.status(400).json({ error: errors.array()[0].msg, errors: errors.array() });
      }

      const { receiver_identifier, amount, description, payment_method, password, bank_name } = req.body;

      // Verify user password
      const [users]: any = await connection.query(
        'SELECT password_hash FROM users WHERE id = ?',
        [req.user?.id]
      );

      if (users.length === 0) {
        connection.release();
        return res.status(404).json({ error: 'User not found' });
      }

      const bcrypt = require('bcryptjs');
      const validPassword = await bcrypt.compare(password, users[0].password_hash);
      if (!validPassword) {
        connection.release();
        return res.status(401).json({ error: 'Invalid password' });
      }

      // Validate bank name if payment method is bank
      if (payment_method === 'bank') {
        if (!bank_name || !MALAWIAN_BANKS.includes(bank_name)) {
          connection.release();
          return res.status(400).json({ 
            error: 'Invalid bank name',
            available_banks: MALAWIAN_BANKS
          });
        }
      }

      // Validate phone number format for mobile money
      if (payment_method === 'airtel_money' || payment_method === 'mpamba') {
        const validation = validatePhoneForMethod(receiver_identifier, payment_method);
        if (!validation.valid) {
          connection.release();
          return res.status(400).json({ error: validation.error });
        }
      }

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

      // Get receiver (for InkaWallet transfers, support phone or account number)
      let receiverId = null;
      
      if (payment_method === 'inkawallet') {
        const [receivers]: any = await connection.query(
          'SELECT id FROM users WHERE phone_number = ? OR account_number = ?',
          [receiver_identifier, receiver_identifier]
        );

        if (receivers.length === 0) {
          await connection.rollback();
          connection.release();
          return res.status(404).json({ error: 'Receiver not found with that phone or account number' });
        }
        
        receiverId = receivers[0].id;
        
        // Update receiver balance for InkaWallet transfers
        await connection.query('UPDATE wallets SET balance = balance + ? WHERE user_id = ?', [amount, receiverId]);
      }

      // Update sender balance (always deduct)
      await connection.query('UPDATE wallets SET balance = balance - ? WHERE user_id = ?', [amount, req.user?.id]);

      // Record transaction
      const txId = generateTxId();
      const txDescription = description || 
        (payment_method === 'bank' ? `Transfer to ${bank_name}` :
         payment_method === 'airtel_money' ? 'Airtel Money transfer' :
         payment_method === 'mpamba' ? 'MPamba transfer' :
         'InkaWallet transfer');
         
      await connection.query(
        'INSERT INTO transactions (transaction_id, sender_id, receiver_id, amount, transaction_type, payment_method, status, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [txId, req.user?.id, receiverId, amount, 'send', payment_method, 'completed', txDescription]
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

// Get available Malawian banks
router.get('/banks', (req: AuthRequest, res: Response) => {
  res.json({ banks: MALAWIAN_BANKS });
});

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
