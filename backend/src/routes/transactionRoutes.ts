import { Router } from 'express';
import { body } from 'express-validator';
import { authenticate } from '../middleware/auth';
import {
  sendMoney,
  getTransactionHistory,
  getTransactionDetails,
} from '../controllers/transactionController';

const router = Router();

/**
 * @route   POST /api/transactions/send
 * @desc    Send money
 * @access  Private
 */
router.post(
  '/send',
  authenticate,
  [
    body('recipient_phone')
      .matches(/^\+?[0-9]{10,15}$/)
      .withMessage('Valid phone number is required'),
    body('amount')
      .isFloat({ min: 100 })
      .withMessage('Amount must be at least 100'),
    body('wallet_provider')
      .notEmpty()
      .withMessage('Wallet provider is required'),
  ],
  sendMoney
);

/**
 * @route   GET /api/transactions/history
 * @desc    Get transaction history
 * @access  Private
 */
router.get('/history', authenticate, getTransactionHistory);

/**
 * @route   GET /api/transactions/:id
 * @desc    Get transaction details
 * @access  Private
 */
router.get('/:id', authenticate, getTransactionDetails);

export default router;
