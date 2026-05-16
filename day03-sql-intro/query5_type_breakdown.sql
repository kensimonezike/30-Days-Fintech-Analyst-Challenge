-- Query 5: Full breakdown by transaction type
-- Business question: Which type drives the most volume and revenue?
-- PalmPay Analytics | Day 3 | January 2024

SELECT
    transaction_type,
    COUNT(*) AS total_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS pct_of_transactions,
    SUM(amount_ngn) AS total_volume_ngn,
    ROUND(AVG(amount_ngn)::numeric, 2) AS avg_amount_ngn,
    MAX(amount_ngn) AS largest_transaction_ngn
FROM transactions
GROUP BY transaction_type
ORDER BY total_volume_ngn DESC;

-- Result:
-- Airtime      | 12 | 24% | ₦3,106,970 | avg ₦258,914 | max ₦462,810
-- Deposit      | 11 | 22% | ₦1,366,370 | avg ₦124,215 | max ₦473,150
-- Transfer     |  9 | 18% | ₦1,263,150 | avg ₦140,350 | max ₦386,320
-- Withdrawal   | 11 | 22% |   ₦786,120 | avg ₦71,465  | max ₦472,840
-- Bill Payment |  7 | 14% |  -₦377,210 | (negative — raw data issue)
-- Finding: Airtime = #1 by volume AND highest avg value despite not being largest single type
