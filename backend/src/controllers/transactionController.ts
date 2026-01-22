import { Response } from 'express';
import { validationResult } from 'express-validator';
import { AuthRequest } from '../middleware/auth';
import db from '../config/database';
import logger from '../utils/logger';

/**
 * Send money
 */
export const sendMoney = async (req: AuthRequest, res: Response): Promise<void> => {
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

    if (!req.user) {
      res.status(401).json({
        success: false,
        message: 'Unauthorized',
      });
      return;
    }

    const { recipient_phone, amount, wallet_provider, description } = req.body;

    // Get sender's wallet
    const [wallets] = await db.query(
      'SELECT * FROM wallets WHERE user_id = ? AND is_active = TRUE',
      [req.user.id]
    );

    if (!Array.isArray(wallets) || wallets.length === 0) {
      res.status(404).json({
        success: false,
        message: 'Wallet not found',
      });
      return;
    }

    const wallet: any = wallets[0];

    // Use stored procedure for transaction
    const [_result]: any = await db.query(
      'CALL transfer_money(?, ?, ?, ?, ?, ?, @transaction_id, @transaction_status, @error_message)',
      [
        wallet.id,
        req.user.id,
        recipient_phone,
        amount,
        wallet_provider,
        description || null,
      ]
    );

    // Get output parameters
    const [output]: any = await db.query(
      'SELECT @transaction_id AS id, @transaction_status AS status, @error_message AS error'
    );

    const txResult = output[0];

    if (txResult.status === 'failed') {
      res.status(400).json({
        success: false,
        message: txResult.error,
      });
      return;
    }

    // Get transaction details
    const [transactions] = await db.query(
      'SELECT * FROM transactions WHERE id = ?',
      [txResult.id]
    );

    const transaction: any = Array.isArray(transactions) ? transactions[0] : null;

    logger.info('Transaction completed', {
      userId: req.user.id,
      transactionId: txResult.id,
      amount,
    });

    res.json({
      success: true,
      message: 'Transaction completed successfully',
      transaction: {
        id: transaction.id,
        wallet_id: transaction.wallet_id,
        type: transaction.type,
        amount: parseFloat(transaction.amount),
        currency: transaction.currency,
        recipient_phone: transaction.recipient_phone,
        recipient_wallet_provider: transaction.recipient_wallet_provider,
        description: transaction.description,
        status: transaction.status,
        reference_number: transaction.reference_number,
        created_at: transaction.created_at,
        completed_at: transaction.completed_at,
      },
    });
  } catch (error: any) {
    logger.error('Send money error:', error);
    res.status(500).json({
      success: false,
      message: 'Transaction failed',
      error: error.message,
    });
  }
};

/**
 * Get transaction history
 */
export const getTransactionHistory = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        message: 'Unauthorized',
      });
      return;
    }

    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = (page - 1) * limit;

    // Get user's wallet
    const [wallets] = await db.query(
      'SELECT id FROM wallets WHERE user_id = ?',
      [req.user.id]
    );

    if (!Array.isArray(wallets) || wallets.length === 0) {
      res.json({
        success: true,
        transactions: [],
        pagination: { page, limit, total: 0 },
      });
      return;
    }

    const wallet: any = wallets[0];

    // Get transactions
    const [transactions] = await db.query(
      `SELECT * FROM transactions 
       WHERE wallet_id = ? 
       ORDER BY created_at DESC 
       LIMIT ? OFFSET ?`,
      [wallet.id, limit, offset]
    );

    // Get total count
    const [countResult]: any = await db.query(
      'SELECT COUNT(*) as total FROM transactions WHERE wallet_id = ?',
      [wallet.id]
    );

    const total = countResult[0].total;

    res.json({
      success: true,
      transactions: Array.isArray(transactions) ? transactions.map((tx: any) => ({
        id: tx.id,
        wallet_id: tx.wallet_id,
        type: tx.type,
        amount: parseFloat(tx.amount),
        currency: tx.currency,
        recipient_name: tx.recipient_name,
        recipient_phone: tx.recipient_phone,
        recipient_wallet_provider: tx.recipient_wallet_provider,
        sender_name: tx.sender_name,
        sender_phone: tx.sender_phone,
        description: tx.description,
        status: tx.status,
        reference_number: tx.reference_number,
        created_at: tx.created_at,
        completed_at: tx.completed_at,
      })) : [],
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error: any) {
    logger.error('Get transaction history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get transaction history',
    });
  }
};

/**
 * Get transaction details
 */
export const getTransactionDetails = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        message: 'Unauthorized',
      });
      return;
    }

    const { id } = req.params;

    const [transactions] = await db.query(
      `SELECT t.* FROM transactions t
       JOIN wallets w ON t.wallet_id = w.id
       WHERE t.id = ? AND w.user_id = ?`,
      [id, req.user.id]
    );

    if (!Array.isArray(transactions) || transactions.length === 0) {
      res.status(404).json({
        success: false,
        message: 'Transaction not found',
      });
      return;
    }

    const transaction: any = transactions[0];

    res.json({
      success: true,
      transaction: {
        id: transaction.id,
        wallet_id: transaction.wallet_id,
        type: transaction.type,
        amount: parseFloat(transaction.amount),
        currency: transaction.currency,
        recipient_name: transaction.recipient_name,
        recipient_phone: transaction.recipient_phone,
        recipient_wallet_provider: transaction.recipient_wallet_provider,
        sender_name: transaction.sender_name,
        sender_phone: transaction.sender_phone,
        description: transaction.description,
        status: transaction.status,
        reference_number: transaction.reference_number,
        created_at: transaction.created_at,
        completed_at: transaction.completed_at,
      },
    });
  } catch (error: any) {
    logger.error('Get transaction details error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get transaction details',
    });
  }
};
