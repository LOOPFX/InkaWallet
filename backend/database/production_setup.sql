-- InkaWallet Production Database Setup
-- Aiven MySQL Database Initialization
-- DO NOT include test data, only schema and admin user
-- Use the default database
USE defaultdb;
-- Drop existing tables if any (in correct order to avoid FK constraints)
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS money_requests;
DROP TABLE IF EXISTS wallets;
DROP TABLE IF EXISTS kyc_documents;
DROP TABLE IF EXISTS kyc_verifications;
DROP TABLE IF EXISTS bnpl_payments;
DROP TABLE IF EXISTS bnpl_purchases;
DROP TABLE IF EXISTS credit_payments;
DROP TABLE IF EXISTS credit_applications;
DROP TABLE IF EXISTS users;
-- ===== MAIN SCHEMA =====
-- Users Table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    google_id VARCHAR(255) UNIQUE,
    accessibility_enabled BOOLEAN DEFAULT TRUE,
    voice_enabled BOOLEAN DEFAULT TRUE,
    haptics_enabled BOOLEAN DEFAULT TRUE,
    biometric_enabled BOOLEAN DEFAULT FALSE,
    is_admin BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_phone (phone_number)
);
-- Wallets Table
CREATE TABLE wallets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    balance DECIMAL(15, 2) DEFAULT 100000.00,
    currency VARCHAR(3) DEFAULT 'MKW',
    is_locked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);
-- Transactions Table
CREATE TABLE transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(100) UNIQUE NOT NULL,
    sender_id INT,
    receiver_id INT,
    amount DECIMAL(15, 2) NOT NULL,
    transaction_type ENUM('send', 'receive', 'deposit', 'withdrawal') NOT NULL,
    payment_method ENUM('inkawallet', 'mpamba', 'airtel_money', 'bank') DEFAULT 'inkawallet',
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE
    SET NULL,
        FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE
    SET NULL,
        INDEX idx_transaction_id (transaction_id),
        INDEX idx_sender (sender_id),
        INDEX idx_receiver (receiver_id),
        INDEX idx_created_at (created_at)
);
-- Money Requests Table
CREATE TABLE money_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id VARCHAR(100) UNIQUE NOT NULL,
    requester_id INT NOT NULL,
    requestee_id INT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    status ENUM('pending', 'accepted', 'rejected', 'cancelled') DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (requestee_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_request_id (request_id),
    INDEX idx_requester (requester_id),
    INDEX idx_requestee (requestee_id),
    INDEX idx_status (status)
);
-- ===== KYC SCHEMA =====
CREATE TABLE kyc_verifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    verification_level ENUM('basic', 'intermediate', 'advanced') DEFAULT 'basic',
    status ENUM(
        'pending',
        'under_review',
        'approved',
        'rejected'
    ) DEFAULT 'pending',
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    date_of_birth DATE,
    nationality VARCHAR(100),
    id_type ENUM('national_id', 'passport', 'drivers_license'),
    id_number VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    occupation VARCHAR(100),
    source_of_income VARCHAR(100),
    rejection_reason TEXT,
    verified_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
);
CREATE TABLE kyc_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kyc_id INT NOT NULL,
    document_type ENUM(
        'id_front',
        'id_back',
        'selfie',
        'proof_of_address',
        'other'
    ) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100),
    file_size INT,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    rejection_reason TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kyc_id) REFERENCES kyc_verifications(id) ON DELETE CASCADE,
    INDEX idx_kyc_id (kyc_id),
    INDEX idx_status (status)
);
-- ===== CREDIT & BNPL SCHEMA =====
CREATE TABLE credit_applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    requested_amount DECIMAL(15, 2) NOT NULL,
    approved_amount DECIMAL(15, 2),
    interest_rate DECIMAL(5, 2) DEFAULT 15.00,
    term_months INT NOT NULL,
    monthly_payment DECIMAL(15, 2),
    status ENUM(
        'pending',
        'approved',
        'rejected',
        'active',
        'completed',
        'defaulted'
    ) DEFAULT 'pending',
    purpose TEXT,
    employment_status VARCHAR(100),
    monthly_income DECIMAL(15, 2),
    credit_score INT,
    rejection_reason TEXT,
    disbursed_at TIMESTAMP NULL,
    due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
);
CREATE TABLE credit_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    credit_id INT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    remaining_balance DECIMAL(15, 2) NOT NULL,
    status ENUM('completed', 'failed', 'pending') DEFAULT 'completed',
    FOREIGN KEY (credit_id) REFERENCES credit_applications(id) ON DELETE CASCADE,
    INDEX idx_credit_id (credit_id)
);
CREATE TABLE bnpl_purchases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    merchant_name VARCHAR(255) NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    down_payment DECIMAL(15, 2) NOT NULL,
    remaining_amount DECIMAL(15, 2) NOT NULL,
    installment_count INT NOT NULL,
    installment_amount DECIMAL(15, 2) NOT NULL,
    status ENUM('active', 'completed', 'defaulted', 'cancelled') DEFAULT 'active',
    next_payment_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
);
CREATE TABLE bnpl_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bnpl_id INT NOT NULL,
    installment_number INT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('completed', 'failed', 'pending') DEFAULT 'completed',
    FOREIGN KEY (bnpl_id) REFERENCES bnpl_purchases(id) ON DELETE CASCADE,
    INDEX idx_bnpl_id (bnpl_id)
);
-- ===== CREATE ADMIN USER =====
-- Insert admin user (password: "Mytest@01")
-- Hash generated with bcrypt (10 rounds)
INSERT INTO users (
        email,
        password_hash,
        full_name,
        phone_number,
        is_admin,
        is_active,
        accessibility_enabled,
        voice_enabled
    )
VALUES (
        'txe-012-22@must.ac.mw',
        '$2a$10$jTattRJNpomJOPziKZCgd.4ZaX1bSsGfdG64nC6xdoj2KOSSIoqjS',
        'Admin User',
        '+265999000001',
        TRUE,
        TRUE,
        TRUE,
        TRUE
    );
-- Create wallet for admin user
INSERT INTO wallets (user_id, balance, currency)
VALUES (LAST_INSERT_ID(), 100000.00, 'MKW');
-- ===== VERIFICATION =====
SELECT 'Database setup completed!' as status;
SELECT COUNT(*) as admin_user_count
FROM users
WHERE is_admin = TRUE;
SELECT COUNT(*) as total_tables
FROM information_schema.tables
WHERE table_schema = 'defaultdb';