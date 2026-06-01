-- Query 3: Top 10 customers by total transaction spend
-- Business question: Who are our highest-value customers in January?

-- JOIN type: INNER JOIN

SELECT
    c.full_name,
    c.account_tier,
    c.city,
    c.kyc_status,
    COUNT(t.transaction_id)             	AS total_transactions,
    SUM(t.amount_ngn)                   	AS total_spend_ngn,
    ROUND(AVG(t.amount_ngn)::numeric, 2)   	AS avg_transaction_ngn
FROM transactions AS t
INNER JOIN customers AS c
    ON t.user_id = c.user_id
GROUP BY c.full_name, c.account_tier, c.city, c.kyc_status
ORDER BY total_spend_ngn DESC
LIMIT 10;

-- Result (Top 10 by total spend):
-- Babatunde Oladele  (Standard, Abuja)         | 5 txns | ₦993,820  | avg ₦198,764
-- Chukwudi Eze       (Standard, Ibadan)        | 3 txns | ₦859,820  | avg ₦286,607
-- Halima Yusuf       (Standard, Port Harcourt) | 3 txns | ₦801,230  | avg ₦267,077
-- Blessing Eze       (Standard, Lagos)         | 3 txns | ₦495,420  | avg ₦165,140
-- Emeka Okafor       (Standard, Lagos)         | 3 txns | ₦479,170  | avg ₦159,723
-- Aisha Musa         (VIP,      Ibadan)        | 2 txns | ₦477,590  | avg ₦238,795
-- Obiageli Nwosu     (Standard, Ibadan)        | 3 txns | ₦476,310  | avg ₦158,770
-- Yetunde Balogun    (Standard, Port Harcourt) | 1 txns | ₦391,910  | avg ₦391,910
-- Fatima Al-Hassan   (Premium,  Ibadan)        | 1 txns | ₦386,320  | avg ₦386,320
-- Uche Nnamdi        (VIP,      Kano)          | 4 txns | ₦376,950  | avg  ₦94,238
--
-- Key insight: The #1 spender (Babatunde Oladele) is a Standard tier customer:
-- a strong candidate for a Premium upgrade offer.
