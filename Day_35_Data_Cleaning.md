# Day 35: SQL Challenge - Data Cleaning (Forward Fill / LOCF)

## 📌 Business Scenario
A telemetry database logs daily sensor temperatures. To conserve sensor battery and network bandwidth, the device only writes a temperature reading when the temperature actually changes. On days with no change, the log contains a `NULL` value. 

For downstream forecasting models to function, we need to clean this dataset by performing a **Forward Fill**—also known as **Last Observation Carried Forward (LOCF)**—to replace each `NULL` value with the last recorded non-null temperature.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Sensor Logs Table
CREATE TABLE sensor_logs (
    log_date DATE PRIMARY KEY,
    temperature DECIMAL(5, 2) -- Can be NULL
);

-- Insert Sample Data
INSERT INTO sensor_logs (log_date, temperature) VALUES
('2026-07-01', 22.50),
('2026-07-02', NULL),  -- Should inherit 22.50
('2026-07-03', NULL),  -- Should inherit 22.50
('2026-07-04', 24.00),
('2026-07-05', NULL),  -- Should inherit 24.00
('2026-07-06', 23.80),
('2026-07-07', NULL);  -- Should inherit 23.80
```

---

## ❓ The Question
Write an SQL query to perform a **Forward Fill (LOCF)** on the `temperature` column. For each row, return the `log_date`, the original `temperature` reading, and the cleaned `filled_temperature` carrying forward the last active temperature. Order the output chronologically by `log_date`.

---

## 💡 The Solution

```sql
WITH GroupedLogs AS (
    SELECT 
        log_date,
        temperature,
        -- Step 1: Create a running count of non-null values to define group buckets
        COUNT(temperature) OVER (ORDER BY log_date) AS temp_group
    FROM sensor_logs
)
SELECT 
    log_date,
    temperature,
    -- Step 2: Grab the max (non-null) value within each group bucket
    MAX(temperature) OVER (PARTITION BY temp_group) AS filled_temperature
FROM GroupedLogs
ORDER BY log_date;
```

---

## 📝 Explanation
- **Step 1: Creating Group Buckets (`COUNT`)**: The aggregate function `COUNT(column)` only counts non-null values. When run as a running total window function (`OVER (ORDER BY log_date)`), the count only increments when a new non-null temperature is found. 
  - For July 1, 2, and 3, the running count of non-nulls remains `1` (`temp_group = 1`).
  - For July 4 and 5, the count becomes `2` (`temp_group = 2`).
  - This groups each parent temperature with its following child `NULL` values.
- **Step 2: Filling Nulls (`MAX`)**: In the outer query, we apply `MAX(temperature) OVER (PARTITION BY temp_group)`. Because each group contains exactly one non-null value (the first value of that group) and otherwise only `NULL`s, taking the `MAX` within that partition dynamically copies the first reading onto all the trailing null rows in the same group.
- **Why not LAG?**: Standard `LAG()` only looks back a fixed number of rows (e.g. `LAG(temperature, 1)`). If we have multiple consecutive nulls (like July 2 and 3), looking back 1 row on July 3 would return another `NULL`. The running count bucket method resolves any number of consecutive nulls.
