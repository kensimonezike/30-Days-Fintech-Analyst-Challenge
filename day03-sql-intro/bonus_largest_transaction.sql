-- Bonus: Find the single largest transaction and identify the customer
-- Business question: Which transaction was the highest value in January?
-- PalmPay Analytics | Day 3 | January 2024

SELECT *
FROM transactions
ORDER BY amount_ngn DESC
LIMIT 1;

-- Result: TXN-0033 | USR-3286 | 15-Jan-2024 | Deposit | ₦473,150 | Success
-- At 3.8x the average value (₦122,908), this would trigger an AML review flag
-- in a production transaction monitoring system
