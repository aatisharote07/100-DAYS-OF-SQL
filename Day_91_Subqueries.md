# Day 91: SQL Challenge - Subqueries (Correlated Subquery vs JOIN for Top-1 Item)

## 📌 Business Scenario
A product category manager at an online marketplace wants to generate a catalog summary report. For every product category, the report must show:
1. The `category_id` and `category_name`.
2. The name and price of the **single most expensive product** currently offered within that category.

In production environments, developers frequently debate whether to retrieve this top-1 attribute using a window function, an `INNER JOIN` on a grouped aggregate, or a scalar correlated subquery. 

When an index exists on `(category_id, price DESC)`, a **scalar correlated subquery** in the `SELECT` list or a clean `CROSS APPLY` / `LATERAL JOIN` often outperforms large join-and-sort pipelines by directly seeking the top record per category.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Categories Table
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50)
);

-- Create Products Table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    category_id INT,
    product_name VARCHAR(100),
    price DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO categories VALUES
(1, 'Electronics'),
(2, 'Home & Kitchen'),
(3, 'Books'),
(4, 'Apparel'); -- Category with no products yet

INSERT INTO products VALUES
(101, 1, 'Smartphone Pro', 999.99),
(102, 1, 'Wireless Earbuds', 149.99),
(103, 1, 'Gaming Laptop', 1899.99), -- Most expensive in Electronics
(104, 2, 'Coffee Maker', 89.99),
(105, 2, 'Blender 5000', 129.99),     -- Most expensive in Home & Kitchen
(106, 3, 'SQL Mastery Guide', 49.99);  -- Most expensive in Books
```

---

## ❓ The Question
Write an SQL query to retrieve all categories along with the name and price of their most expensive product. 

Use scalar correlated subqueries in the `SELECT` clause (or standard ANSI SQL subquery pattern) so categories without any products (such as `'Apparel'`) still appear in the output with `NULL` product details.

Return `category_id`, `category_name`, `top_product_name`, and `top_product_price`. Order the results by `category_id`.

---

## 💡 The Solution

```sql
SELECT 
    c.category_id,
    c.category_name,
    -- Correlated Subquery 1: Extract top product name
    (
        SELECT p.product_name
        FROM products p
        WHERE p.category_id = c.category_id
        ORDER BY p.price DESC, p.product_id ASC
        LIMIT 1
    ) AS top_product_name,
    -- Correlated Subquery 2: Extract top product price
    (
        SELECT p.price
        FROM products p
        WHERE p.category_id = c.category_id
        ORDER BY p.price DESC, p.product_id ASC
        LIMIT 1
    ) AS top_product_price
FROM categories c
ORDER BY c.category_id;
```

*(Note for SQL Server users: Replace `LIMIT 1` with `SELECT TOP 1 ...`)*
*(Note for PostgreSQL / Modern MySQL / Oracle: You can also use `LEFT JOIN LATERAL` or `CROSS APPLY` to fetch both columns in a single subquery pass).*

---

## 📝 Explanation

### How Scalar Correlated Subqueries Work
- A subquery placed directly in the `SELECT` list is called a **scalar subquery** because it must return at most a single value (one row, one column).
- It is **correlated** because the inner `WHERE p.category_id = c.category_id` references the outer query's row (`c`).
- For each category row processed, the engine searches the `products` table, orders the matching rows by `price DESC`, and grabs the top entry (`LIMIT 1`).
- Tiebreaking with `p.product_id ASC` guarantees deterministic output if two products share the exact same top price.

### Handling Empty Categories Automatically
- If a category has no products (like Category 4, `Apparel`), the inner subquery returns 0 rows.
- In SQL, a scalar subquery returning 0 rows evaluates cleanly to `NULL`. No complex outer joins or null-coalescing are strictly required to preserve the category.

### Index Optimization in Production
When an index is present on `products(category_id, price DESC)`:
- The database engine executes an index seek per category and reads just the very first index leaf node.
- For tables with millions of products across a modest number of categories, this technique can be substantially faster than loading the entire product table into a window function sort buffer (`ROW_NUMBER() OVER (...)`).
