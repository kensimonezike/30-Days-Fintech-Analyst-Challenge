# Day 11 — Cohort Analysis: Track Customer Retention Over Time

**Date completed:** [DD-MMM-2024]
**Tool:** Python 3.11 + Jupyter Notebook
**Time taken:** [X] minutes
**Phase:** 2 — Intermediate

---

## Business Scenario

My manager needed to know whether customers who signed up earlier perform better
than newer cohorts. Today I built a cohort analysis using customer signup months
as cohort labels, tracked their January 2024 activity, calculated retention rates,
and built a heatmap showing retention by cohort and period — the standard retention
tool used at every fintech company.

---

## What is Cohort Analysis?

A cohort groups customers by a shared characteristic — usually signup month.
Cohort analysis tracks how each group behaves across subsequent periods.

**Key question it answers:** Do customers who joined in Month X retain better
than customers who joined in Month Y?

---

## Code

### Cell 1: Assign Cohorts

```python
cust['cohort'] = cust['signup_date'].dt.to_period('M').astype(str)
df = df.merge(cust[['user_id','cohort','signup_date']], on='user_id', how='left')
```

### Cell 2: Build Cohort Matrix

```python
df['transaction_period'] = df['transaction_date'].dt.to_period('M')
df['signup_period']      = df['signup_date'].dt.to_period('M')
df['period_number'] = (
    (df['transaction_period'] - df['signup_period']).apply(lambda x: x.n)
)

cohort_data = df.groupby(['cohort','period_number'])['user_id'].nunique().reset_index()
cohort_data.columns = ['cohort','period_number','active_customers']

cohort_matrix = cohort_data.pivot_table(
    index='cohort', columns='period_number', values='active_customers'
)
```

### Cell 3: Retention Rates + Heatmap

```python
cohort_sizes = df.groupby('cohort')['user_id'].nunique()
retention = cohort_matrix.divide(cohort_sizes, axis=0) * 100

sns.heatmap(retention, annot=True, fmt='.1f', cmap='YlGn',
            vmin=0, vmax=100, linewidths=0.5, linecolor='white')
plt.title('PalmPay Customer Cohort Retention — January 2024')
plt.savefig('cohort_retention_heatmap.png', dpi=150, bbox_inches='tight')
```

### Cell 4: Cohort ARPU

```python
cohort_quality = df.groupby('cohort').agg(
    active_customers = ('user_id',       'nunique'),
    total_txns       = ('transaction_id','count'),
    total_volume     = ('amount_ngn',    'sum'),
    avg_txn_value    = ('amount_ngn',    'mean')
).round(1)
cohort_quality['arpu'] = (
    cohort_quality['total_volume'] / cohort_quality['active_customers']
).round(0)
cohort_quality.to_csv('palmpay_cohort_quality.csv')
```

---

## Results

### Cohort Sizes (fill in after running)

| Signup Cohort | Customers |
|---|---|
| [Cohort 1] | [X] |
| [Cohort 2] | [X] |
| [Cohort 3] | [X] |
| ... | ... |

### Retention Heatmap

See `screenshots/cohort_retention_heatmap.png`

| Cohort | Period 0 | Period 1 | Period 2 | Period 3 | ... |
|---|---|---|---|---|---|
| [Your cohort] | [X]% | [X]% | [X]% | [X]% | ... |

### ARPU by Cohort (fill in after running)

| Signup Cohort | Active Customers | Total Volume | ARPU |
|---|---|---|---|
| [Best ARPU cohort] | [X] | ₦[X] | ₦[X] |
| ... | ... | ... | ... |

---

## Cohort Findings

[Write your own after running the notebook]

Template: "The [month] signup cohort had the highest January ARPU at ₦[X], "
suggesting that [older/newer] customers generate more value per user. "
The [month] cohort had the highest retention rate at [X]%. "
[Older/Newer] cohorts appear to [outperform/underperform] more recent signups — "
[a positive/concerning] signal for the February acquisition campaign."

---

## Key Lessons Learned

1. **Use nunique() not count()** — retention measures whether a customer came back,
   not how many transactions they made. Always count unique user_ids.

2. **period_number is relative** — Period 3 means 3 months after signup, not
   March. Label your axes clearly.

3. **One month of data limits cohort depth** — with only January 2024, you can
   see snapshot activity but not a true multi-period retention curve. Note this
   limitation in all findings.

4. **ARPU per cohort ≠ retention** — a cohort with 50% retention but ₦500K ARPU
   is more valuable than 80% retention with ₦50K ARPU. Always report both.

5. **Cohort analysis + RFM is a powerful combination** — Day 10's RFM told you
   who your best customers are NOW. Day 11's cohort tells you WHICH signup month
   produced the best customers. Together they answer: who to acquire AND when.

---

## Files in This Folder

```
day11-cohort-analysis/
├── README.md
├── palmpay_day11_cohort.ipynb
├── palmpay_cohort_quality.csv
└── screenshots/
    ├── cohort_retention_heatmap.png
    └── cohort_arpu.png
```

---

*Part of the [30-Day Fintech Data Analyst Bootcamp](../README.md) — PalmPay Analytics Case Study*
