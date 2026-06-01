-- Query 1: Total transaction volume and count by account tier
-- Business question: Which account tier generates the most transaction volume?
-- JOIN type: INNER JOIN (only transactions with a matching customer record)
-- PalmPay Analytics | Day 4 | January 2024

SELECT
    c.account_tier,
    COUNT(t.transaction_id)             AS transaction_count,
    SUM(t.amount_ngn)                   AS total_volume_ngn,
    ROUND(AVG(t.amount_ngn), 2)         AS avg_transaction_ngn,
    MAX(t.amount_ngn)                   AS largest_transaction_ngn
FROM transactions AS t
INNER JOIN customers AS c
    ON t.user_id = c.user_id
WHERE t.status = 'Success'
  AND t.amount_ngn > 0
GROUP BY c.account_tier
ORDER BY total_volume_ngn DESC;

-- Result:
-- Standard | 28 txns | ₦3,430,660 (63.5%) | avg ₦122,524 | max ₦472,840
-- VIP      |  7 txns | ₦1,585,860 (29.4%) | avg ₦226,551 | max ₦473,150
-- Premium  |  1 txns |   ₦386,320 ( 7.2%) | avg ₦386,320 | max ₦386,320
--
-- Finding: Standard tier drives 63.5% of volume by count but VIP averages
-- 85% higher per transaction. VIP retention is disproportionately valuable.
