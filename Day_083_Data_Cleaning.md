# Day 83: SQL Challenge - Data Cleaning (Forward Fill / Missing Value Imputation)

## 📌 Business Scenario
An IoT energy monitoring platform tracks daily electricity consumption from industrial smart meters. Due to intermittent network outages and sensor packet drops, some daily records contain a `NULL` reading.

Data science models and billing pipelines cannot handle missing values in time-series data. The engineering team has decided to apply the industry-standard **Last Observation Carried Forward (LOCF)** technique (commonly known as **Forward Fill**). 

Any `NULL` value must be imputed using the most recent valid, non-NULL reading recorded for that specific meter.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Meter Readings Table
CREATE TABLE meter_readings (
    reading_id INT PRIMARY KEY,
    meter_id INT,
    reading_date DATE,
    kwh_reading DECIMAL(10, 2) -- Can contain NULLs due to sensor drops
);

-- Insert Sample Data
INSERT INTO meter_readings VALUES
(1, 101, '2026-10-01', 120.50), -- Base reading
(2, 101, '2026-10-02', NULL),   -- Drop! Should be imputed with 120.50
(3, 101, '2026-10-03', NULL),   -- Drop! Should be imputed with 120.50
(4, 101, '2026-10-04', 135.00), -- New valid reading
(5, 101, '2026-10-05', NULL),   -- Drop! Should be imputed with 135.00
(6, 102, '2026-10-01', 50.00),  -- Meter 102
(7, 102, '2026-10-02', NULL);   -- Drop! Should be imputed with 50.00
```

---

## ❓ The Question
Write an SQL query to forward-fill missing `kwh_reading` values for each meter chronologically. If a row has a `NULL` reading, impute it with the most recent non-NULL reading for that `meter_id`.

Return `reading_id`, `meter_id`, `reading_date`, and the final `imputed_kwh_reading`. Order the results by `meter_id` and `reading_date`.

---

## 💡 The Solution

### Universal ANSI SQL Approach (Works in MySQL, PostgreSQL, SQL Server, SQLite):
```sql
WITH ReadingGroups AS (
    -- Step 1: Create a group ID that only increments on non-NULL values
    SELECT 
        reading_id,
        meter_id,
        reading_date,
        kwh_reading,
        COUNT(kwh_reading) OVER (
            PARTITION BY meter_id 
            ORDER BY reading_date 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS value_group
    FROM meter_readings
)
-- Step 2: Use MAX() over the value_group to broadcast the non-NULL value to all NULLs in the group
SELECT 
    reading_id,
    meter_id,
    reading_date,
    MAX(kwh_reading) OVER (
        PARTITION BY meter_id, value_group
    ) AS imputed_kwh_reading
FROM ReadingGroups
ORDER BY meter_id, reading_date;
```

*(Note for Snowflake, Oracle, BigQuery, and Databricks users: You can also use the native clause `LAST_VALUE(kwh_reading IGNORE NULLS) OVER (PARTITION BY meter_id ORDER BY reading_date)`).*

---

## 📝 Explanation
Forward Fill is one of the trickiest interview questions in SQL because window functions like `LAG()` only look back a fixed number of rows (e.g., 1 row), which fails when there are multiple consecutive `NULL` values.

The universal ANSI SQL solution uses a clever two-step grouping technique:
- **Step 1: The `COUNT(column)` Property**:
  - `COUNT(*)` counts every row, but `COUNT(column_name)` **ignores `NULL`s**.
  - As we run a cumulative `COUNT(kwh_reading)` ordered by date:
    - Day 1 (120.50) -> count = `1`
    - Day 2 (NULL) -> count stays `1`
    - Day 3 (NULL) -> count stays `1`
    - Day 4 (135.00) -> count increments to `2`
    - Day 5 (NULL) -> count stays `2`
  - This effectively clusters every valid reading and all subsequent `NULL` rows following it into the same `value_group`.
- **Step 2: Broadcasting with `MAX()`**:
  - Inside each `(meter_id, value_group)` partition, there is exactly one non-NULL value and zero or more `NULL`s.
  - Applying `MAX(kwh_reading)` across that partition grabs that single valid value and carries it across every `NULL` in the group, perfectly completing the forward fill!
