-- Query 6: Complete executive KPI summary — all 5 core fintech KPIs in one query
-- Business question: What is the full performance picture for January 2024?
-- Concept: Chained CTEs — each CTE builds on the previous one
-- KPIs: Success Rate, Failure Rate, ATV (Avg Transaction Value), ARPU, Txn Velocity
-- PalmPay Analytics | Day 5 | January 2024
-- This query is REUSABLE: change the date filter in clean_txns to run for any month.

WITH
clean_txns AS (
    -- Step 1: Exclude data quality issues (negative amounts)
    SELECT * FROM transactions
    WHERE amount_ngn > 0
),
kpi_base AS (
    -- Step 2: Pre-aggregate all counts and volumes needed for KPI calculations
    SELECT
        COUNT(*)                                                    AS total_transactions,
        COUNT(DISTINCT user_id)                                     AS active_users,
        COUNT(CASE WHEN status = 'Success' THEN 1 END)             AS successful_txns,
        COUNT(CASE WHEN status = 'Failed'  THEN 1 END)             AS failed_txns,
        COUNT(CASE WHEN status = 'Pending' THEN 1 END)             AS pending_txns,
        SUM(CASE WHEN status = 'Success' THEN amount_ngn ELSE 0 END) AS successful_volume
    FROM clean_txns
)
-- Step 3: Calculate all 5 KPIs from the pre-aggregated base
SELECT
    'January 2024'                                                  AS period,
    total_transactions,
    active_users,
    successful_txns,
    failed_txns,
    -- KPI 1: Transaction Success Rate
    ROUND(successful_txns * 100.0 / NULLIF(total_transactions, 0), 1) AS success_rate_pct,
    -- KPI 2: Failure Rate
    ROUND(failed_txns * 100.0 / NULLIF(total_transactions, 0), 1)     AS failure_rate_pct,
    -- KPI 3: Average Transaction Value (ATV)
    ROUND(successful_volume / NULLIF(successful_txns, 0), 2)           AS avg_txn_value_ngn,
    -- KPI 4: Average Revenue Per User (ARPU)
    ROUND(successful_volume / NULLIF(active_users, 0), 2)              AS arpu_ngn,
    -- KPI 5: Transaction Velocity (avg transactions per user)
    ROUND(total_transactions::numeric / NULLIF(active_users, 0), 2)    AS txn_velocity,
    -- Total volume for reference
    successful_volume                                                   AS total_volume_ngn
FROM kpi_base;

-- ════════════════════════════════════════════════════════════════════
-- RESULT — January 2024 Executive KPI Summary (1 row)
-- ════════════════════════════════════════════════════════════════════
--
-- period        | January 2024
-- total_txns    | 50
-- active_users  | 22
-- successful    | 36
-- failed        | 9
-- success_rate  | 72.0%         ← Below 95% industry benchmark — attention needed
-- failure_rate  | 18.0%         ← Critical — nearly 1 in 5 transactions failed
-- avg_txn_value | ₦150,078.89   ← Baseline ATV for February comparison
-- arpu          | ₦245,583.64   ← Revenue per active user this month
-- txn_velocity  | 2.27          ← Average of 2.27 transactions per user in January
-- total_volume  | ₦5,402,840.00 ← Clean revenue (negative amounts excluded)
-- ════════════════════════════════════════════════════════════════════
