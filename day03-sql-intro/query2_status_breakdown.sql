-- Query 2: Transaction breakdown by status with percentage
-- Business question: What is the overall success rate?
-- PalmPay Analytics | Day 3 | January 2024

SELECT
    status,
    COUNT(*)                                            AS transaction_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM transactions
GROUP BY status
ORDER BY transaction_count DESC;

-- Result:
-- Success  | 36 | 72.0%
-- Failed   |  9 | 18.0%
-- Pending  |  5 | 10.0%
-- Finding: 18% failure rate = ~₦1.1M in failed transaction volume
