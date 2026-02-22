import { Router, Response } from 'express';
import db from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth.middleware';
import { body, validationResult } from 'express-validator';
import crypto from 'crypto';

const router = Router();

const generateRequestId = () => `REQ-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
const generatePaymentToken = () => crypto.randomBytes(32).toString('hex');

// Create money request
router.post('/create',
  authenticateToken,
  body('payer_identifier').notEmpty().withMessage('Payer phone/email required'),
  body('amount').isFloat({ min: 1 }).withMessage('Amount must be at least 1'),
  async (req: AuthRequest, res: Response) => {
    const connection = await db.getConnection();
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        connection.release();
        return res.status(400).json({ error: errors.array()[0].msg });
      }

      const { payer_identifier, amount, description } = req.body;

      await connection.beginTransaction();

      // Get requester details
      const [requesters]: any = await connection.query(
        'SELECT id, full_name, phone_number, account_number FROM users WHERE id = ?',
        [req.user?.id]
      );

      if (requesters.length === 0) {
        await connection.rollback();
        connection.release();
        return res.status(404).json({ error: 'Requester not found' });
      }

      const requester = requesters[0];

      // Check if payer is registered user or external
      const [payers]: any = await connection.query(
        'SELECT id, email, phone_number, full_name FROM users WHERE phone_number = ? OR email = ? OR account_number = ?',
        [payer_identifier, payer_identifier, payer_identifier]
      );

      let payerId = null;
      let payerEmail = null;
      let payerPhone = null;

      if (payers.length > 0) {
        // Registered user
        payerId = payers[0].id;
        payerEmail = payers[0].email;
        payerPhone = payers[0].phone_number;
      } else {
        // External user - determine if email or phone
        if (payer_identifier.includes('@')) {
          payerEmail = payer_identifier;
        } else {
          payerPhone = payer_identifier;
        }
      }

      // Generate unique payment token and request ID
      const requestId = generateRequestId();
      const paymentToken = generatePaymentToken();
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

      // Create money request
      await connection.query(
        `INSERT INTO money_requests (request_id, requester_id, payer_id, payer_phone, payer_email, 
         amount, description, payment_token, expires_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [requestId, req.user?.id, payerId, payerPhone, payerEmail, amount, description || '', paymentToken, expiresAt]
      );

      // Create notification for payer if registered
      if (payerId) {
        await connection.query(
          `INSERT INTO notifications (user_id, type, title, message, reference_id) 
           VALUES (?, 'money_request', ?, ?, ?)`,
          [
            payerId,
            'Money Request',
            `${requester.full_name} is requesting MKW ${parseFloat(amount).toLocaleString()} from you`,
            requestId
          ]
        );
      }

      // Create notification for requester
      await connection.query(
        `INSERT INTO notifications (user_id, type, title, message, reference_id) 
         VALUES (?, 'money_request', ?, ?, ?)`,
        [
          req.user?.id,
          'Request Sent',
          `Money request sent to ${payerPhone || payerEmail}`,
          requestId
        ]
      );

      await connection.commit();
      connection.release();

      // Generate payment link
      const paymentLink = `${process.env.APP_URL || 'http://localhost:3001'}/pay/${paymentToken}`;

      // TODO: Send email if payer has email
      if (payerEmail) {
        console.log(`Email to ${payerEmail}: ${requester.full_name} requests MKW ${amount}. Pay: ${paymentLink}`);
      }

      res.json({
        message: 'Money request sent successfully',
        request_id: requestId,
        payment_link: paymentLink,
        expires_at: expiresAt
      });
    } catch (error) {
      await connection.rollback();
      connection.release();
      console.error('Money request error:', error);
      res.status(500).json({ error: 'Failed to create money request' });
    }
  }
);

// Get payment request details by token (public endpoint for payment links)
router.get('/payment/:token', async (req: AuthRequest, res: Response) => {
  try {
    const { token } = req.params;

    const [requests]: any = await db.query(
      `SELECT mr.*, u.full_name as requester_name, u.phone_number as requester_phone, u.account_number as requester_account
       FROM money_requests mr
       JOIN users u ON mr.requester_id = u.id
       WHERE mr.payment_token = ? AND mr.status = 'pending' AND mr.expires_at > NOW()`,
      [token]
    );

    if (requests.length === 0) {
      return res.status(404).json({ error: 'Payment request not found or expired' });
    }

    const request = requests[0];

    res.json({
      request_id: request.request_id,
      requester_name: request.requester_name,
      requester_account: request.requester_account,
      amount: request.amount,
      description: request.description,
      expires_at: request.expires_at
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch payment request' });
  }
});

// Pay a money request
router.post('/pay/:token',
  authenticateToken,
  body('password').notEmpty().withMessage('Password required'),
  async (req: AuthRequest, res: Response) => {
    const connection = await db.getConnection();
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        connection.release();
        return res.status(400).json({ error: errors.array()[0].msg });
      }

      const { token } = req.params;
      const { password } = req.body;

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

      // Get money request
      const [requests]: any = await connection.query(
        `SELECT * FROM money_requests 
         WHERE payment_token = ? AND status = 'pending' AND expires_at > NOW()`,
        [token]
      );

      if (requests.length === 0) {
        await connection.rollback();
        connection.release();
        return res.status(404).json({ error: 'Payment request not found or expired' });
      }

      const request = requests[0];

      // Check payer balance
      const [wallets]: any = await connection.query(
        'SELECT balance, is_locked FROM wallets WHERE user_id = ?',
        [req.user?.id]
      );

      if (wallets.length === 0) {
        await connection.rollback();
        connection.release();
        return res.status(404).json({ error: 'Wallet not found' });
      }

      const wallet = wallets[0];

      if (wallet.is_locked) {
        await connection.rollback();
        connection.release();
        return res.status(403).json({ error: 'Wallet is locked' });
      }

      if (parseFloat(wallet.balance) < parseFloat(request.amount)) {
        await connection.rollback();
        connection.release();
        return res.status(400).json({ error: 'Insufficient balance' });
      }

      // Transfer money
      await connection.query('UPDATE wallets SET balance = balance - ? WHERE user_id = ?', [request.amount, req.user?.id]);
      await connection.query('UPDATE wallets SET balance = balance + ? WHERE user_id = ?', [request.amount, request.requester_id]);

      // Update request status
      await connection.query(
        'UPDATE money_requests SET status = ?, payer_id = ?, paid_at = NOW() WHERE id = ?',
        ['paid', req.user?.id, request.id]
      );

      // Create transaction record
      const txId = `TX-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
      await connection.query(
        `INSERT INTO transactions (transaction_id, sender_id, receiver_id, amount, transaction_type, 
         payment_method, status, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [txId, req.user?.id, request.requester_id, request.amount, 'send', 'inkawallet', 'completed', 
         `Payment for request: ${request.request_id}`]
      );

      // Create notifications
      await connection.query(
        `INSERT INTO notifications (user_id, type, title, message, reference_id) 
         VALUES (?, 'request_paid', ?, ?, ?)`,
        [request.requester_id, 'Request Paid', `Your request has been paid. MKW ${parseFloat(request.amount).toLocaleString()} received`, request.request_id]
      );

      await connection.query(
        `INSERT INTO notifications (user_id, type, title, message, reference_id) 
         VALUES (?, 'payment_received', ?, ?, ?)`,
        [req.user?.id, 'Payment Sent', `You paid MKW ${parseFloat(request.amount).toLocaleString()}`, txId]
      );

      await connection.commit();
      connection.release();

      res.json({
        message: 'Payment successful',
        transaction_id: txId,
        amount: request.amount
      });
    } catch (error) {
      await connection.rollback();
      connection.release();
      console.error('Payment error:', error);
      res.status(500).json({ error: 'Payment failed' });
    }
  }
);

// Get my money requests (sent)
router.get('/sent', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const [requests]: any = await db.query(
      `SELECT mr.*, u.full_name as payer_name 
       FROM money_requests mr
       LEFT JOIN users u ON mr.payer_id = u.id
       WHERE mr.requester_id = ?
       ORDER BY mr.created_at DESC`,
      [req.user?.id]
    );

    res.json(requests);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch requests' });
  }
});

// Get money requests I need to pay
router.get('/received', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const [user]: any = await db.query(
      'SELECT email, phone_number FROM users WHERE id = ?',
      [req.user?.id]
    );

    if (user.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const [requests]: any = await db.query(
      `SELECT mr.*, u.full_name as requester_name, u.account_number as requester_account
       FROM money_requests mr
       JOIN users u ON mr.requester_id = u.id
       WHERE (mr.payer_id = ? OR mr.payer_email = ? OR mr.payer_phone = ?) 
       AND mr.status = 'pending' AND mr.expires_at > NOW()
       ORDER BY mr.created_at DESC`,
      [req.user?.id, user[0].email, user[0].phone_number]
    );

    res.json(requests);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch requests' });
  }
});

// Cancel money request
router.put('/cancel/:requestId',
  authenticateToken,
  async (req: AuthRequest, res: Response) => {
    const connection = await db.getConnection();
    try {
      const { requestId } = req.params;

      await connection.beginTransaction();

      const [requests]: any = await connection.query(
        'SELECT * FROM money_requests WHERE request_id = ? AND requester_id = ? AND status = ?',
        [requestId, req.user?.id, 'pending']
      );

      if (requests.length === 0) {
        await connection.rollback();
        connection.release();
        return res.status(404).json({ error: 'Request not found or already processed' });
      }

      await connection.query(
        'UPDATE money_requests SET status = ? WHERE request_id = ?',
        ['cancelled', requestId]
      );

      await connection.commit();
      connection.release();

      res.json({ message: 'Request cancelled successfully' });
    } catch (error) {
      await connection.rollback();
      connection.release();
      res.status(500).json({ error: 'Failed to cancel request' });
    }
  }
);

// Get notifications
router.get('/notifications', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const [notifications]: any = await db.query(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
      [req.user?.id]
    );

    res.json(notifications);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// Mark notification as read
router.put('/notifications/:id/read', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    await db.query(
      'UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?',
      [req.params.id, req.user?.id]
    );

    res.json({ message: 'Notification marked as read' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update notification' });
  }
});

export default router;
