-- Query 5: Find customers who made ZERO transactions in January 2024
-- Business question: Which registered customers are inactive this month?

-- JOIN type: LEFT JOIN with customers as base table (tables swapped)

SELECT
    c.customer_id,
    c.full_name,
    c.account_tier,
    c.city,
    c.signup_date,
    c.kyc_status,
    c.monthly_income_band,
    t.transaction_id    -- will be NULL if no transactions
FROM customers AS c
LEFT JOIN transactions AS t
    ON c.user_id = t.user_id
WHERE t.transaction_id IS NULL
ORDER BY c.account_tier, c.full_name;

-- Result (3 dormant customers):
-- CUS-023 | Kemi Adebayo  | Standard | Lagos | 2023-06-15 | Verified | 200k-500k
-- CUS-024 | Rotimi Akande | Premium  | Lagos | 2023-06-15 | Verified | 200k-500k
-- CUS-025 | Hadiza Sule   | VIP      | Lagos | 2023-06-15 | Verified | 200k-500k
--
-- All 3 dormant customers are Verified KYC, and they are eligible to transact
-- but chose not to in January. This makes them highest-priority re-engagement targets.
-- A VIP customer who does not transact in a full month is a churn risk.

-- Bonus: Count of transactions per customer (shows 0 for dormant)
SELECT
    c.full_name,
    c.account_tier,
    COUNT(t.transaction_id)  AS transaction_count
FROM customers AS c
LEFT JOIN transactions AS t
    ON c.user_id = t.user_id
GROUP BY c.full_name, c.account_tier
ORDER BY transaction_count ASC, c.account_tier;

-- This query shows all 25 customers with their January transaction count.
-- The 3 dormant customers appear at the top with count = 0.
