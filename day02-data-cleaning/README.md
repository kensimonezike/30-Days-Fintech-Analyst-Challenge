# Day 02 — Data Cleaning + First Pivot Analysis

**Date completed:** [DD-MMM-YYYY]  
**Tool:** Microsoft Excel  
**Time taken:** [X minutes]  
**Score:** [X/100]

---

## 📋 Business Scenario

My manager needed the January data cleaned and three business questions answered before the Monday growth meeting. No more profiling — time to fix the data and produce real answers.

---

## 🎯 Task

Fix all 5 data quality issues using Excel helper columns, build 3 pivot tables answering real business questions, and write a one-page insight summary in professional business language.

---

## 🧹 Cleaning Approach

| Column | Problem | Formula Used | Result |
|---|---|---|---|
| I — flag_duplicate_id | 2 duplicate IDs | =IF(COUNTIF($A$2:$A$51,A2)>1,"DUPLICATE","OK") | 2 flagged |
| J — status_clean | Inconsistent casing | =PROPER(F2) | All standardised |
| K — amount_clean | 2 negative amounts | =IF(E2<0,0,E2) | Replaced with 0 |
| L — date_clean | 1 date in year 2004 | =IF(YEAR(C2)<>2024,DATE(2024,MONTH(C2),DAY(C2)),C2) | Corrected to 2024 |
| M — region_clean | 5 missing regions | =IF(H2="","Unknown",H2) | Labelled Unknown |

**Impact of cleaning on total volume:**  
Raw SUM: ₦[X,XXX,XXX] → Cleaned SUM: ₦[X,XXX,XXX] (difference: ₦[XX,XXX])

---

## 📊 Pivot Table Findings

**Pivot 1 — Success Rate by Channel**
> [Your key finding — e.g. "USSD had the highest failure rate at XX% vs the XX% overall average"]

**Pivot 2 — Volume by Region and Transaction Type**
> [Your key finding — e.g. "Lagos accounted for XX% of total volume, driven primarily by Transfers"]

**Pivot 3 — Daily Transaction Trend**
> [Your key finding — e.g. "Peak day was [date] with X transactions. Volume was flat/growing/declining across January"]

---

## 💬 Business Insights Written

**Insight 1 (Channel performance):**
[Paste your 3-sentence insight paragraph here]

**Insight 2 (Regional volume):**
[Paste your 3-sentence insight paragraph here]

**Insight 3 (Daily trend):**
[Paste your 3-sentence insight paragraph here]

---

## 💡 Key Lesson

[Write one thing you will not forget from this task — in your own words]

---

## 📁 Files

- `palmpay_cleaned.xlsx` — cleaned dataset with helper columns and 3 pivot tables
- `screenshots/helper_columns.png` — columns I-M with cleaning formulas
- `screenshots/pivot1_channel.png` — success rate by channel
- `screenshots/pivot2_region.png` — volume by region and type
- `screenshots/pivot3_trend.png` — daily transaction trend
