# Day 28: SQL Challenge - CTEs (First and Last Value Analysis)

## 📌 Business Scenario
A marketing team wants to analyze customer behavior evolution. They want to identify:
1. The first product a customer ever purchased (first-touch acquisition product).
2. The most recent product the customer purchased.

Comparing these two values helps trace how a customer's product preferences evolve over time (e.g., entering the brand buying accessories, and graduating to high-value electronics).

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    product_name VARCHAR(100),
    purchase_timestamp TIMESTAMP
);

-- Insert Sample Data
INSERT INTO orders (order_id, customer_id, product_name, purchase_timestamp) VALUES
(1, 101, 'Wireless Mouse', '2026-01-05 10:00:00'),
(2, 101, 'Mechanical Keyboard', '2026-02-10 14:00:00'),
(3, 101, 'Gaming Monitor', '2026-03-15 16:30:00'), -- 101 First: Mouse | Last: Monitor
(4, 102, 'Office Chair', '2026-01-10 09:00:00'),
(5, 102, 'Desk Lamp', '2026-01-12 11:30:00'),      -- 102 First: Chair | Last: Lamp
(6, 103, 'USB-C Cable', '2026-03-01 12:00:00'),
(7, 103, 'USB-C Hub', '2026-03-01 12:00:00'),       -- Tie in timestamp (resolved by order_id)
(8, 104, 'Smart Watch', '2026-02-20 15:00:00');    -- 104 First: Watch | Last: Watch (Single order)
```

---

## ❓ The Question
Write an SQL query using Common Table Expressions (CTEs) to find the first and most recent product purchased by each customer. For each unique customer, return their `customer_id`, the name of their first purchased product (`first_product`), and the name of their most recent purchased product (`last_product`). Resolve any timestamp ties by selecting the record with the higher `order_id`.

---

## 💡 The Solution

```sql
WITH RankedPurchases AS (
    -- Step 1: Assign chronological and reverse-chronological rank values
    SELECT 
        customer_id,
        product_name,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY purchase_timestamp ASC, order_id ASC
        ) AS rn_first,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY purchase_timestamp DESC, order_id DESC
        ) AS rn_last
    FROM orders
),
FirstPurchases AS (
    -- Step 2: Filter for the very first purchase
    SELECT customer_id, product_name AS first_product
    FROM RankedPurchases
    WHERE rn_first = 1
),
LastPurchases AS (
    -- Step 3: Filter for the very last purchase
    SELECT customer_id, product_name AS last_product
    FROM RankedPurchases
    WHERE rn_last = 1
)
-- Step 4: Join the sets to display first and last next to each other
SELECT 
    f.customer_id,
    f.first_product,
    l.last_product
FROM FirstPurchases f
JOIN LastPurchases l ON f.customer_id = l.customer_id
ORDER BY f.customer_id;
```

---

## 📝 Explanation
- **`RankedPurchases` CTE**: Computes two distinct rankings using the `ROW_NUMBER()` window function.
  - `rn_first` orders rows ascendingly by date, assigning `1` to the oldest order.
  - `rn_last` orders rows descendingly by date, assigning `1` to the newest order.
  - The secondary order condition `order_id` serves as a tie-breaker when transactions occur at the exact same millisecond.
- **`FirstPurchases` & `LastPurchases` CTEs**: Filter the master ranked dataset, isolating the specific rows where the chronological rankings equal `1`.
- **Final Join**: Merges the two isolated datasets back together on `customer_id`. For customers who have only made a single purchase (like customer `104`), both `rn_first = 1` and `rn_last = 1` point to the same row, safely displaying the identical product name in both columns.
