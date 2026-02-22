import { Router, Response } from 'express';
import db from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth.middleware';

const router = Router();

// Get all user's BNPL loans
router.get('/loans', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const [loans]: any = await db.query(
      `SELECT 
        loan_id,
        merchant_name,
        item_description,
        principal_amount,
        interest_rate,
        total_amount,
        amount_paid,
        installments_total,
        installments_paid,
        installment_amount,
        status,
        approval_status,
        next_payment_date,
        final_payment_date,
        created_at
      FROM bnpl_loans 
      WHERE user_id = ? 
      ORDER BY created_at DESC`,
      [req.user?.id]
    );

    res.json({ loans });
  } catch (error) {
    console.error('BNPL loans error:', error);
    res.status(500).json({ error: 'Failed to fetch loans' });
  }
});

// Get single loan details
router.get('/loans/:loanId', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { loanId } = req.params;

    const [loans]: any = await db.query(
      `SELECT * FROM bnpl_loans WHERE loan_id = ? AND user_id = ?`,
      [loanId, req.user?.id]
    );

    if (loans.length === 0) {
      return res.status(404).json({ error: 'Loan not found' });
    }

    // Get payment history for this loan
    const [payments]: any = await db.query(
      `SELECT * FROM bnpl_payments WHERE loan_id = ? ORDER BY created_at DESC`,
      [loans[0].id]
    );

    res.json({
      loan: loans[0],
      payments
    });
  } catch (error) {
    console.error('BNPL loan details error:', error);
    res.status(500).json({ error: 'Failed to fetch loan details' });
  }
});

// Apply for BNPL loan
router.post('/apply', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { merchant_name, item_description, amount, installments } = req.body;

    if (!merchant_name || !amount) {
      return res.status(400).json({ error: 'Merchant name and amount are required' });
    }

    const loanAmount = parseFloat(amount);
    if (loanAmount < 1000 || loanAmount > 1000000) {
      return res.status(400).json({ error: 'Loan amount must be between MKW 1,000 and MKW 1,000,000' });
    }

    const installmentsCount = installments || 4;
    if (![4, 6, 12].includes(installmentsCount)) {
      return res.status(400).json({ error: 'Installments must be 4, 6, or 12' });
    }

    // Check credit score eligibility
    const [creditScores]: any = await db.query(
      `SELECT score FROM credit_scores WHERE user_id = ?`,
      [req.user?.id]
    );

    const creditScore = creditScores[0]?.score || 500;
    if (creditScore < 400) {
      return res.status(403).json({ 
        error: 'Credit score too low for BNPL',
        credit_score: creditScore,
        minimum_required: 400
      });
    }

    // Calculate max loan based on credit score
    const maxLoan = calculateMaxLoan(creditScore);
    if (loanAmount > maxLoan) {
      return res.status(403).json({ 
        error: 'Loan amount exceeds your credit limit',
        requested: loanAmount,
        max_allowed: maxLoan
      });
    }

    // Check for existing active loans
    const [activeLoans]: any = await db.query(
      `SELECT COUNT(*) as count FROM bnpl_loans 
       WHERE user_id = ? AND status IN ('active', 'pending')`,
      [req.user?.id]
    );

    if (activeLoans[0].count >= 3) {
      return res.status(403).json({ error: 'Maximum 3 active loans allowed' });
    }

    // Calculate interest and total
    const interestRate = 5.0; // 5% interest
    const interest = loanAmount * (interestRate / 100);
    const totalAmount = loanAmount + interest;
    const installmentAmount = totalAmount / installmentsCount;

    // Calculate payment dates
    const firstPaymentDate = new Date();
    firstPaymentDate.setDate(firstPaymentDate.getDate() + 30); // First payment in 30 days

    const finalPaymentDate = new Date(firstPaymentDate);
    finalPaymentDate.setMonth(finalPaymentDate.getMonth() + (installmentsCount - 1));

    // Generate loan ID
    const loanId = `BNPL-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

    // Create loan (auto-approve for demo, in production this would be pending)
    await db.query(
      `INSERT INTO bnpl_loans (
        loan_id, user_id, merchant_name, item_description,
        principal_amount, interest_rate, total_amount,
        installments_total, installment_amount,
        status, approval_status, first_payment_date, next_payment_date, final_payment_date,
        approved_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', 'approved', ?, ?, ?, NOW())`,
      [
        loanId,
        req.user?.id,
        merchant_name,
        item_description || '',
        loanAmount,
        interestRate,
        totalAmount,
        installmentsCount,
        installmentAmount,
        firstPaymentDate,
        firstPaymentDate,
        finalPaymentDate
      ]
    );

    // Log credit history
    await db.query(
      `INSERT INTO credit_history (user_id, event_type, description) 
       VALUES (?, 'loan_approved', ?)`,
      [req.user?.id, `BNPL loan approved: ${loanId} for MKW ${loanAmount}`]
    );

    res.json({
      success: true,
      loan_id: loanId,
      principal_amount: loanAmount,
      interest_rate: interestRate,
      total_amount: totalAmount,
      installment_amount: installmentAmount,
      installments_total: installmentsCount,
      first_payment_date: firstPaymentDate,
      final_payment_date: finalPaymentDate,
      message: 'BNPL loan approved successfully'
    });
  } catch (error) {
    console.error('BNPL application error:', error);
    res.status(500).json({ error: 'Failed to process loan application' });
  }
});

// Make BNPL payment
router.post('/pay', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { loan_id, payment_method, password } = req.body;

    if (!loan_id || !password) {
      return res.status(400).json({ error: 'Loan ID and password required' });
    }

    // Verify password
    const bcrypt = require('bcryptjs');
    const [users]: any = await db.query(
      `SELECT password_hash FROM users WHERE id = ?`,
      [req.user?.id]
    );

    const validPassword = await bcrypt.compare(password, users[0].password_hash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid password' });
    }

    // Get loan details
    const [loans]: any = await db.query(
      `SELECT * FROM bnpl_loans WHERE loan_id = ? AND user_id = ?`,
      [loan_id, req.user?.id]
    );

    if (loans.length === 0) {
      return res.status(404).json({ error: 'Loan not found' });
    }

    const loan = loans[0];

    if (loan.status !== 'active') {
      return res.status(400).json({ error: 'Loan is not active' });
    }

    if (loan.installments_paid >= loan.installments_total) {
      return res.status(400).json({ error: 'Loan already fully paid' });
    }

    // Check wallet balance
    const [wallets]: any = await db.query(
      `SELECT balance FROM wallets WHERE user_id = ?`,
      [req.user?.id]
    );

    const walletBalance = parseFloat(wallets[0].balance);
    const installmentAmount = parseFloat(loan.installment_amount);

    if (walletBalance < installmentAmount) {
      return res.status(400).json({ 
        error: 'Insufficient balance',
        balance: walletBalance,
        required: installmentAmount
      });
    }

    // Check if payment is late
    const now = new Date();
    const nextPaymentDate = new Date(loan.next_payment_date);
    const isLate = now > nextPaymentDate;
    const lateDays = isLate ? Math.floor((now.getTime() - nextPaymentDate.getTime()) / (1000 * 60 * 60 * 24)) : 0;
    const lateFee = isLate ? lateDays * 100 : 0; // MKW 100 per day late fee

    const totalPayment = parseFloat(loan.installment_amount) + lateFee;

    // Deduct from wallet
    await db.query(
      `UPDATE wallets SET balance = balance - ? WHERE user_id = ?`,
      [totalPayment, req.user?.id]
    );

    // Record payment
    const paymentId = `PAY-${Date.now()}-${Math.floor(Math.random() * 10000)}`;
    await db.query(
      `INSERT INTO bnpl_payments (
        payment_id, loan_id, user_id, amount, payment_method,
        installment_number, status, is_late, late_days, late_fee
      ) VALUES (?, ?, ?, ?, ?, ?, 'completed', ?, ?, ?)`,
      [
        paymentId,
        loan.id,
        req.user?.id,
        totalPayment,
        payment_method || 'inkawallet',
        loan.installments_paid + 1,
        isLate,
        lateDays,
        lateFee
      ]
    );

    // Update loan
    const newAmountPaid = parseFloat(loan.amount_paid) + totalPayment;
    const newInstallmentsPaid = loan.installments_paid + 1;
    const isCompleted = newInstallmentsPaid >= loan.installments_total;

    let nextPayment = new Date(loan.next_payment_date);
    nextPayment.setMonth(nextPayment.getMonth() + 1);

    await db.query(
      `UPDATE bnpl_loans SET 
        amount_paid = ?,
        installments_paid = ?,
        next_payment_date = ?,
        status = ?,
        completed_at = ?
      WHERE id = ?`,
      [
        newAmountPaid,
        newInstallmentsPaid,
        isCompleted ? null : nextPayment,
        isCompleted ? 'completed' : 'active',
        isCompleted ? new Date() : null,
        loan.id
      ]
    );

    // Log credit history
    await db.query(
      `INSERT INTO credit_history (user_id, event_type, description) 
       VALUES (?, ?, ?)`,
      [
        req.user?.id,
        isCompleted ? 'loan_completed' : 'payment_made',
        `BNPL payment ${paymentId}: MKW ${totalPayment} for ${loan_id}`
      ]
    );

    // Record transaction
    const transactionId = `TX-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
    await db.query(
      `INSERT INTO transactions (
        transaction_id, sender_id, amount, transaction_type, payment_method, status, description
      ) VALUES (?, ?, ?, 'withdrawal', ?, 'completed', ?)`,
      [
        transactionId,
        req.user?.id,
        totalPayment,
        payment_method || 'inkawallet',
        `BNPL payment ${newInstallmentsPaid}/${loan.installments_total} for ${loan.merchant_name}`
      ]
    );

    res.json({
      success: true,
      payment_id: paymentId,
      transaction_id: transactionId,
      amount_paid: totalPayment,
      late_fee: lateFee,
      installment_paid: newInstallmentsPaid,
      installments_remaining: loan.installments_total - newInstallmentsPaid,
      loan_completed: isCompleted,
      next_payment_date: isCompleted ? null : nextPayment,
      message: isCompleted ? 'Loan completed!' : 'Payment successful'
    });
  } catch (error) {
    console.error('BNPL payment error:', error);
    res.status(500).json({ error: 'Payment failed' });
  }
});

// Helper function
function calculateMaxLoan(score: number): number {
  if (score >= 750) return 500000;
  if (score >= 650) return 300000;
  if (score >= 550) return 150000;
  if (score >= 450) return 75000;
  if (score >= 400) return 50000;
  return 0;
}

export default router;
