import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { getBalance } from '../controllers/walletController';

const router = Router();

/**
 * @route   GET /api/wallet/balance
 * @desc    Get wallet balance
 * @access  Private
 */
router.get('/balance', authenticate, getBalance);

export default router;
