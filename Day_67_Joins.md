# Day 67: SQL Challenge - Joins (The Anti-Join vs NOT EXISTS)

## 📌 Business Scenario
An e-commerce platform's marketing team is launching a targeted email campaign. They want a list of all registered users who have **never placed a single order** since creating their account. 

Finding records in Table A that *do not* exist in Table B is a fundamental SQL pattern known as an **Anti-Join**. While there are several ways to write this query, understanding the nuances between them (especially regarding `NULL` handling and performance) is critical for advanced SQL developers.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Users Table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT, -- Foreign Key
    order_date DATE
);

-- Insert Sample Data
INSERT INTO users VALUES
(1, 'Alice Smith', 'alice@test.com'),
(2, 'Bob Jones', 'bob@test.com'),
(3, 'Charlie Ray', 'charlie@test.com'), -- Has never ordered
(4, 'David Green', 'david@test.com'); -- Has never ordered

INSERT INTO orders VALUES
(101, 1, '2026-08-01'),
(102, 1, '2026-08-15'),
(103, 2, '2026-08-10');
```

---

## ❓ The Question
Write an SQL query to find the `user_id` and `email` of users who have zero orders in the `orders` table. 

Provide two different solutions: one using a `LEFT JOIN` and one using a `NOT EXISTS` subquery. Order the results by `user_id`.

---

## 💡 The Solution

### Method 1: The `LEFT JOIN` (Anti-Join Pattern)
```sql
SELECT 
    u.user_id, 
    u.email
FROM users u
-- Step 1: Attempt to match every user to their orders
LEFT JOIN orders o 
    ON u.user_id = o.user_id
-- Step 2: Keep only the users where the join failed (resulting in NULLs)
WHERE o.order_id IS NULL
ORDER BY u.user_id;
```

### Method 2: The `NOT EXISTS` Subquery
```sql
SELECT 
    u.user_id, 
    u.email
FROM users u
WHERE NOT EXISTS (
    -- The database stops searching the moment it finds even 1 matching order
    SELECT 1 
    FROM orders o 
    WHERE o.user_id = u.user_id
)
ORDER BY u.user_id;
```

---

## 📝 Explanation
- **Method 1 (`LEFT JOIN` / `IS NULL`)**: This is the classic "Anti-Join". A standard `LEFT JOIN` grabs all users and attaches their order data. For users like Charlie and David who have no orders, the right side of the join evaluates to `NULL`. The `WHERE o.order_id IS NULL` filter then cleanly isolates these missing records.
- **Method 2 (`NOT EXISTS`)**: This approach uses a Correlated Subquery. For every user, it peeks into the `orders` table. Because it uses `EXISTS`, the database engine is smart enough to stop searching the instant it finds the *first* matching order. It doesn't waste time scanning all 100 orders for Alice; it finds 1, returns `TRUE`, and immediately excludes her.
- **Which is better?**: In modern relational databases (PostgreSQL, SQL Server, MySQL 8+), the query optimizer usually compiles both methods into the exact same execution plan, resulting in identical performance. However, `NOT EXISTS` is generally preferred by purists because its intent is perfectly clear.
- **Warning on `NOT IN`**: A third option is `WHERE user_id NOT IN (SELECT user_id FROM orders)`. While this works, it is **highly dangerous**. If the subquery returns even a single `NULL` value (e.g., an order with a missing `user_id`), the entire `NOT IN` statement evaluates to `UNKNOWN` and your query will suddenly return 0 rows. `NOT EXISTS` and Anti-Joins are immune to this trap.
