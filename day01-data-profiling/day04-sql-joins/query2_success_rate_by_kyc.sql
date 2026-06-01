-- Query 2: Transaction success rate broken down by KYC verification status
-- Business question: Do verified customers have better success rates?
-- JOIN type: INNER JOIN
-- New concept: CASE WHEN (SQL's IF statement inside aggregations)
-- PalmPay Analytics | Day 4 | January 2024

SELECT
    c.kyc_status,
    COUNT(*)                                                        AS total_transactions,
    COUNT(CASE WHEN t.status = 'Success' THEN 1 END)               AS successful_count,
    COUNT(CASE WHEN t.status = 'Failed'  THEN 1 END)               AS failed_count,
    COUNT(CASE WHEN t.status = 'Pending' THEN 1 END)               AS pending_count,
    ROUND(
        COUNT(CASE WHEN t.status = 'Success' THEN 1 END) * 100.0
        / COUNT(*),
        1
    )                                                               AS success_rate_pct
FROM transactions AS t
INNER JOIN customers AS c
    ON t.user_id = c.user_id
GROUP BY c.kyc_status
ORDER BY success_rate_pct DESC;

-- Result:
-- Pending  | 14 txns | success 11 (78.6%) | failed  0 (0.0%)  | pending 3
-- Verified | 36 txns | success 25 (69.4%) | failed  9 (25.0%) | pending 2
--
-- Surprising finding: Pending KYC customers had a HIGHER success rate (78.6%)
-- than Verified customers (69.4%). Verified customers had ALL 9 failures.
-- This warrants investigation — are failed transactions coming from a specific
-- subset of verified accounts? Possible fraud or system routing issue.
