# Day 11: SQL Challenge - Subqueries (EXISTS & NOT EXISTS)

## 📌 Business Scenario
An e-commerce marketing manager wants to execute a cross-selling email campaign. They want to identify customers who are interested in tech but lack basic add-ons. Specifically, they need a list of customers who have purchased at least one product from the `'Electronics'` category, but have *never* purchased any product from the `'Accessories'` category.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100)
);

-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    product_name VARCHAR(100),
    category VARCHAR(50),
    order_date DATE
);

-- Insert Sample Data
INSERT INTO customers (customer_id, customer_name, email) VALUES
(1, 'Alice Smith', 'alice@email.com'),
(2, 'Bob Jones', 'bob@email.com'),
(3, 'Charlie Brown', 'charlie@email.com'),
(4, 'David Green', 'david@email.com'),
(5, 'Emma White', 'emma@email.com');

INSERT INTO orders (order_id, customer_id, product_name, category, order_date) VALUES
(101, 1, 'Laptop', 'Electronics', '2026-05-10'),
(102, 1, 'Mouse Pad', 'Accessories', '2026-05-11'),  -- Alice bought both
(103, 2, 'Phone Charger', 'Accessories', '2026-05-12'), -- Bob only bought Accessories
(104, 3, 'Smart Watch', 'Electronics', '2026-05-15'),  -- Charlie only bought Electronics (Target!)
(105, 4, 'Headphones', 'Electronics', '2026-05-18'),    -- David only bought Electronics (Target!)
(106, 5, 'Keyboard', 'Accessories', '2026-05-20');     -- Emma only bought Accessories
```

---

## ❓ The Question
Write an SQL query to retrieve the `customer_id`, `customer_name`, and `email` of all customers who have purchased at least one item in the `'Electronics'` category but have never purchased any item in the `'Accessories'` category. Use correlated subqueries with `EXISTS` and `NOT EXISTS`.

---

## 💡 The Solution

```sql
SELECT 
    c.customer_id,
    c.customer_name,
    c.email
FROM customers c
WHERE EXISTS (
    SELECT 1 
    FROM orders o1
    WHERE o1.customer_id = c.customer_id
      AND o1.category = 'Electronics'
)
AND NOT EXISTS (
    SELECT 1 
    FROM orders o2
    WHERE o2.customer_id = c.customer_id
      AND o2.category = 'Accessories'
)
ORDER BY c.customer_id;
```

---

## 📝 Explanation
- **Correlated Subqueries**: Subqueries inside `EXISTS` and `NOT EXISTS` reference `c.customer_id` from the outer query. This forces the subqueries to evaluate relative to each specific customer evaluated in the main query.
- **`EXISTS` Condition**: The first filter checks if the customer has at least one record in the `orders` table under the category `'Electronics'`.
- **`NOT EXISTS` Condition**: The second filter ensures that the customer does not have any records in the `orders` table under the category `'Accessories'`.
- **Performance Benefits**: Using `EXISTS` / `NOT EXISTS` is highly performant compared to `IN` / `NOT IN` because the query executor can short-circuit (stop processing as soon as a single match or contradiction is found), avoiding full table scans.
