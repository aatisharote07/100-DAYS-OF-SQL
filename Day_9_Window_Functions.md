# Day 9: SQL Challenge - Window Functions (Cumulative Sum) 

## 📌 Business Scenario
A finance director wants to monitor day-over-day cash flow for the month. They need a report showing the daily net revenue and the cumulative running total of revenue generated since the beginning of the month to assess company liquidity and cash growth.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Transactions Table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    transaction_date DATE,
    amount DECIMAL(10, 2),
    transaction_type VARCHAR(20) -- 'deposit' (revenue) or 'withdrawal' (expense)
);

-- Insert Sample Data
INSERT INTO transactions (transaction_id, transaction_date, amount, transaction_type) VALUES
(101, '2026-06-01', 5000.00, 'deposit'),
(102, '2026-06-01', 1200.00, 'deposit'),
(103, '2026-06-02', 300.00, 'withdrawal'),
(104, '2026-06-02', 4500.00, 'deposit'),
(105, '2026-06-03', 1500.00, 'deposit'),
(106, '2026-06-04', 2000.00, 'withdrawal'),
(107, '2026-06-04', 3500.00, 'deposit'),
(108, '2026-06-05', 800.00, 'deposit');
```

---

## ❓ The Question
Write an SQL query to calculate the daily net revenue (deposits represent positive values, withdrawals represent negative values) and the cumulative running balance (running total of net revenue) ordered by date.

---

## 💡 The Solution

```sql
WITH DailyNetRevenue AS (
    SELECT 
        transaction_date,
        SUM(CASE WHEN transaction_type = 'deposit' THEN amount ELSE -amount END) AS net_revenue
    FROM transactions
    GROUP BY transaction_date
)
SELECT 
    transaction_date,
    net_revenue,
    SUM(net_revenue) OVER (
        ORDER BY transaction_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_revenue
FROM DailyNetRevenue
ORDER BY transaction_date;
```

---

## 📝 Explanation
- **`DailyNetRevenue` CTE**: This CTE groups all logs by date and calculates the net income for each day. We use a conditional `CASE WHEN` statement to treat deposits as positive values and withdrawals as negative values before running the `SUM` aggregation.
- **Cumulative Window `SUM`**: We apply the `SUM` aggregate function as a window function using `OVER (ORDER BY transaction_date)`. The engine processes the rows in chronological order, accumulating the `net_revenue` as it moves forward.
- **Window Frame**: The clause `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` explicitly defines the window frame. It forces the query to sum all daily net revenue from the very first day up to the current row's date, successfully creating the running balance.
