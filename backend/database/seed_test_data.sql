-- Add test users and transactions to existing database
USE inkawallet_db;
-- Add more test users (password for all: admin123)
INSERT INTO users (
        email,
        password_hash,
        full_name,
        phone_number,
        accessibility_enabled,
        voice_enabled,
        haptics_enabled,
        biometric_enabled,
        is_admin,
        is_active
    )
VALUES (
        'maria.kalonga@example.com',
        '$2a$10$VsM94jNTI8JdfGuMyX9ArOE8vChi1MNWd1axCWbzfaImO5jVYqb36',
        'Maria Kalonga',
        '+265888111222',
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
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        TRUE
    ),
    (
        'james.phiri@example.com',
        '$2a$10$VsM94jNTI8JdfGuMyX9ArOE8vChi1MNWd1axCWbzfaImO5jVYqb36',
        'James Phiri',
        '+265888777888',
        TRUE,
        TRUE,
        TRUE,
        TRUE,
        FALSE,
        TRUE
    );
-- Create wallets for new users (MKW 100,000 each)
INSERT INTO wallets (user_id, balance, currency, is_locked)
SELECT id,
    100000.00,
    'MKW',
    FALSE
FROM users
WHERE id > 1;
-- Add sample transactions
INSERT INTO transactions (
        transaction_id,
        sender_id,
        receiver_id,
        amount,
        transaction_type,
        payment_method,
        status,
        description,
        created_at
    )
VALUES (
        'TX-1708434001-12345',
        2,
        3,
        15000.00,
        'send',
        'inkawallet',
        'completed',
        'Payment for groceries',
        '2026-02-19 10:30:00'
    ),
    (
        'TX-1708434002-23456',
        3,
        2,
        5000.00,
        'send',
        'inkawallet',
        'completed',
        'Refund for overpayment',
        '2026-02-19 11:15:00'
    ),
    (
        'TX-1708434003-34567',
        NULL,
        2,
        25000.00,
        'receive',
        'mpamba',
        'completed',
        'Salary top-up from employer',
        '2026-02-19 14:00:00'
    ),
    (
        'TX-1708434004-45678',
        NULL,
        4,
        40000.00,
        'receive',
        'airtel_money',
        'completed',
        'Cash deposit at agent',
        '2026-02-19 15:30:00'
    ),
    (
        'TX-1708434005-56789',
        4,
        2,
        3000.00,
        'send',
        'inkawallet',
        'completed',
        'Loan repayment',
        '2026-02-19 16:45:00'
    ),
    (
        'TX-1708434006-67890',
        5,
        3,
        8500.00,
        'send',
        'inkawallet',
        'completed',
        'School fees contribution',
        '2026-02-20 08:00:00'
    ),
    (
        'TX-1708434007-78901',
        NULL,
        5,
        50000.00,
        'receive',
        'bank',
        'completed',
        'Bank transfer',
        '2026-02-20 09:30:00'
    ),
    (
        'TX-1708434008-89012',
        2,
        4,
        12000.00,
        'send',
        'inkawallet',
        'completed',
        'Medical expenses',
        '2026-02-20 10:15:00'
    ),
    (
        'TX-1708434009-90123',
        3,
        5,
        7500.00,
        'send',
        'inkawallet',
        'completed',
        'Birthday gift',
        '2026-02-20 11:00:00'
    ),
    (
        'TX-1708434010-01234',
        NULL,
        3,
        20000.00,
        'receive',
        'bank',
        'completed',
        'Savings withdrawal',
        '2026-02-20 12:30:00'
    );
-- Update wallet balances based on transactions
UPDATE wallets
SET balance = 100000.00 - 15000.00 - 12000.00 + 25000.00 + 5000.00 + 3000.00
WHERE user_id = 2;
UPDATE wallets
SET balance = 100000.00 + 15000.00 - 5000.00 - 7500.00 + 20000.00
WHERE user_id = 3;
UPDATE wallets
SET balance = 100000.00 + 40000.00 - 3000.00 + 12000.00
WHERE user_id = 4;
UPDATE wallets
SET balance = 100000.00 - 8500.00 + 50000.00 + 7500.00
WHERE user_id = 5;
SELECT 'Database seeded successfully!' as status;
SELECT COUNT(*) as total_users
FROM users;
SELECT COUNT(*) as total_transactions
FROM transactions;
SELECT user_id,
    balance
FROM wallets
ORDER BY user_id;