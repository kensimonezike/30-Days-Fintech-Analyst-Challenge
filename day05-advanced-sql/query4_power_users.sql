-- Query 4: Identify power users — customers with 3 or more transactions in January
-- Business question: Who are our most engaged customers this month?

SELECT
    t.user_id, c.full_name, c.account_tier, c.city,
    COUNT(t.transaction_id)                 AS transaction_count,
    SUM(t.amount_ngn)                       AS total_volume_ngn,
    ROUND(AVG(t.amount_ngn)::numeric, 2)    AS avg_transaction_ngn
FROM transactions t
INNER JOIN customers c ON t.user_id = c.user_id
GROUP BY t.user_id, c.full_name, c.account_tier, c.city
HAVING COUNT(t.transaction_id) >= 3
ORDER BY transaction_count DESC, total_volume_ngn DESC;

-- Result (10 power users with 3+ transactions): check /screenshots
--
-- 10 of 22 active users (45%) are power users, a strong engagement signal.
-- The top power user (Babatunde Oladele) is Standard tier, strong upgrade candidate.
-- 7 of the 10 power users are Standard tier, suggesting tier labels underrepresent
-- actual engagement levels.
