-- Query 1: Total transactions, volume, and average transaction value
-- Business question: How many transactions were processed in January?
-- PalmPay Analytics | Day 3 | January 2024

SELECT
    COUNT(*)                    AS total_transactions,
    SUM(amount_ngn)             AS total_volume_ngn,
    ROUND(AVG(amount_ngn), 2)   AS avg_transaction_ngn
FROM transactions;

-- Result: 50 transactions | ₦6,145,400.00 total | ₦122,908.00 average
-- Note: includes 2 negative amounts from raw data — clean volume is ₦6,834,720.00
