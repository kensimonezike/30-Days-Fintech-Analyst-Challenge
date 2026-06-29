# Day 09 — Time-Series Analysis: Rolling Averages + Week-over-Week Growth

**Date completed:** [DD-MMM-2024]
**Tool:** Python 3.11 + Jupyter Notebook
**Time taken:** [X] minutes
**Phase:** 2 — Intermediate

---

## Business Scenario

The CFO asked whether PalmPay is growing. Today I built a full time-series
analysis of January 2024 daily transaction data — filling missing dates,
computing 3-day and 7-day rolling averages, calculating week-over-week growth
rates, and assembling a 4-panel trend dashboard saved as a PNG.

---

## New Concepts Learned

| Concept | Code | What it does |
|---|---|---|
| Fill missing dates | `reindex(full_range, fill_value=0)` | Ensures every calendar day appears — critical for rolling averages |
| Rolling average | `df['col'].rolling(7, min_periods=1).mean()` | Moving window average — smooths daily noise |
| pct_change() | `weekly['col'].pct_change() * 100` | Week-over-week % change |
| Cumulative sum | `daily['col'].cumsum()` | Running total — shows acceleration |
| savefig() | `plt.savefig('file.png', dpi=150)` | Exports chart as image file |
| Subplots grid | `fig, axes = plt.subplots(2, 2, figsize=(14,9))` | Multi-panel dashboard figure |

---

## Task 1 — Daily Time-Series

```python
daily = df.groupby('transaction_date').agg(
    txn_count    = ('transaction_id', 'count'),
    total_volume = ('amount_ngn',    'sum'),
    success_count= ('status', lambda x: (x=='Success').sum()),
    failed_count = ('status', lambda x: (x=='Failed').sum())
).reset_index()

full_range = pd.date_range('2024-01-01', '2024-01-31', freq='D')
daily = daily.set_index('transaction_date').reindex(full_range, fill_value=0).reset_index()
daily.columns = ['date'] + list(daily.columns[1:])
daily['success_rate'] = np.where(daily['txn_count']>0,
    daily['success_count']/daily['txn_count']*100, np.nan)
```

**Result:** 31 rows — one per calendar day in January 2024, including zero-transaction days.

---

## Task 2 — Rolling Averages

```python
daily['txn_3d_avg'] = daily['txn_count'].rolling(3,  min_periods=1).mean().round(1)
daily['txn_7d_avg'] = daily['txn_count'].rolling(7,  min_periods=1).mean().round(1)
daily['vol_7d_avg'] = daily['total_volume'].rolling(7, min_periods=1).mean().round(0)
```

**[Your result]** — record the 7-day MA value at the end of January vs the start.
If it's higher, the month ended on an upward trend. If lower, it was declining.

---

## Task 3 — Week-over-Week Growth

```python
daily['week'] = ((daily['date'].dt.day - 1) // 7) + 1

weekly = daily.groupby('week').agg(
    txns   = ('txn_count',    'sum'),
    volume = ('total_volume', 'sum'),
    success= ('success_count','sum'),
    failed = ('failed_count', 'sum')
)
weekly['txn_wow_pct'] = weekly['txns'].pct_change() * 100
weekly['vol_wow_pct'] = weekly['volume'].pct_change() * 100
weekly['success_rate']= (weekly['success'] / weekly['txns'] * 100).round(1)
```

**[Your result]** — fill in your weekly table here:

| Week | Transactions | Volume | Success Rate | WoW Txn Growth | WoW Vol Growth |
|---|---|---|---|---|---|
| 1 | [X] | ₦[X] | [X]% | — | — |
| 2 | [X] | ₦[X] | [X]% | [X]% | [X]% |
| 3 | [X] | ₦[X] | [X]% | [X]% | [X]% |
| 4 | [X] | ₦[X] | [X]% | [X]% | [X]% |
| 5 | [X] | ₦[X] | [X]% | [X]% | [X]% |

---

## Task 4 — Trend Dashboard

```python
fig, axes = plt.subplots(2, 2, figsize=(14, 9))
# Chart 1: Daily count + 7-day MA
# Chart 2: 7-day rolling volume
# Chart 3: Daily success rate with average reference line
# Chart 4: WoW growth bars (green = positive, red = negative)
plt.savefig('trend_dashboard.png', dpi=150, bbox_inches='tight')
```

See `screenshots/trend_dashboard.png` for the saved output.

---

## Trend Summary

[Write your own 1-paragraph summary here after running the notebook]

Template: "January 2024 transaction activity was [growing/flat/declining] across
the month. The 7-day rolling average moved from [X] transactions/day in week 1
to [X] transactions/day in week 4. The strongest week-over-week growth was
[+X%] in week [X], while week [X] saw the sharpest contraction at [X]%.
Daily success rate fluctuated between [X]% and [X]%, with the highest
reliability on [date] ([X]% success rate)."

---

## Files in This Folder

```
day09-time-series/
├── README.md
├── palmpay_day9_timeseries.ipynb
└── screenshots/
    └── trend_dashboard.png          ← 4-panel dashboard, saved with savefig()
```

---

*Part of the [30-Day Fintech Data Analyst Bootcamp](../README.md) — PalmPay Analytics Case Study*
