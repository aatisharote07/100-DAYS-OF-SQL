# Day 29: SQL Challenge - Aggregate Functions (Pivoting Row Data to Columns)

## 📌 Business Scenario
A retail management team wants to view a quarterly sales performance summary for the year 2026. The raw transaction table stores each sale on a separate row with its transaction date. 

To make the report easy to read for executives, the business intelligence team wants to pivot the row-level data. The output should display exactly one row per product category, with separate columns representing the total revenue for `Q1`, `Q2`, `Q3`, and `Q4`.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Sales Table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    category VARCHAR(50),
    revenue DECIMAL(10, 2),
    sale_date DATE
);

-- Insert Sample Data for 2026
INSERT INTO sales (sale_id, category, revenue, sale_date) VALUES
(1, 'Electronics', 1500.00, '2026-01-15'), -- Q1
(2, 'Electronics', 2200.00, '2026-04-10'), -- Q2
(3, 'Furniture', 800.00, '2026-03-05'),   -- Q1
(4, 'Furniture', 1200.00, '2026-07-20'),  -- Q3
(5, 'Electronics', 3000.00, '2026-10-05'), -- Q4
(6, 'Furniture', 1500.00, '2026-11-12'),  -- Q4
(7, 'Apparel', 600.00, '2026-02-14'),      -- Q1
(8, 'Apparel', 900.00, '2026-05-22'),      -- Q2
(9, 'Apparel', 1100.00, '2026-08-19');     -- Q3
```

---

## ❓ The Question
Write an SQL query to pivot the quarterly sales of each product category for the year 2026. The result should display the `category`, `q1_revenue`, `q2_revenue`, `q3_revenue`, and `q4_revenue`. If a category has no sales in a given quarter, display `0.00` instead of `NULL`. Order the output alphabetically by `category`.

---

## 💡 The Solution

### MySQL Solution
```sql
SELECT 
    category,
    COALESCE(SUM(CASE WHEN QUARTER(sale_date) = 1 THEN revenue END), 0.00) AS q1_revenue,
    COALESCE(SUM(CASE WHEN QUARTER(sale_date) = 2 THEN revenue END), 0.00) AS q2_revenue,
    COALESCE(SUM(CASE WHEN QUARTER(sale_date) = 3 THEN revenue END), 0.00) AS q3_revenue,
    COALESCE(SUM(CASE WHEN QUARTER(sale_date) = 4 THEN revenue END), 0.00) AS q4_revenue
FROM sales
WHERE YEAR(sale_date) = 2026
GROUP BY category
ORDER BY category;
```

### PostgreSQL Solution
```sql
SELECT 
    category,
    COALESCE(SUM(CASE WHEN EXTRACT(QUARTER FROM sale_date) = 1 THEN revenue END), 0.00) AS q1_revenue,
    COALESCE(SUM(CASE WHEN EXTRACT(QUARTER FROM sale_date) = 2 THEN revenue END), 0.00) AS q2_revenue,
    COALESCE(SUM(CASE WHEN EXTRACT(QUARTER FROM sale_date) = 3 THEN revenue END), 0.00) AS q3_revenue,
    COALESCE(SUM(CASE WHEN EXTRACT(QUARTER FROM sale_date) = 4 THEN revenue END), 0.00) AS q4_revenue
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2026
GROUP BY category
ORDER BY category;
```

---

## 📝 Explanation
- **Pivoting using Conditional Aggregation**: We use `CASE WHEN` inside the `SUM()` function. For each row:
  - If the quarter matches (e.g. `QUARTER(sale_date) = 1`), the `CASE` statement returns the `revenue`.
  - If the quarter does not match, it returns `NULL` (by default).
  - Since aggregate functions like `SUM` ignore `NULL` values, the expression sums *only* the transactions that took place in that specific quarter.
- **Extracting Quarters**: The MySQL function `QUARTER()` and the PostgreSQL syntax `EXTRACT(QUARTER FROM ...)` return the quarter integer (1, 2, 3, or 4) for a given date.
- **COALESCE Defaulting**: In cases where a category has no sales in a particular quarter (e.g. Electronics in Q3), the `SUM` returns `NULL`. Wrapping the expression in `COALESCE(..., 0.00)` replaces the `NULL` with a clean `0.00` value.
