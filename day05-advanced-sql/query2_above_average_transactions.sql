-- Query 2: Find all transactions with amount above the January average
-- Business question: Which transactions are high-value and warrant fraud review?

SELECT
    transaction_id,
    user_id,
    transaction_date,
    transaction_type,
    amount_ngn,
    status,
    ROUND(
        (
            amount_ngn - (
                SELECT AVG(amount_ngn)
                FROM transactions
                WHERE amount_ngn > 0
            )
        )::numeric,
        2
    ) AS above_avg_by_ngn
FROM transactions
WHERE amount_ngn > (
    SELECT AVG(amount_ngn)
    FROM transactions
    WHERE amount_ngn > 0
)
ORDER BY amount_ngn DESC;

-- Average (positive transactions only): ₦142,390.00
--
-- 15 of 50 transactions (30%) exceeded the average.
-- The top transaction (TXN-0033) was 3.3x the average, a standard AML flag threshold.
-- Note: TXN-0039 is above average AND Pending; this combination warrants investigation.
