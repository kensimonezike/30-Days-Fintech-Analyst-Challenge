# Day 07 — Phase 1 Mini-Project: Complete PalmPay January 2024 Report

**Date completed:** [DD-MMM-2024]
**Tools:** Excel + PostgreSQL/SQL + Python/Pandas
**Time taken:** [X] hours
**Score:** [X/100]
**Phase:** 1 — Foundations (Capstone)

---

## Project Overview

This is the Phase 1 capstone — a single end-to-end report on PalmPay Analytics'
January 2024 transaction performance, combining everything learned across Days 1-6:
Excel data profiling and pivot tables, SQL queries from basic to advanced (JOINs,
HAVING, CTEs), and Python/Pandas EDA. The report is written for a non-technical
executive audience and validated for consistency across all three tools.

---

## Executive Summary

PalmPay Analytics processed 50 transactions from 22 active users in January 2024,
generating ₦5,402,840 in clean successful revenue. The platform-wide success rate
was 72.0% — below the 95% industry benchmark — driven primarily by reliability
issues on the Web channel (31.2% failure rate).

**Three key findings:**
- Web and App channels account for 7 of 9 failed transactions in January,
  representing approximately ₦467,000 in lost monthly volume.
- Lagos generates 33% of total transaction volume — the single most concentrated
  regional revenue source.
- VIP customers generate the highest ARPU (₦309,430) but Standard tier drives
  7 of the top 10 customers by total spend — suggesting tier classification may
  not reflect true customer value.

**Critical risk:** The 18% platform-wide failure rate is more than 3x the industry
benchmark. If unaddressed, this represents continued revenue leakage and customer
trust erosion heading into February.

**Recommended action:** Engineering should prioritise a Web channel reliability
audit before any February marketing spend.

---

## Data Quality Methodology

| Issue | Rows Affected | Fix Applied | Tool Used |
|---|---|---|---|
| Duplicate transaction IDs | 4 (2 pairs) | Flagged with `is_duplicate` — not deleted, pending investigation | Excel formula + Python `duplicated()` |
| Missing region values | 5 | Filled with `'Unknown'` — preserves row count, flags gap | Excel IF + Python `fillna()` |
| Negative transaction amounts | 2 | Replaced with 0 — pending engineering confirmation | Excel IF + Python `clip()` |
| Inconsistent status casing | 5 (8 variants) | Standardised to Title Case | Excel `PROPER()` + Python `str.title()` |
| Date outlier (year 2004) | 1 | Corrected to 2024, kept month/day | Excel `DATE()` + Python `dt.year` |

During profiling, 5 distinct data quality issues were identified affecting 12 of
50 rows (24%). All issues were documented and corrected using consistent logic
across Excel, SQL, and Python to ensure reproducibility. No rows were deleted;
all anomalies were flagged or corrected with transparent labelling so the
analysis remains fully auditable.

---

## Cross-Tool Validation

| Metric | Excel Result | SQL Result | Python Result | Match? |
|---|---|---|---|---|
| Total transactions | 50 | 50 | 50 | ✅ Y |
| Success rate | 72.0% | 72.0% | 72.0% | ✅ Y |
| Failed count | 9 | 9 | 9 | ✅ Y |
| Total clean volume | ₦6,834,720* | ₦5,402,840** | ₦5,402,840 | ⚠️ See note |
| Top region by volume | Lagos | Lagos | Lagos | ✅ Y |
| Top failure channel | Web | Web | Web | ✅ Y |

> **Note on volume discrepancy:** Excel's ₦6,834,720 includes ALL clean amounts
> regardless of transaction status (Success + Failed + Pending). SQL and Python's
> ₦5,402,840 filters to `status = 'Success'` only. Both figures are correct —
> they answer different questions. This distinction is documented here rather
> than hidden, which is the standard practice for any reported discrepancy.

---

## 5 Core Business Findings (Ranked by Impact)

### Finding 1 — Channel Reliability Crisis 🔴 CRITICAL
Web channel failure rate of 31.2% (5 of 16 transactions) and App at 20.0%
(2 of 10) both exceed the 15% escalation threshold. Combined, these two channels
account for 7 of the platform's 9 January failures.
*Source: Day 3 Query 3, Day 5 Query 1, Day 6 Task 4 — confirmed across all 3 tools.*
**Action:** Engineering should audit Web channel infrastructure before any
February campaign spend.

### Finding 2 — Regional Revenue Concentration 🟠 HIGH
Lagos generates ₦2,125,170 in successful volume — 33% of total clean revenue
from a single region. Kano is a distant second at ₦1,021,240.
*Source: Day 2 Pivot 2, Day 3 Query 4, Day 6 Task 2 — consistent across all tools.*
**Action:** Diversify regional acquisition spend; investigate why Lagos so
significantly outperforms other regions.

### Finding 3 — Tier-Value Misalignment 🟠 HIGH
Premium tier customers have the LOWEST ARPU (₦159,545) of all three tiers —
below both Standard (₦270,560) and VIP (₦309,430). 7 of the top 10 individual
spenders are Standard tier, including the #1 spender at ₦993,820.
*Source: Day 4 Query 1 & 3, Day 5 Query 3 — confirmed via JOIN and CTE analysis.*
**Action:** Review tier classification criteria; proactively offer upgrades to
high-spending Standard customers.

### Finding 4 — KYC Status Paradox 🔵 MEDIUM
Pending KYC customers had a HIGHER success rate (78.6%) than Verified customers
(69.4%) — and all 9 January failures came from Verified accounts.
*Source: Day 4 Query 2 — the most counter-intuitive finding of the week.*
**Action:** Investigate whether failures cluster around specific Verified
accounts (possible fraud signal) or a routing bug.

### Finding 5 — Customer Engagement is Strong 🟢 POSITIVE
45% of active users (10 of 22) made 3 or more transactions in January — a
strong engagement signal. Top user Babatunde Oladele made 5 transactions
totalling ₦993,820.
*Source: Day 5 Query 4 — power user identification via HAVING clause.*
**Action:** Build a retention/loyalty programme around these 10 identified
power users before they have reason to churn.

---

## Recommendations (Ranked by Priority)

| Priority | Recommendation | Owner | Expected Impact |
|---|---|---|---|
| 1 (Urgent) | Audit Web channel infrastructure for reliability issues | Engineering | Recover ~₦467K/month in failed volume |
| 2 (High) | Review tier classification criteria for Premium customers | Product | Better align tier perks with actual value |
| 3 (High) | Investigate KYC-Verified failure cluster | Risk/Compliance | Identify potential fraud or routing bug |
| 4 (Medium) | Launch retention programme for 10 power users | Customer Success | Reduce churn risk among highest-value users |
| 5 (Medium) | Diversify regional acquisition spend beyond Lagos | Growth/Marketing | Reduce concentration risk |

---

## Tools and Techniques Used (Phase 1 Summary)

| Day | Tool | Techniques Applied in This Report |
|---|---|---|
| Day 1-2 | Excel | Data profiling, helper-column cleaning, 3 pivot tables |
| Day 3 | SQL (basic) | SELECT, WHERE, GROUP BY, aggregate functions |
| Day 4 | SQL (joins) | INNER JOIN, LEFT JOIN, anti-join pattern, CASE WHEN |
| Day 5 | SQL (advanced) | HAVING, subqueries, CTEs, NULLIF, fintech KPIs |
| Day 6 | Python/Pandas | Programmatic profiling, groupby/agg, IQR outlier detection, matplotlib charts |

---

## Files in This Folder

```
day07-mini-project/
├── README.md                          ← this file
├── PalmPay_January_2024_Report.docx   ← full polished report (Word or PDF)
├── validation_queries.sql              ← SQL used to cross-check Excel/Python numbers
├── eda_charts.ipynb                    ← consolidated notebook with all 5 finding charts
└── screenshots/
    ├── executive_summary_page.png
    ├── data_quality_table.png
    ├── finding1_channel_chart.png
    ├── finding2_region_chart.png
    ├── finding3_tier_chart.png
    ├── finding4_kyc_chart.png
    └── finding5_power_users_chart.png
```

---

## Portfolio Publication Checklist

- [ ] **GitHub** — this folder pushed to `fintech-analyst-bootcamp` repo
- [ ] **Medium** — published as first case study article: *"How I Analyzed a Fintech
      Company's Transaction Data Using Excel, SQL, and Python"*
- [ ] **LinkedIn** — executive summary posted as a standalone post with
      `#DataAnalytics #SQL #Python #Fintech`
- [ ] **X/Twitter** — 5-tweet thread, one per finding, linking to the Medium article

---

## Phase 1 Complete ✅

Days 1-7 covered the full Foundations phase: Excel profiling and cleaning, SQL from
SELECT statements through JOINs to CTEs and KPIs, and Python/Pandas EDA — all
validated against each other and synthesised into one professional report.

**Phase 2 begins at Day 8:** Advanced EDA, correlation analysis, and customer
segmentation — building toward churn and fraud detection in Days 16-23.

---

*Part of the [30-Day Fintech Data Analyst Bootcamp](../README.md) — PalmPay Analytics Case Study*
