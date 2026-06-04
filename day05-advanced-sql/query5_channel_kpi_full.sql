-- Query 5: Complete channel reliability KPI report
-- Business question: Full success/failure breakdown per channel with all metrics

WITH channel_metrics AS (
    SELECT
        channel,
        COUNT(*) AS total_txns,
        -- Using Postgres FILTER clause for cleaner code
        COUNT(*) FILTER (WHERE status = 'Success') AS success_count,
        COUNT(*) FILTER (WHERE status = 'Failed')  AS failed_count,
        COUNT(*) FILTER (WHERE status = 'Pending') AS pending_count,
        -- Coalesce ensures we get 0 instead of NULL if there are no successful txns
        COALESCE(SUM(amount_ngn) FILTER (WHERE status = 'Success' AND amount_ngn > 0), 0) AS successful_volume
    FROM transactions
    GROUP BY channel
)
SELECT
    channel, 
    total_txns, 
    success_count, 
    failed_count, 
    pending_count,
    ROUND((success_count::numeric / NULLIF(total_txns, 0)) * 100, 1) AS success_rate_pct,
    ROUND((failed_count::numeric  / NULLIF(total_txns, 0)) * 100, 1) AS failure_rate_pct,
    successful_volume,
    ROUND(successful_volume::numeric / NULLIF(success_count, 0), 2)  AS avg_success_value_ngn
FROM channel_metrics
ORDER BY failure_rate_pct DESC;

-- Engineering escalation priority: Web → App → USSD → Agent. Despite USSD handling 
-- the most volume (₦2,093,190.00) it is the third-most reliable channel. Web handles 
-- ₦1.5M in volume but loses 31.3% of transactions, approximately ₦749,800.00 in failed 
-- transaction volume every month that generates zero revenue. Agent is the reliability 
-- benchmark with zero failures and should be studied to understand what makes it the most resilient channel.
