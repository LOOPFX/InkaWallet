import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
  getDashboardStats,
  getUsers,
  getUserById,
  updateUserStatus,
  getTransactions,
  getTransactionById,
  getActivityLogs,
  getFeedback,
  exportData,
} from '../controllers/adminController';

const router = Router();

// All admin routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/admin/stats
 * @desc    Get dashboard statistics
 * @access  Admin
 */
router.get('/stats', getDashboardStats);

/**
 * @route   GET /api/admin/users
 * @desc    Get all users with pagination
 * @access  Admin
 */
router.get('/users', getUsers);

/**
 * @route   GET /api/admin/users/:id
 * @desc    Get user by ID
 * @access  Admin
 */
router.get('/users/:id', getUserById);

/**
 * @route   PATCH /api/admin/users/:id/status
 * @desc    Update user status (activate/deactivate)
 * @access  Admin
 */
router.patch('/users/:id/status', updateUserStatus);

/**
 * @route   GET /api/admin/transactions
 * @desc    Get all transactions with filters
 * @access  Admin
 */
router.get('/transactions', getTransactions);

/**
 * @route   GET /api/admin/transactions/:id
 * @desc    Get transaction by ID
 * @access  Admin
 */
router.get('/transactions/:id', getTransactionById);

/**
 * @route   GET /api/admin/logs
 * @desc    Get activity logs with filters
 * @access  Admin
 */
router.get('/logs', getActivityLogs);

/**
 * @route   GET /api/admin/feedback
 * @desc    Get user feedback
 * @access  Admin
 */
router.get('/feedback', getFeedback);

/**
 * @route   GET /api/admin/export/:type
 * @desc    Export data as CSV
 * @access  Admin
 */
router.get('/export/:type', exportData);

export default router;
