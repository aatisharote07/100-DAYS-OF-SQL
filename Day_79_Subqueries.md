# Day 79: SQL Challenge - Subqueries (The Semi-Join & EXISTS)

## 📌 Business Scenario
A marketing team is preparing an email blast to thank their active customers. They have requested a simple list containing the `name` and `email` of every user who has placed **at least one order** in the company's history. 

A junior analyst wrote the following query using an `INNER JOIN`:
```sql
SELECT DISTINCT u.name, u.email
FROM users u
JOIN orders o ON u.user_id = o.user_id;
```
While this produces the correct result, it is incredibly inefficient. If a power user has placed 500 orders, the database engine joins their profile 500 times, only to have the `DISTINCT` keyword painstakingly compress it back down to 1 row at the very end.

You need to rewrite this query using a **Semi-Join** pattern via the `EXISTS` operator to drastically improve performance.

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
(3, 'Charlie Ray', 'charlie@test.com'); -- Never placed an order

INSERT INTO orders VALUES
(101, 1, '2026-01-05'),
(102, 1, '2026-02-15'), -- Alice ordered twice
(103, 1, '2026-03-20'), -- Alice ordered three times
(104, 2, '2026-01-10'); -- Bob ordered once
```

---

## ❓ The Question
Write a query to fetch the `name` and `email` of active users without using any `JOIN`s in the `FROM` clause and without using the `DISTINCT` keyword. 

Instead, use a correlated subquery with the `EXISTS` operator to filter the users. Order the results alphabetically by `name`.

---

## 💡 The Solution

```sql
SELECT 
    u.name, 
    u.email
FROM users u
-- The Semi-Join Pattern
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.user_id = u.user_id
)
ORDER BY u.name;
```

---

## 📝 Explanation
- **What is a Semi-Join?**: A traditional `JOIN` physically combines columns from both tables and can multiply rows (fan-out) if there are 1-to-many relationships. A **Semi-Join** uses the second table *strictly as a filter*. It checks if a match exists, but it never actually retrieves or attaches the columns from the second table, entirely avoiding the fan-out problem.
- **How `EXISTS` works**: The `EXISTS` operator executes a correlated subquery for every row in the outer `users` table. 
  - For Alice (`user_id = 1`), it peeks into the `orders` table. 
  - The instant it finds Order 101, it returns `TRUE` and immediately **stops searching**. It doesn't waste time scanning Orders 102 and 103!
- **Performance Gains**: Because it "short-circuits" the search the moment a single match is found, and because it inherently prevents row duplication (meaning no expensive `DISTINCT` sorting is required later), `EXISTS` is the gold standard for checking presence across massive datasets.
- **Why `SELECT 1`?**: Because `EXISTS` only cares *if* a row is returned (not *what* data is inside the row), standard convention is to just `SELECT 1` inside the subquery to minimize processing overhead.
