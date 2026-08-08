# Day 49: SQL Challenge - Window Functions (FIRST_VALUE, LAST_VALUE & Window Frames)

## 📌 Business Scenario
A global logistics and shipping company tracks packages as they move through various distribution centers. Every time a package is scanned, a new row is inserted into the database. 

The customer support team needs a summarized view. Instead of seeing every scan, they want a single row per package showing its **Origin City** (the very first location it was scanned) and its **Current City** (the most recent location it was scanned).

This is a perfect use case for `FIRST_VALUE()` and `LAST_VALUE()`, but it comes with a famous "gotcha" regarding default window frames!

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Package Scans Table
CREATE TABLE package_scans (
    scan_id INT PRIMARY KEY,
    package_id INT,
    scan_location VARCHAR(100),
    scan_timestamp DATETIME
);

-- Insert Sample Data
INSERT INTO package_scans VALUES
(1, 101, 'New York', '2026-08-10 08:00:00'),   -- Pkg 101 Origin
(2, 101, 'Philadelphia', '2026-08-10 14:00:00'),
(3, 101, 'Washington DC', '2026-08-11 09:00:00'), -- Pkg 101 Current
(4, 102, 'Los Angeles', '2026-08-09 10:00:00'),  -- Pkg 102 Origin
(5, 102, 'Phoenix', '2026-08-10 11:00:00'),      -- Pkg 102 Current
(6, 103, 'Chicago', '2026-08-11 12:00:00');      -- Pkg 103 Origin & Current
```

---

## ❓ The Question
Write an SQL query to retrieve a unique list of packages alongside their `origin_city` and `current_city`. You must use the `FIRST_VALUE()` and `LAST_VALUE()` window functions. 

Return `package_id`, `origin_city`, and `current_city`. Order the output by `package_id`.

---

## 💡 The Solution

```sql
SELECT DISTINCT
    package_id,
    -- Get the first location in the chronological partition
    FIRST_VALUE(scan_location) OVER (
        PARTITION BY package_id 
        ORDER BY scan_timestamp ASC
    ) AS origin_city,
    
    -- Get the last location in the chronological partition
    LAST_VALUE(scan_location) OVER (
        PARTITION BY package_id 
        ORDER BY scan_timestamp ASC 
        -- Crucial: Override the default window frame!
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS current_city
FROM package_scans
ORDER BY package_id;
```

---

## 📝 Explanation
- **`FIRST_VALUE()`**: Operates exactly as expected. By partitioning by the package and sorting by time ascending, it looks at the entire group and grabs the first value (New York for package 101).
- **The `LAST_VALUE()` Gotcha**: By default, SQL standard window frames are defined as `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. 
  - If we simply wrote `LAST_VALUE(scan_location) OVER (PARTITION BY package_id ORDER BY scan_timestamp ASC)`, the "last value" it sees up to the *current row* is just the current row's value! This would return the wrong result when we apply `DISTINCT`.
  - **The Fix**: We must explicitly define the window frame as `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`. This forces the window to look at the *entire* partition from start to finish for every single row, successfully grabbing the true final destination (Washington DC for package 101).
- **`DISTINCT`**: Because window functions append results to every row rather than grouping them, using `DISTINCT` collapses the multiple scan rows per package into a single summary row.
