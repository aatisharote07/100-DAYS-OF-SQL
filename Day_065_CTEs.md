# Day 65: SQL Challenge - CTEs (Calculating Year-over-Year Growth)

## 📌 Business Scenario
A Chief Financial Officer (CFO) is analyzing the company's long-term sales trends. Because retail sales are highly seasonal (e.g., holiday spikes in December), comparing December's revenue to November's revenue is not very helpful. 

Instead, the CFO wants a **Year-over-Year (YoY) Growth** report. They need to compare the revenue of a specific month (e.g., August 2026) to the exact same month from the previous year (August 2025), and calculate the percentage increase or decrease.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Monthly Sales Table
CREATE TABLE monthly_sales (
    report_date DATE PRIMARY KEY,
    revenue DECIMAL(12, 2)
);

-- Insert Sample Data
INSERT INTO monthly_sales VALUES
('2025-01-01', 50000.00),
('2025-02-01', 45000.00),
('2025-12-01', 120000.00), -- 2025 Holiday Spike
('2026-01-01', 60000.00),  -- 2026 Jan: Increased from 50k to 60k
('2026-02-01', 40000.00),  -- 2026 Feb: Dropped from 45k to 40k
('2026-12-01', 150000.00); -- 2026 Holiday Spike: Increased from 120k to 150k
```

---

## ❓ The Question
Write an SQL query using a Common Table Expression (CTE) and a Self-Join to calculate the Year-over-Year growth percentage for each month. 

Return the `current_year`, `month`, `current_revenue`, `previous_year_revenue`, and the `yoy_growth_pct` (rounded to 2 decimal places). Order the results chronologically by year and month. If a previous year's data is missing (like for 2025), the previous revenue and growth should gracefully return `NULL`.

---

## 💡 The Solution

```sql
WITH ExtractedSales AS (
    -- Step 1: Extract the Year and Month components for easier joining
    SELECT 
        EXTRACT(YEAR FROM report_date) AS sales_year,
        EXTRACT(MONTH FROM report_date) AS sales_month,
        revenue
    FROM monthly_sales
)
SELECT 
    curr.sales_year AS current_year,
    curr.sales_month AS month,
    curr.revenue AS current_revenue,
    prev.revenue AS previous_year_revenue,
    -- Step 3: The standard growth formula -> ((New - Old) / Old) * 100
    ROUND(((curr.revenue - prev.revenue) / prev.revenue) * 100, 2) AS yoy_growth_pct
FROM ExtractedSales curr
-- Step 2: Self-Join the CTE to match the SAME month, but the PREVIOUS year
LEFT JOIN ExtractedSales prev 
    ON curr.sales_month = prev.sales_month 
    AND curr.sales_year = prev.sales_year + 1
ORDER BY 
    curr.sales_year, 
    curr.sales_month;
```

---

## 📝 Explanation
- **Why not use `LAG(revenue, 12)`?**: You *could* use a window function to look exactly 12 rows back. However, that assumes the database has perfectly continuous data for every single month without gaps. If a month had 0 sales and the row was entirely missing, `LAG(..., 12)` would grab the wrong month. The Self-Join approach is much safer and more robust.
- **The CTE (`ExtractedSales`)**: First, we use `EXTRACT()` (or `YEAR()`/`MONTH()` depending on your dialect) to isolate the year and month into separate columns. This makes our join logic much cleaner.
- **The Self-Join**: We alias the CTE twice in the outer query (`curr` for Current Year, and `prev` for Previous Year). We join them where the `sales_month` matches perfectly (e.g., January to January), but where the `curr.sales_year` is exactly one year higher than the `prev.sales_year` (2026 matches to 2025).
- **The Growth Formula**: The mathematical formula for percentage growth is `((Current - Previous) / Previous) * 100`. 
  - For January 2026: `((60000 - 50000) / 50000) * 100` = **+20.00%**
  - For February 2026: `((40000 - 45000) / 45000) * 100` = **-11.11%**
