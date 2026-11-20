# Day 33: SQL Challenge - Subqueries (Category-wise Top Seller / Group Maxima)

## 📌 Business Scenario
A product manager wants to review sales performance. They need a list of the top-performing product (the one that generated the highest total revenue) within each product category. 

To ensure the query runs on simple legacy database systems, the solution must use standard correlated subqueries instead of window functions like `RANK()` or `DENSE_RANK()`.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Product Sales Table
CREATE TABLE product_sales (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    total_revenue DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO product_sales (product_id, product_name, category, total_revenue) VALUES
(1, 'iPhone 15', 'Electronics', 150000.00),
(2, 'Galaxy S24', 'Electronics', 120000.00),
(3, 'MacBook Pro', 'Electronics', 250000.00), -- Top Electronics
(4, 'Office Desk', 'Furniture', 45000.00),
(5, 'Ergonomic Chair', 'Furniture', 55000.00),  -- Top Furniture
(6, 'Running Shoes', 'Apparel', 30000.00),     -- Top Apparel
(7, 'Winter Coat', 'Apparel', 25000.00);
```

---

## ❓ The Question
Write an SQL query to retrieve the details of the product that generated the highest `total_revenue` in each `category`. Use a correlated subquery in the `WHERE` clause (do not use window functions). The output should display the `product_name`, `category`, and `total_revenue`, ordered alphabetically by category.

---

## 💡 The Solution

```sql
SELECT 
    ps1.product_name,
    ps1.category,
    ps1.total_revenue
FROM product_sales ps1
WHERE ps1.total_revenue = (
    -- Correlated subquery to find maximum revenue in the current category
    SELECT MAX(ps2.total_revenue)
    FROM product_sales ps2
    WHERE ps2.category = ps1.category
)
ORDER BY ps1.category;
```

---

## 📝 Explanation
- **Correlated Subquery**: The subquery `SELECT MAX(ps2.total_revenue)...` is correlated because it references `ps1.category` from the outer query. It executes relative to each specific product row evaluated by the outer query.
- **Filtering by Maxima**: For each product in `ps1`, the subquery calculates the maximum revenue within that product's specific category. The outer query's `WHERE` clause then keeps only the rows where the product's individual revenue matches that maximum value.
- **Handling Ties**: If two products within the same category are tied for the highest revenue, this query will return both of them, which is the correct and accurate behavior when auditing records.
- **Comparison to Window Functions**: While `ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_revenue DESC)` is cleaner for modern engines, this subquery approach is fully ANSI SQL compliant and runs on any SQL engine, including older legacy systems.
