-- InkaWallet Database Schema
-- MySQL Database for Inclusive Digital Wallet
-- Create database
CREATE DATABASE IF NOT EXISTS inkawallet_db;
USE inkawallet_db;
-- Users table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_phone (phone)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- Wallets table
CREATE TABLE IF NOT EXISTS wallets (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    balance DECIMAL(15, 2) DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'MWK',
    account_number VARCHAR(20) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_account_number (account_number)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(36) PRIMARY KEY,
    wallet_id VARCHAR(36) NOT NULL,
    type ENUM('send', 'receive', 'deposit', 'withdrawal') NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'MWK',
    recipient_name VARCHAR(200),
    recipient_phone VARCHAR(20),
    recipient_wallet_provider VARCHAR(50),
    sender_name VARCHAR(200),
    sender_phone VARCHAR(20),
    description TEXT,
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    reference_number VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
    INDEX idx_wallet_id (wallet_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_reference_number (reference_number)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- Refresh tokens table (for JWT)
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_token (token(255)),
    INDEX idx_expires_at (expires_at)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- Activity logs table (for security and audit)
CREATE TABLE IF NOT EXISTS activity_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(36),
    action VARCHAR(100) NOT NULL,
    resource VARCHAR(100),
    ip_address VARCHAR(45),
    user_agent TEXT,
    details JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE
    SET NULL,
        INDEX idx_user_id (user_id),
        INDEX idx_action (action),
        INDEX idx_created_at (created_at)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- Feedback table (for user feedback and research)
CREATE TABLE IF NOT EXISTS feedback (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    rating INT CHECK (
        rating >= 1
        AND rating <= 5
    ),
    status ENUM('new', 'reviewed', 'resolved') DEFAULT 'new',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE
    SET NULL,
        INDEX idx_user_id (user_id),
        INDEX idx_status (status),
        INDEX idx_created_at (created_at)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- Failed login attempts table (for security)
CREATE TABLE IF NOT EXISTS failed_login_attempts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email_or_phone VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email_phone (email_or_phone),
    INDEX idx_ip_address (ip_address),
    INDEX idx_attempted_at (attempted_at)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- External wallet providers table (for interoperability)
CREATE TABLE IF NOT EXISTS external_wallet_providers (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    api_endpoint VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- Insert default external wallet providers
INSERT INTO external_wallet_providers (id, name, api_endpoint, is_active)
VALUES (UUID(), 'InkaWallet', NULL, TRUE),
    (
        UUID(),
        'Mpamba',
        'https://api.mpamba.mw/mock',
        TRUE
    ),
    (
        UUID(),
        'Airtel Money',
        'https://api.airtel.mw/mock',
        TRUE
    ),
    (
        UUID(),
        'Standard Bank',
        'https://api.bank.mw/mock/standard',
        TRUE
    ),
    (
        UUID(),
        'National Bank',
        'https://api.bank.mw/mock/national',
        TRUE
    ),
    (
        UUID(),
        'FDH Bank',
        'https://api.bank.mw/mock/fdh',
        TRUE
    );
-- Admin users table
CREATE TABLE IF NOT EXISTS admin_users (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL UNIQUE,
    role ENUM('super_admin', 'admin', 'moderator') DEFAULT 'admin',
    permissions JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- Create stored procedure for money transfer
DELIMITER // CREATE PROCEDURE transfer_money(
    IN sender_wallet_id VARCHAR(36),
    IN sender_user_id VARCHAR(36),
    IN recipient_phone VARCHAR(20),
    IN transfer_amount DECIMAL(15, 2),
    IN wallet_provider VARCHAR(50),
    IN transfer_description TEXT,
    OUT transaction_id VARCHAR(36),
    OUT transaction_status VARCHAR(20),
    OUT error_message VARCHAR(255)
) BEGIN
DECLARE sender_balance DECIMAL(15, 2);
DECLARE ref_number VARCHAR(50);
DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK;
SET transaction_status = 'failed';
SET error_message = 'Transaction failed due to database error';
END;
START TRANSACTION;
-- Check sender balance
SELECT balance INTO sender_balance
FROM wallets
WHERE id = sender_wallet_id
    AND user_id = sender_user_id
    AND is_active = TRUE FOR
UPDATE;
IF sender_balance IS NULL THEN
SET transaction_status = 'failed';
SET error_message = 'Wallet not found or inactive';
ROLLBACK;
ELSEIF sender_balance < transfer_amount THEN
SET transaction_status = 'failed';
SET error_message = 'Insufficient funds';
ROLLBACK;
ELSE -- Generate transaction ID and reference number
SET transaction_id = UUID();
SET ref_number = CONCAT('TXN', LPAD(FLOOR(RAND() * 1000000000), 9, '0'));
-- Deduct from sender
UPDATE wallets
SET balance = balance - transfer_amount
WHERE id = sender_wallet_id;
-- Create transaction record
INSERT INTO transactions (
        id,
        wallet_id,
        type,
        amount,
        currency,
        recipient_phone,
        recipient_wallet_provider,
        description,
        status,
        reference_number,
        created_at,
        completed_at
    )
VALUES (
        transaction_id,
        sender_wallet_id,
        'send',
        transfer_amount,
        'MWK',
        recipient_phone,
        wallet_provider,
        transfer_description,
        'completed',
        ref_number,
        NOW(),
        NOW()
    );
SET transaction_status = 'completed';
SET error_message = NULL;
COMMIT;
END IF;
END // DELIMITER;
-- Create trigger for activity logging on transactions
DELIMITER // CREATE TRIGGER after_transaction_insert
AFTER
INSERT ON transactions FOR EACH ROW BEGIN
DECLARE sender_user_id VARCHAR(36);
SELECT user_id INTO sender_user_id
FROM wallets
WHERE id = NEW.wallet_id;
INSERT INTO activity_logs (user_id, action, resource, details)
VALUES (
        sender_user_id,
        'transaction_created',
        'transactions',
        JSON_OBJECT(
            'transaction_id',
            NEW.id,
            'type',
            NEW.type,
            'amount',
            NEW.amount,
            'status',
            NEW.status
        )
    );
END // DELIMITER;