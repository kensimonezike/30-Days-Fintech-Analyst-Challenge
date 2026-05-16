# Day 03 — SQL Introduction: First Queries on Transaction Data

**Date completed:** [DD-MMM-2024]  
**Tool:** PostgreSQL + DBeaver  
**Time taken:** [X] minutes  
**Score:** [X/100]  
**Phase:** 1 — Foundations

---

## Business Scenario

My manager asked me to stop relying solely on Excel and start querying the PalmPay transaction
database directly using SQL. The goal was to answer five business questions about January 2024
transaction data using SQL queries — the same questions I answered with pivot tables on Day 2,
but now written as reusable, scalable code.

---

## Environment Setup

| Component | Tool | Version |
|---|---|---|
| Database engine | PostgreSQL | 16.x |
| Query interface | DBeaver Community Edition | Latest |
| Database created | `palmpay_db` | — |
| Table loaded | `transactions` | 50 rows |

**Setup steps completed:**
1. Installed PostgreSQL 16 with default settings, port 5432
2. Installed DBeaver and connected to PostgreSQL (Host: localhost, User: postgres)
3. Created `palmpay_db` database
4. Created `transactions` table with 8 columns matching the cleaned Excel dataset
5. Loaded 50 rows from `palmpay_jan2024.csv` via DBeaver CSV import
6. Verified: `SELECT COUNT(*) FROM transactions;` → returned **50** ✅

---

## Table Schema

```sql
CREATE TABLE transactions (
    transaction_id    VARCHAR(20)   PRIMARY KEY,
    user_id           VARCHAR(20),
    transaction_date  DATE,
    transaction_type  VARCHAR(30),
    amount_ngn        NUMERIC(15,2),
    status            VARCHAR(20),
    channel           VARCHAR(20),
    region            VARCHAR(40)
);
```

---

## SQL Concepts Learned Today

| Concept | What it does |
|---|---|
| `SELECT` | Chooses which columns to return |
| `FROM` | Specifies which table to query |
| `WHERE` | Filters rows before any aggregation |
| `GROUP BY` | Groups rows to apply aggregate functions per group |
| `ORDER BY DESC` | Sorts results largest first |
| `LIMIT` | Caps the number of rows returned |
| `COUNT(*)` | Counts all rows in a group |
| `SUM(col)` | Adds all values in a numeric column |
| `AVG(col)` | Calculates the mean of a numeric column |
| `MAX(col)` | Returns the largest value in a group |
| `ROUND(x, n)` | Rounds a number to n decimal places |
| `AS` | Renames a column in the result for readability |
| `SUM(COUNT(*)) OVER()` | Window function — grand total across all groups for % calculation |

---

## Query 1 — Total Transactions and Volume

**Business question:** How many transactions were processed in January, and what was the total volume?

```sql
SELECT
    COUNT(*)                    AS total_transactions,
    SUM(amount_ngn)             AS total_volume_ngn,
    ROUND(AVG(amount_ngn), 2)   AS avg_transaction_ngn
FROM transactions;
```

**Result:**

| total_transactions | total_volume_ngn | avg_transaction_ngn |
|---|---|---|
| 50 | 6,145,400.00 | 122,908.00 |

> ⚠️ **Data quality note:** This total includes 2 negative amount rows (a data issue
> identified on Day 1). The correct clean volume after zeroing negatives is **₦6,834,720.00**.
> Always state which figure you are using in any report and document why.

**Business finding:** PalmPay processed 50 transactions in January 2024. Raw total volume
was ₦6,145,400 (₦6,834,720 after cleaning). The average transaction value was ₦122,908 —
a useful baseline for flagging unusually large or suspiciously small transactions.

---

## Query 2 — Transaction Breakdown by Status

**Business question:** What is the success rate of January transactions? Break it down by status.

```sql
SELECT
    status,
    COUNT(*)                                            AS transaction_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM transactions
GROUP BY status
ORDER BY transaction_count DESC;
```

**Result:**

| status | transaction_count | percentage |
|---|---|---|
| Success | 36 | 72.0% |
| Failed | 9 | 18.0% |
| Pending | 5 | 10.0% |

> 💡 **Key learning:** `SUM(COUNT(*)) OVER ()` is a window function. It calculates the
> grand total (50) across all status groups simultaneously, allowing the percentage to be
> calculated in a single query without a subquery. Without `OVER ()`, you would need
> two separate queries and manual division.

**Business finding:** 72% of January transactions completed successfully, 18% failed,
and 10% remain pending. The 18% failure rate is a red flag — nearly 1 in 5 transactions
did not complete. At an average value of ₦122,908, the 9 failed transactions represent
approximately ₦1.1M in volume that generated no revenue for the business.

---

## Query 3 — Failed Transactions by Channel

**Business question:** Which channel had the most failed transactions in January?

```sql
SELECT
    channel,
    COUNT(*) AS failed_transactions
FROM transactions
WHERE status = 'Failed'
GROUP BY channel
ORDER BY failed_transactions DESC
LIMIT 4;
```

**Result:**

| channel | failed_transactions |
|---|---|
| Web | 5 |
| USSD | 2 |
| App | 2 |
| Agent | 0 |

> 💡 **Key learning:** `WHERE status = 'Failed'` filters rows BEFORE they enter
> `GROUP BY`. Only the 9 failed rows are grouped and counted. This is the correct
> approach — not filtering first and grouping on all 50 rows, which would give
> total counts per channel, not failure counts.

**Business finding:** Web had the most failed transactions in January with 5 failures —
more than USSD and App combined and 55% of all failures. Agent was the only
channel with zero failures. This aligns with the Day 2 Pivot Table 1 finding
and confirms Web reliability should be the first engineering priority.

---

## Query 4 — Transaction Volume by Region (Successful Only)

**Business question:** Which region generated the most successful transaction volume in January?

```sql
SELECT
    region,
    COUNT(*)                    AS transaction_count,
    SUM(amount_ngn)             AS total_volume_ngn,
    ROUND(AVG(amount_ngn), 2)   AS avg_amount_ngn
FROM transactions
WHERE status = 'Success'
GROUP BY region
ORDER BY total_volume_ngn DESC;
```

**Result:**

| region | transaction_count | total_volume_ngn | avg_amount_ngn |
|---|---|---|---|
| Lagos | 9 | 2,125,170.00 | 236,130.00 |
| Kano | 8 | 1,021,240.00 | 127,655.00 |
| NULL | 5 | 995,720.00 | 199,144.00 |
| Port Harcourt | 5 | 510,720.00 | 102,144.00 |
| Abuja | 5 | 327,370.00 | 65,474.00 |
| Ibadan | 4 | -16,620.00 | -4,155.00 |

> ⚠️ **Two data quality flags surfaced in this result:**
>
> **1. NULL region:** 5 successful transactions (₦995,720) have no region value.
> These are the 5 missing region rows identified on Day 1. They appear as NULL here
> because we are querying the raw table, not the cleaned Excel data.
> In production, use the cleaned `region_clean` column or impute from source systems.
>
> **2. Ibadan negative total:** The 2 negative amount rows fall under Ibadan,
> making its total appear as -₦16,620. This is factually wrong — Ibadan customers
> transacted, but the data error distorts the result. A business report showing
> Ibadan with negative revenue would cause serious confusion.
> **This is exactly why Day 2 data cleaning was not optional.**

**Business finding:** Lagos generated the highest successful transaction volume at ₦2,125,170 —
more than double Kano in second place at ₦1,021,240. Lagos customers also transact at
the highest average value (₦236,130 vs the overall average of ₦122,908), indicating
a higher-spending customer segment concentrated in Lagos.

---

## Query 5 — Breakdown by Transaction Type

**Business question:** Which transaction type drives the most volume? What is the average and largest transaction per type?

```sql
SELECT
    transaction_type,
    COUNT(*)                            AS total_count,
    COUNT(*) * 100 / SUM(COUNT(*)) OVER() AS pct_of_transactions,
    SUM(amount_ngn)                     AS total_volume_ngn,
    ROUND(AVG(amount_ngn), 2)           AS avg_amount_ngn,
    MAX(amount_ngn)                     AS largest_transaction_ngn
FROM transactions
GROUP BY transaction_type
ORDER BY total_volume_ngn DESC;
```

**Result:**

| transaction_type | total_count | pct_of_txns | total_volume_ngn | avg_amount_ngn | largest_txn_ngn |
|---|---|---|---|---|---|
| Airtime | 12 | 24% | 3,106,970.00 | 258,914.17 | 462,810.00 |
| Deposit | 11 | 22% | 1,366,370.00 | 124,215.45 | 473,150.00 |
| Transfer | 9 | 18% | 1,263,150.00 | 140,350.00 | 386,320.00 |
| Withdrawal | 11 | 22% | 786,120.00 | 71,465.45 | 472,840.00 |
| Bill Payment | 7 | 14% | -377,210.00 | -53,887.14 | 46,560.00 |

> ⚠️ **Data quality flag:** Bill Payment shows a negative total (₦-377,210).
> The 2 negative raw amount rows fall under this transaction type, corrupting the figure.
> The SQL is correct — the data is not. Always add `WHERE amount_ngn > 0`
> or use cleaned amounts when this table is used for revenue reporting.

**Business finding:** Airtime was the highest-volume transaction type in January at ₦3,106,970
across 12 transactions (24% of all activity). Despite being small by count, Airtime had the
highest average transaction value at ₦258,914 — suggesting bulk or high-denomination
airtime purchases rather than small top-ups. Transfers came third by volume
but second by average value at ₦140,350, confirming their importance as a revenue driver.

---

## Bonus Query — Largest Single Transaction

**Business question:** What was the single largest transaction in January — and who made it?

```sql
SELECT *
FROM transactions
ORDER BY amount_ngn DESC
LIMIT 1;
```

**Result:**

| transaction_id | user_id | transaction_date | transaction_type | amount_ngn | status |
|---|---|---|---|---|---|
| TXN-0033 | USR-3286 | 15-Jan-2024 | Deposit | 473,150.00 | Success |

**Business finding:** The largest single transaction in January was a ₦473,150 Deposit by
user USR-3286, completed successfully on 15 January 2024. At 3.8x the average transaction
value (₦122,908), this transaction would trigger a review flag under standard AML
(Anti-Money Laundering) transaction monitoring rules — not because it is necessarily
suspicious, but because size alone warrants documentation.

---

## Key Lessons Learned

1. **`WHERE` filters BEFORE `GROUP BY`** — always apply status or amount conditions before
   grouping to avoid aggregating the wrong rows.

2. **Raw data poisons SQL results too** — the negative amounts and NULL regions from Day 1
   surfaced directly in Queries 4 and 5, producing nonsense figures. SQL does not warn you.
   You have to know your data before you trust your results.

3. **`AS` is not optional in professional work** — a column named `count` or `sum` in a
   report is meaningless. Every aggregated column must have a descriptive alias.

4. **Window functions unlock percentage calculations** — `SUM(COUNT(*)) OVER()` calculates
   the grand total without collapsing groups, enabling inline percentages in a single query
   without self-joins or subqueries.

5. **SQL vs Excel for the same questions** — the 5 queries above answered questions that
   took 25 minutes of pivot table work on Day 2. The SQL took under 10 minutes to write
   and will run instantly on 10 million rows as easily as 50.

---

## SQL vs Excel — Same Questions Compared

| Question | Excel approach | SQL approach | Winner |
|---|---|---|---|
| Total volume | `=SUM(E2:E51)` | `SELECT SUM(amount_ngn) FROM transactions` | Tie |
| Success rate | COUNTIF ÷ COUNTA | `GROUP BY status` with window function | SQL — more precise |
| Volume by region | Pivot table — manual | `GROUP BY region ORDER BY SUM DESC` | SQL — reusable |
| Type breakdown | 5 separate COUNTIFs | Single `GROUP BY transaction_type` | SQL — one query |
| Updating for Feb data | Refresh pivot | Re-run same query | SQL — zero rework |
| Scalability | Breaks at ~1M rows | Handles 100M+ rows | SQL — no contest |

---

## Files in This Folder

```
day03-sql-intro/
├── README.md                        ← this file
├── query1_total_volume.sql
├── query2_status_breakdown.sql
├── query3_failed_by_channel.sql
├── query4_volume_by_region.sql
├── query5_type_breakdown.sql
├── bonus_largest_transaction.sql
└── screenshots/
    ├── dbeaver_connection.png       ← DBeaver connected to palmpay_db
    ├── transactions_table_load.png  ← 50 rows confirmed loaded
    ├── query1_result.png
    ├── query2_result.png
    ├── query3_result.png
    ├── query4_result.png
    └── query5_result.png
```

---

*Part of the [30-Day Fintech Data Analyst Bootcamp](../README.md) — PalmPay Analytics Case Study*
