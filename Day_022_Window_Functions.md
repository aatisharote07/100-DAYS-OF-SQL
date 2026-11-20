# Day 22: SQL Challenge - Window Functions (NTILE / Spend Quartiles)

## 📌 Business Scenario
A marketing team wants to segment their customer base to run a target promotion. They want to divide their customers into **4 equal groups (quartiles)** based on their total historical spend:
- **Quartile 1:** Top 25% spenders (VIPs, target for high-value upsells)
- **Quartile 2:** High-Mid spenders
- **Quartile 3:** Low-Mid spenders
- **Quartile 4:** Bottom 25% spenders (target for budget discount reactivations)

To perform this division dynamically, we use the `NTILE` window function.

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
(4, 'David'),
(5, 'Emily'),
(6, 'Frank'),
(7, 'George'),
(8, 'Hannah');

INSERT INTO orders (order_id, customer_id, order_amount) VALUES
(101, 1, 500.00), -- Alice
(102, 2, 150.00), -- Bob
(103, 3, 350.00), -- Charlie
(104, 4, 1000.00),-- David
(105, 5, 200.00), -- Emily
(106, 6, 80.00),  -- Frank
(107, 7, 600.00), -- George
(108, 8, 450.00); -- Hannah
```

---

## ❓ The Question
Write an SQL query to calculate the total spend of each customer and partition them into 4 spend quartiles. Quartile 1 must contain the highest spenders and Quartile 4 the lowest. Display the `customer_id`, `customer_name`, `total_spend`, and `spend_quartile`. Order the final output by `total_spend` descending.

---

## 💡 The Solution

```sql
WITH CustomerSpend AS (
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
    total_spend,
    NTILE(4) OVER (ORDER BY total_spend DESC) AS spend_quartile
FROM CustomerSpend
ORDER BY total_spend DESC;
```

---

## 📝 Explanation
- **`CustomerSpend` CTE**: Joins the customer table with orders to compile a aggregated list of each customer's total spending.
- **`NTILE(4)` Function**: The `NTILE(n)` window function splits an ordered result set into `n` buckets as equally as possible. By ordering by `total_spend DESC`, the top 25% of earners are bucketed into group `1`, the next 25% in group `2`, and so on.
- **Handling Uneven Buckets**: When the number of rows is not perfectly divisible by the number of buckets, the remaining rows are distributed starting with the first bucket. In this scenario, we have exactly 8 records, so each of the 4 quartiles receives exactly 2 rows.
