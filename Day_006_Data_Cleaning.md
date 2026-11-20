# Day 6: SQL Challenge - Data Cleaning (Deduplication & Null Handling)

## 📌 Business Scenario
A data engineer receives a dirty log of customer pageviews. Due to tracking glitches, the same pageview event is sometimes logged multiple times. In other cases, the page path is logged as `NULL` or empty, which needs to be replaced with a default value. 

We need to clean this dataset by:
1. Replacing missing or empty paths with `'home'`.
2. Keeping only the latest event log (highest `log_timestamp`) for each unique combination of `user_id`, `page_path`, and `session_id`.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Pageviews Table
CREATE TABLE pageviews (
    view_id INT PRIMARY KEY,
    user_id INT,
    session_id VARCHAR(50),
    page_path VARCHAR(255),
    log_timestamp TIMESTAMP
);

-- Insert Dirty Sample Data (contains duplicates and empty/NULL paths)
INSERT INTO pageviews (view_id, user_id, session_id, page_path, log_timestamp) VALUES
(1, 101, 'sess_abc123', '/products', '2026-05-28 10:00:00'),
(2, 101, 'sess_abc123', '/products', '2026-05-28 10:01:00'), -- Duplicate (keep this latest one)
(3, 102, 'sess_xyz789', '/cart', '2026-05-28 10:05:00'),
(4, 102, 'sess_xyz789', NULL, '2026-05-28 10:06:00'),    -- NULL path (replace with 'home')
(5, 101, 'sess_abc123', '/checkout', '2026-05-28 10:10:00'),
(6, 103, 'sess_qwe456', '/products', '2026-05-28 10:12:00'),
(7, 103, 'sess_qwe456', '/products', '2026-05-28 10:12:00'), -- Exact duplicate time (keep one with higher view_id)
(8, 102, 'sess_xyz789', '', '2026-05-28 10:20:00');         -- Empty string path (replace with 'home')
```

---

## ❓ The Question
Write an SQL query to produce a cleaned dataset of pageviews. The results must:
1. Standardize the `page_path` such that any `NULL` values or empty strings (`''`) are replaced with `'home'`.
2. Deduplicate the records by keeping only the latest record (based on `log_timestamp`) for each combination of `user_id`, standardized `page_path`, and `session_id`. If there is an exact tie in `log_timestamp`, select the one with the higher `view_id`.

---

## 💡 The Solution

```sql
WITH CleanedPageviews AS (
    SELECT 
        view_id,
        user_id,
        session_id,
        COALESCE(NULLIF(page_path, ''), 'home') AS clean_page_path,
        log_timestamp
    FROM pageviews
),
RankedPageviews AS (
    SELECT 
        view_id,
        user_id,
        session_id,
        clean_page_path,
        log_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, session_id, clean_page_path 
            ORDER BY log_timestamp DESC, view_id DESC
        ) AS rn
    FROM CleanedPageviews
)
SELECT 
    view_id,
    user_id,
    session_id,
    clean_page_path AS page_path,
    log_timestamp
FROM RankedPageviews
WHERE rn = 1
ORDER BY log_timestamp ASC;
```

---

## 📝 Explanation
- **Standardizing Paths**: The expression `COALESCE(NULLIF(page_path, ''), 'home')` handles both empty strings and NULLs. `NULLIF(page_path, '')` converts empty strings (`''`) into true `NULL` values. Subsequently, `COALESCE` replaces any `NULL` value with the default string `'home'`.
- **Identifying Duplicates**: The `ROW_NUMBER()` window function divides the data into partitions using the unique keys `user_id`, `session_id`, and our standardized `clean_page_path`.
- **Deduplication Filtering**: Inside each partition, the rows are ordered by `log_timestamp DESC` (to prioritize the newest log) and `view_id DESC` (to break ties). Selecting records with a row number (`rn`) of `1` returns exactly one row per partition, successfully deduplicating the table.
