# Day 54: SQL Challenge - CTEs (Generating a Date Series to Fill Gaps)

## 📌 Business Scenario
A retail company is analyzing daily sales for August 2026. They need a time-series report showing the total sales amount for *every single day* of the month. 

However, there is a problem: on certain days (like Sundays or public holidays), the store was closed and zero sales occurred. If you simply `GROUP BY sale_date` on the `daily_sales` table, those zero-sales days will be completely omitted from the report. 

To fix this, we need to generate a continuous **Date Series** (a calendar table) on the fly and `LEFT JOIN` the sales data onto it.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Sales Table
CREATE TABLE daily_sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    amount DECIMAL(10, 2)
);

-- Insert Sample Data (Notice August 2nd and 3rd are missing!)
INSERT INTO daily_sales VALUES
(1, '2026-08-01', 150.00),
(2, '2026-08-01', 50.00),
(3, '2026-08-04', 200.00),
(4, '2026-08-05', 300.00);
```

---

## ❓ The Question
Write an SQL query using a Recursive CTE to generate a continuous calendar of dates from `'2026-08-01'` to `'2026-08-05'`. Then, calculate the total daily sales for each date in that range. 

Return the `calendar_date` and `total_sales`. Ensure that days with no sales return `0` instead of `NULL`. Order the output chronologically.

---

## 💡 The Solution

### MySQL 8.0+ / SQL Server (Using Recursive CTE)
```sql
WITH RECURSIVE DateSeries AS (
    -- Anchor Member: Start Date
    SELECT CAST('2026-08-01' AS DATE) AS calendar_date
    
    UNION ALL
    
    -- Recursive Member: Add 1 day until End Date is reached
    SELECT DATE_ADD(calendar_date, INTERVAL 1 DAY)
    FROM DateSeries
    WHERE calendar_date < '2026-08-05'
)
SELECT 
    d.calendar_date,
    -- Use COALESCE to replace NULL sums with 0
    COALESCE(SUM(s.amount), 0) AS total_sales
FROM DateSeries d
LEFT JOIN daily_sales s 
    ON d.calendar_date = s.sale_date
GROUP BY 
    d.calendar_date
ORDER BY 
    d.calendar_date;
```
*(Note for SQL Server: replace `DATE_ADD(..., INTERVAL 1 DAY)` with `DATEADD(day, 1, calendar_date)`).*

### PostgreSQL (Using built-in `generate_series`)
```sql
SELECT 
    d.calendar_date::DATE,
    COALESCE(SUM(s.amount), 0) AS total_sales
FROM generate_series('2026-08-01'::DATE, '2026-08-05'::DATE, '1 day'::INTERVAL) AS d(calendar_date)
LEFT JOIN daily_sales s 
    ON d.calendar_date = s.sale_date
GROUP BY 
    d.calendar_date
ORDER BY 
    d.calendar_date;
```

---

## 📝 Explanation
- **The Missing Date Problem**: Aggregating data inherently only groups the data that *exists*. A `LEFT JOIN` requires a left table that contains the complete, uninterrupted sequence you wish to report on.
- **Recursive CTE for Dates**: In dialects lacking a native series generator, a recursive CTE is the standard solution. 
  - The **Anchor** creates the starting boundary (`2026-08-01`). 
  - The **Recursive step** repeatedly takes the previous date and adds exactly one day, looping until it hits the `WHERE` clause condition boundary (`< '2026-08-05'`).
- **The `LEFT JOIN`**: We take our perfectly continuous `DateSeries` and `LEFT JOIN` the sporadic `daily_sales` table onto it. This guarantees every day is represented in the final output.
- **`COALESCE`**: For dates with no matches (Aug 2nd and 3rd), the `SUM(s.amount)` evaluates to `NULL`. Wrapping it in `COALESCE(..., 0)` elegantly converts those `NULL`s into `0`s for the final BI report.
