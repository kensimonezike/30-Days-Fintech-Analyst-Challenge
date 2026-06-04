# Day 05. Advanced SQL: HAVING, Subqueries, CTEs + Fintech KPIs

**Tool:** PostgreSQL + DBeaver

---

## Business Scenario

My manager asked me to go beyond basic GROUP BY queries and start calculating
actual business KPIs directly in SQL. Today I learned three new SQL concepts:
HAVING, Subqueries, and CTEs, and used them to build a complete fintech KPI
report for January 2024 covering success rate, failure rate, ATV, ARPU, and
transaction velocity.

---

## New SQL Concepts Learned

| Concept | Plain English | When to use it |
|---|---|---|
| `HAVING` | Filters entire groups AFTER aggregation, like WHERE but for GROUP BY results | When your filter condition contains COUNT, SUM, AVG, MAX, or MIN |
| **Subquery** | A query nested inside another query. The inner query runs first | When you need to compare each row against a calculated value like AVG |
| **CTE** (`WITH`) | A named temporary result defined at the top, referenced like a table below | When logic has multiple steps or you need to reuse a calculated result |
| `NULLIF(x, 0)` | Returns NULL instead of 0, preventing divide-by-zero crashes | Any time you divide by a COUNT or SUM that could theoretically be zero |
| `::numeric` cast | Forces integer values to produce decimal division results | Dividing two integers where you need a decimal answer (e.g. velocity = 5/2 = 2.5 not 2) |

---

## The 5 Core Fintech KPIs

| KPI | Definition | SQL Pattern | January Result |
|---|---|---|---|
| **Transaction Success Rate** | % of transactions that completed | `COUNT(CASE WHEN status='Success' THEN 1 END) * 100.0 / COUNT(*)` | 72.0% |
| **Failure Rate** | % of transactions that failed | `COUNT(CASE WHEN status='Failed' THEN 1 END) * 100.0 / COUNT(*)` | 18.0% |
| **Average Transaction Value (ATV)** | Mean value of successful transactions | `SUM(amount) / COUNT(successful_txns)` | ₦150,078.89 |
| **ARPU** | Revenue divided by unique active users | `SUM(amount) / COUNT(DISTINCT user_id)` | ₦245,583.64 |
| **Transaction Velocity** | Average transactions per user | `COUNT(txns) / COUNT(DISTINCT user_id)` | 2.27 txns/user |

---

## Query 1. Channels Where Failure Rate Exceeds 15%

**Business question:** Which channels have a reliability problem requiring engineering escalation?
**New concept:** `HAVING` — filtering groups after aggregation.

```sql
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
```

**Result:**

| channel | total_transactions | failed_count | failure_rate_pct |
|---|---|---|---|
| Web | 16 | 5 | 31.2% |

> 💡 **Key learning:** App (10.0%), USSD (12.5%), and Agent (0.0%) did NOT appear because HAVING excluded them.
> Their failure rates were below the 15% threshold. This is what HAVING does:
> it removes entire groups that fail the condition. WHERE cannot do this because the
> failure rate does not exist as a value until AFTER GROUP BY runs.
>
> NOTE: You cannot use the alias `failure_rate_pct` in the HAVING clause.
> PostgreSQL evaluates HAVING before SELECT aliases are assigned, you must
> repeat the full expression.

**Business finding:** 1 of 4 channels exceeded the 15% failure rate threshold in January.
Web at 31.2%, nearly 1 in 3 transactions on Web failed.

---

## Query 2. Transactions Above the Average Value (High-Value Flag)

**Business question:** Which transactions exceeded the January average and should be flagged for fraud review?
**New concept:** Subquery inside `WHERE`.

```sql
SELECT
    transaction_id,
    user_id,
    transaction_date,
    transaction_type,
    amount_ngn,
    status,
    ROUND(
        (
            amount_ngn - (
                SELECT AVG(amount_ngn)
                FROM transactions
                WHERE amount_ngn > 0
            )
        )::numeric,
        2
    ) AS above_avg_by_ngn
FROM transactions
WHERE amount_ngn > (
    SELECT AVG(amount_ngn)
    FROM transactions
    WHERE amount_ngn > 0
)
ORDER BY amount_ngn DESC;
```

**Key numbers:**
- Average transaction value (positive only): **₦142,390.00**
- Transactions above average: **15 of 50 (30%)**

**Top 5 high-value transactions:**

| transaction_id | amount_ngn | status | type | above avg by |
|---|---|---|---|---|
| TXN-0033 | 473,150.00 | Success | Deposit | ₦330,760 |
| TXN-0046 | 472,840.00 | Success | Withdrawal | ₦330,450 |
| TXN-0041 | 462,810.00 | Success | Airtime | ₦320,420 |
| TXN-0039 | 459,000.00 | Pending | Bill Payment | ₦316,610 |
| TXN-0003 | 441,650.00 | Success | Deposit | ₦299,260 |

> **TXN-0039 is flagged as both high-value AND Pending**, a combination that
> warrants immediate investigation. A large Pending transaction could indicate
> a processing delay, a routing failure, or a held transaction pending fraud review.

**Business finding:** 15 transactions (30%) exceeded the January average of ₦142,390.
The largest single transaction (TXN-0033 at ₦473,150) was 3.3x the average,
a standard AML flag threshold at most fintech companies. All 15 should be
included in the monthly high-value transaction review log.

---

## Query 3. ARPU and Transaction Velocity by Account Tier

**Business question:** Which account tier delivers the most revenue per user?
**New concept:** CTE (`WITH` clause) + ARPU and velocity KPIs.

```sql
WITH tier_stats AS (
    SELECT
        c.account_tier,
        COUNT(t.transaction_id) AS total_transactions,
        COUNT(DISTINCT t.user_id) AS active_users,
        SUM(
            CASE
                WHEN t.status = 'Success'
                     AND t.amount_ngn > 0
                THEN t.amount_ngn
                ELSE 0
            END
        ) AS successful_volume
    FROM transactions t
    INNER JOIN customers c
        ON t.user_id = c.user_id
    GROUP BY c.account_tier
)
SELECT
    account_tier,
    total_transactions,
    active_users,
    successful_volume,
    ROUND(
        (successful_volume / NULLIF(active_users, 0))::numeric,
        2
    ) AS arpu_ngn,
    ROUND(
        total_transactions::numeric / NULLIF(active_users, 0),
        2
    ) AS txn_velocity
FROM tier_stats
ORDER BY arpu_ngn DESC;
```

**Result:**

| account_tier | total_transactions | active_users | successful_volume | arpu_ngn | txn_velocity |
|---|---|---|---|---|---|
| VIP | 14 | 7 | 1,585,860.00 | 226,551.43 | 2.00 |
| Standard | 35 | 14 | 3,416,940.00 | 244,067.14 | 2.50 |
| Premium | 1 | 1 | 386,320.00 | 386,320.00 | 1.00 |

> **Unexpected finding:** Premium tier has the HIGHEST ARPU at ₦386,320.00,
> 70.5% higher than VIP and 58.3% higher than Standard. However,
> Premium customers also have the lowest transaction velocity (1.00 vs
> 2.00 for VIP and 2.50 for Standard). This result should be interpreted
> with caution because the Premium tier contains only one active user and
> one transaction. While the customer generated the highest value per
> user, the sample size is too small to determine whether Premium
> customers are genuinely more valuable or if this is an outlier.
> Additional Premium customer activity is needed before making product,
> pricing, or engagement decisions based on this segment.

**Business finding:** VIP customers generate the highest ARPU at ₦309,430/user —
13% more than Standard and 94% more than Premium. However, Standard tier drives
the most total volume at ₦3,517,280 due to volume of users (13 vs 3 for VIP).
The most urgent action is investigating why Premium ARPU is the lowest of all
three tiers — this should not be the case in a well-designed tier system.

---

## Query 4. Power Users (3+ Transactions in January)

**Business question:** Who are the most engaged customers — our retention priority list?
**Concept:** `HAVING` on user-level `GROUP BY`.

```sql
SELECT
    t.user_id, c.full_name, c.account_tier, c.city,
    COUNT(t.transaction_id)             AS transaction_count,
    SUM(t.amount_ngn)                   AS total_volume_ngn,
    ROUND(AVG(t.amount_ngn)::numeric, 2)         AS avg_transaction_ngn
FROM transactions t
INNER JOIN customers c ON t.user_id = c.user_id
GROUP BY t.user_id, c.full_name, c.account_tier, c.city
HAVING COUNT(t.transaction_id) >= 3
ORDER BY transaction_count DESC, total_volume_ngn DESC;
```

**Result (10 power users):**

| User ID   | Name               | Tier     | City          | Metric 1 | Metric 2    | Metric 3     |
|-----------|--------------------|----------|---------------|----------|-------------|--------------|
| USR-2679  | Babatunde Oladele  | Standard | Abuja         | 5        | 993,820.0    | 198,764.00    |
| USR-9935  | Uche Nnamdi        | VIP      | Kano          | 4        | 376,950.0    | 942,37.50     |
| USR-5506  | Zainab Umar        | Standard | Ibadan        | 4        | 134,950.0    | 337,37.50     |
| USR-1106  | Adaeze Okonkwo     | Standard | Abuja         | 4        | 101,210.0    | 253,02.50     |
| USR-2424  | Chukwudi Eze       | Standard | Ibadan        | 3        | 859,820.0    | 286,606.67    |
| USR-8359  | Halima Yusuf       | Standard | Port Harcourt | 3        | 801,230.0    | 267,076.67    |
| USR-7912  | Blessing Eze       | Standard | Lagos         | 3        | 495,420.0    | 165,140.00    |
| USR-1409  | Emeka Okafor       | Standard | Lagos         | 3        | 479,170.0    | 159,723.33    |
| USR-3615  | Obiageli Nwosu     | Standard | Ibadan        | 3        | 476,310.0    | 158,770.00    |
| USR-7924  | Taiwo Adekoya      | VIP      | Port Harcourt | 3        | 224,080.0    | 74,693.33     |

**Business finding:** 10 of 22 active users (45%) are power users with 3+ transactions,
a strong engagement signal for a 31-day period. Babatunde Oladele leads with 5 transactions
and ₦993,820 in volume on a Standard account, the strongest tier upgrade candidate.
7 of the 10 power users are Standard tier, reinforcing the earlier finding that
Standard tier labels underrepresent actual customer value.
These 10 customers should receive priority customer success attention and loyalty rewards.

---

## Query 5. Complete Channel KPI Report

**Business question:** Full reliability breakdown per channel with all metrics.
**Concept:** CTE + multiple KPIs + `NULLIF` for safe division.

```sql
WITH channel_metrics AS (
    SELECT
        channel,
        COUNT(*) AS total_txns,
        -- Using Postgres FILTER clause for cleaner code
        COUNT(*) FILTER (WHERE status = 'Success') AS success_count,
        COUNT(*) FILTER (WHERE status = 'Failed')  AS failed_count,
        COUNT(*) FILTER (WHERE status = 'Pending') AS pending_count,
        -- Coalesce ensures we get 0 instead of NULL if there are no successful txns
        COALESCE(SUM(amount_ngn) FILTER (WHERE status = 'Success' AND amount_ngn > 0), 0) AS successful_volume
    FROM transactions
    GROUP BY channel
)
SELECT
    channel, 
    total_txns, 
    success_count, 
    failed_count, 
    pending_count,
    ROUND((success_count::numeric / NULLIF(total_txns, 0)) * 100, 1) AS success_rate_pct,
    ROUND((failed_count::numeric  / NULLIF(total_txns, 0)) * 100, 1) AS failure_rate_pct,
    successful_volume,
    ROUND(successful_volume::numeric / NULLIF(success_count, 0), 2)  AS avg_success_value_ngn
FROM channel_metrics
ORDER BY failure_rate_pct DESC;
```

**Result:**

| channel | total_txns | success_count | failed_count | pending_count | success_rate_pct | failure_rate_pct | successful_volume | avg_success_value_ngn |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Web | 16 | 10 | 5 | 1 | 62.5 | 31.3 | 1499600.0 | 149960.00 |
| USSD | 16 | 12 | 2 | 1 | 75.0 | 12.5 | 2093190.0 | 174432.50 |
| App | 10 | 6 | 1 | 1 | 60.0 | 10.0 | 886770.0 | 147795.00 |
| Agent | 8 | 5 | 0 | 1 | 62.5 | 0.0 | 909560.0 | 181912.00 |

**Business finding:** Engineering escalation priority: Web → App → USSD → Agent. Despite USSD handling the most volume (₦2,093,190.00) it is the third-most reliable channel. Web handles ₦1.5M in volume but loses 31.3% of transactions, approximately ₦749,800.00 in failed transaction volume every month that generates zero revenue. Agent is the reliability benchmark with zero failures and should be studied to understand what makes it the most resilient channel.

---

## Query 6. Executive KPI Summary (All 5 KPIs)

**Business question:** What is the complete January 2024 performance picture in one view?
**Concept:** Chained CTEs: each CTE builds on the previous one.

```sql
WITH clean_txns AS (
    SELECT * 
    FROM transactions 
    WHERE amount_ngn > 0
),
kpi_base AS (
    SELECT
        COUNT(*) AS total_transactions,
        COUNT(DISTINCT user_id) AS active_users,
        COUNT(CASE WHEN status = 'Success' THEN 1 END) AS successful_txns,
        COUNT(CASE WHEN status = 'Failed' THEN 1 END) AS failed_txns,
        SUM(CASE WHEN status = 'Success' THEN amount_ngn ELSE 0 END) AS successful_volume
    FROM clean_txns
)

SELECT
    'January 2024' AS period,
    total_transactions,
    active_users,

    ROUND((successful_txns * 100::numeric / NULLIF(total_transactions, 0))::numeric, 1) AS success_rate_pct,

    ROUND((failed_txns * 100::numeric / NULLIF(total_transactions, 0))::numeric, 1) AS failure_rate_pct,

    ROUND((successful_volume / NULLIF(successful_txns, 0))::numeric, 2) AS avg_txn_value_ngn,

    ROUND((successful_volume / NULLIF(active_users, 0))::numeric, 2) AS arpu_ngn,

    ROUND((total_transactions::numeric / NULLIF(active_users, 0))::numeric, 2) AS txn_velocity,

    successful_volume AS total_volume_ngn
FROM kpi_base;
```

**Result — January 2024 Executive KPI Card (1 row):**

| Period        | total_transactions | active_users | success_rate_pct | failure_rate_pct | avg_txn_value_ngn | arpu_ngn     | txn_velocity | total_volume_ngn |
|---------------|-------------------|--------------|------------------|------------------|-------------------|--------------|----------------------|------------------|
| January 2024  | 48                | 21           | 66.7             | 16.7             | 168,410.00        | 256,624.76   | 2.29                 | 5,389,120.00     |

> 🔴 **Critical flags:** Success rate of 72.0% is well below the 95% industry benchmark.
> Failure rate of 18.0% exceeds the 5% threshold significantly.
> These are the top two priorities for the engineering and product teams in February.

**Business finding:** January 2024 KPI summary shows PalmPay processed 48 transactions from 21 active users, generating ₦5,389,120 in total volume. The 66.7% success rate and 16.7% failure rate indicate moderate transaction reliability, with a significant portion of transactions still not completing successfully. An ARPU of ₦256,624.76 and transaction velocity of 2.29 transactions per user suggest moderate but concentrated user engagement within the active base. This performance establishes the January baseline against which subsequent monthly improvements in reliability, user engagement, and revenue efficiency will be measured.

---

## Key Lessons Learned

1. **HAVING vs WHERE, the most common beginner mistake**: WHERE filters rows before
   grouping, HAVING filters groups after grouping. If your condition uses COUNT/SUM/AVG,
   it belongs in HAVING. If it uses a column value directly, it belongs in WHERE.
   You can use both in the same query.

2. **Never use alias names in HAVING**: PostgreSQL evaluates HAVING before SELECT
   aliases are assigned. `HAVING failure_rate_pct > 15` errors even though the
   alias is defined in the same query. Repeat the full expression.

3. **Always protect divisions with NULLIF**: `ROUND(volume / NULLIF(count, 0), 2)`
   returns NULL instead of crashing when count is zero. In production dashboards,
   a divide-by-zero error with no NULLIF protection will break your entire report.

4. **CTEs make complex queries readable and debuggable**: breaking a 3-step
   calculation into 3 named CTEs means you can test each step independently.
   A nested subquery 4 levels deep is impossible to debug at 9pm before a board meeting.

5. **Integer division silently truncates in PostgreSQL**: `5 / 2 = 2`, not `2.5`.
   Always cast to numeric when dividing counts: `count::numeric / other_count`
   or multiply by `1.0`. This has corrupted real analyst reports that were never caught.

6. **The 72% success rate is the headline finding**: every other metric is context.
   When presenting this KPI card to a non-technical audience, lead with the success
   rate because it is the most universally understood measure of platform reliability.

---

## Files in This Folder

```
day05-advanced-sql/
├── README.md                                      ← this file
├── query1_channels_above_15pct_failure.sql
├── query2_above_average_transactions.sql
├── query3_arpu_velocity_by_tier.sql
├── query4_power_users.sql
├── query5_channel_kpi_full.sql
├── query6_executive_kpi_summary.sql             
└── screenshots/
    ├── query1_result.png
    ├── query2_result.png
    ├── query3_result.png
    ├── query4_result.png
    ├── query5_result.png
    └── query6_kpi_card.png                      
```

---
