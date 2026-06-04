-- Query 6: Complete executive KPI summary — all 5 core fintech KPIs in one query
-- Business question: What is the full performance picture for January 2024?

WITH clean_txns AS (
    SELECT * 
    FROM transactions 
    WHERE amount_ngn > 0
),
kpi_base AS (
    SELECT
        COUNT(*) AS total_transactions,
        COUNT(DISTINCT user_id) AS active_users,
        COUNT(CASE WHEN status = 'Success' THEN 1 END) AS successful_txns,
        COUNT(CASE WHEN status = 'Failed' THEN 1 END) AS failed_txns,
        SUM(CASE WHEN status = 'Success' THEN amount_ngn ELSE 0 END) AS successful_volume
    FROM clean_txns
)

SELECT
    'January 2024' AS period,
    total_transactions,
    active_users,

    ROUND((successful_txns * 100::numeric / NULLIF(total_transactions, 0))::numeric, 1) AS success_rate_pct,

    ROUND((failed_txns * 100::numeric / NULLIF(total_transactions, 0))::numeric, 1) AS failure_rate_pct,

    ROUND((successful_volume / NULLIF(successful_txns, 0))::numeric, 2) AS avg_txn_value_ngn,

    ROUND((successful_volume / NULLIF(active_users, 0))::numeric, 2) AS arpu_ngn,

    ROUND((total_transactions::numeric / NULLIF(active_users, 0))::numeric, 2) AS txn_velocity,

    successful_volume AS total_volume_ngn
FROM kpi_base;

-- ════════════════════════════════════════════════════════════════════
-- RESULT: check /screenshots
-- ════════════════════════════════════════════════════════════════════
