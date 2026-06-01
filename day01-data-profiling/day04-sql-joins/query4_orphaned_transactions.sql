-- Query 4: Find transactions with NO matching customer record
-- Business question: How many transactions cannot be linked to a known customer?
-- JOIN type: LEFT JOIN + WHERE IS NULL (anti-join pattern)
-- PalmPay Analytics | Day 4 | January 2024

SELECT
    t.transaction_id,
    t.user_id,
    t.transaction_date,
    t.amount_ngn,
    t.status,
    t.transaction_type,
    c.full_name,        -- will be NULL for unmatched rows
    c.account_tier      -- will be NULL for unmatched rows
FROM transactions AS t
LEFT JOIN customers AS c
    ON t.user_id = c.user_id
WHERE c.customer_id IS NULL
ORDER BY t.transaction_date;

-- Result: 0 rows returned
--
-- Finding: All 50 transactions in January have a matching customer record.
-- This is a positive data quality result — there are no orphaned transactions.
-- Zero orphaned transactions = clean referential integrity between the two tables.
-- In a production environment this check should run daily as a data quality monitor.

-- Verification query — confirm match rate:
SELECT
    COUNT(*)                                        AS total_transactions,
    COUNT(c.customer_id)                            AS matched_transactions,
    COUNT(*) - COUNT(c.customer_id)                 AS unmatched_transactions,
    ROUND(COUNT(c.customer_id) * 100.0 / COUNT(*), 1) AS match_rate_pct
FROM transactions AS t
LEFT JOIN customers AS c
    ON t.user_id = c.user_id;

-- Result: 50 total | 50 matched | 0 unmatched | 100.0% match rate
