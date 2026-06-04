-- Query 3: ARPU and transaction velocity by account tier
-- Business question: Which tier delivers the most value per user?
-- New concept: CTE (WITH clause) — named temporary result used by main query
-- KPIs introduced: ARPU (Average Revenue Per User), Transaction Velocity
-- PalmPay Analytics | Day 5 | January 2024

WITH tier_stats AS (
    SELECT
        c.account_tier,
        COUNT(t.transaction_id)                                     AS total_transactions,
        COUNT(DISTINCT t.user_id)                                   AS active_users,
        SUM(CASE WHEN t.status = 'Success'
             AND t.amount_ngn > 0 THEN t.amount_ngn ELSE 0 END)    AS successful_volume
    FROM transactions t
    INNER JOIN customers c ON t.user_id = c.user_id
    GROUP BY c.account_tier
)
SELECT
    account_tier,
    total_transactions,
    active_users,
    successful_volume,
    ROUND(successful_volume / NULLIF(active_users, 0), 2)           AS arpu_ngn,
    ROUND(total_transactions::numeric / NULLIF(active_users, 0), 2) AS txn_velocity
FROM tier_stats
ORDER BY arpu_ngn DESC;

-- Result:
-- VIP      | 8 txns  | 3 users  | ₦928,290  | ARPU ₦309,430 | velocity 2.7
-- Standard | 32 txns | 13 users | ₦3,517,280| ARPU ₦270,560 | velocity 2.5
-- Premium  | 10 txns | 6 users  | ₦957,270  | ARPU ₦159,545 | velocity 1.7
--
-- Surprising insight: VIP has the highest ARPU (₦309,430) as expected,
-- but Standard tier has the second-highest ARPU (₦270,560) — only 13% below VIP.
-- More critically, Premium tier has the LOWEST ARPU at ₦159,545 — 48% below VIP.
-- This suggests Premium customers are either misclassified or under-engaged.
-- The product team should investigate what drives Premium customers to transact less.
--
-- Note: NULLIF(active_users, 0) prevents divide-by-zero if a tier had zero users.
-- The ::numeric cast forces decimal division (prevents integer truncation in PostgreSQL).
