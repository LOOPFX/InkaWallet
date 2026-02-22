import { Router, Response } from 'express';
import db from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth.middleware';

const router = Router();

// Get user's credit score
router.get('/score', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const [scores]: any = await db.query(
      `SELECT 
        score,
        payment_history_score,
        transaction_volume_score,
        account_age_score,
        defaults_count,
        total_borrowed,
        total_repaid,
        last_calculated
      FROM credit_scores 
      WHERE user_id = ?`,
      [req.user?.id]
    );

    if (scores.length === 0) {
      // Initialize credit score if not exists
      await db.query(
        `INSERT INTO credit_scores (user_id, score, account_age_score) VALUES (?, 500, 50)`,
        [req.user?.id]
      );
      
      return res.json({
        score: 500,
        payment_history_score: 0,
        transaction_volume_score: 0,
        account_age_score: 50,
        defaults_count: 0,
        total_borrowed: 0,
        total_repaid: 0,
        rating: 'Fair',
        eligible_for_bnpl: true,
        max_loan_amount: 50000
      });
    }

    const creditScore = scores[0];
    const rating = getCreditRating(creditScore.score);
    const eligibility = creditScore.score >= 400;
    const maxLoan = calculateMaxLoan(creditScore.score);

    res.json({
      ...creditScore,
      rating,
      eligible_for_bnpl: eligibility,
      max_loan_amount: maxLoan
    });
  } catch (error) {
    console.error('Credit score error:', error);
    res.status(500).json({ error: 'Failed to fetch credit score' });
  }
});

// Recalculate credit score
router.post('/recalculate', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    // Get user account age
    const [users]: any = await db.query(
      `SELECT DATEDIFF(NOW(), created_at) as account_age_days FROM users WHERE id = ?`,
      [req.user?.id]
    );
    const accountAgeDays = users[0]?.account_age_days || 0;
    const accountAgeScore = Math.min(100, Math.floor(accountAgeDays / 3.65)); // 1 year = 100 points

    // Get transaction volume (last 90 days)
    const [transactions]: any = await db.query(
      `SELECT COUNT(*) as tx_count, COALESCE(SUM(amount), 0) as total_volume 
       FROM transactions 
       WHERE (sender_id = ? OR receiver_id = ?) 
       AND status = 'completed'
       AND created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)`,
      [req.user?.id, req.user?.id]
    );
    const txCount = transactions[0]?.tx_count || 0;
    const totalVolume = parseFloat(transactions[0]?.total_volume || 0);
    const transactionVolumeScore = Math.min(100, Math.floor(txCount / 2) + Math.floor(totalVolume / 10000));

    // Get BNPL payment history
    const [bnplPayments]: any = await db.query(
      `SELECT 
        COUNT(*) as total_payments,
        SUM(CASE WHEN status = 'completed' AND is_late = 0 THEN 1 ELSE 0 END) as on_time_payments,
        SUM(CASE WHEN status = 'completed' AND is_late = 1 THEN 1 ELSE 0 END) as late_payments
       FROM bnpl_payments 
       WHERE user_id = ?`,
      [req.user?.id]
    );
    
    const totalPayments = bnplPayments[0]?.total_payments || 0;
    const onTimePayments = bnplPayments[0]?.on_time_payments || 0;
    const latePayments = bnplPayments[0]?.late_payments || 0;
    
    let paymentHistoryScore = 100;
    if (totalPayments > 0) {
      const onTimeRate = onTimePayments / totalPayments;
      paymentHistoryScore = Math.floor(onTimeRate * 100);
      paymentHistoryScore -= latePayments * 5; // Penalty for late payments
      paymentHistoryScore = Math.max(0, paymentHistoryScore);
    }

    // Get defaults count
    const [defaults]: any = await db.query(
      `SELECT COUNT(*) as defaults_count FROM bnpl_loans WHERE user_id = ? AND status = 'defaulted'`,
      [req.user?.id]
    );
    const defaultsCount = defaults[0]?.defaults_count || 0;

    // Get total borrowed and repaid
    const [loanStats]: any = await db.query(
      `SELECT 
        COALESCE(SUM(total_amount), 0) as total_borrowed,
        COALESCE(SUM(amount_paid), 0) as total_repaid
       FROM bnpl_loans 
       WHERE user_id = ? AND status IN ('active', 'completed')`,
      [req.user?.id]
    );

    const totalBorrowed = parseFloat(loanStats[0]?.total_borrowed || 0);
    const totalRepaid = parseFloat(loanStats[0]?.total_repaid || 0);

    // Calculate final score (300-850 range)
    let finalScore = 300;
    finalScore += Math.floor(paymentHistoryScore * 3.5); // Max 350 points
    finalScore += Math.floor(transactionVolumeScore * 1.5); // Max 150 points
    finalScore += Math.floor(accountAgeScore * 0.5); // Max 50 points
    finalScore -= defaultsCount * 50; // Penalty for defaults
    finalScore = Math.max(300, Math.min(850, finalScore));

    // Update credit score
    const [current]: any = await db.query(
      `SELECT score FROM credit_scores WHERE user_id = ?`,
      [req.user?.id]
    );
    const previousScore = current[0]?.score || 500;

    await db.query(
      `UPDATE credit_scores SET 
        score = ?,
        payment_history_score = ?,
        transaction_volume_score = ?,
        account_age_score = ?,
        defaults_count = ?,
        total_borrowed = ?,
        total_repaid = ?,
        last_calculated = NOW()
      WHERE user_id = ?`,
      [
        finalScore,
        paymentHistoryScore,
        transactionVolumeScore,
        accountAgeScore,
        defaultsCount,
        totalBorrowed,
        totalRepaid,
        req.user?.id
      ]
    );

    // Log credit history
    await db.query(
      `INSERT INTO credit_history (user_id, event_type, previous_score, new_score, score_change, description) 
       VALUES (?, 'score_calculated', ?, ?, ?, 'Automatic score recalculation')`,
      [req.user?.id, previousScore, finalScore, finalScore - previousScore]
    );

    res.json({
      score: finalScore,
      previous_score: previousScore,
      score_change: finalScore - previousScore,
      payment_history_score: paymentHistoryScore,
      transaction_volume_score: transactionVolumeScore,
      account_age_score: accountAgeScore,
      defaults_count: defaultsCount,
      rating: getCreditRating(finalScore),
      eligible_for_bnpl: finalScore >= 400,
      max_loan_amount: calculateMaxLoan(finalScore)
    });
  } catch (error) {
    console.error('Credit recalculation error:', error);
    res.status(500).json({ error: 'Failed to recalculate credit score' });
  }
});

// Get credit history
router.get('/history', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const [history]: any = await db.query(
      `SELECT 
        event_type,
        previous_score,
        new_score,
        score_change,
        description,
        created_at
      FROM credit_history 
      WHERE user_id = ? 
      ORDER BY created_at DESC 
      LIMIT 50`,
      [req.user?.id]
    );

    res.json({ history });
  } catch (error) {
    console.error('Credit history error:', error);
    res.status(500).json({ error: 'Failed to fetch credit history' });
  }
});

// Helper functions
function getCreditRating(score: number): string {
  if (score >= 750) return 'Excellent';
  if (score >= 650) return 'Good';
  if (score >= 550) return 'Fair';
  if (score >= 450) return 'Poor';
  return 'Very Poor';
}

function calculateMaxLoan(score: number): number {
  if (score >= 750) return 500000; // MKW 500,000
  if (score >= 650) return 300000; // MKW 300,000
  if (score >= 550) return 150000; // MKW 150,000
  if (score >= 450) return 75000;  // MKW 75,000
  if (score >= 400) return 50000;  // MKW 50,000
  return 0; // Not eligible
}

export default router;
