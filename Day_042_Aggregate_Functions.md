# Day 42: SQL Challenge - Aggregate Functions (String Aggregation / GROUP_CONCAT)

## 📌 Business Scenario
An e-commerce platform wants to generate a clean product catalog report for its marketing team. Instead of multiple rows per product (one per tag), the team wants a **single row per product** with all associated tags compiled into a comma-separated list.

This is a classic "unpivot-to-pivot" string aggregation problem that collapses many-to-one relationships into a single denormalized cell — a common requirement when preparing data for reports, APIs, or spreadsheet exports.

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

-- Create Product Tags Table
CREATE TABLE product_tags (
    tag_id INT PRIMARY KEY,
    product_id INT,
    tag VARCHAR(50)
);

-- Insert Sample Data
INSERT INTO products (product_id, product_name, category) VALUES
(1, 'TrailBlaze Running Shoes', 'Footwear'),
(2, 'QuantumGrip Gloves', 'Accessories'),
(3, 'AeroLite Jacket', 'Apparel');

INSERT INTO product_tags (tag_id, product_id, tag) VALUES
(1, 1, 'outdoor'),
(2, 1, 'running'),
(3, 1, 'trail'),
(4, 2, 'grip'),
(5, 2, 'winter'),
(6, 3, 'lightweight'),
(7, 3, 'windproof'),
(8, 3, 'running');
```

---

## ❓ The Question
Write an SQL query to produce a single row per product that includes the `product_id`, `product_name`, `category`, and a `tags` column containing all associated tags compiled into a single alphabetically sorted, comma-separated string. Products with no tags should still appear in the output with an empty or NULL `tags` column.

---

## 💡 The Solution

### MySQL Solution (using GROUP_CONCAT)
```sql
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    GROUP_CONCAT(pt.tag ORDER BY pt.tag ASC SEPARATOR ', ') AS tags
FROM products p
LEFT JOIN product_tags pt ON p.product_id = pt.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY p.product_id;
```

### PostgreSQL Solution (using STRING_AGG)
```sql
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    STRING_AGG(pt.tag, ', ' ORDER BY pt.tag ASC) AS tags
FROM products p
LEFT JOIN product_tags pt ON p.product_id = pt.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY p.product_id;
```

### SQL Server Solution (using STRING_AGG)
```sql
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    STRING_AGG(pt.tag, ', ') WITHIN GROUP (ORDER BY pt.tag ASC) AS tags
FROM products p
LEFT JOIN product_tags pt ON p.product_id = pt.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY p.product_id;
```

---

## 📝 Explanation
- **`GROUP_CONCAT` (MySQL)**: A MySQL-specific aggregate function that concatenates non-NULL values from a group into a single string. The `ORDER BY` clause inside `GROUP_CONCAT` controls the sort order of the concatenated tags, and `SEPARATOR` defines the delimiter between values.
- **`STRING_AGG` (PostgreSQL / SQL Server)**: The ANSI-standard equivalent. In PostgreSQL, `ORDER BY` goes directly inside the function. In SQL Server, ordering uses the `WITHIN GROUP (ORDER BY ...)` clause.
- **`LEFT JOIN`**: We use a `LEFT JOIN` from `products` to `product_tags` to retain products that have no associated tags (they'd return `NULL` for the `tags` column). An `INNER JOIN` would silently drop tag-less products.
- **Expected Output**:

| product_id | product_name              | category    | tags                          |
|------------|---------------------------|-------------|-------------------------------|
| 1          | TrailBlaze Running Shoes  | Footwear    | outdoor, running, trail       |
| 2          | QuantumGrip Gloves        | Accessories | grip, winter                  |
| 3          | AeroLite Jacket           | Apparel     | lightweight, running, windproof |
