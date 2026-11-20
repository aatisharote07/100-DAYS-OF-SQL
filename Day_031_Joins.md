# Day 31: SQL Challenge - Joins (Left Join Filter: ON vs WHERE clause)

## 📌 Business Scenario
An analytics team wants to generate a complete report of all active users alongside any high-value transactions they made (defined as transactions of **$100.00 or more**). 

Crucially, the final output must still represent every user in the database, even if they have made no purchases or only made purchases under $100.00 (in which case the transaction fields should display `NULL`).

Understanding where to place the filter condition (`amount >= 100.00`) is critical to achieving the correct result.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Users Table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(100)
);

-- Create Transactions Table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    user_id INT,
    amount DECIMAL(10, 2),
    transaction_date DATE
);

-- Insert Sample Data
INSERT INTO users (user_id, user_name) VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Charlie');

INSERT INTO transactions (transaction_id, user_id, amount, transaction_date) VALUES
(101, 1, 150.00, '2026-07-01'), -- Alice: High-value transaction
(102, 1, 50.00, '2026-07-02'),  -- Alice: Low-value transaction
(103, 2, 80.00, '2026-07-03');  -- Bob: Low-value transaction
-- Charlie has no transaction records at all
```

---

## ❓ The Question
Write an SQL query to retrieve a list of all users. If a user has made a transaction of `$100.00` or more, display the transaction details (`amount`, `transaction_date`). If not, those columns should show `NULL`, but the user record must remain in the output. 

Write the correct query and explain how placing the condition in the `ON` clause versus the `WHERE` clause alters the result.

---

## 💡 The Solution

### The Correct Query (Condition in the ON clause)
```sql
SELECT 
    u.user_id,
    u.user_name,
    t.amount,
    t.transaction_date
FROM users u
LEFT JOIN transactions t ON u.user_id = t.user_id 
                       AND t.amount >= 100.00
ORDER BY u.user_id;
```

### The Incorrect Query (Condition in the WHERE clause)
```sql
SELECT 
    u.user_id,
    u.user_name,
    t.amount,
    t.transaction_date
FROM users u
LEFT JOIN transactions t ON u.user_id = t.user_id
WHERE t.amount >= 100.00
ORDER BY u.user_id;
```

---

## 📝 Explanation
- **Why the ON Clause works (Correct)**: During a `LEFT JOIN`, the conditions inside the `ON` clause determine how rows from the right table are matched to the left table *before* joining. Adding `AND t.amount >= 100.00` ensures we only look for matches that are high-value. If a user has no such transaction (like Bob or Charlie), the join fails to find a match, and the left-table user is still returned with right-table columns padded as `NULL`.
- **Why the WHERE Clause fails (Incorrect)**: The `WHERE` clause executes *after* the join has completed. For Bob and Charlie, the join generates rows with `t.amount` as `NULL`. The filter `WHERE t.amount >= 100.00` evaluates `NULL >= 100.00` as `UNKNOWN` (which acts as `FALSE`), discarding Bob and Charlie. This converts the `LEFT JOIN` into an implicit `INNER JOIN`.
