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

## Query 1 — Channels Where Failure Rate Exceeds 15%

**Business question:** Which channels have a reliability problem requiring engineering escalation?
**New concept:** `HAVING` — filtering groups after aggregation.

```sql
SELECT
    channel,
    COUNT(*)                                                        AS total_transactions,
    COUNT(CASE WHEN status = 'Failed' THEN 1 END)                  AS failed_count,
    ROUND(
        COUNT(CASE WHEN status = 'Failed' THEN 1 END) * 100.0
        / COUNT(*), 1
    )                                                               AS failure_rate_pct
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
| App | 10 | 2 | 20.0% |

> 💡 **Key learning:** USSD (12.5%) and Agent (0.0%) did NOT appear — HAVING excluded them
> because their failure rates were below the 15% threshold. This is what HAVING does:
> it removes entire groups that fail the condition. WHERE cannot do this because the
> failure rate does not exist as a value until AFTER GROUP BY runs.
>
> ⚠️ You cannot use the alias `failure_rate_pct` in the HAVING clause.
> PostgreSQL evaluates HAVING before SELECT aliases are assigned — you must
> repeat the full expression.

**Business finding:** 2 of 4 channels exceeded the 15% failure rate threshold in January.
Web was the worst at 31.2% — nearly 1 in 3 transactions on Web failed.
App at 20.0% is also critical. Engineering should prioritise Web channel infrastructure
before the February growth campaign, as it is currently losing approximately
₦750,000 in failed transaction volume per month.

---

## Query 2 — Transactions Above the Average Value (High-Value Flag)

**Business question:** Which transactions exceeded the January average and should be flagged for fraud review?
**New concept:** Subquery inside `WHERE`.

```sql
SELECT
    transaction_id, user_id, transaction_date,
    transaction_type, amount_ngn, status,
    ROUND(amount_ngn - (
        SELECT AVG(amount_ngn) FROM transactions WHERE amount_ngn > 0
    ), 2)                                   AS above_avg_by_ngn
FROM transactions
WHERE amount_ngn > (
    SELECT AVG(amount_ngn) FROM transactions WHERE amount_ngn > 0
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

> ⚠️ **TXN-0039 is flagged as both high-value AND Pending** — a combination that
> warrants immediate investigation. A large Pending transaction could indicate
> a processing delay, a routing failure, or a held transaction pending fraud review.

**Business finding:** 15 transactions (30%) exceeded the January average of ₦142,390.
The largest single transaction (TXN-0033 at ₦473,150) was 3.3x the average —
a standard AML flag threshold at most fintech companies. All 15 should be
included in the monthly high-value transaction review log.

---

## Query 3 — ARPU and Transaction Velocity by Account Tier

**Business question:** Which account tier delivers the most revenue per user?
**New concept:** CTE (`WITH` clause) + ARPU and velocity KPIs.

```sql
WITH tier_stats AS (
    SELECT
        c.account_tier,
        COUNT(t.transaction_id)                                     AS total_transactions,
        COUNT(DISTINCT t.user_id)                                   AS active_users,
        SUM(CASE WHEN t.status = 'Success'
             AND t.amount_ngn > 0 THEN t.amount_ngn ELSE 0 END)    AS successful_volume
    FROM transactions t
    INNER JOIN customers c ON t.user_id = c.user_id
    GROUP BY c.account_tier
)
SELECT
    account_tier,
    total_transactions,
    active_users,
    successful_volume,
    ROUND(successful_volume / NULLIF(active_users, 0), 2)           AS arpu_ngn,
    ROUND(total_transactions::numeric / NULLIF(active_users, 0), 2) AS txn_velocity
FROM tier_stats
ORDER BY arpu_ngn DESC;
```

**Result:**

| account_tier | total_transactions | active_users | successful_volume | arpu_ngn | txn_velocity |
|---|---|---|---|---|---|
| VIP | 8 | 3 | 928,290.00 | 309,430.00 | 2.67 |
| Standard | 32 | 13 | 3,517,280.00 | 270,560.00 | 2.46 |
| Premium | 10 | 6 | 957,270.00 | 159,545.00 | 1.67 |

> 💡 **Unexpected finding:** Premium tier has the LOWEST ARPU at ₦159,545 —
> 48% below VIP and 41% below Standard. Premium customers also have the lowest
> transaction velocity (1.67 vs 2.67 for VIP). This is counter-intuitive:
> Premium should sit between Standard and VIP but it is underperforming both.
> Possible explanations: Premium customers are misclassified, the Premium product
> lacks features that drive engagement, or Premium customers use competitor platforms
> for high-value transactions.

**Business finding:** VIP customers generate the highest ARPU at ₦309,430/user —
13% more than Standard and 94% more than Premium. However, Standard tier drives
the most total volume at ₦3,517,280 due to volume of users (13 vs 3 for VIP).
The most urgent action is investigating why Premium ARPU is the lowest of all
three tiers — this should not be the case in a well-designed tier system.

---

## Query 4 — Power Users (3+ Transactions in January)

**Business question:** Who are the most engaged customers — our retention priority list?
**Concept:** `HAVING` on user-level `GROUP BY`.

```sql
SELECT
    t.user_id, c.full_name, c.account_tier, c.city,
    COUNT(t.transaction_id)             AS transaction_count,
    SUM(t.amount_ngn)                   AS total_volume_ngn,
    ROUND(AVG(t.amount_ngn), 2)         AS avg_transaction_ngn
FROM transactions t
INNER JOIN customers c ON t.user_id = c.user_id
GROUP BY t.user_id, c.full_name, c.account_tier, c.city
HAVING COUNT(t.transaction_id) >= 3
ORDER BY transaction_count DESC, total_volume_ngn DESC;
```

**Result (10 power users):**

| full_name | account_tier | city | txn_count | total_volume | avg_txn |
|---|---|---|---|---|---|
| Babatunde Oladele | Standard | Abuja | 5 | 993,820.00 | 198,764.00 |
| Adaeze Okonkwo | Standard | Abuja | 4 | 101,210.00 | 25,302.50 |
| Uche Nnamdi | VIP | Kano | 4 | 376,950.00 | 94,237.50 |
| Zainab Umar | VIP | Ibadan | 4 | 134,950.00 | 33,737.50 |
| Obiageli Nwosu | Premium | Ibadan | 3 | 476,310.00 | 158,770.00 |
| Chukwudi Eze | Standard | Ibadan | 3 | 859,820.00 | 286,606.67 |
| Taiwo Adekoya | Premium | Port Harcourt | 3 | 224,080.00 | 74,693.33 |
| Blessing Eze | Standard | Lagos | 3 | 495,420.00 | 165,140.00 |
| Halima Yusuf | Standard | Port Harcourt | 3 | 801,230.00 | 267,076.67 |
| Emeka Okafor | Standard | Lagos | 3 | 479,170.00 | 159,723.33 |

**Business finding:** 10 of 22 active users (45%) are power users with 3+ transactions —
a strong engagement signal for a 31-day period. Babatunde Oladele leads with 5 transactions
and ₦993,820 in volume on a Standard account — the strongest tier upgrade candidate.
7 of the 10 power users are Standard tier, reinforcing the earlier finding that
Standard tier labels underrepresent actual customer value.
These 10 customers should receive priority customer success attention and loyalty rewards.

---

## Query 5 — Complete Channel KPI Report

**Business question:** Full reliability breakdown per channel with all metrics.
**Concept:** CTE + multiple KPIs + `NULLIF` for safe division.

```sql
WITH channel_metrics AS (
    SELECT
        channel,
        COUNT(*)                                              AS total_txns,
        COUNT(CASE WHEN status = 'Success' THEN 1 END)       AS success_count,
        COUNT(CASE WHEN status = 'Failed'  THEN 1 END)       AS failed_count,
        COUNT(CASE WHEN status = 'Pending' THEN 1 END)       AS pending_count,
        SUM(CASE WHEN status = 'Success'
             AND amount_ngn > 0 THEN amount_ngn ELSE 0 END)  AS successful_volume
    FROM transactions
    GROUP BY channel
)
SELECT
    channel, total_txns, success_count, failed_count, pending_count,
    ROUND(success_count * 100.0 / total_txns, 1)             AS success_rate_pct,
    ROUND(failed_count  * 100.0 / total_txns, 1)             AS failure_rate_pct,
    successful_volume,
    ROUND(successful_volume / NULLIF(success_count, 0), 2)   AS avg_success_value_ngn
FROM channel_metrics
ORDER BY failure_rate_pct DESC;
```

**Result:**

| channel | total | success | failed | pending | succ% | fail% | volume | avg_value |
|---|---|---|---|---|---|---|---|---|
| Web | 16 | 10 | 5 | 1 | 62.5% | 31.2% | 1,499,600 | 149,960 |
| App | 10 | 7 | 2 | 1 | 70.0% | 20.0% | 893,870 | 127,696 |
| USSD | 16 | 13 | 2 | 1 | 81.2% | 12.5% | 2,097,850 | 161,373 |
| Agent | 8 | 6 | 0 | 2 | 75.0% | 0.0% | 911,520 | 151,920 |

**Business finding:** Engineering escalation priority: Web → App → USSD → Agent.
Despite USSD handling the most volume (₦2,097,850) it is the third-most reliable channel.
Web handles ₦1.5M in volume but loses 31.2% of transactions — approximately
₦467,000 in failed transaction volume every month that generates zero revenue.
Agent is the reliability benchmark with zero failures and should be studied
to understand what makes it the most resilient channel.

---

## Query 6 — Executive KPI Summary (All 5 KPIs)

**Business question:** What is the complete January 2024 performance picture in one view?
**Concept:** Chained CTEs — each CTE builds on the previous one.

```sql
WITH
clean_txns AS (
    SELECT * FROM transactions WHERE amount_ngn > 0
),
kpi_base AS (
    SELECT
        COUNT(*)                                                    AS total_transactions,
        COUNT(DISTINCT user_id)                                     AS active_users,
        COUNT(CASE WHEN status = 'Success' THEN 1 END)             AS successful_txns,
        COUNT(CASE WHEN status = 'Failed'  THEN 1 END)             AS failed_txns,
        SUM(CASE WHEN status = 'Success' THEN amount_ngn ELSE 0 END) AS successful_volume
    FROM clean_txns
)
SELECT
    'January 2024'                                                  AS period,
    total_transactions,
    active_users,
    ROUND(successful_txns * 100.0 / NULLIF(total_transactions, 0), 1) AS success_rate_pct,
    ROUND(failed_txns * 100.0 / NULLIF(total_transactions, 0), 1)     AS failure_rate_pct,
    ROUND(successful_volume / NULLIF(successful_txns, 0), 2)           AS avg_txn_value_ngn,
    ROUND(successful_volume / NULLIF(active_users, 0), 2)              AS arpu_ngn,
    ROUND(total_transactions::numeric / NULLIF(active_users, 0), 2)    AS txn_velocity,
    successful_volume                                                   AS total_volume_ngn
FROM kpi_base;
```

**Result — January 2024 Executive KPI Card (1 row):**

| KPI | Value | Benchmark | Status |
|---|---|---|---|
| Total transactions | 50 | — | Baseline |
| Active users | 22 | — | Baseline |
| **Success rate** | **72.0%** | >95% | 🔴 Critical |
| **Failure rate** | **18.0%** | <5% | 🔴 Critical |
| **Avg Transaction Value** | **₦150,078.89** | — | Baseline for Feb |
| **ARPU** | **₦245,583.64** | — | Baseline for Feb |
| **Transaction velocity** | **2.27 txns/user** | — | Baseline for Feb |
| Total clean volume | ₦5,402,840.00 | — | Reference |

> 🔴 **Critical flags:** Success rate of 72.0% is well below the 95% industry benchmark.
> Failure rate of 18.0% exceeds the 5% threshold significantly.
> These are the top two priorities for the engineering and product teams in February.

**Business finding:** January 2024 KPI summary — PalmPay processed 50 transactions
from 22 active users, generating ₦5,402,840 in clean volume. The 72.0% success rate
and 18.0% failure rate are below acceptable industry benchmarks and require immediate
investigation. ARPU of ₦245,584 and velocity of 2.27 transactions/user establish
the January baseline that February performance will be measured against.
The single most important action for February is reducing the Web channel failure
rate (currently 31.2%), which alone could recover an estimated ₦470,000 in
currently-lost monthly transaction volume.

---

## Key Lessons Learned

1. **HAVING vs WHERE — the most common beginner mistake** — WHERE filters rows before
   grouping, HAVING filters groups after grouping. If your condition uses COUNT/SUM/AVG,
   it belongs in HAVING. If it uses a column value directly, it belongs in WHERE.
   You can use both in the same query.

2. **Never use alias names in HAVING** — PostgreSQL evaluates HAVING before SELECT
   aliases are assigned. `HAVING failure_rate_pct > 15` errors even though the
   alias is defined in the same query. Repeat the full expression.

3. **Always protect divisions with NULLIF** — `ROUND(volume / NULLIF(count, 0), 2)`
   returns NULL instead of crashing when count is zero. In production dashboards,
   a divide-by-zero error with no NULLIF protection will break your entire report.

4. **CTEs make complex queries readable and debuggable** — breaking a 3-step
   calculation into 3 named CTEs means you can test each step independently.
   A nested subquery 4 levels deep is impossible to debug at 9pm before a board meeting.

5. **Integer division silently truncates in PostgreSQL** — `5 / 2 = 2`, not `2.5`.
   Always cast to numeric when dividing counts: `count::numeric / other_count`
   or multiply by `1.0`. This has corrupted real analyst reports that were never caught.

6. **The 72% success rate is the headline finding** — every other metric is context.
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
├── query6_executive_kpi_summary.sql              ← save this as monthly_kpi_report.sql
└── screenshots/
    ├── query1_result.png
    ├── query2_result.png
    ├── query3_result.png
    ├── query4_result.png
    ├── query5_result.png
    └── query6_kpi_card.png                       ← most important screenshot for portfolio
```

---

## Phase 1 SQL Summary (Days 3–5)

| Day | Concepts | Key output |
|---|---|---|
| Day 3 | SELECT, FROM, WHERE, GROUP BY, ORDER BY, LIMIT | Basic transaction analysis — 5 queries |
| Day 4 | INNER JOIN, LEFT JOIN, anti-join, CASE WHEN | Customer-linked analysis — 5 queries |
| Day 5 | HAVING, subqueries, CTEs, NULLIF, KPIs | Full KPI report — 6 queries |

By the end of Day 5, I can write any query that a fintech analyst encounters
in their first 6 months on the job.

---

*Part of the [30-Day Fintech Data Analyst Bootcamp](../README.md) — PalmPay Analytics Case Study*
