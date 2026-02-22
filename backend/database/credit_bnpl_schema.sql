-- Credit Scoring and Buy Now Pay Later Schema
-- Created: 2026-02-22
USE inkawallet_db;
-- Credit Scores Table
CREATE TABLE IF NOT EXISTS credit_scores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    score INT NOT NULL DEFAULT 300,
    -- 300-850 range
    payment_history_score INT DEFAULT 0,
    -- 0-100
    transaction_volume_score INT DEFAULT 0,
    -- 0-100
    account_age_score INT DEFAULT 0,
    -- 0-100
    defaults_count INT DEFAULT 0,
    total_borrowed DECIMAL(15, 2) DEFAULT 0.00,
    total_repaid DECIMAL(15, 2) DEFAULT 0.00,
    last_calculated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_score (score)
);
-- BNPL Loans Table
CREATE TABLE IF NOT EXISTS bnpl_loans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id VARCHAR(100) UNIQUE NOT NULL,
    user_id INT NOT NULL,
    merchant_name VARCHAR(255) NOT NULL,
    item_description TEXT,
    principal_amount DECIMAL(15, 2) NOT NULL,
    interest_rate DECIMAL(5, 2) DEFAULT 5.00,
    -- percentage
    total_amount DECIMAL(15, 2) NOT NULL,
    -- principal + interest
    amount_paid DECIMAL(15, 2) DEFAULT 0.00,
    installments_total INT NOT NULL DEFAULT 4,
    -- 4 installments (monthly)
    installments_paid INT DEFAULT 0,
    installment_amount DECIMAL(15, 2) NOT NULL,
    status ENUM(
        'pending',
        'active',
        'completed',
        'defaulted',
        'cancelled'
    ) DEFAULT 'pending',
    approval_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    first_payment_date DATE,
    next_payment_date DATE,
    final_payment_date DATE,
    approved_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_next_payment (next_payment_date)
);
-- BNPL Payments Table
CREATE TABLE IF NOT EXISTS bnpl_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payment_id VARCHAR(100) UNIQUE NOT NULL,
    loan_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    payment_method ENUM(
        'inkawallet',
        'mpamba',
        'airtel_money',
        'bank',
        'card'
    ) DEFAULT 'inkawallet',
    installment_number INT NOT NULL,
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    is_late BOOLEAN DEFAULT FALSE,
    late_days INT DEFAULT 0,
    late_fee DECIMAL(15, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES bnpl_loans(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_loan_id (loan_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
);
-- Credit History Table (for tracking credit-related events)
CREATE TABLE IF NOT EXISTS credit_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    event_type ENUM(
        'score_calculated',
        'loan_applied',
        'loan_approved',
        'loan_rejected',
        'payment_made',
        'payment_missed',
        'loan_completed',
        'loan_defaulted'
    ) NOT NULL,
    previous_score INT,
    new_score INT,
    score_change INT DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_event_type (event_type),
    INDEX idx_created (created_at)
);
-- Initialize credit scores for existing users
INSERT INTO credit_scores (user_id, score, account_age_score)
SELECT id,
    500,
    50
FROM users
WHERE NOT EXISTS (
        SELECT 1
        FROM credit_scores
        WHERE credit_scores.user_id = users.id
    );