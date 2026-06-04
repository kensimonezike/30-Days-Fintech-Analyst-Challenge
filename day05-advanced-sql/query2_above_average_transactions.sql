-- Query 2: Find all transactions with amount above the January average
-- Business question: Which transactions are high-value and warrant fraud review?
-- New concept: Subquery inside WHERE — inner query runs first, result used by outer query
-- PalmPay Analytics | Day 5 | January 2024

SELECT
    transaction_id,
    user_id,
    transaction_date,
    transaction_type,
    amount_ngn,
    status,
    ROUND(amount_ngn - (
        SELECT AVG(amount_ngn)
        FROM transactions
        WHERE amount_ngn > 0          -- exclude negative amounts from average
    ), 2)                             AS above_avg_by_ngn
FROM transactions
WHERE amount_ngn > (
    SELECT AVG(amount_ngn)
    FROM transactions
    WHERE amount_ngn > 0
)
ORDER BY amount_ngn DESC;

-- Average (positive transactions only): ₦142,390.00
--
-- Result (15 transactions above average):
-- TXN-0033 | USR-3286 | 15-Jan-2024 | Deposit      | 473,150.00 | Success | above by 330,760
-- TXN-0046 | USR-1409 | 28-Jan-2024 | Withdrawal   | 472,840.00 | Success | above by 330,450
-- TXN-0041 | USR-7924 | 25-Jan-2024 | Airtime      | 462,810.00 | Success | above by 320,420
-- TXN-0039 | USR-2679 | 24-Jan-2024 | Bill Payment | 459,000.00 | Pending | above by 316,610
-- TXN-0003 | USR-2424 | 02-Jan-2024 | Deposit      | 441,650.00 | Success | above by 299,260
-- ... (10 more transactions)
--
-- 15 of 50 transactions (30%) exceeded the average.
-- The top transaction (TXN-0033) was 3.3x the average — a standard AML flag threshold.
-- Note: TXN-0039 is above average AND Pending — this combination warrants investigation.
