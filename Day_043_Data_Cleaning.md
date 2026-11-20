# Day 43: SQL Challenge - Data Cleaning (Detecting & Removing Fuzzy Duplicates)

## 📌 Business Scenario
A CRM system has accumulated duplicate customer records over time due to manual data entry errors. Unlike exact duplicates, these are **fuzzy duplicates** — records where the name and email match, but the phone number may differ slightly, or the accounts were created at different times.

A data engineering team needs to identify and deduplicate these records, keeping only the **most recently created** record for each unique `(email)` combination and discarding the older entries.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    created_at DATETIME
);

-- Insert Sample Data (with fuzzy duplicates by email)
INSERT INTO customers VALUES
(1, 'Alice Johnson', 'alice@example.com', '555-1234', '2025-01-10 09:00:00'),
(2, 'Alice Johnson', 'alice@example.com', '555-9876', '2025-06-15 14:00:00'), -- Newer duplicate
(3, 'Alice Johnson', 'ALICE@EXAMPLE.COM', '555-1234', '2024-11-01 08:00:00'), -- Older duplicate (different casing!)
(4, 'Bob Smith', 'bob@example.com', '555-4444', '2025-03-22 11:00:00'),       -- Unique
(5, 'Charlie Ray', 'charlie@example.com', '555-7777', '2025-05-05 10:00:00'),
(6, 'Charlie Ray', 'charlie@example.com', '555-8888', '2025-07-01 09:00:00'); -- Newer duplicate
```

---

## ❓ The Question
Write an SQL query to:
1. Identify all duplicate records by normalizing the `email` column to lowercase before comparing.
2. Among duplicates, retain the row with the most recent `created_at` timestamp.
3. Return a result set of **only the records that should be deleted** (the older duplicates), showing their `customer_id`, `full_name`, `email`, and `created_at`.

---

## 💡 The Solution

```sql
WITH RankedCustomers AS (
    SELECT 
        customer_id,
        full_name,
        email,
        created_at,
        -- Rank within each email group: most recent = rank 1
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(email)
            ORDER BY created_at DESC, customer_id DESC
        ) AS rn
    FROM customers
)
-- Select the records to DELETE (all rows except the most recent per email)
SELECT 
    customer_id,
    full_name,
    email,
    created_at
FROM RankedCustomers
WHERE rn > 1
ORDER BY LOWER(email), created_at;

-- To actually remove these records in MySQL / PostgreSQL:
-- DELETE FROM customers
-- WHERE customer_id IN (
--     SELECT customer_id
--     FROM (
--         SELECT customer_id,
--                ROW_NUMBER() OVER (
--                    PARTITION BY LOWER(email)
--                    ORDER BY created_at DESC, customer_id DESC
--                ) AS rn
--         FROM customers
--     ) ranked
--     WHERE rn > 1
-- );
```

---

## 📝 Explanation
- **Email Normalization with `LOWER()`**: The raw data contains `alice@example.com` and `ALICE@EXAMPLE.COM`. Without normalizing, they would be treated as separate emails. By applying `LOWER(email)` inside the `PARTITION BY` clause, all casing variants of the same email are grouped into one dedupe bucket.
- **`ROW_NUMBER()` for Deduplication**: Within each email group (`PARTITION BY LOWER(email)`), rows are ranked by `created_at DESC` so the most recent row receives `rn = 1`. A secondary sort on `customer_id DESC` acts as a tie-breaker if two records share an identical timestamp.
- **Identifying Stale Records**: Rows where `rn > 1` are older duplicates that should be deleted, leaving only one canonical record per email.
- **Safe DELETE Pattern**: Most SQL engines (MySQL, PostgreSQL, SQL Server) do not allow referencing a CTE directly in a `DELETE` statement. The workaround shown wraps the window function logic inside a subquery to produce the list of `customer_id` values to remove.
