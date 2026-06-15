# Day 13: SQL Challenge - Aggregate Functions (ROLLUP for Hierarchical Summaries)

## 📌 Business Scenario
A retail business intelligence team needs to generate a sales revenue report. Rather than running separate queries for different aggregation levels, they want a single query that generates hierarchical sales summaries at three levels:
1. Total sales revenue per product category and subcategory.
2. Subtotals: Total sales revenue per category (across all its subcategories).
3. Grand Total: Total sales revenue across the entire company.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Sales Table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    category VARCHAR(50),
    subcategory VARCHAR(50),
    revenue DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO sales (sale_id, category, subcategory, revenue) VALUES
(1, 'Electronics', 'Laptops', 5000.00),
(2, 'Electronics', 'Laptops', 3000.00),
(3, 'Electronics', 'Phones', 1500.00),
(4, 'Electronics', 'Phones', 2000.00),
(5, 'Furniture', 'Chairs', 800.00),
(6, 'Furniture', 'Chairs', 1200.00),
(7, 'Furniture', 'Tables', 2500.00);
```

---

## ❓ The Question
Write an SQL query to retrieve the total sales revenue grouped by `category` and `subcategory`, including hierarchical summaries (subtotals by category and the grand total). Use `ROLLUP` to compute these summaries in a single result set. Replace the resulting grouping `NULL` values with `'ALL Categories'` and `'ALL Subcategories'` as appropriate.

---

## 💡 The Solution

### Standard ANSI SQL Syntax (PostgreSQL, SQL Server, Oracle)
```sql
SELECT 
    COALESCE(category, 'ALL Categories') AS category,
    COALESCE(subcategory, 'ALL Subcategories') AS subcategory,
    SUM(revenue) AS total_revenue
FROM sales
GROUP BY ROLLUP (category, subcategory)
ORDER BY category, subcategory;
```

### MySQL Specific Syntax
```sql
SELECT 
    COALESCE(category, 'ALL Categories') AS category,
    COALESCE(subcategory, 'ALL Subcategories') AS subcategory,
    SUM(revenue) AS total_revenue
FROM sales
GROUP BY category, subcategory WITH ROLLUP;
```

---

## 📝 Explanation
- **`ROLLUP` Aggregation**: The `ROLLUP` extension in the `GROUP BY` clause generates multiple grouping sets. For `ROLLUP (category, subcategory)`, the query aggregates the revenue at three levels:
  1. `(category, subcategory)` - Daily specific combinations.
  2. `(category)` - Subtotals for each category.
  3. `()` - The grand total of all records.
- **Handling NULLs via `COALESCE`**: When `ROLLUP` computes subtotals and grand totals, it inserts `NULL` values into the columns being rolled up. `COALESCE` replaces these `NULL` values with readable labels like `'ALL Categories'` and `'ALL Subcategories'`.
- **Order of Columns**: The order of columns in `ROLLUP` matters. A rollup on `(category, subcategory)` provides subtotals for categories. If we did `ROLLUP (subcategory, category)`, it would provide subtotals for subcategories.
