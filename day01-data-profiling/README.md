# Day 01. Data Profiling

**Date completed:** 13-05-2026  
**Tool:** Microsoft Excel 

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
| 1 | Duplicate transaction IDs | Found 2 duplicate transaction IDs: TXN-0003 appears in rows 3 and 8. TXN-0015 appears in rows 15 and 22. | Any SUM of transaction volume or revenue will count these transactions twice. If either transaction is 100,000, our reported volume is overstated by 100,000. Must be investigated with the engineering team to determine if these are processing duplicates before analysis proceeds. |
| 2 | Missing region values | 5 rows have no region value: rows 5, 12, 20, 29, and 37. | Regional performance reports will silently exclude these transactions. Example: if 3 of the 5 missing rows belong to Lagos, the Lagos total volume figure is wrong. Recommended action: attempt to recover region data from the source system using user_id as a lookup key. |
| 3 | Negative transaction amounts | Rows 10 and 34 contain negative transaction amounts. | =SUM(E2:E51) will produce an incorrect total volume figure. Negative amounts require clarification. Are these authorised reversals, system errors, or refund entries? Cannot be included in any analysis until confirmed. |
| 4 | Inconsistent status casing | 5 rows use incorrect casing in the status column: Row 6: 'success'; Row 13: 'SUCCESS'; Row 25: 'failed'; Row 39: 'PENDING'; Row 44: 'success' | =COUNTIF(F:F,"Success") undercounts successful transactions by at least 3, making the success rate KPI incorrect. Every formula or filter on this column is unreliable until standardised using =PROPER() or =UPPER(). |
| 5 | Date outlier: year 2004 | Row 17 contains a transaction date of 17-Jan-2004 (year 2004 instead of 2024). | Date range analysis (=MIN, =MAX, time-series charts) will reference 2004. Any chart showing transaction trends over January 2024 will include a phantom 2004 data point. This is almost certainly a data entry typo. Recommend correcting to 17-Jan-2024 after confirming with the source system. |

**Data readiness verdict:** NOT ready for analysis. Issues 3, 4, and 5 would produce materially wrong numbers if not fixed first.

---

## ❓ Three Business Questions I Proposed

1. Did daily transaction volume decline in the final week of January 2024 compared to the first week?
2. Which channel (App, USSD, Web, Agent) had the highest failure rate in January 2024, and how does it
compare to the overall average?
3. Which transaction type (Transfer, Airtime, Bill Payment, Withdrawal, Deposit) accounts for the largest share of total transaction volume in January 2024?


---

## 📁 Files

- `palmpay_transactions_jan2024.xlsx` — raw dataset with flag columns and data profile sheet
- `screenshots/data_profile.png` — column-by-column profile table
- `screenshots/issues_found.png` — flagged rows in the dataset
