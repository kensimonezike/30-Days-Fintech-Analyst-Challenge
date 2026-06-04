-- Query 3: ARPU and transaction velocity by account tier
-- Business question: Which tier delivers the most value per user?

WITH tier_stats AS (
    SELECT
        c.account_tier,
        COUNT(t.transaction_id) AS total_transactions,
        COUNT(DISTINCT t.user_id) AS active_users,
        SUM(
            CASE
                WHEN t.status = 'Success'
                     AND t.amount_ngn > 0
                THEN t.amount_ngn
                ELSE 0
            END
        ) AS successful_volume
    FROM transactions t
    INNER JOIN customers c
        ON t.user_id = c.user_id
    GROUP BY c.account_tier
)
SELECT
    account_tier,
    total_transactions,
    active_users,
    successful_volume,
    ROUND(
        (successful_volume / NULLIF(active_users, 0))::numeric,
        2
    ) AS arpu_ngn,
    ROUND(
        total_transactions::numeric / NULLIF(active_users, 0),
        2
    ) AS txn_velocity
FROM tier_stats
ORDER BY arpu_ngn DESC;

-- Result:
-- check /screenshots
