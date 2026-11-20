# Day 38: SQL Challenge - Subqueries (Filtering by Aggregate of Aggregates)

## 📌 Business Scenario
A customer relationship management (CRM) team wants to identify VIP customers for a premium loyalty program. They define a **VIP customer** as anyone whose **total historical spending** is strictly greater than the **average total spending of all customers** in the database.

Calculating this requires nesting aggregate calculations (finding the average of sum values), which is a common pattern in business intelligence reports.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100)
);

-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_amount DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO customers (customer_id, customer_name) VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Charlie'),
(4, 'David');

INSERT INTO orders (order_id, customer_id, order_amount) VALUES
(101, 1, 150.00), -- Alice Total: 200
(102, 1, 50.00),
(103, 2, 80.00),  -- Bob Total: 80
(104, 3, 400.00), -- Charlie Total: 400
(105, 4, 120.00); -- David Total: 120
-- Customer Total Spends: Alice (200), Bob (80), Charlie (400), David (120)
-- Overall Average Customer Spend: (200 + 80 + 400 + 120) / 4 = 200
```

---

## ❓ The Question
Write an SQL query to find all customers whose total spend is greater than the average total spend of all customers. Return the `customer_id`, `customer_name`, and their `total_spend`. Order the results by `total_spend` descending.

---

## 💡 The Solution

### Method 1: Using a Subquery in the HAVING Clause
```sql
SELECT 
    c.customer_id,
    c.customer_name,
    SUM(o.order_amount) AS total_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.order_amount) > (
    -- Subquery: Calculate the average of all customer total spends
    SELECT AVG(customer_totals.total_spend)
    FROM (
        SELECT SUM(order_amount) AS total_spend
        FROM orders
        GROUP BY customer_id
    ) AS customer_totals
)
ORDER BY total_spend DESC;
```

### Method 2: Using a CTE (Alternative & Clean)
```sql
WITH CustomerTotals AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        SUM(o.order_amount) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT 
    customer_id,
    customer_name,
    total_spend
FROM CustomerTotals
WHERE total_spend > (SELECT AVG(total_spend) FROM CustomerTotals)
ORDER BY total_spend DESC;
```

---

## 📝 Explanation
- **Aggregating at Two Levels**: We cannot simply run `AVG(SUM(order_amount))` because SQL engines do not allow direct nesting of aggregate functions.
- **The Inner Subquery**: The subquery inside the `HAVING` (or the CTE) first aggregates order amounts by `customer_id` to produce a table of total spends. The outer layer of that subquery then takes the `AVG()` of those sums ($200.00).
- **`HAVING` vs `WHERE`**: In Method 1, because the comparison is done against a grouped column (`SUM(o.order_amount)`), the filter must reside in the `HAVING` clause rather than the `WHERE` clause.
- **Filtering Results**: With the average computed as $200.00, only Charlie ($400.00) is returned. Alice ($200.00) is excluded because the condition is strictly greater than (`>`).
