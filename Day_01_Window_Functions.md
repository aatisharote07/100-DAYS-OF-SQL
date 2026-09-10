# Day 1: SQL Challenge - Window Functions (DENSE_RANK)

## 📌 Business Scenario
An e-commerce platform wants to identify the top 2 highest-selling products within each product category based on their total sales amount. If there are products with the same sales amount, they should receive the same rank, and no ranks should be skipped.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Products Table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50)
);

-- Create Sales Table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    quantity INT,
    price_per_unit DECIMAL(10, 2),
    sale_date DATE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Insert Sample Data
INSERT INTO products (product_id, product_name, category) VALUES
(1, 'iPhone 15', 'Electronics'),
(2, 'MacBook Pro', 'Electronics'),
(3, 'AirPods Pro', 'Electronics'),
(4, 'Running Shoes', 'Footwear'),
(5, 'Leather Boots', 'Footwear'),
(6, 'Sneakers', 'Footwear'),
(7, 'Coffee Maker', 'Home Appliances');

INSERT INTO sales (sale_id, product_id, quantity, price_per_unit, sale_date) VALUES
(101, 1, 2, 999.99, '2026-05-15'),
(102, 2, 1, 1999.99, '2026-05-16'),
(103, 3, 5, 249.99, '2026-05-17'),
(104, 4, 3, 120.00, '2026-05-18'),
(105, 5, 2, 150.00, '2026-05-19'),
(106, 6, 4, 90.00, '2026-05-20'),
(107, 7, 2, 80.00, '2026-05-21'),
(108, 1, 1, 999.99, '2026-05-22');
```

---

## ❓ The Question
Write an SQL query to retrieve the top 2 products in each category based on their total sales revenue (calculated as `quantity * price_per_unit`). Use a ranking function that does not skip rank numbers in case of a tie.

---

## 💡 The Solution

```sql
WITH ProductSales AS (
    SELECT 
        p.category,
        p.product_name,
        SUM(s.quantity * s.price_per_unit) AS total_revenue
    FROM products p
    JOIN sales s ON p.product_id = s.product_id
    GROUP BY p.category, p.product_name
),
RankedProducts AS (
    SELECT 
        category,
        product_name,
        total_revenue,
        DENSE_RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) AS sales_rank
    FROM ProductSales
)
SELECT 
    category,
    product_name,
    total_revenue,
    sales_rank
FROM RankedProducts
WHERE sales_rank <= 2;
```

---

## 📝 Explanation
- **`ProductSales` CTE**: Aggregates sales data to calculate total revenue for each product by category.
- **`DENSE_RANK()` Window Function**: Assigns a rank to each product within its product category partition, ordered by revenue descending. It is chosen over `RANK()` because it avoids gaps in ranking sequence when duplicate values (ties) occur.
- **Filtering**: The final query wraps the results to filter where `sales_rank <= 2`, successfully fetching the top 2 performing products for each category.
