# Day 18: SQL Challenge - Subqueries (Finding the Nth Highest Value)

## 📌 Business Scenario
An auditing team needs to verify high-value transactions. They require a query that extracts the details of the transaction(s) with the **second-highest order amount**. 

To ensure the query is highly portable across different database management systems (DBMS), the solution must use standard SQL subqueries and avoid proprietary row-limiting commands like `LIMIT`, `OFFSET`, `TOP`, or `ROWNUM`.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_amount DECIMAL(10, 2),
    order_date DATE
);

-- Insert Sample Data
INSERT INTO orders (order_id, customer_id, order_amount, order_date) VALUES
(1, 101, 1500.00, '2026-06-01'), -- Highest
(2, 102, 1200.00, '2026-06-02'), -- Second Highest
(3, 103, 800.00, '2026-06-03'),
(4, 104, 1200.00, '2026-06-04'), -- Second Highest (Tie)
(5, 105, 950.00, '2026-06-05');
```

---

## ❓ The Question
Write an SQL query to retrieve all details of the transaction(s) with the second-highest `order_amount`. Your solution must use nested subqueries and must not rely on row limiting functions like `LIMIT`, `TOP`, or `ROWNUM`.

---

## 💡 The Solution

```sql
SELECT 
    order_id,
    customer_id,
    order_amount,
    order_date
FROM orders
WHERE order_amount = (
    SELECT MAX(order_amount)
    FROM orders
    WHERE order_amount < (
        SELECT MAX(order_amount)
        FROM orders
    )
);
```

---

## 📝 Explanation
- **Innermost Subquery**: The subquery `SELECT MAX(order_amount) FROM orders` scans the table to find the absolute maximum order value ($1,500.00).
- **Middle Subquery**: The subquery `SELECT MAX(order_amount) FROM orders WHERE order_amount < (...)` runs next. It searches for the maximum order amount that is strictly smaller than the absolute maximum value. This evaluates to the second-highest value ($1,200.00).
- **Outer Query & Handling Ties**: The main query filters the table to find rows matching this second-highest value. Because we use an equality filter (`=`) rather than a single-record limit, the query correctly handles and returns all transactions tied for the second-highest spot (both `order_id = 2` and `order_id = 4`).
