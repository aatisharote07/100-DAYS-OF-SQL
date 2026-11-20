# Day 62: SQL Challenge - Window Functions (Identifying Local Peaks with LAG & LEAD)

## 📌 Business Scenario
A quantitative finance team is analyzing historical stock market data to fine-tune a trading algorithm. As part of their feature engineering, they need to identify all "Local Peaks" in a stock's closing price. 

A **Local Peak** is defined as a day where the closing price was strictly greater than both the day immediately preceding it *and* the day immediately following it.

This time-series comparison is perfectly suited for the `LAG()` and `LEAD()` window functions.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Stock Prices Table
CREATE TABLE stock_prices (
    trade_date DATE,
    ticker VARCHAR(10),
    close_price DECIMAL(10, 2),
    PRIMARY KEY (trade_date, ticker)
);

-- Insert Sample Data for 'TECH'
INSERT INTO stock_prices VALUES
('2026-08-01', 'TECH', 150.00),
('2026-08-02', 'TECH', 155.00), -- Peak! (Higher than Aug 1 and Aug 3)
('2026-08-03', 'TECH', 152.00),
('2026-08-04', 'TECH', 158.00),
('2026-08-05', 'TECH', 160.00), -- Peak! (Higher than Aug 4 and Aug 6)
('2026-08-06', 'TECH', 159.00),
('2026-08-07', 'TECH', 165.00); -- Not a peak yet, no "next day" data
```

---

## ❓ The Question
Write an SQL query to find all the dates where the `'TECH'` stock reached a local peak. 

Use a Common Table Expression (CTE) to fetch the previous day's price and the next day's price for each row. Then, filter the results to only show the peaks. 

Return the `trade_date`, `ticker`, and the `close_price` (aliased as `peak_price`). Order chronologically.

---

## 💡 The Solution

```sql
WITH AdjacentPrices AS (
    -- Step 1: Use window functions to peek backward and forward in time
    SELECT 
        trade_date,
        ticker,
        close_price,
        LAG(close_price) OVER (
            PARTITION BY ticker 
            ORDER BY trade_date
        ) AS prev_price,
        LEAD(close_price) OVER (
            PARTITION BY ticker 
            ORDER BY trade_date
        ) AS next_price
    FROM stock_prices
    WHERE ticker = 'TECH'
)
-- Step 2: Filter for rows where the current price is strictly greater than both neighbors
SELECT 
    trade_date,
    ticker,
    close_price AS peak_price
FROM AdjacentPrices
WHERE close_price > prev_price 
  AND close_price > next_price
ORDER BY trade_date;
```

---

## 📝 Explanation
- **`LAG()`**: This window function allows you to look backward. By partitioning by the `ticker` and ordering chronologically, `LAG(close_price)` fetches the price from exactly 1 row prior (the previous day's closing price).
- **`LEAD()`**: This function does the exact opposite. `LEAD(close_price)` fetches the price from 1 row ahead (the next day's closing price). 
- **The CTE Necessity**: Window functions cannot be evaluated directly inside a `WHERE` clause because they are calculated *after* the `WHERE` clause executes in the SQL order of operations. Therefore, we must calculate `prev_price` and `next_price` inside a CTE first, and then apply our filtering logic (`> prev_price AND > next_price`) in the outer query.
- **Edge Cases**: For the very first day in the dataset, `prev_price` evaluates to `NULL`. For the very last day, `next_price` evaluates to `NULL`. The standard `>` operator yields `UNKNOWN` when comparing against a `NULL`, meaning the first and last days will naturally (and correctly) fail the peak test.
