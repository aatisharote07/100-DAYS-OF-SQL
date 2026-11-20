# Day 61: SQL Challenge - Data Cleaning (Splitting Delimited Strings into Rows)

## 📌 Business Scenario
A data engineering team is migrating data from a legacy CRM system. Unfortunately, the old system stored customer marketing tags as a single, messy, comma-separated string in a single column (e.g., `"VIP, Returning , High Value"`).

To properly analyze the frequency of each tag or join them to other marketing tables, these strings must be **split and unnested** into standard relational rows (one tag per row per customer). Furthermore, messy spacing around the commas needs to be cleaned up.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    tags_string VARCHAR(255)
);

-- Insert Sample Data
INSERT INTO customers VALUES
(1, 'Alice Smith', 'VIP, Returning , High Value'),
(2, 'Bob Jones', 'New User, Discount Seeker'),
(3, 'Charlie Ray', 'Churn Risk'),
(4, 'David Green', NULL);
```

---

## ❓ The Question
Write an SQL query to split the comma-separated `tags_string` into individual rows. 

Ensure that any leading or trailing whitespace around the split tags is removed (e.g., `" Returning "` should become `"Returning"`). Customers with a `NULL` tag string should be excluded. 

Return the `customer_id`, `name`, and the cleaned `tag`. Order the results by `customer_id`, and then alphabetically by `tag`.

---

## 💡 The Solution

*(Note: String splitting is highly dialect-specific. Below are solutions for the two most common modern dialects).*

### PostgreSQL Solution
```sql
SELECT 
    customer_id,
    name,
    -- Step 1: STRING_TO_ARRAY splits the string into an array
    -- Step 2: UNNEST expands the array into separate rows
    -- Step 3: TRIM removes any messy whitespace
    TRIM(UNNEST(STRING_TO_ARRAY(tags_string, ','))) AS tag
FROM customers
WHERE tags_string IS NOT NULL
ORDER BY customer_id, tag;
```

### SQL Server Alternative (2016+)
```sql
SELECT 
    c.customer_id,
    c.name,
    -- TRIM cleans up the split value provided by STRING_SPLIT
    TRIM(s.value) AS tag
FROM customers c
-- CROSS APPLY acts like a join that evaluates the function for every row
CROSS APPLY STRING_SPLIT(c.tags_string, ',') s
WHERE c.tags_string IS NOT NULL
ORDER BY c.customer_id, tag;
```

---

## 📝 Explanation
- **The Anti-Pattern**: Storing multiple distinct values in a single delimited string violates the First Normal Form (1NF) of relational database design. It makes grouping, counting, and joining incredibly difficult.
- **The PostgreSQL Approach**: 
  - `STRING_TO_ARRAY('A, B', ',')` converts the string into an array: `{'A', ' B'}`.
  - `UNNEST()` is an incredibly powerful set-returning function. It takes that array and explodes it vertically, creating a new row for every element in the array while duplicating the other columns (`customer_id`, `name`) alongside it.
- **The SQL Server Approach**: `STRING_SPLIT` is a table-valued function. It returns a temporary table with a single column named `value`. By using `CROSS APPLY`, we join the main `customers` table to the results of the `STRING_SPLIT` function evaluated *specifically* for that row's string.
- **The `TRIM()` Polish**: Because humans often type spaces after commas (e.g., `A, B, C`), simply splitting by `,` leaves leading spaces (` B`, ` C`). Wrapping the split output in `TRIM()` ensures pristine data.
