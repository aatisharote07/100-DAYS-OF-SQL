# Day 7: SQL Challenge - Window Functions (LAG)

## 📌 Business Scenario
A marketing team wants to analyze customer purchasing behavior to improve retention. Specifically, they need to measure customer purchase velocity—the number of days that pass between a customer's consecutive purchases. This insight will be used to trigger automated engagement emails to customers whose purchasing frequency drops.

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
(201, 101, '2026-05-01', 50.00),
(202, 102, '2026-05-02', 150.00),
(203, 101, '2026-05-05', 75.00),   -- 4 days after order 201
(204, 103, '2026-05-08', 200.00),
(205, 101, '2026-05-15', 30.00),   -- 10 days after order 203
(206, 102, '2026-05-20', 100.00),  -- 18 days after order 202
(207, 101, '2026-05-16', 45.00),   -- 1 day after order 205
(208, 103, '2026-05-25', 120.00);  -- 17 days after order 204
```

---

## ❓ The Question
Write an SQL query to retrieve all orders. For each order, display the `customer_id`, `order_id`, `order_date`, `order_amount`, the date of the customer's *previous* order, and the number of days elapsed between the current order and the previous order.

---

## 💡 The Solution

```sql
WITH OrderHistory AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        order_amount,
        LAG(order_date, 1) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date, order_id
        ) AS previous_order_date
    FROM orders
)
SELECT 
    customer_id,
    order_id,
    order_date,
    order_amount,
    previous_order_date,
    DATEDIFF(order_date, previous_order_date) AS days_between_orders
FROM OrderHistory
ORDER BY customer_id, order_date;
```

---

## 📝 Explanation
- **`LAG` Window Function**: Inside the `OrderHistory` CTE, `LAG(order_date, 1)` pulls the `order_date` from the previous row. The `PARTITION BY customer_id` clause separates the records by customer, and the `ORDER BY order_date, order_id` ensures the chronology is correct.
- **Date Arithmetic**: The outer query uses `DATEDIFF(order_date, previous_order_date)` to calculate the interval in days between the current order date and the retrieved previous order date.
- **Handling First Purchases**: For any customer's very first order, the `LAG` function evaluates to `NULL` (since there is no preceding row), which naturally sets the `days_between_orders` to `NULL`.
