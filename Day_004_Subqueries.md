# Day 4: SQL Challenge - Subqueries (Correlated Subqueries)

## 📌 Business Scenario
A retail analytics team wants to identify premium products within their catalog. A product is classified as a "premium" offering if its retail price exceeds the average retail price of all products within its specific product category.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Products Table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO products (product_id, product_name, category, price) VALUES
(1, 'Wireless Mouse', 'Electronics', 25.00),
(2, 'Mechanical Keyboard', 'Electronics', 120.00),
(3, 'Gaming Monitor', 'Electronics', 350.00),
(4, 'Ergonomic Chair', 'Furniture', 250.00),
(5, 'Desk Lamp', 'Furniture', 45.00),
(6, 'Standing Desk', 'Furniture', 450.00),
(7, 'Running Shoes', 'Apparel', 80.00),
(8, 'Winter Jacket', 'Apparel', 150.00),
(9, 'T-Shirt', 'Apparel', 20.00);
```

---

## ❓ The Question
Write an SQL query to retrieve all products whose price is greater than the average price of products within their respective category. Display the `product_name`, `category`, `price`, and the corresponding category's average price (rounded to 2 decimal places).

---

## 💡 The Solution

```sql
SELECT 
    p1.product_name,
    p1.category,
    p1.price,
    (
        SELECT ROUND(AVG(p2.price), 2)
        FROM products p2
        WHERE p2.category = p1.category
    ) AS category_avg_price
FROM products p1
WHERE p1.price > (
    SELECT AVG(p2.price)
    FROM products p2
    WHERE p2.category = p1.category
);
```

---

## 📝 Explanation
- **Correlated Subquery in WHERE**: The subquery inside the `WHERE` clause dynamically computes the average price of products belonging to the *same* category as the outer product row (`p2.category = p1.category`). The outer query filters for products whose price is higher than this calculated value.
- **Correlated Subquery in SELECT**: A second correlated subquery is placed in the `SELECT` statement to pull the category's average price and round it to 2 decimal places. This allows immediate visual verification of why each product qualifies as "premium".
- **Execution Flow**: For each candidate row evaluated by the outer query, the inner subqueries are executed to fetch the aggregate category metrics, creating a row-by-row relationship.
