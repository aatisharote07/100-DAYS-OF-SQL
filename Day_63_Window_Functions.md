# Day 63: SQL Challenge - Window Functions (Calculating Moving Averages)

## 📌 Business Scenario
A SaaS startup experiences significant volatility in its month-to-month revenue (e.g., massive spikes in December due to annual renewals, followed by drops in January). 

To smooth out this volatility and better understand their true growth trend, the CFO has requested a report showing the **3-Month Rolling Average Revenue** (also known as a moving average or trailing average) alongside the raw monthly revenue.

This requires defining a specific "Window Frame" to limit how far back the average calculation looks.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Monthly Revenue Table
CREATE TABLE monthly_revenue (
    report_month DATE PRIMARY KEY,
    revenue DECIMAL(12, 2)
);

-- Insert Sample Data
INSERT INTO monthly_revenue VALUES
('2026-01-01', 10000.00),
('2026-02-01', 15000.00), -- 2-month avg: 12,500
('2026-03-01', 20000.00), -- 3-month avg: 15,000 (Jan+Feb+Mar)
('2026-04-01', 10000.00), -- 3-month avg: 15,000 (Feb+Mar+Apr)
('2026-05-01', 30000.00), -- 3-month avg: 20,000 (Mar+Apr+May)
('2026-06-01', 20000.00); -- 3-month avg: 20,000 (Apr+May+Jun)
```

---

## ❓ The Question
Write an SQL query to calculate the 3-month rolling average revenue for each month. 

The calculation for any given month should include the revenue from that current month, plus the revenue from the *two strictly preceding months*. 

Return the `report_month`, the raw `revenue`, and the `rolling_3_month_avg` (rounded to 2 decimal places). Order the results chronologically.

---

## 💡 The Solution

```sql
SELECT 
    report_month,
    revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY report_month 
            -- Explicitly define the window frame:
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 
    2) AS rolling_3_month_avg
FROM monthly_revenue
ORDER BY report_month;
```

---

## 📝 Explanation
- **The Core Problem**: Standard aggregate functions like `AVG()` compress all rows into a single number. Standard window functions like `AVG() OVER(ORDER BY report_month)` default to calculating a cumulative running average (from the beginning of time up to the current row). Neither is what we want here!
- **The Window Frame (`ROWS BETWEEN`)**: By adding the `ROWS BETWEEN` clause to the `OVER()` statement, we manually override the default behavior.
  - `2 PRECEDING`: Tells the engine to look back exactly two rows.
  - `CURRENT ROW`: Tells the engine to stop at the current row being evaluated.
- **The Result**: 
  - For **March** (`2026-03-01`), the engine looks at Mar (Current), Feb (1 Preceding), and Jan (2 Preceding). It averages 20k + 15k + 10k to get exactly `15,000.00`.
  - For **April** (`2026-04-01`), the window slides down. It looks at Apr (Current), Mar (1 Preceding), and Feb (2 Preceding). It drops January from the calculation entirely!
- **Edge Cases**: For January and February, there are not enough preceding rows to form a full 3-month lookback. The SQL engine gracefully handles this by simply averaging whatever is available within the frame boundaries (Jan is just averaged by itself; Feb averages Jan+Feb).
