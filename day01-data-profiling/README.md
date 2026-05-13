# Day 01 — Data Profiling

**Date completed:** [DD-MMM-YYYY]  
**Tool:** Microsoft Excel  
**Time taken:** [X minutes]  
**Score:** [X/100]

---

## 📋 Business Scenario

I joined PalmPay Analytics as a junior data analyst. My manager dropped the January 2024 transaction dataset on my desk and asked for a full data quality report before any analysis could begin.

---

## 🎯 Task

Profile the dataset column by column, identify every data quality issue, and write a one-page business summary with three questions the data could answer.

---

## 🔍 What I Found

**Dataset:** 50 transaction records, January 2024, 8 columns

**Data quality issues discovered:**

| # | Issue | Rows Affected | Business Risk |
|---|---|---|---|
| 1 | Duplicate transaction IDs | Found 2 duplicate transaction IDs: TXN-0003 appears in rows 3 and 8 TXN-0015 appears in rows 15 and 22.| Any SUM of transaction volume or revenue will count these transactions twice. If either
transaction is 100,000, our reported volume is overstated by 100,000. Must be investigated with the
engineering team to determine if these are processing duplicates before analysis proceeds.] |
| 2 | Missing region values | 5 rows (rows X, X, X, X, X) | Regional analysis inaccurate |
| 3 | Negative transaction amounts | Rows [X] and [X] | Total volume understated |
| 4 | Inconsistent status casing | 5 rows | Success rate KPI wrong |
| 5 | Date outlier — year 2004 | Row [X] | Time-series charts broken |

**Data readiness verdict:** NOT ready for analysis. Issues 3, 4, and 5 would produce materially wrong numbers if not fixed first.

---

## ❓ Three Business Questions I Proposed

1. [Your question 1]
2. [Your question 2]
3. [Your question 3]

---

## 💡 Key Lesson

[Write one thing you will not forget from this task — in your own words]

---

## 📁 Files

- `palmpay_transactions_jan2024.xlsx` — raw dataset with flag columns and data profile sheet
- `screenshots/data_profile.png` — column-by-column profile table
- `screenshots/issues_found.png` — flagged rows in the dataset
