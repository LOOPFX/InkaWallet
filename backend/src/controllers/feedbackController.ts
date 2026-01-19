import { Response } from 'express';
import { validationResult } from 'express-validator';
import { v4 as uuidv4 } from 'uuid';
import { AuthRequest } from '../middleware/auth';
import db from '../config/database';
import logger from '../utils/logger';

/**
 * Submit user feedback
 */
export const submitFeedback = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
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

    const { subject, message, rating } = req.body;
    const feedbackId = uuidv4();

    await db.query(
      `INSERT INTO feedback (id, user_id, subject, message, rating) 
       VALUES (?, ?, ?, ?, ?)`,
      [feedbackId, req.user.id, subject, message, rating]
    );

    logger.info('Feedback submitted', {
      userId: req.user.id,
      feedbackId,
      rating,
    });

    res.status(201).json({
      success: true,
      message: 'Thank you for your feedback',
    });
  } catch (error: any) {
    logger.error('Submit feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit feedback',
    });
  }
};
