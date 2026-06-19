# Day 06. Python for Data Analysis: Pandas, NumPy + First EDA

**Tool:** Python 3.14.6 + Jupyter Notebook
---

## Business Scenario

My manager asked me to stop relying solely on Excel and start using Python for
data analysis. Today I loaded the PalmPay January 2024 transaction dataset into
a Jupyter notebook, profiled it programmatically, cleaned all 5 data quality
issues using Pandas, and performed a first exploratory data analysis (EDA)
with 5 charts and business findings.

---

## Environment Setup

| Tool | Version |
|---|---|
| Python | 3.14.6 |
| pandas | Latest |
| numpy | Latest |
| matplotlib | Latest |
| seaborn | Latest |
| jupyter | Latest |
| openpyxl | Latest |

**Install command:**
```bash
pip install pandas numpy matplotlib seaborn jupyter openpyxl
or
pip3 install pandas numpy matplotlib seaborn jupyter openpyxl
```

---

## Python vs Excel. Same Tasks Compared

| Task | Excel (Days 1-2) | Python (Day 6) | Winner |
|---|---|---|---|
| Data profile (8 columns) | 25 min - manual formulas | 3 cells, ~10 seconds | Python |
| Count nulls per column | `=COUNTBLANK()` per column | `df.isnull().sum()` - one line | Python |
| Unique value count | `=SUMPRODUCT(1/COUNTIF(...))` | `df.nunique()` - one line | Python |
| Fix status casing | `=PROPER(F2)` drag to F51 | `df['status'].str.title()` - one line | Python |
| Replace negatives with 0 | `=IF(E2<0,0,E2)` drag to K51 | `df['amount'].clip(lower=0)` - one line | Python |
| Filter rows | Excel filter dropdown | `df[df['status'] == 'Success']` | Python |
| Group + aggregate | Pivot table - drag and drop | `df.groupby().agg()` | Tie |
| Scalability | Breaks at ~1M rows | Handles 100M+ rows | Python |

---

## Notebook Structure

The notebook `palmpay_day6_eda.ipynb` contains 9 cells:

| Cell | Purpose |
|---|---|
| Cell 1 | Import libraries, load Excel file |
| Cell 2 | Data profile - df.info(), df.describe() |
| Cell 3 | Missing values, unique counts, duplicates |
| Cell 4 | Clean all 5 issues - df_clean |
| Cell 5 | Task 1 - Status breakdown + bar chart |
| Cell 6 | Task 2 - Volume by region + horizontal bar chart |
| Cell 7 | Task 3 - Daily trend + line chart |
| Cell 8 | Task 4 - Channel failure rate + grouped bar chart |
| Cell 9 | Task 5 - Amount distribution + histogram + boxplot |

---

## Data Cleaning (Cell 4)

All 5 data quality issues from Day 1 fixed in Python:

```python
# Start with a full copy — never modify the original
df_clean = df.copy()

# FIX 1: Standardise status casing — Python IS case-sensitive unlike Excel
df_clean['status'] = df_clean['status'].str.strip().str.title()

# FIX 2: Replace negative amounts with 0
df_clean['amount_ngn'] = df_clean['amount_ngn'].clip(lower=0)

# FIX 3: Convert to datetime safely + correct year outliers
df_clean['transaction_date'] = pd.to_datetime(df_clean['transaction_date'], errors='coerce')

mask = df_clean['transaction_date'].dt.year != 2024

df_clean.loc[mask, 'transaction_date'] = df_clean.loc[mask, 'transaction_date'].apply(
    lambda x: x.replace(year=2024) if pd.notnull(x) else x
)

# FIX 4: Fill missing regions with 'Unknown'
df_clean['region'] = df_clean['region'].fillna('Unknown')

# FIX 5: Flag (don't delete) duplicate transaction IDs
df_clean['is_duplicate'] = df_clean.duplicated(
    subset=['transaction_id'], keep=False
)

# Verify all 5 fixes worked
print(f'Null regions: {df_clean["region"].isnull().sum()}')
print(f'Negative amounts: {(df_clean["amount_ngn"] < 0).sum()}')
print(f'Status values: {sorted(df_clean["status"].dropna().unique())}')

print(
    f'Date range: {df_clean["transaction_date"].min().date()} to '
    f'{df_clean["transaction_date"].max().date()}'
)
```

**Verification output after cleaning:**
```
Null regions:     0
Negative amounts: 0
Status values:    ['Failed', 'Pending', 'Success']
Date range:       2024-01-01 to 2024-01-31
```

---

## Task 1 - Status Breakdown

**Business question:** What percentage of January transactions succeeded, failed, or are pending?

```python
status_summary = df_clean.groupby('status').agg(
    count      = ('transaction_id', 'count'),
    total_vol  = ('amount_ngn',    'sum'),
    avg_amount = ('amount_ngn',    'mean')
).round(2)

status_summary['pct'] = (
    status_summary['count'] / status_summary['count'].sum() * 100
).round(1)

print(status_summary.sort_values('count', ascending=False))
```

**Result:**

| status | count | total_vol | avg_amount | pct |
|---|---|---|---|---|
| Success | 36 | 5,402,840 | 150,078.89 | 72.0% |
| Failed | 9 | 689,320 | 76,591.11 | 18.0% |
| Pending | 5 | 742,240 | 148,448.00 | 10.0% |

**Business finding:** 72% of January transactions completed successfully, 18% failed,
and 10% are pending. The 18% failure rate is well above the industry benchmark of 5%
and represents approximately ₦689,320 in transaction volume that generated zero revenue.
Engineering must reduce the failure rate before the February growth campaign.

---

## Task 2 - Volume by Region (Successful Only)

**Business question:** Which region generates the most successful transaction volume?

```python
df_ok = df_clean[df_clean['status'] == 'Success']  # boolean indexing = SQL WHERE

region_vol = df_ok.groupby('region').agg(
    txn_count  = ('transaction_id', 'count'),
    total_vol  = ('amount_ngn',    'sum'),
    avg_amount = ('amount_ngn',    'mean')
).round(2).sort_values('total_vol', ascending=False)

print(region_vol)
```

**Result:**

| region | txn_count | total_vol | avg_amount |
|---|---|---|---|
| Lagos | 9 | 2,125,170.00 | 236,130.00 |
| Kano | 8 | 1,021,240.00 | 127,655.00 |
| Unknown | 5 | 995,720.00 | 199,144.00 |
| Port Harcourt | 5 | 510,720.00 | 102,144.00 |
| Abuja | 5 | 327,370.00 | 65,474.00 |
| Ibadan | 4 | 422,620.00 | 105,655.00 |

**Business finding:** Lagos generated the highest successful transaction volume at
₦2,125,170 - more than double Kano in second place. Lagos customers also have the
highest average transaction value at ₦236,130 per transaction, confirming a
higher-spending customer segment. The 5 'Unknown' region transactions (₦995,720)
represent a reporting gap that must be resolved by recovering region data from
source systems using user_id as a lookup key.

---

## Task 3 - Daily Transaction Trend

**Business question:** How did transaction activity change across January 2024?

```python
df_clean['transaction_date'] = pd.to_datetime(df_clean['transaction_date'])

daily = df_clean.groupby('transaction_date').agg(
    txn_count    = ('transaction_id', 'count'),
    daily_volume = ('amount_ngn',    'sum')
)

peak = daily['txn_count'].idxmax()
print(f'Peak day: {peak.date()} with {daily["txn_count"].max()} transactions')
```

**Key results:**
- Peak day: **[your peak date]** with **[X]** transactions
- Active transaction days in January: **[X] of 31**
- Trend direction: **[flat / growing / declining]** across the month

**Business finding:** Transaction activity peaked on [date] with [X] transactions.
The trend across January was [direction], with the first week averaging [X] transactions/day
vs [X] transactions/day in the final week. [If declining: the growth team should investigate
retention and re-engagement strategies before February ends.]

---

## Task 4 - Channel Failure Rate

**Business question:** Which channels have a reliability problem requiring engineering escalation?

```python
ch = df_clean.groupby('channel').agg(
    total   = ('transaction_id', 'count'),
    success = ('status', lambda x: (x == 'Success').sum()),
    failed  = ('status', lambda x: (x == 'Failed').sum()),
).assign(
    success_rate = lambda x: (x['success'] / x['total'] * 100).round(1),
    failure_rate = lambda x: (x['failed']  / x['total'] * 100).round(1)
).sort_values('failure_rate', ascending=False)

print(ch)
# Channels above 15% - Python equivalent of SQL HAVING
print('Flagged channels:', list(ch[ch['failure_rate'] > 15].index))
```

**Result:**

| channel | total | success | failed | success_rate | failure_rate |
|---|---|---|---|---|---|
| Web | 16 | 10 | 5 | 62.5% | 31.2% |
| App | 10 | 7 | 2 | 70.0% | 20.0% |
| USSD | 16 | 13 | 2 | 81.2% | 12.5% |
| Agent | 8 | 6 | 0 | 75.0% | 0.0% |

**Flagged channels above 15%:** Web, App

**Business finding:** Web (31.2%) and App (20.0%) both exceed the 15% failure rate
escalation threshold. Web alone loses approximately ₦467,000 in failed transaction
volume per month. Agent is the reliability benchmark with zero failures - engineering
should study what makes Agent infrastructure more resilient. Web reliability must be
resolved before the February growth campaign.

---

## Task 5 - Amount Distribution + Outlier Detection

**Business question:** How are transaction amounts distributed, and which transactions should be flagged as high-value outliers?

```python
amounts = df_clean[df_clean['amount_ngn'] > 0]['amount_ngn']

q1    = amounts.quantile(0.25)
q3    = amounts.quantile(0.75)
iqr   = q3 - q1
fence = q3 + 1.5 * iqr  # standard outlier threshold

print(f'Mean:          NGN {amounts.mean():>12,.2f}')
print(f'Median:        NGN {amounts.median():>12,.2f}')
print(f'Std deviation: NGN {amounts.std():>12,.2f}')
print(f'Q1 (25th pct): NGN {q1:>12,.2f}')
print(f'Q3 (75th pct): NGN {q3:>12,.2f}')
print(f'Outlier fence: NGN {fence:>12,.2f}')

outliers = df_clean[df_clean['amount_ngn'] > fence]
print(f'\nOutlier transactions: {len(outliers)}')
```

**Key statistics:**
- Mean: ₦142,390.00
- Median: ₦[your result]
- Std deviation: ₦[your result]
- Outlier fence (Q3 + 1.5×IQR): ₦[your result]
- Transactions above fence: **[X]** flagged as high-value

> 💡 **Mean vs Median:** If mean > median, the distribution is right-skewed -
> a few very large transactions are pulling the average up. This is typical in
> fintech transaction data. Always report both when describing amounts to
> a non-technical audience.

**Business finding:** The outlier fence at ₦[X] flags [X] transactions as statistically
high-value. These transactions are [X]x the average and should be included in the
monthly high-value transaction review log as a standard AML (Anti-Money Laundering)
monitoring practice.

---

## Key Lessons Learned

1. **Python IS case-sensitive, Excel is NOT** - `df[df['status'] == 'success']`
   returns 0 rows after cleaning because all values are 'Success'. Always use
   exact casing after str.title().

2. **Never modify the original DataFrame** - always use `df_clean = df.copy()`.
   If you overwrite df, you lose the raw data permanently.

3. **boolean indexing is SQL WHERE** - `df[df['status'] == 'Success']` is the
   Python equivalent of `WHERE status = 'Success'`. Master this pattern.

4. **Mean vs Median tells you about skewness** - a large gap between the two means
   your data has outliers pulling the average. Median is more representative of a
   typical transaction.

5. **IQR method is the standard outlier approach** - Q3 + 1.5×IQR is used in
   fraud detection, transaction monitoring, and risk scoring across the industry.

6. **Run All cells before submitting** - use Kernel > Restart & Run All to verify
   the notebook runs top to bottom without errors before sharing.

---

## Files in This Folder

```
day06-python-eda/
├── README.md                        ← this file
├── palmpay_day6_eda.ipynb           ← Jupyter notebook with all 9 cells
├── palmpay_jan2024_clean.csv        ← cleaned dataset exported from Python
└── screenshots/
    ├── cell4_verification_output.png
    ├── task1_status_bar_chart.png
    ├── task2_region_bar_chart.png
    ├── task3_daily_trend_line.png
    ├── task4_channel_failure_bar.png
    └── task5_distribution_histogram_boxplot.png
```

---
