# Day 23: SQL Challenge - CTEs (Month-over-Month Revenue Growth)

## 📌 Business Scenario
A SaaS startup wants to evaluate their financial performance across the first half of the year. The finance team needs a monthly breakdown showing:
1. Total revenue collected in the current month.
2. Total revenue collected in the previous month.
3. The Month-over-Month (MoM) revenue growth rate percentage.

To build this pipeline, we will combine string formatting, window functions, and multi-stage CTEs.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Payments Table
CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    amount DECIMAL(10, 2),
    payment_date DATE
);

-- Insert Sample Data
INSERT INTO payments (payment_id, amount, payment_date) VALUES
(1, 12000.00, '2026-01-15'),
(2, 8000.00, '2026-01-20'),
(3, 22000.00, '2026-02-10'),
(4, 18000.00, '2026-02-28'),
(5, 45000.00, '2026-03-05'),
(6, 42000.00, '2026-04-12'),
(7, 48000.00, '2026-05-18'),
(8, 52000.00, '2026-06-25');
```

---

## ❓ The Question
Write an SQL query using a Common Table Expression (CTE) to calculate the Month-over-Month (MoM) revenue growth. The query should return:
- `payment_month` (formatted as `'YYYY-MM'`)
- `current_month_revenue`
- `previous_month_revenue`
- `mom_growth_pct` (rounded to 2 decimal places)

---

## 💡 The Solution

### MySQL Solution
```sql
WITH MonthlyRevenue AS (
    -- Step 1: Calculate total revenue per month
    SELECT 
        DATE_FORMAT(payment_date, '%Y-%m') AS payment_month,
        SUM(amount) AS current_month_revenue
    FROM payments
    GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
),
MonthlyGrowth AS (
    -- Step 2: Use LAG to pull the previous month's revenue
    SELECT 
        payment_month,
        current_month_revenue,
        LAG(current_month_revenue, 1) OVER (ORDER BY payment_month) AS previous_month_revenue
    FROM MonthlyRevenue
)
-- Step 3: Compute the percentage growth rate
SELECT 
    payment_month,
    current_month_revenue,
    previous_month_revenue,
    ROUND(
        (current_month_revenue - previous_month_revenue) * 100.0 / NULLIF(previous_month_revenue, 0),
        2
    ) AS mom_growth_pct
FROM MonthlyGrowth
ORDER BY payment_month;
```

### PostgreSQL Solution
```sql
WITH MonthlyRevenue AS (
    SELECT 
        TO_CHAR(payment_date, 'YYYY-MM') AS payment_month,
        SUM(amount) AS current_month_revenue
    FROM payments
    GROUP BY TO_CHAR(payment_date, 'YYYY-MM')
),
MonthlyGrowth AS (
    SELECT 
        payment_month,
        current_month_revenue,
        LAG(current_month_revenue, 1) OVER (ORDER BY payment_month) AS previous_month_revenue
    FROM MonthlyRevenue
)
SELECT 
    payment_month,
    current_month_revenue,
    previous_month_revenue,
    ROUND(
        (current_month_revenue - previous_month_revenue) * 100.0 / NULLIF(previous_month_revenue, 0),
        2
    ) AS mom_growth_pct
FROM MonthlyGrowth
ORDER BY payment_month;
```

---

## 📝 Explanation
- **`MonthlyRevenue` CTE**: Groups payments chronologically by calendar month (parsing dates using `DATE_FORMAT` in MySQL or `TO_CHAR` in PostgreSQL) and sums up the total cash intake.
- **`MonthlyGrowth` CTE**: Uses the `LAG` window function to capture the `current_month_revenue` of the previous month's row.
- **MoM Percentage Formula**: Calculates growth using `(current_revenue - previous_revenue) * 100 / previous_revenue`. 
- **Division-by-Zero Protection**: The first month has no previous month record, resulting in a `previous_month_revenue` of `NULL` (and thus `0` value). The `NULLIF(previous_month_revenue, 0)` function prevents SQL division-by-zero crashes, returning `NULL` for January's growth.
