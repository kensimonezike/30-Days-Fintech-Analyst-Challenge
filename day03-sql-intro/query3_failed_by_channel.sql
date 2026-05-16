-- Query 3: Failed transactions by channel
-- Business question: Which channel has the worst failure rate?
-- PalmPay Analytics | Day 3 | January 2024

SELECT
    channel,
    COUNT(*) AS failed_transactions
FROM transactions
WHERE status = 'Failed'
GROUP BY channel
ORDER BY failed_transactions DESC
LIMIT 4;

-- Result:
-- Web   | 5 failures (55% of all failures)
-- USSD  | 2 failures
-- App   | 2 failures
-- Agent | 0 failures
-- Finding: Web channel is highest priority for engineering reliability fix
