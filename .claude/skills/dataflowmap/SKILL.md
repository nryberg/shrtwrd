---
name: dataflowmap
description: Map a data process (SQL, pandas, Excel, or any analytics/data engineering task) as a Data Flow Map of symbol-tagged steps across Source → Focus → Build. Use when the user runs /dfm or asks to map, document, or analyze a data flow.
---

# Data Flow Map Skills

## `/dfm` — Map a Data Flow

Apply the Data Flow Map framework to analyze, document, or build a data process.

A **Data Flow Map** breaks any analytics or data engineering task into a sequence of named steps across three motions: **Source → Focus → Build**. Each step is tagged with a symbol so the intent is immediately scannable.

### Symbols

| Symbol | Motion | Action | Description |
|--------|--------|--------|-------------|
| `@` | — | Tag | Name a flow |
| `O` | Source | Get | Find the primary data source |
| `X` | Source | Fix | Modify or clean data |
| `+` | Source | Join | Combine with other sources |
| `v` | Focus | Cut | Drop Data |
| `^` | Focus | Keep | Keep Data |
| `\` | Focus | Sort | Order data |
| `]` | Build | Box | Group or categorize |
| `#` | Build | Size | Measure / aggregate |
| `=` | Build | Ship | Produce the final result |

### Grouping 

An analysis typically consists of multiple stages with individual names.  For instance, you might source sales, location, and customer data, then join them together to analyze sales by region.

- @sales (o x + ^ v \ ] # = )
- @customers (o x + ^ v \ ] # = )
- @locations (o x + ^ v \ ] # = )
- @mix_sales_customers (@sales + @customers + @locations)

### How to Apply

When a user shares a SQL query, Python dataframe operation, Excel formula, or any data process:

1. Identify the **flow name** and tag it with `@`.
2. Walk through the logic and assign the appropriate symbol to each step.
3. Write the map as a compact table or list using the symbols above.
4. If multiple flows exist, tag each one separately and show how they relate.

### SQL Mapping Reference

| SQL Element | Symbol | Label |
|-------------|--------|-------|
| Primary `FROM` table | `O` | Get |
| `CAST`, column expressions | `X` | Fix |
| `JOIN` | `+` | Join |
| `WHERE` | `v` | Cut |
| `SELECT col1, col2` | `^` | Keep |
| `ORDER BY` | `\` | Sort |
| `GROUP BY` | `]` | Box |
| `SUM()`, `COUNT()`, etc. | `#` | Size |
| `CREATE TABLE` / final output | `=` | Ship |

### pandas Mapping Reference

| pandas Element | Symbol | Label |
|----------------|--------|-------|
| `pd.read_csv()`, `pd.read_sql()`, etc. | `O` | Get |
| `pd.to_datetime()`, column assignments | `X` | Fix |
| `df.merge()` | `+` | Join |
| `df[df['col'] condition]` | `v` | Cut |
| `df[['col1', 'col2']]` | `^` | Keep |
| `df.sort_values()` | `\` | Sort |
| `df.groupby()` | `]` | Box |
| `.agg()`, `.sum()`, `.count()`, etc. | `#` | Size |
| `.to_csv()`, `.to_sql()`, final assignment | `=` | Ship |

### Example

**Input SQL:**
```sql
CREATE TABLE monthly_revenue AS
SELECT region, SUM(amount) AS total
FROM orders
JOIN customers ON orders.customer_id = customers.id
WHERE CAST(order_date AS DATE) >= '2025-01-01'
GROUP BY region
ORDER BY total DESC;
```

**Data Flow Map:**
```
@ Monthly Revenue
O  orders
X  cast order_date as date
+  customers
^  region, amount
v  order_date >= 2025-01-01
]  region
#  SUM(amount)
\  total DESC
=  monthly_revenue
```

**Input pandas:**
```python
df = pd.read_csv('orders.csv')
df['order_date'] = pd.to_datetime(df['order_date'])
df = df.merge(customers, on='customer_id')
df = df[df['order_date'] >= '2025-01-01']
df = df[['region', 'amount']]
result = df.groupby('region').agg({'amount': 'sum'}).sort_values('amount', ascending=False)
result.to_csv('monthly_revenue.csv')
```

**Data Flow Map:**
```
@ Monthly Revenue
O  orders.csv
X  cast order_date to datetime
+  customers
v  order_date >= 2025-01-01
^  region, amount
]  region
#  SUM(amount)
\  amount DESC
=  monthly_revenue.csv
```

### Output Format

Produce the map as a clean symbol-prefixed list, one step per line, grouped by motion if helpful. Include a brief label after each symbol describing the specific operation in plain language.
