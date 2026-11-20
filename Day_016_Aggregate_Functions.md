# Day 16: SQL Challenge - Aggregate Functions (GROUP BY & HAVING)

## 📌 Business Scenario
A risk management team at an e-commerce platform wants to build a simple fraud detection system. They define a "suspicious activity flag" when a single user places **more than 3 distinct orders** on the **same day**, AND their **total transaction value for that day exceeds $1,000.00**. 

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATE,
    order_amount DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO orders (order_id, user_id, order_date, order_amount) VALUES
(1001, 101, '2026-06-17', 250.00),
(1002, 101, '2026-06-17', 300.00),
(1003, 101, '2026-06-17', 150.00),
(1004, 101, '2026-06-17', 400.00), -- User 101: 4 orders, total $1,100 (Flagged!)
(1005, 102, '2026-06-17', 800.00),
(1006, 102, '2026-06-17', 300.00), -- User 102: 2 orders, total $1,100 (Not Flagged - count too low)
(1007, 103, '2026-06-18', 100.00),
(1008, 103, '2026-06-18', 50.00),
(1009, 103, '2026-06-18', 200.00),
(1010, 103, '2026-06-18', 120.00),  -- User 103: 4 orders, total $470 (Not Flagged - amount too low)
(1011, 104, '2026-06-18', 1200.00); -- User 104: 1 order, total $1,200 (Not Flagged - count too low)
```

---

## ❓ The Question
Write an SQL query to retrieve all suspicious user records. For each record, display the `user_id`, the `order_date`, the total number of orders placed (`total_orders`), and the sum of order amounts (`total_spent`).

---

## 💡 The Solution

```sql
SELECT 
    user_id,
    order_date,
    COUNT(order_id) AS total_orders,
    SUM(order_amount) AS total_spent
FROM orders
GROUP BY user_id, order_date
HAVING COUNT(order_id) > 3 
   AND SUM(order_amount) > 1000.00;
```

---

## 📝 Explanation
- **`GROUP BY` Clause**: We group transactions by both `user_id` and `order_date` to isolate user behavior per day.
- **`WHERE` vs `HAVING`**: A `WHERE` clause cannot filter aggregated results (like `SUM` or `COUNT`) because it executes before the data is grouped. We use the `HAVING` clause, which runs after the grouping operation, to filter the aggregated rows.
- **Multiple Conditions**: The `HAVING` clause checks two conditions using the `AND` operator: it verifies that the count of daily orders is greater than 3, and the sum of their daily transaction value exceeds $1,000.00.
