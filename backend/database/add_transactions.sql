-- Add sample transactions only
USE inkawallet_db;
-- Clear existing transactions
TRUNCATE TABLE transactions;
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
-- 106000
UPDATE wallets
SET balance = 100000.00 + 15000.00 - 5000.00 - 7500.00 + 20000.00
WHERE user_id = 3;
-- 122500
UPDATE wallets
SET balance = 100000.00 + 40000.00 - 3000.00 + 12000.00
WHERE user_id = 4;
-- 149000
UPDATE wallets
SET balance = 100000.00 - 8500.00 + 50000.00 + 7500.00
WHERE user_id = 5;
-- 149000
-- Show results
SELECT 'Database seeded successfully!' as status;
SELECT id,
    email,
    full_name
FROM users;
SELECT user_id,
    balance
FROM wallets
ORDER BY user_id;
SELECT COUNT(*) as total_transactions
FROM transactions;