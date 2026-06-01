# Day 04. SQL Joins: Linking Tables to Answer Richer Business Questions

**Tool:** PostgreSQL + DBeaver  

---

## Business Scenario

My manager wanted me to go beyond single-table queries. Real fintech databases
have multiple tables that connect. Transactions record WHAT happened,
customers record WHO did it. Today I learned SQL JOINs to link both tables using
the shared `user_id` column, enabling richer business questions that neither table
could answer alone.

---

## New Table Added — customers

| Column | Type | Description |
|---|---|---|
| `customer_id` | VARCHAR(20) | Primary key — unique per customer |
| `user_id` | VARCHAR(20) | Foreign key — links to transactions table |
| `full_name` | VARCHAR(100) | Customer full name |
| `account_tier` | VARCHAR(20) | Standard / Premium / VIP |
| `signup_date` | DATE | Date customer registered |
| `city` | VARCHAR(40) | Customer's primary city |
| `kyc_status` | VARCHAR(20) | Verified / Pending / Failed |
| `monthly_income_band` | VARCHAR(20) | Income bracket |

**Table stats:** 25 customers total — 22 active (matched to transactions), 3 dormant (no transactions in January).

---

## JOIN Concepts Learned

| JOIN Type | What it returns | When to use it |
|---|---|---|
| `INNER JOIN` | Only rows with a match in BOTH tables | Revenue analysis, customer behaviour — need clean matched data |
| `LEFT JOIN` | ALL rows from the left table + matches from right (NULL if no match) | Finding orphaned records, checking data completeness |
| `LEFT JOIN + IS NULL` | Only left table rows with NO match in right table | Anti-join — finding gaps (orphaned transactions, missing customers) |
| Swapped `LEFT JOIN` | All customers + their transactions (NULL if none) | Finding dormant customers |

**New SQL concepts introduced today:**
- `AS t` / `AS c` — table aliases to avoid typing full table names and resolve ambiguity
- `t.column_name` — column prefixes to specify which table each column comes from
- `CASE WHEN condition THEN value END` — SQL's IF statement inside aggregations
- Anti-join pattern — `LEFT JOIN + WHERE right_table.id IS NULL`

---

## Database Relationship

```
transactions                    customers
──────────────────              ──────────────────────
transaction_id (PK)             customer_id (PK)
user_id  ────────────────────── user_id (UNIQUE)
transaction_date                full_name
transaction_type                account_tier
amount_ngn                      signup_date
status                          city
channel                         kyc_status
region                          monthly_income_band
```

The `user_id` column is the bridge — it exists in both tables and links every transaction
to its corresponding customer profile.

---

## Query 1 — Transaction Volume by Account Tier

**Business question:** Which account tier generates the most transaction volume?  
**JOIN type:** INNER JOIN — only transactions with a matching customer record.

```sql
SELECT
    c.account_tier,
    COUNT(t.transaction_id)             AS transaction_count,
    SUM(t.amount_ngn)                   AS total_volume_ngn,
    ROUND(AVG(t.amount_ngn), 2)         AS avg_transaction_ngn,
    MAX(t.amount_ngn)                   AS largest_transaction_ngn
FROM transactions AS t
INNER JOIN customers AS c
    ON t.user_id = c.user_id
WHERE t.status = 'Success'
  AND t.amount_ngn > 0
GROUP BY c.account_tier
ORDER BY total_volume_ngn DESC;
```

**Result:**

| account_tier | transaction_count | total_volume_ngn | avg_transaction_ngn | largest_transaction_ngn |
|---|---|---|---|---|
| Standard | 28 | 3,430,660.00 | 122,524.00 | 472,840.00 |
| VIP | 7 | 1,585,860.00 | 226,551.43 | 473,150.00 |
| Premium | 1 | 386,320.00 | 386,320.00 | 386,320.00 |

**Business finding:** Standard tier customers drove 63.5% of total matched volume
in January — the highest share by far. However, VIP customers averaged ₦226,551
per transaction vs ₦122,524 for Standard — 85% higher per transaction.
A single VIP customer generates roughly twice the revenue per transaction.
This confirms that VIP retention efforts have disproportionate revenue impact
and should be prioritised accordingly.

---

## Query 2 — Success Rate by KYC Status

**Business question:** Do Verified KYC customers have better transaction success rates?  
**JOIN type:** INNER JOIN. New concept: `CASE WHEN` inside `COUNT()`.

```sql
SELECT
    c.kyc_status,
    COUNT(*)                                                        AS total_transactions,
    COUNT(CASE WHEN t.status = 'Success' THEN 1 END)               AS successful_count,
    COUNT(CASE WHEN t.status = 'Failed'  THEN 1 END)               AS failed_count,
    ROUND(
        COUNT(CASE WHEN t.status = 'Success' THEN 1 END) * 100.0
        / COUNT(*),
        1
    )                                                               AS success_rate_pct
FROM transactions AS t
INNER JOIN customers AS c
    ON t.user_id = c.user_id
GROUP BY c.kyc_status
ORDER BY success_rate_pct DESC;
```

**Result:**

| kyc_status | total_transactions | successful_count | failed_count | success_rate_pct |
|---|---|---|---|---|
| Pending | 14 | 11 | 0 | 78.6% |
| Verified | 36 | 25 | 9 | 69.4% |

> 💡 **Unexpected finding:** Pending KYC customers had a HIGHER success rate (78.6%)
> than Verified customers (69.4%) — and ALL 9 failures came from Verified accounts.
>
> This is counter-intuitive. It could mean:
> - Pending customers make smaller, simpler transactions that are less likely to fail
> - A specific routing bug is affecting Verified accounts specifically
> - The 9 failures cluster around a small subset of Verified users
>
> This result would trigger an immediate investigation in a real fintech company.
> The next query should be: which specific Verified customers experienced failures?

**Business finding:** Verified KYC customers had a 69.4% success rate vs 78.6%
for Pending KYC — an unexpected reversal. All 9 January failures came from Verified
accounts. Engineering and compliance teams should investigate whether Verified account
routing has a systematic issue, or whether the failures cluster around specific users
that warrant a fraud review.

---

## Query 3 — Top 10 Customers by Total Spend

**Business question:** Who are our highest-value customers in January?  
**JOIN type:** INNER JOIN.

```sql
SELECT
    c.full_name,
    c.account_tier,
    c.city,
    c.kyc_status,
    COUNT(t.transaction_id)             AS total_transactions,
    SUM(t.amount_ngn)                   AS total_spend_ngn,
    ROUND(AVG(t.amount_ngn), 2)         AS avg_transaction_ngn
FROM transactions AS t
INNER JOIN customers AS c
    ON t.user_id = c.user_id
GROUP BY c.full_name, c.account_tier, c.city, c.kyc_status
ORDER BY total_spend_ngn DESC
LIMIT 10;
```

**Result:**

| full_name | account_tier | city | total_transactions | total_spend_ngn | avg_transaction_ngn |
|---|---|---|---|---|---|
| Babatunde Oladele | Standard | Abuja | 5 | 993,820.00 | 198,764.00 |
| Chukwudi Eze | Standard | Ibadan | 3 | 859,820.00 | 286,606.67 |
| Halima Yusuf | Standard | Port Harcourt | 3 | 801,230.00 | 267,076.67 |
| Blessing Eze | Standard | Lagos | 3 | 495,420.00 | 165,140.00 |
| Emeka Okafor | Standard | Lagos | 3 | 479,170.00 | 159,723.33 |
| Aisha Musa | VIP | Ibadan | 2 | 477,590.00 | 238,795.00 |
| Obiageli Nwosu | Standard | Ibadan | 3 | 476,310.00 | 158,770.00 |
| Yetunde Balogun | Standard | Port Harcourt | 1 | 391,910.00 | 391,910.00 |
| Fatima Al-Hassan | Premium | Ibadan | 1 | 386,320.00 | 386,320.00 |
| Uche Nnamdi | VIP | Kano | 4 | 376,950.00 | 94,237.50 |

**Business finding:** Babatunde Oladele is the highest-spending customer in January
at ₦993,820 across 5 transactions — nearly ₦1M in a single month on a Standard account.
This customer is the strongest candidate for a Premium tier upgrade offer.
Notably, 7 of the top 10 spenders are Standard tier customers, suggesting the tier
classification may not accurately reflect customer value. The bank should review
its upgrade criteria and proactively reach out to high-spending Standard customers.

---

## Query 4 — Orphaned Transactions (Anti-Join)

**Business question:** How many transactions have NO matching customer record?  
**JOIN type:** LEFT JOIN + WHERE IS NULL (anti-join pattern).

```sql
SELECT
    t.transaction_id,
    t.user_id,
    t.transaction_date,
    t.amount_ngn,
    t.status,
    t.transaction_type,
    c.full_name,        -- NULL for unmatched rows
    c.account_tier      -- NULL for unmatched rows
FROM transactions AS t
LEFT JOIN customers AS c
    ON t.user_id = c.user_id
WHERE c.customer_id IS NULL
ORDER BY t.transaction_date;
```

**Result:** `0 rows returned`

**Verification query result:**

| total_transactions | matched_transactions | unmatched_transactions | match_rate_pct |
|---|---|---|---|
| 50 | 50 | 0 | 100.0% |

**Business finding:** All 50 January transactions have a matching customer record —
a 100% referential integrity match rate. This is a positive data quality result.
Zero orphaned transactions means every transaction can be attributed to a known
customer, enabling reliable customer-level analytics.

> 📌 **Analyst note:** This check should run as a daily automated data quality monitor
> in production. Any day where match rate drops below 100% would indicate either a
> pipeline failure, a customer record deletion, or a data ingestion bug — all of which
> require immediate investigation.

---

## Query 5 — Dormant Customers (Zero Transactions)

**Business question:** Which registered customers made no transactions in January?  
**JOIN type:** LEFT JOIN with customers as the base table (tables swapped from previous queries).

```sql
SELECT
    c.customer_id,
    c.full_name,
    c.account_tier,
    c.city,
    c.signup_date,
    c.kyc_status,
    t.transaction_id    -- NULL if no transactions
FROM customers AS c
LEFT JOIN transactions AS t
    ON c.user_id = t.user_id
WHERE t.transaction_id IS NULL
ORDER BY c.account_tier, c.full_name;
```

**Result:**

| customer_id | full_name | account_tier | city | signup_date | kyc_status |
|---|---|---|---|---|---|
| CUS-025 | Hadiza Sule | VIP | Lagos | 2023-06-15 | Verified |
| CUS-024 | Rotimi Akande | Premium | Lagos | 2023-06-15 | Verified |
| CUS-023 | Kemi Adebayo | Standard | Lagos | 2023-06-15 | Verified |

**Bonus — all customers with their transaction count (0 for dormant):**

```sql
SELECT
    c.full_name,
    c.account_tier,
    COUNT(t.transaction_id) AS transaction_count
FROM customers AS c
LEFT JOIN transactions AS t
    ON c.user_id = t.user_id
GROUP BY c.full_name, c.account_tier
ORDER BY transaction_count ASC, c.account_tier;
```

**Business finding:** 3 of 25 registered customers (12%) made zero transactions in
January. All 3 are Verified KYC — meaning they are fully eligible to transact but
chose not to. This is particularly concerning for Hadiza Sule (VIP tier) and Rotimi
Akande (Premium tier) — both high-value customers who went an entire month without
a single transaction. These 3 customers should be flagged for immediate re-engagement:
a targeted offer, a push notification, or a personal outreach from the customer
success team before they churn permanently.

---

## Key Lessons Learned

1. **Always alias your tables in JOINs** — `FROM transactions AS t INNER JOIN customers AS c`
   is mandatory when both tables share column names like `user_id`. Without prefixes
   like `t.user_id` and `c.user_id`, SQL throws an "ambiguous column" error.

2. **Check your match rate with LEFT JOIN before committing to INNER JOIN** —
   running the verification query first showed 100% match rate, confirming INNER JOIN
   was safe. If match rate had been 80%, INNER JOIN would silently drop 20% of rows.

3. **GROUP BY must include all non-aggregated SELECT columns** — every column in
   SELECT without COUNT/SUM/AVG/MAX/MIN must appear in GROUP BY, or the query errors.

4. **CASE WHEN is SQL's IF statement** — `COUNT(CASE WHEN status = 'Success' THEN 1 END)`
   counts only the rows matching the condition. Essential for conditional aggregation
   within GROUP BY without writing separate queries.

5. **Swapping table order changes which side is "kept"** — in Query 5, putting
   `customers` in FROM and `transactions` in LEFT JOIN meant all customers were
   preserved, not all transactions. The anti-join pattern then isolates the non-matches.

6. **Unexpected findings are the most valuable** — the KYC result (Pending customers
   outperforming Verified) was not the expected answer. In real analytics, surprises
   that contradict assumptions are often the most actionable findings.

---

## Files in This Folder

```
day04-sql-joins/
├── README.md                          ← this file
├── create_customers_table.sql         ← CREATE TABLE + all 25 INSERT records
├── query1_volume_by_tier.sql
├── query2_success_rate_by_kyc.sql
├── query3_top_customers.sql
├── query4_orphaned_transactions.sql
├── query5_dormant_customers.sql
└── screenshots/
    ├── customers_table_loaded.png      ← 25 rows confirmed in DBeaver
    ├── query1_result.png
    ├── query2_result.png
    ├── query3_result.png
    ├── query4_result.png               ← 0 rows = clean referential integrity
    └── query5_result.png
```

---

## Day 3 vs Day 4 — What JOINs Unlocked

| Day 3 question (single table) | Day 4 question (with JOIN) |
|---|---|
| Which channel had most failures? | Which account tier has the worst failure rate? |
| Volume by region | Volume by customer income band |
| Transaction type breakdown | Transaction type breakdown per tier |
| Who made the largest transaction? | What tier/KYC status is our biggest spender? |
| — | Which customers are dormant this month? |

JOINs transform transaction data into customer intelligence.

---
