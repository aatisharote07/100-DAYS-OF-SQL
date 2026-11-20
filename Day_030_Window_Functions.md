# Day 30: SQL Challenge - Window Functions (Time to Second Purchase)

## 📌 Business Scenario
A growth marketing team wants to analyze the latency of customer activation. They want to calculate the **Time to Second Purchase**—the number of days that elapsed between a customer's very first purchase and their second purchase. 

This metric is critical: customers who buy a second time quickly are much more likely to have high lifetime value (LTV).

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_amount DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO orders (order_id, customer_id, order_date, order_amount) VALUES
(1, 101, '2026-06-01', 50.00),  -- 101: 1st purchase
(2, 101, '2026-06-05', 75.00),  -- 101: 2nd purchase (4 days latency)
(3, 101, '2026-06-15', 120.00), -- 101: 3rd purchase
(4, 102, '2026-06-10', 200.00), -- 102: 1st purchase
(5, 102, '2026-06-25', 150.00), -- 102: 2nd purchase (15 days latency)
(6, 103, '2026-06-12', 30.00),  -- 103: 1st purchase (No 2nd purchase)
(7, 104, '2026-06-20', 45.00),  -- 104: 1st purchase
(8, 104, '2026-06-21', 10.00);  -- 104: 2nd purchase (1 day latency)
```

---

## ❓ The Question
Write an SQL query to retrieve the number of days between the first and second purchase for each customer who has made at least two purchases. Return the `customer_id`, `first_purchase_date`, `second_purchase_date`, and the calculated `days_to_second_purchase`. Order the output by `days_to_second_purchase` ascending.

---

## 💡 The Solution

```sql
WITH OrderSequencing AS (
    SELECT 
        customer_id,
        order_date,
        -- Rank purchase dates chronologically for each customer
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY order_date, order_id
        ) AS rn,
        -- Grab the date of the next purchase
        LEAD(order_date, 1) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date, order_id
        ) AS next_order_date
    FROM orders
)
SELECT 
    customer_id,
    order_date AS first_purchase_date,
    next_order_date AS second_purchase_date,
    DATEDIFF(next_order_date, order_date) AS days_to_second_purchase
FROM OrderSequencing
WHERE rn = 1 AND next_order_date IS NOT NULL
ORDER BY days_to_second_purchase ASC;
```

---

## 📝 Explanation
- **`ROW_NUMBER()`**: Numbers the orders chronologically for each customer, marking the very first order as `rn = 1`.
- **`LEAD()` Window Function**: Looks forward to the next chronological row within the customer partition and retrieves its `order_date`. For the row where `rn = 1`, `LEAD` fetches the date of the *second* order (`rn = 2`).
- **Filtering**: By filtering `WHERE rn = 1`, we discard all subsequent rows (such as the 3rd purchase), isolating only the first purchase row. The check `next_order_date IS NOT NULL` automatically filters out customers who have only made a single purchase.
- **Efficiency**: Rather than performing a heavy self-join on the `orders` table (which is a common way to solve this), this solution uses a single pass over the window functions, making it highly optimized for large transaction databases.
