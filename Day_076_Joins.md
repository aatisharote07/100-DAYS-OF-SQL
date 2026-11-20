# Day 76: SQL Challenge - Joins (Preventing Join Explosion / Fan-Out)

## 📌 Business Scenario
A Junior Analyst was asked to write a single query that returns two company-wide metrics: the **Total Revenue** across all orders, and the **Total Number of Tags** applied to those orders.

They wrote the following query:
```sql
SELECT SUM(o.revenue) AS total_revenue, COUNT(t.tag) AS total_tags
FROM orders o
LEFT JOIN order_tags t ON o.order_id = t.order_id;
```
When the CFO saw the report, they panicked—the revenue was artificially inflated by millions of dollars! 

This happened because of a **Join Explosion** (or Fan-Out). Because one order can have multiple tags (e.g., 'Gift Wrap' and 'Expedited'), the SQL engine duplicates the `orders` row for every tag. When `SUM()` is applied, it blindly adds up those duplicated revenues. 

You need to fix this query by aggregating the data at the correct granularity *before* combining it.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    revenue DECIMAL(10, 2)
);

-- Create Order Tags Table (1-to-Many Relationship)
CREATE TABLE order_tags (
    tag_id INT PRIMARY KEY,
    order_id INT,
    tag VARCHAR(50)
);

-- Insert Sample Data
INSERT INTO orders VALUES
(1, 100.00),
(2, 50.00),  -- True Total Revenue: $150.00
(3, 0.00);   -- Order 3 was cancelled

INSERT INTO order_tags VALUES
(101, 1, 'Gift'),
(102, 1, 'Next Day Air'), -- Order 1 has 2 tags
(103, 2, 'Promo Code');   -- Order 2 has 1 tag
-- True Total Tags: 3
```

---

## ❓ The Question
Write a corrected SQL query that accurately calculates the `total_revenue` and the `total_tags` without inflating the revenue. 

Use a Common Table Expression (CTE) to pre-aggregate the tags per order, and then join that CTE back to the main `orders` table.

---

## 💡 The Solution

```sql
WITH TagCounts AS (
    -- Step 1: Pre-aggregate the tags at the order_id level
    SELECT 
        order_id, 
        COUNT(tag) AS num_tags
    FROM order_tags
    GROUP BY order_id
)
-- Step 2: Safely join the pre-aggregated 1-to-1 data to the orders table
SELECT 
    SUM(o.revenue) AS total_revenue,
    SUM(t.num_tags) AS total_tags
FROM orders o
LEFT JOIN TagCounts t 
    ON o.order_id = t.order_id;
```

*(Note: Another perfectly valid and highly performant approach is calculating the two grand totals in entirely separate CTEs and then `CROSS JOIN`ing them together at the very end).*

---

## 📝 Explanation
- **The Anatomy of the Bug**: In the Junior Analyst's broken query, Order 1 is duplicated because it has 2 tags. The intermediate join result looks like this:
  - `Order 1 | $100 | Gift`
  - `Order 1 | $100 | Next Day Air`
  - `Order 2 | $50  | Promo Code`
  - When `SUM(revenue)` runs on this intermediate table, it adds `$100 + $100 + $50 = $250`. It artificially inflated the true `$150` revenue by `$100`!
- **The CTE Fix**: By creating the `TagCounts` CTE, we collapse the `order_tags` table down so that there is strictly one row per `order_id` (e.g., `Order 1 | 2 tags`). 
- **The Safe Join**: When we join the `orders` table to the `TagCounts` CTE, the relationship is now 1-to-1 (or 1-to-0). Order 1 matches exactly one row in the CTE. No rows are duplicated, meaning `SUM(o.revenue)` safely evaluates to the correct `$150.00`.
