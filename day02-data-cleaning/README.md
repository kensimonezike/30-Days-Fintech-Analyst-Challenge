# Day 02. Data Cleaning + First Pivot Analysis

**Date completed:** 14-05-2026  
**Tool:** Microsoft Excel

---

## 📋 Business Scenario

My manager needed the January data cleaned and three business questions answered before the Monday growth meeting. No more profiling. Time to fix the data and produce real answers.

---

## 🎯 Task

Fix all 5 data quality issues using Excel helper columns, build 3 pivot tables answering real business questions, and write a one-page insight summary in professional business language.

---

## 🧹 Cleaning Approach

| Column | Problem | Formula Used | Result |
|---|---|---|---|
| I: flag_duplicate_id | 2 duplicate IDs | =IF(COUNTIF($A$2:$A$51,A2)>1,"DUPLICATE","OK") | 2 flagged |
| J: status_clean | Inconsistent casing | =PROPER(F2) | All standardised |
| K: amount_clean | 2 negative amounts | =IF(E2<0,0,E2) | Replaced with 0 |
| L: date_clean | 1 date in year 2004 | =IF(YEAR(C2)<>2024,DATE(2024,MONTH(C2),DAY(C2)),C2) | Corrected to 2024 |
| M: region_clean | 5 missing regions | =IF(H2="","Unknown",H2) | Labelled Unknown |

---

## 📊 Pivot Table Findings

**Pivot 1 — Success Rate by Channel**
> Web had the highest failure rate at 31.2% (5 of 16 transactions failed), compared to the overall failure rate of 18.0%.

**Pivot 2 — Volume by Region and Transaction Type**
> Lagos generated the highest total transaction volume at ₦2,253,090, accounting for 33.0% of all transaction volume. Within Lagos, Transfer transactions were the dominant transaction type at ₦872,680.

**Pivot 3 — Daily Transaction Trend**
> Peak transaction activity occurred on 05-Jan-2024 with 4 transactions recorded. January had 26 active transaction days, with total clean transaction volume reaching ₦6,834,720.

---

## 💬 Business Insights Written

**Insight 1 (Channel performance):**
Web transactions showed the weakest performance among all channels, recording the highest failure rate of 31.2%, which is significantly above the overall average failure rate of 18.0%. In comparison, USSD maintained a higher success rate of 81.2%, while Agent transactions recorded no failures during the period. This suggests that the Web channel may require further investigation into technical reliability, payment-processing flow, or user-experience issues.

**Insight 2 (Regional volume):**
Lagos emerged as the highest-performing region, contributing 33.0% of the total transaction volume in January 2024. The region’s transaction activity was largely driven by Transfers, which accounted for ₦872,680 in volume. This indicates that Lagos represents a major operational and revenue-driving market, making it a strong candidate for targeted growth initiatives and customer retention strategies.

**Insight 3 (Daily trend):**
Transaction activity remained relatively consistent throughout January, with occasional spikes in volume on specific dates. The peak activity day was 05-Jan-2024, which recorded the highest number of transactions for the month. Overall, the dataset shows steady transaction engagement across 26 active days, indicating stable platform usage patterns during the period.

---

## 📁 Files

- `palmpay_cleaned.xlsx`
- `screenshots/helper_columns.png`
- `screenshots/pivot1_channel.png` 
- `screenshots/pivot2_region.png` 
- `screenshots/pivot3_trend.png` 
