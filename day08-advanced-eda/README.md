# Day 08 — Advanced EDA: Feature Engineering + Correlation Analysis

**Date completed:** [DD-MMM-2024]
**Tool:** Python 3.11 + Jupyter Notebook
**Time taken:** [X] minutes
**Score:** [X/100]
**Phase:** 2 — Intermediate (Days 8-15)

---

## Business Scenario

Phase 1 answered WHAT happened in January. Phase 2 starts answering WHAT DRIVES
WHAT. Today I merged the transactions and customers datasets into one
analysis-ready DataFrame, engineered 5 new features that did not exist in the
raw data, and ran a correlation analysis to find real relationships between
variables — laying the foundation for churn modelling later in the bootcamp.

---

## Part 1 — Merging Datasets

```python
df = df_clean.merge(customers, on='user_id', how='inner')
print(f'Merged shape: {df.shape}')
```

`merge(on='user_id', how='inner')` is the Pandas equivalent of SQL's
`INNER JOIN ... ON user_id = user_id` from Day 4.

**Result:** Merged shape: (36, 16) — 36 successful+failed+pending transactions
matched to customer records (using the corrected user_ids from Day 4).

---

## Part 2 — 5 Engineered Features

| Feature | Code | What it captures |
|---|---|---|
| `tenure_days` | `(transaction_date - signup_date).dt.days` | How long the customer has been registered at time of transaction |
| `tenure_band` | `pd.cut(tenure_days, bins=[...])` | New (0-90d) / Established (91-365d) / Loyal (365d+) |
| `is_high_value` | `(amount_ngn > avg_amount).astype(int)` | Binary flag for above-average transactions |
| `is_successful` | `(status == 'Success').astype(int)` | Binary version of status — required for correlation |
| `amount_rank_within_user` | `groupby('user_id')['amount_ngn'].rank()` | Each customer's transactions ranked by size |

```python
df['tenure_days'] = (df['transaction_date'] - df['signup_date']).dt.days

df['tenure_band'] = pd.cut(
    df['tenure_days'],
    bins=[-1, 90, 365, 99999],
    labels=['New (0-90d)', 'Established (91-365d)', 'Loyal (365d+)']
)

avg_amount = df[df['amount_ngn'] > 0]['amount_ngn'].mean()
df['is_high_value'] = (df['amount_ngn'] > avg_amount).astype(int)

df['is_successful'] = (df['status'] == 'Success').astype(int)

df['amount_rank_within_user'] = df.groupby('user_id')['amount_ngn'] \
    .rank(ascending=False, method='dense')
```

> 💡 **Key trick:** `.mean()` of a binary 0/1 column directly gives you the rate.
> `df['is_successful'].mean()` returns 0.72 — the exact success rate from Day 3-6.

---

## Part 3 — Correlation Analysis

```python
numeric_cols = ['amount_ngn', 'tenure_days', 'is_high_value',
                'is_successful', 'amount_rank_within_user']
corr_matrix = df[numeric_cols].corr()

sns.heatmap(corr_matrix, annot=True, cmap='coolwarm', center=0,
            fmt='.2f', square=True, linewidths=1)
plt.title('Correlation Matrix — Transaction Features', fontweight='bold')
```

**Correlation strength reference:**
| |r| range | Interpretation |
|---|---|
| < 0.1 | Negligible |
| 0.1 – 0.3 | Weak |
| 0.3 – 0.5 | Moderate |
| 0.5 – 0.7 | Strong |
| > 0.7 | Very strong |

**[Your result]** — fill in your actual correlation matrix values here after running
the notebook. Record the strongest positive pair, strongest negative pair, and any
pair that surprised you.

---

## Tenure vs Success Rate

```python
tenure_success = df.groupby('tenure_band', observed=True).agg(
    success_rate=('is_successful', 'mean'),
    txn_count=('transaction_id', 'count')
).round(3)
tenure_success['success_rate_pct'] = tenure_success['success_rate'] * 100
```

**[Your result]** — does success rate increase, decrease, or stay flat as tenure
increases? Note the pattern and txn_count per band (small bands are less reliable).

---

## Account Tier vs Transaction Amount Distribution

```python
sns.boxplot(data=df[df['amount_ngn']>0], x='account_tier', y='amount_ngn',
            order=['Standard','Premium','VIP'], palette='Blues')
```

**[Your result]** — record median and spread per tier. Connects back to the Day 5/7
finding that Premium tier has the lowest ARPU — does the boxplot support or
complicate that finding?

---

## Key Lessons Learned

1. **merge() = SQL JOIN** — `how='inner'/'left'/'right'` maps directly to the JOIN
   types learned on Day 4. Always check `df.shape` immediately after merging to
   catch silent row loss.

2. **Binary flags (0/1) unlock correlation and rate calculations** — converting
   `is_successful` to 0/1 means `.mean()` gives the success rate directly, and the
   column becomes usable in `df.corr()`.

3. **pd.cut() bins continuous data into categories** — the Pandas equivalent of a
   nested Excel IF formula for bucketing values into ranges.

4. **Correlation ≠ causation** — a relationship between tenure and success rate
   does not prove tenure causes higher success. Always phrase findings as
   "associated with," never "causes," without a controlled experiment.

5. **Weak correlations are still findings** — a correlation near zero tells you
   what does NOT drive an outcome, which narrows the search for what does.
   Do not discard a near-zero result as "nothing found."

---

## Files in This Folder

```
day08-advanced-eda/
├── README.md                       ← this file
├── palmpay_day8_eda.ipynb          ← notebook with merge, features, correlation
├── palmpay_features.csv            ← exported DataFrame with all 5 new columns
└── screenshots/
    ├── merged_dataframe_shape.png
    ├── correlation_heatmap.png
    ├── tenure_vs_success_chart.png
    └── tier_vs_amount_boxplot.png
```

---

*Part of the [30-Day Fintech Data Analyst Bootcamp](../README.md) — PalmPay Analytics Case Study*
