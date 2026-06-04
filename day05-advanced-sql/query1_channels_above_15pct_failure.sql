-- Query 1: Find channels where the failure rate exceeds 15%
-- Business question: Which channels have a reliability problem requiring escalation?

SELECT
    channel,
    COUNT(*)                                                       AS total_transactions,
    COUNT(CASE WHEN status = 'Failed' THEN 1 END)                  AS failed_count,
    ROUND(
        COUNT(CASE WHEN status = 'Failed' THEN 1 END) * 100.0
        / COUNT(*), 1
    )                                                              AS failure_rate_pct
FROM transactions
GROUP BY channel
HAVING
    COUNT(CASE WHEN status = 'Failed' THEN 1 END) * 100.0
    / COUNT(*) > 15
ORDER BY failure_rate_pct DESC;

-- Result (channels exceeding 15% threshold):
-- Web  | 16 total | 5 failed | 31.2%  ← EXCEEDS — highest priority

