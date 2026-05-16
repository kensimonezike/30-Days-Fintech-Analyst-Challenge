-- Query 4: Successful transaction volume by region
-- Business question: Which region generates the most revenue?
-- PalmPay Analytics | Day 3 | January 2024

SELECT
    region,
    COUNT(*)                    AS transaction_count,
    SUM(amount_ngn)             AS total_volume_ngn,
    ROUND(AVG(amount_ngn), 2)   AS avg_amount_ngn
FROM transactions
WHERE status = 'Success'
GROUP BY region
ORDER BY total_volume_ngn DESC;

-- Result:
-- Lagos         |  9 | ₦2,125,170.00 | avg ₦236,130
-- Kano          |  8 | ₦1,021,240.00 | avg ₦127,655
-- NULL          |  5 |   ₦995,720.00 | (missing region — data gap)
-- Port Harcourt |  5 |   ₦510,720.00 | avg ₦102,144
-- Abuja         |  5 |   ₦327,370.00 | avg ₦65,474
-- Ibadan        |  4 |   -₦16,620.00 | (negative due to raw data issues)
-- Finding: Lagos = 33% of clean volume with highest avg transaction value
