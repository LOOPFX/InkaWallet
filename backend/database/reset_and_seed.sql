-- InkaWallet Reset and Seed Script
-- WARNING: This will erase ALL data in inkawallet_db
CREATE DATABASE IF NOT EXISTS inkawallet_db;
USE inkawallet_db;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE activity_logs;
TRUNCATE TABLE voice_biometrics;
TRUNCATE TABLE two_factor_auth;
TRUNCATE TABLE transactions;
TRUNCATE TABLE wallets;
TRUNCATE TABLE users;
TRUNCATE TABLE payment_providers;
SET FOREIGN_KEY_CHECKS = 1;
-- Seed payment providers (mock external services)
INSERT INTO payment_providers (name, code)
VALUES ('TNM Mpamba', 'mpamba'),
    ('Airtel Money', 'airtel_money'),
    ('National Bank of Malawi', 'nbm_bank'),
    ('Standard Bank', 'standard_bank'),
    ('FDH Bank', 'fdh_bank');
-- Users (password for all users: admin123)
INSERT INTO users (
        email,
        password_hash,
        full_name,
        phone_number,
        google_id,
        accessibility_enabled,
        voice_enabled,
        haptics_enabled,
        biometric_enabled,
        is_admin,
        is_active
    )
VALUES (
        'admin@inkawallet.com',
        '$2a$10$VsM94jNTI8JdfGuMyX9ArOE8vChi1MNWd1axCWbzfaImO5jVYqb36',
        'System Administrator',
        '+265888000000',
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        TRUE,
        TRUE
    ),
    (
        'maria.kalonga@example.com',
        '$2a$10$VsM94jNTI8JdfGuMyX9ArOE8vChi1MNWd1axCWbzfaImO5jVYqb36',
        'Maria Kalonga',
        '+265888111222',
        NULL,
        TRUE,
        TRUE,
        TRUE,
        TRUE,
        FALSE,
        TRUE
    ),
    (
        'joseph.banda@example.com',
        '$2a$10$VsM94jNTI8JdfGuMyX9ArOE8vChi1MNWd1axCWbzfaImO5jVYqb36',
        'Joseph Banda',
        '+265888333444',
        NULL,
        TRUE,
        TRUE,
        TRUE,
        FALSE,
        FALSE,
        TRUE
    ),
    (
        'grace.chirwa@example.com',
        '$2a$10$VsM94jNTI8JdfGuMyX9ArOE8vChi1MNWd1axCWbzfaImO5jVYqb36',
        'Grace Chirwa',
        '+265888555666',
        NULL,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        TRUE
    );
-- Wallets (default MKW 100,000 for each user)
INSERT INTO wallets (user_id, balance, currency, is_locked)
VALUES (1, 100000.00, 'MKW', FALSE),
    (2, 100000.00, 'MKW', FALSE),
    (3, 100000.00, 'MKW', FALSE),
    (4, 100000.00, 'MKW', FALSE);
-- Transactions (sample history)
INSERT INTO transactions (
        transaction_id,
        sender_id,
        receiver_id,
        amount,
        transaction_type,
        payment_method,
        status,
        description
    )
VALUES (
        'TX-TEST-1001',
        2,
        3,
        15000.00,
        'send',
        'inkawallet',
        'completed',
        'Payment for groceries'
    ),
    (
        'TX-TEST-1002',
        3,
        2,
        5000.00,
        'send',
        'inkawallet',
        'completed',
        'Refund'
    ),
    (
        'TX-TEST-1003',
        NULL,
        2,
        25000.00,
        'receive',
        'mpamba',
        'completed',
        'Salary top-up'
    ),
    (
        'TX-TEST-1004',
        NULL,
        4,
        40000.00,
        'receive',
        'airtel_money',
        'completed',
        'Cash deposit'
    ),
    (
        'TX-TEST-1005',
        4,
        2,
        3000.00,
        'send',
        'bank',
        'completed',
        'Bank transfer'
    );