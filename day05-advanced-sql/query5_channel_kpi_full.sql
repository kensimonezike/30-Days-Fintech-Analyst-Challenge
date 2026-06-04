-- Query 5: Complete channel reliability KPI report
-- Business question: Full success/failure breakdown per channel with all metrics
-- Concept: CTE + multiple KPIs + NULLIF for safe division
-- New function: NULLIF(expr, value) — returns NULL instead of value to prevent ÷0 crash
-- PalmPay Analytics | Day 5 | January 2024

WITH channel_metrics AS (
    SELECT
        channel,
        COUNT(*)                                              AS total_txns,
        COUNT(CASE WHEN status = 'Success' THEN 1 END)       AS success_count,
        COUNT(CASE WHEN status = 'Failed'  THEN 1 END)       AS failed_count,
        COUNT(CASE WHEN status = 'Pending' THEN 1 END)       AS pending_count,
        SUM(CASE WHEN status  = 'Success'
             AND amount_ngn > 0 THEN amount_ngn ELSE 0 END)  AS successful_volume
    FROM transactions
    GROUP BY channel
)
SELECT
    channel,
    total_txns,
    success_count,
    failed_count,
    pending_count,
    ROUND(success_count * 100.0 / total_txns, 1)              AS success_rate_pct,
    ROUND(failed_count  * 100.0 / total_txns, 1)              AS failure_rate_pct,
    successful_volume,
    ROUND(successful_volume / NULLIF(success_count, 0), 2)    AS avg_success_value_ngn
FROM channel_metrics
ORDER BY failure_rate_pct DESC;

-- Result:
-- Channel | Total | Success | Failed | Pending | Succ% | Fail% | Volume      | AvgValue
-- Web     |    16 |      10 |      5 |       1 | 62.5% | 31.2% | 1,499,600   | 149,960
-- App     |    10 |       7 |      2 |       1 | 70.0% | 20.0% |   893,870   | 127,696
-- USSD    |    16 |      13 |      2 |       1 | 81.2% | 12.5% | 2,097,850   | 161,373
-- Agent   |     8 |       6 |      0 |       2 | 75.0% |  0.0% |   911,520   | 151,920
--
-- Engineering escalation order: Web (31.2%) → App (20.0%) → USSD (12.5%) → Agent (0.0%)
-- Despite having the most volume (₦2,097,850), USSD is the 3rd most reliable channel.
-- Web handles ₦1.5M but loses 31.2% of transactions — a significant revenue leakage.
-- Agent is the only channel with zero failures this month — benchmark for reliability.
