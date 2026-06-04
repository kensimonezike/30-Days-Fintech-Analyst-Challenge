-- Query 1: Find channels where the failure rate exceeds 15%
-- Business question: Which channels have a reliability problem requiring escalation?
-- New concept: HAVING — filters groups AFTER aggregation (not individual rows)
-- PalmPay Analytics | Day 5 | January 2024

SELECT
    channel,
    COUNT(*)                                                        AS total_transactions,
    COUNT(CASE WHEN status = 'Failed' THEN 1 END)                  AS failed_count,
    ROUND(
        COUNT(CASE WHEN status = 'Failed' THEN 1 END) * 100.0
        / COUNT(*),
        1
    )                                                               AS failure_rate_pct
FROM transactions
GROUP BY channel
HAVING
    COUNT(CASE WHEN status = 'Failed' THEN 1 END) * 100.0
    / COUNT(*) > 15
ORDER BY failure_rate_pct DESC;

-- Result (channels exceeding 15% threshold):
-- Web  | 16 total | 5 failed | 31.2%  ← EXCEEDS — highest priority
-- App  | 10 total | 2 failed | 20.0%  ← EXCEEDS
--
-- Channels that did NOT appear (below threshold):
-- USSD | 16 total | 2 failed | 12.5%  (below threshold, not returned)
-- Agent|  8 total | 0 failed |  0.0%  (below threshold, not returned)
--
-- Key learning: HAVING filters entire groups after GROUP BY.
-- WHERE could not do this — the failure rate doesn't exist until after grouping.
-- You MUST repeat the full expression in HAVING (not the alias) because
-- PostgreSQL evaluates HAVING before SELECT aliases are assigned.
