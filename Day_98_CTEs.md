# Day 98: SQL Challenge - CTEs (Recursive Date Range & Missing Time-Series Imputation)

## 📌 Business Scenario
A revenue operations analyst is preparing a daily gross sales trend chart for an e-commerce dashboard. The reporting date window spans from **November 1, 2026 to November 7, 2026**.

In typical transaction databases, records are only created when sales actually occur. If zero sales happen on a specific day (such as a weekend or holiday), no row is inserted into the `daily_sales` table. 

If this raw table is fed directly into BI tools, dates with zero revenue simply disappear from the horizontal axis, distorting the time-series visualization and breaking moving-average calculations.

To solve this, data engineers use a **Recursive CTE to generate a continuous calendar spine**, performing an outer join against transaction facts to guarantee that every single calendar day is present with a default of `$0.00`.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Daily Sales Fact Table
CREATE TABLE daily_sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    revenue DECIMAL(10, 2)
);

-- Insert Sample Data (Note: Nov 2, Nov 4, and Nov 6 have ZERO sales!)
INSERT INTO daily_sales VALUES
(1, '2026-11-01', 1250.00),
(2, '2026-11-03', 850.00),
(3, '2026-11-03', 400.00), -- Multiple sales on Nov 3 ($1,250.00 total)
(4, '2026-11-05', 2100.00),
(5, '2026-11-07', 950.00);
```

---

## ❓ The Question
Write an SQL query using a `WITH RECURSIVE` Common Table Expression to construct a complete calendar table between `'2026-11-01'` and `'2026-11-07'`. 

`LEFT JOIN` this calendar spine to the `daily_sales` table so that days without sales are displayed with a revenue of `0.00` rather than `NULL`. 

Return `calendar_date` and `total_revenue` (rounded to 2 decimal places). Order the results chronologically by `calendar_date ASC`.

---

## 💡 The Solution

*(Standard ANSI SQL / MySQL 8.0+ / PostgreSQL syntax)*

```sql
-- Step 1: Recursive CTE generating the date spine
WITH RECURSIVE DateSpine AS (
    -- Anchor Member: Start Date
    SELECT DATE('2026-11-01') AS calendar_date
    
    UNION ALL
    
    -- Recursive Member: Increment by 1 day until reaching End Date
    SELECT DATE_ADD(calendar_date, INTERVAL 1 DAY)
    FROM DateSpine
    WHERE calendar_date < '2026-11-07'
)
-- Step 2: Outer join the calendar spine to sales data and coalesce missing values
SELECT 
    d.calendar_date,
    COALESCE(SUM(s.revenue), 0.00) AS total_revenue
FROM DateSpine d
LEFT JOIN daily_sales s 
    ON d.calendar_date = s.sale_date
GROUP BY d.calendar_date
ORDER BY d.calendar_date ASC;
```

*(Note for PostgreSQL users: Replace `DATE_ADD(calendar_date, INTERVAL 1 DAY)` with `(calendar_date + INTERVAL '1 day')::DATE`, or use `generate_series(DATE '2026-11-01', DATE '2026-11-07', INTERVAL '1 day')`).*
*(Note for SQL Server users: Omit the keyword `RECURSIVE`, and use `DATEADD(day, 1, calendar_date)`).*

---

## 📝 Explanation

### The Date Spine Architecture
- **Why Can't We Just Group By `sale_date`?**: 
  - Standard `GROUP BY sale_date` only groups rows that physically exist in the table. 
  - November 2, 4, and 6 would never appear in the query output, creating gaps in line charts and breaking lag-based window functions.
- **Anchor Member**: 
  - Evaluates once, outputting `'2026-11-01'`.
- **Recursive Step**: 
  - `DATE_ADD(calendar_date, INTERVAL 1 DAY)` adds 24 hours per recursion loop. 
  - The termination clause `WHERE calendar_date < '2026-11-07'` halts the engine as soon as November 7 is generated, outputting exactly 7 consecutive date rows.
- **The Outer Join (`LEFT JOIN`)**: 
  - Keeps all 7 generated dates on the left side of the join. 
  - For dates with sales (Nov 1, 3, 5, 7), the rows match and aggregate normally via `SUM(s.revenue)`.
  - For empty days (Nov 2, 4, 6), `s.revenue` evaluates to `NULL`.
- **`COALESCE(SUM(s.revenue), 0.00)`**: 
  - Intercepts the aggregate `NULL` and gracefully converts it into `$0.00`, providing a clean, production-ready time-series feed for visualization tools.
