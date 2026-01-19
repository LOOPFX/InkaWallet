import { Router } from 'express';
import { body } from 'express-validator';
import { authenticate } from '../middleware/auth';
import { submitFeedback } from '../controllers/feedbackController';

const router = Router();

/**
 * @route   POST /api/feedback
 * @desc    Submit user feedback
 * @access  Private
 */
router.post(
  '/',
  authenticate,
  [
    body('subject').notEmpty().withMessage('Subject is required'),
    body('message').notEmpty().withMessage('Message is required'),
    body('rating')
      .isInt({ min: 1, max: 5 })
      .withMessage('Rating must be between 1 and 5'),
  ],
  submitFeedback
);

export default router;
