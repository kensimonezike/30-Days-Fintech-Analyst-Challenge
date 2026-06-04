-- Query 4: Identify power users — customers with 3 or more transactions in January
-- Business question: Who are our most engaged customers this month?
-- Concept: HAVING on user-level GROUP BY — cannot use WHERE for this filter
-- PalmPay Analytics | Day 5 | January 2024

SELECT
    t.user_id,
    c.full_name,
    c.account_tier,
    c.city,
    COUNT(t.transaction_id)             AS transaction_count,
    SUM(t.amount_ngn)                   AS total_volume_ngn,
    ROUND(AVG(t.amount_ngn), 2)         AS avg_transaction_ngn
FROM transactions t
INNER JOIN customers c ON t.user_id = c.user_id
GROUP BY t.user_id, c.full_name, c.account_tier, c.city
HAVING COUNT(t.transaction_id) >= 3
ORDER BY transaction_count DESC, total_volume_ngn DESC;

-- Result (10 power users with 3+ transactions):
-- Babatunde Oladele (Standard, Abuja)         | 5 txns | ₦993,820  | avg ₦198,764
-- Adaeze Okonkwo    (Standard, Abuja)         | 4 txns | ₦101,210  | avg ₦25,303
-- Uche Nnamdi       (Standard, Kano)          | 4 txns | ₦376,950  | avg ₦94,238
-- Zainab Umar       (VIP,      Ibadan)        | 4 txns | ₦134,950  | avg ₦33,738
-- Obiageli Nwosu    (Premium,  Ibadan)        | 3 txns | ₦476,310  | avg ₦158,770
-- Chukwudi Eze      (Standard, Ibadan)        | 3 txns | ₦859,820  | avg ₦286,607
-- Taiwo Adekoya     (Premium,  Port Harcourt) | 3 txns | ₦224,080  | avg ₦74,693
-- Blessing Eze      (Standard, Lagos)         | 3 txns | ₦495,420  | avg ₦165,140
-- Halima Yusuf      (Standard, Port Harcourt) | 3 txns | ₦801,230  | avg ₦267,077
-- Emeka Okafor      (Standard, Lagos)         | 3 txns | ₦479,170  | avg ₦159,723
--
-- 10 of 22 active users (45%) are power users — a strong engagement signal.
-- The top power user (Babatunde Oladele) is Standard tier — strong upgrade candidate.
-- 7 of the 10 power users are Standard tier — suggesting tier labels underrepresent
-- actual engagement levels.
