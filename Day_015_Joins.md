# Day 15: SQL Challenge - Joins (Cross Join for Data Densification)

## 📌 Business Scenario
An inventory management team wants to view a report of monthly sales revenue for all of their products. However, some products have no sales in certain months, resulting in missing records in the database. A standard `LEFT JOIN` on transaction tables will simply omit those combinations. 

To show a continuous report showing `$0.00` for months with no sales, we must perform a `CROSS JOIN` to generate all possible combinations of products and active sales months, and then merge the actual sales data. This technique is known as **data densification**.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Products Table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50)
);

-- Create Sales Table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    sale_month VARCHAR(7), -- Format: 'YYYY-MM'
    revenue DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO products (product_id, product_name) VALUES
(1, 'Premium Laptop'),
(2, 'Wireless Earbuds'),
(3, 'Mechanical Keyboard');

INSERT INTO sales (sale_id, product_id, sale_month, revenue) VALUES
(101, 1, '2026-04', 1200.00),
(102, 1, '2026-05', 2400.00),
(103, 2, '2026-04', 150.00),
-- Wireless Earbuds (2) has no sales in '2026-05' or '2026-06'
-- Mechanical Keyboard (3) has no sales in '2026-04' or '2026-05'
(104, 3, '2026-06', 90.00);
```

---

## ❓ The Question
Write an SQL query to retrieve a list of all products and all active sale months (dynamically fetched from the `sales` table), showing the total revenue for each combination. If a product has no revenue in a given month, display `0.00` instead of `NULL`. Order the final results by product name and then by month.

---

## 💡 The Solution

```sql
WITH ActiveMonths AS (
    -- Dynamically extract all unique sales months
    SELECT DISTINCT sale_month 
    FROM sales
),
ProductCalendar AS (
    -- Generate all combinations of products and months
    SELECT 
        p.product_id,
        p.product_name,
        m.sale_month
    FROM products p
    CROSS JOIN ActiveMonths m
)
SELECT 
    c.product_name,
    c.sale_month,
    COALESCE(SUM(s.revenue), 0.00) AS total_revenue
FROM ProductCalendar c
LEFT JOIN sales s ON c.product_id = s.product_id AND c.sale_month = s.sale_month
GROUP BY c.product_id, c.product_name, c.sale_month
ORDER BY c.product_name, c.sale_month;
```

---

## 📝 Explanation
- **`ActiveMonths` CTE**: Selects all distinct transaction months (`'2026-04'`, `'2026-05'`, `'2026-06'`) from the `sales` table.
- **`ProductCalendar` CTE**: Uses a `CROSS JOIN` to create a Cartesian product of every product name paired with every active month. This gives us a complete "grid" of all possible observations.
- **`LEFT JOIN` & Aggregation**: We join our grid (`ProductCalendar`) to the actual `sales` table. Since we want to keep every grid item, we use a `LEFT JOIN` and match on both `product_id` and `sale_month`.
- **Handling NULLs via `COALESCE`**: For months with zero sales, the joined `revenue` is `NULL`. The `SUM` of these values is also `NULL`. Wrapping the `SUM` in `COALESCE(..., 0.00)` swaps the `NULL` with a clean `0.00` for final reporting.
