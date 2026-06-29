# Day 10 — Customer Segmentation: RFM Analysis

**Date completed:** [DD-MMM-2024]
**Tool:** Python 3.11 + Jupyter Notebook
**Time taken:** [X] minutes
**Phase:** 2 — Intermediate

---

## Business Scenario

Marketing, retention, and product teams all needed a customer list segmented by
behaviour. Today I built a full RFM (Recency, Frequency, Monetary) analysis on
PalmPay's January 2024 customer base — scoring every customer on 3 dimensions,
assigning them to one of 4 business segments, and exporting an actionable CSV
for each team.

---

## What is RFM?

| Dimension | Definition | Scoring direction |
|---|---|---|
| **R — Recency** | Days since last transaction | Lower days = more recent = score 3 (best) |
| **F — Frequency** | Number of transactions | Higher count = score 3 (best) |
| **M — Monetary** | Total transaction value | Higher spend = score 3 (best) |

---

## Segment Definitions

| Segment | RFM Score | Profile | Business Action |
|---|---|---|---|
| **Champion** | 8-9 | Recent, frequent, high spend | Reward, ask for referrals |
| **Loyal** | 6-7 | Regular with solid spend | Upsell, offer premium features |
| **Promising** | 4-5 | Recent but low frequency/spend | Nurture with targeted campaigns |
| **At Risk** | 3 (low) | Infrequent, low spend, not recent | Re-engagement before churn |

---

## Code

### Cell 1: Calculate RFM Values

```python
reference_date = df['transaction_date'].max() + pd.Timedelta(days=1)

rfm = df.groupby('user_id').agg(
    recency   = ('transaction_date', lambda x: (reference_date - x.max()).days),
    frequency = ('transaction_id',   'count'),
    monetary  = ('amount_ngn',       'sum')
).reset_index()
```

### Cell 2: Score and Segment

```python
# R is INVERTED — lower recency days = more recent = score 3
rfm['R_score'] = pd.qcut(rfm['recency'],   q=3, labels=[3,2,1], duplicates='drop')
rfm['F_score'] = pd.qcut(rfm['frequency'], q=3, labels=[1,2,3], duplicates='drop')
rfm['M_score'] = pd.qcut(rfm['monetary'],  q=3, labels=[1,2,3], duplicates='drop')

rfm['RFM_score'] = (rfm['R_score'].astype(int) +
                    rfm['F_score'].astype(int) +
                    rfm['M_score'].astype(int))

def assign_segment(score):
    if   score >= 8: return 'Champion'
    elif score >= 6: return 'Loyal'
    elif score >= 4: return 'Promising'
    else:            return 'At Risk'

rfm['segment'] = rfm['RFM_score'].apply(assign_segment)
```

### Cell 3: Segment Summary

```python
segment_summary = rfm.groupby('segment').agg(
    customer_count = ('user_id',   'count'),
    avg_recency    = ('recency',   'mean'),
    avg_frequency  = ('frequency', 'mean'),
    avg_monetary   = ('monetary',  'mean'),
    total_revenue  = ('monetary',  'sum')
).round(1)

segment_summary['pct_of_customers'] = (
    segment_summary['customer_count'] / segment_summary['customer_count'].sum() * 100
).round(1)

segment_summary['pct_of_revenue'] = (
    segment_summary['total_revenue'] / segment_summary['total_revenue'].sum() * 100
).round(1)
```

### Cell 5: Export

```python
rfm.to_csv('palmpay_rfm_segments.csv', index=False)
```

---

## Results

### Segment Summary (fill in after running)

| Segment | Customers | % of Customers | Avg Recency | Avg Frequency | Avg Monetary | % of Revenue |
|---|---|---|---|---|---|---|
| Champion | [X] | [X]% | [X] days | [X] txns | ₦[X] | [X]% |
| Loyal | [X] | [X]% | [X] days | [X] txns | ₦[X] | [X]% |
| Promising | [X] | [X]% | [X] days | [X] txns | ₦[X] | [X]% |
| At Risk | [X] | [X]% | [X] days | [X] txns | ₦[X] | [X]% |

### Key Finding

[Write your own after running the notebook]

Template: "Champions represent [X]% of customers but generate [X]% of total revenue —
a [X]x revenue-to-headcount multiplier. The [X] At Risk customers represent
₦[X] in monthly revenue that is at risk of being lost if no retention action
is taken before February."

---

## Key Lessons Learned

1. **R scoring is inverted** — lower recency days = more recent = better score.
   Always verify: your most recently active customer must have R_score = 3.

2. **pd.qcut vs pd.cut** — qcut creates equal-frequency bins (same number of
   customers per bin). cut creates equal-width bins (same value range). Always
   use qcut for RFM so segments are balanced.

3. **RFM is point-in-time** — always date-stamp your output. A customer labelled
   At Risk in January could be a Champion in February. Rerun monthly.

4. **The Pareto check** — always compute % of customers vs % of revenue per
   segment. If Champions are <20% of customers but >50% of revenue, you have
   a concentration risk worth flagging to leadership.

5. **The output is actionable** — the CSV is what your manager actually uses.
   Each team gets the same file and filters to their segment.

---

## Files in This Folder

```
day10-rfm-segmentation/
├── README.md
├── palmpay_day10_rfm.ipynb
├── palmpay_rfm_segments.csv        ← exported RFM table for all teams
└── screenshots/
    └── rfm_segmentation.png        ← 2-panel scatter + revenue chart
```

---

*Part of the [30-Day Fintech Data Analyst Bootcamp](../README.md) — PalmPay Analytics Case Study*
