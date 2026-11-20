# Day 8: SQL Challenge - Joins (Left Join / Anti-Join)

## 📌 Business Scenario
A marketing team wants to run a customer re-engagement campaign. They need a list of all registered customers who have never placed a single order so they can send them a welcome discount code.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    sign_up_date DATE
);

-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Insert Sample Data
INSERT INTO customers (customer_id, customer_name, email, sign_up_date) VALUES
(1, 'Alice Smith', 'alice@email.com', '2026-05-01'),
(2, 'Bob Jones', 'bob@email.com', '2026-05-03'),
(3, 'Charlie Brown', 'charlie@email.com', '2026-05-05'),
(4, 'David Green', 'david@email.com', '2026-05-10'),
(5, 'Emma White', 'emma@email.com', '2026-05-12');

INSERT INTO orders (order_id, customer_id, order_date, order_amount) VALUES
(1001, 1, '2026-05-02', 150.00),
(1002, 3, '2026-05-06', 75.50),
(1003, 1, '2026-05-15', 200.00);
```

---

## ❓ The Question
Write an SQL query to retrieve all customers who have never placed an order. Return their `customer_id`, `customer_name`, `email`, and `sign_up_date`. Order the results chronologically by `sign_up_date` ascending.

---

## 💡 The Solution

```sql
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    c.sign_up_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.sign_up_date ASC;
```

---

## 📝 Explanation
- **Left Join**: By performing a `LEFT JOIN` from `customers` to `orders`, we retain all records from the `customers` table, even if they do not have a matching row in the `orders` table. For customers without orders, the fields from the `orders` table will evaluate to `NULL`.
- **Anti-Join Filtering**: The `WHERE o.order_id IS NULL` clause filters the joined result set to keep only the rows where no matching order was found. Since `order_id` is a primary key, it will only ever be `NULL` in the result of a left join if a match does not exist.
- **Alternative Approaches**: While this can also be solved using `NOT EXISTS` or `NOT IN`, a `LEFT JOIN ... WHERE ... IS NULL` pattern is highly readable and often optimized very well by database query planners.
