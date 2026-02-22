import { Router, Response } from 'express';
import db from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth.middleware';
import { body, validationResult } from 'express-validator';

const router = Router();

const generateTxId = () => `TX-${Date.now()}-${Math.floor(Math.random() * 100000)}`;

// Bill providers list
const BILL_PROVIDERS = {
  tv: ['DStv', 'GoTV', 'Azam TV'],
  water: [
    'Blantyre Water Board',
    'Central Region Water Board',
    'Lilongwe Water Board',
    'Northern Water Board',
    'Southern Region Water Board'
  ],
  electricity: ['ESCOM', 'Yellow Solar', 'Zuwa Energy'],
  government: [
    'Lilongwe City Council',
    'Malawi Housing Corporation',
    'NRB',
    'NEEF'
  ],
  insurance: ['MASM', 'NICO Life', 'Old Mutual', 'Reunion Insurance'],
  fees: ['MANEB', 'NCHE'],
  betting: ['Premier Bet', 'PawaBet']
};

// Get bill providers
router.get('/providers/:type', authenticateToken, (req: AuthRequest, res: Response) => {
  const { type } = req.params;
  
  if (!BILL_PROVIDERS[type as keyof typeof BILL_PROVIDERS]) {
    return res.status(400).json({ error: 'Invalid bill type' });
  }
  
  res.json({ providers: BILL_PROVIDERS[type as keyof typeof BILL_PROVIDERS] });
});

// Buy airtime
router.post('/airtime',
  authenticateToken,
  body('phone_number').notEmpty().withMessage('Phone number required'),
  body('provider').isIn(['airtel', 'tnm']).withMessage('Invalid provider'),
  body('amount').isFloat({ min: 100 }).withMessage('Minimum amount is MKW 100'),
  body('password').notEmpty().withMessage('Password required'),
  async (req: AuthRequest, res: Response) => {
    const connection = await db.getConnection();
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        connection.release();
        return res.status(400).json({ error: errors.array()[0].msg });
      }

      const { phone_number, provider, amount, password } = req.body;

      // Validate phone number format
      const cleaned = phone_number.replace(/\s+/g, '');
      if (provider === 'airtel' && !/^(\+2659|09|099|0999)\d{6,7}$/.test(cleaned)) {
        connection.release();
        return res.status(400).json({ error: 'Invalid Airtel number' });
      }
      if (provider === 'tnm' && !/^(\+2658|08|088|0888)\d{6,7}$/.test(cleaned)) {
        connection.release();
        return res.status(400).json({ error: 'Invalid TNM number' });
      }

      // Verify password
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

      await connection.beginTransaction();

      // Check balance
      const [wallets]: any = await connection.query(
        'SELECT balance, is_locked FROM wallets WHERE user_id = ?',
        [req.user?.id]
      );

      if (wallets.length === 0 || wallets[0].is_locked) {
        await connection.rollback();
        connection.release();
        return res.status(403).json({ error: 'Wallet locked or not found' });
      }

      if (parseFloat(wallets[0].balance) < parseFloat(amount)) {
        await connection.rollback();
        connection.release();
        return res.status(400).json({ error: 'Insufficient balance' });
      }

      // Deduct balance
      await connection.query('UPDATE wallets SET balance = balance - ? WHERE user_id = ?', [amount, req.user?.id]);

      // Record airtime purchase
      const txId = generateTxId();
      await connection.query(
        `INSERT INTO airtime_purchases (transaction_id, user_id, phone_number, provider, amount) 
         VALUES (?, ?, ?, ?, ?)`,
        [txId, req.user?.id, phone_number, provider, amount]
      );

      // Record transaction
      await connection.query(
        `INSERT INTO transactions (transaction_id, sender_id, amount, transaction_type, payment_method, status, description) 
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [txId, req.user?.id, amount, 'send', provider, 'completed', `Airtime for ${phone_number}`]
      );

      await connection.commit();
      connection.release();

      res.json({
        message: 'Airtime purchased successfully',
        transaction_id: txId,
        amount,
        phone_number
      });
    } catch (error) {
      await connection.rollback();
      connection.release();
      console.error('Airtime purchase error:', error);
      res.status(500).json({ error: 'Purchase failed' });
    }
  }
);

// Pay bill
router.post('/bill',
  authenticateToken,
  body('bill_type').isIn(['tv', 'water', 'electricity', 'government', 'insurance', 'fees', 'betting']).withMessage('Invalid bill type'),
  body('provider').notEmpty().withMessage('Provider required'),
  body('account_number').notEmpty().withMessage('Account number required'),
  body('amount').isFloat({ min: 1 }).withMessage('Invalid amount'),
  body('password').notEmpty().withMessage('Password required'),
  async (req: AuthRequest, res: Response) => {
    const connection = await db.getConnection();
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        connection.release();
        return res.status(400).json({ error: errors.array()[0].msg });
      }

      const { bill_type, provider, account_number, amount, password } = req.body;

      // Validate provider
      if (!BILL_PROVIDERS[bill_type as keyof typeof BILL_PROVIDERS].includes(provider)) {
        connection.release();
        return res.status(400).json({ 
          error: 'Invalid provider',
          available_providers: BILL_PROVIDERS[bill_type as keyof typeof BILL_PROVIDERS]
        });
      }

      // Verify password
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

      await connection.beginTransaction();

      // Check balance
      const [wallets]: any = await connection.query(
        'SELECT balance, is_locked FROM wallets WHERE user_id = ?',
        [req.user?.id]
      );

      if (wallets.length === 0 || wallets[0].is_locked) {
        await connection.rollback();
        connection.release();
        return res.status(403).json({ error: 'Wallet locked or not found' });
      }

      if (parseFloat(wallets[0].balance) < parseFloat(amount)) {
        await connection.rollback();
        connection.release();
        return res.status(400).json({ error: 'Insufficient balance' });
      }

      // Deduct balance
      await connection.query('UPDATE wallets SET balance = balance - ? WHERE user_id = ?', [amount, req.user?.id]);

      // Record bill payment
      const txId = generateTxId();
      await connection.query(
        `INSERT INTO bill_payments (transaction_id, user_id, bill_type, provider, account_number, amount) 
         VALUES (?, ?, ?, ?, ?, ?)`,
        [txId, req.user?.id, bill_type, provider, account_number, amount]
      );

      // Record transaction
      await connection.query(
        `INSERT INTO transactions (transaction_id, sender_id, amount, transaction_type, payment_method, status, description) 
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [txId, req.user?.id, amount, 'send', bill_type, 'completed', `${provider} - ${account_number}`]
      );

      await connection.commit();
      connection.release();

      res.json({
        message: 'Bill payment successful',
        transaction_id: txId,
        provider,
        amount
      });
    } catch (error) {
      await connection.rollback();
      connection.release();
      console.error('Bill payment error:', error);
      res.status(500).json({ error: 'Payment failed' });
    }
  }
);

// Top-up wallet
router.post('/topup',
  authenticateToken,
  body('source').isIn(['mpamba', 'airtel_money', 'bank', 'card']).withMessage('Invalid source'),
  body('amount').isFloat({ min: 100 }).withMessage('Minimum amount is MKW 100'),
  body('source_reference').notEmpty().withMessage('Source reference required'),
  async (req: AuthRequest, res: Response) => {
    const connection = await db.getConnection();
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        connection.release();
        return res.status(400).json({ error: errors.array()[0].msg });
      }

      const { source, amount, source_reference } = req.body;

      await connection.beginTransaction();

      // Record top-up (pending verification)
      const txId = generateTxId();
      await connection.query(
        `INSERT INTO topups (transaction_id, user_id, source, source_reference, amount, status) 
         VALUES (?, ?, ?, ?, ?, ?)`,
        [txId, req.user?.id, source, source_reference, amount, 'completed']
      );

      // Add balance (in production, this would be verified first)
      await connection.query('UPDATE wallets SET balance = balance + ? WHERE user_id = ?', [amount, req.user?.id]);

      // Record transaction
      await connection.query(
        `INSERT INTO transactions (transaction_id, receiver_id, amount, transaction_type, payment_method, status, description) 
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [txId, req.user?.id, amount, 'receive', source, 'completed', `Top-up from ${source}`]
      );

      await connection.commit();
      connection.release();

      res.json({
        message: 'Top-up successful',
        transaction_id: txId,
        amount
      });
    } catch (error) {
      await connection.rollback();
      connection.release();
      console.error('Top-up error:', error);
      res.status(500).json({ error: 'Top-up failed' });
    }
  }
);

// Get service history
router.get('/history/:type', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { type } = req.params;
    let query = '';
    
    switch (type) {
      case 'airtime':
        query = 'SELECT * FROM airtime_purchases WHERE user_id = ? ORDER BY created_at DESC LIMIT 50';
        break;
      case 'bills':
        query = 'SELECT * FROM bill_payments WHERE user_id = ? ORDER BY created_at DESC LIMIT 50';
        break;
      case 'topups':
        query = 'SELECT * FROM topups WHERE user_id = ? ORDER BY created_at DESC LIMIT 50';
        break;
      default:
        return res.status(400).json({ error: 'Invalid history type' });
    }

    const [history]: any = await db.query(query, [req.user?.id]);
    res.json(history);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch history' });
  }
});

export default router;
