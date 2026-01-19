import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import db from '../config/database';
import logger from '../utils/logger';

/**
 * Get wallet balance
 */
export const getBalance = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        message: 'Unauthorized',
      });
      return;
    }

    const [wallets] = await db.query(
      `SELECT * FROM wallets WHERE user_id = ? AND is_active = TRUE`,
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

    res.json({
      success: true,
      wallet: {
        id: wallet.id,
        user_id: wallet.user_id,
        balance: parseFloat(wallet.balance),
        currency: wallet.currency,
        account_number: wallet.account_number,
        is_active: wallet.is_active,
        created_at: wallet.created_at,
        updated_at: wallet.updated_at,
      },
    });
  } catch (error: any) {
    logger.error('Get balance error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get balance',
    });
  }
};
