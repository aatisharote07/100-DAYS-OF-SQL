# Day 68: SQL Challenge - Subqueries (Correlated Subquery vs Window Functions)

## 📌 Business Scenario
A retail merchandising team wants to identify their "premium" inventory. They define a product as "premium" if its price is strictly greater than the average price of all products within its *specific category*. 

For example, a $50 T-shirt might be premium for the 'Apparel' category, but a $50 Microwave would be cheap for the 'Appliances' category. We must compare each product against the dynamic average of its own group.

This is a classic use case for a **Correlated Subquery**, but modern SQL offers a much faster alternative using **Window Functions**.

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
INSERT INTO products VALUES
(1, 'Cotton T-Shirt', 'Apparel', 20.00),
(2, 'Running Shorts', 'Apparel', 30.00),
(3, 'Designer Jacket', 'Apparel', 100.00), -- Apparel Avg: $50 (Jacket is Premium!)
(4, 'Basic Blender', 'Appliances', 40.00),
(5, 'Microwave', 'Appliances', 60.00),
(6, 'Espresso Machine', 'Appliances', 200.00); -- Appliance Avg: $100 (Espresso is Premium!)
```

---

## ❓ The Question
Write an SQL query to find all "premium" products whose price is strictly greater than the average price of their category. 

Provide two different solutions: one using a **Correlated Subquery**, and a more modern, performant one using a **CTE and a Window Function**. 

Return the `product_name`, `category`, and `price`. Order the results alphabetically by `category`, then by `price` descending.

---

## 💡 The Solution

### Method 1: The Correlated Subquery (Traditional)
```sql
SELECT 
    p1.product_name,
    p1.category,
    p1.price
FROM products p1
WHERE p1.price > (
    -- This subquery executes over and over again for every row in p1
    SELECT AVG(p2.price)
    FROM products p2
    WHERE p1.category = p2.category
)
ORDER BY p1.category ASC, p1.price DESC;
```

### Method 2: CTE + Window Function (Modern & Performant)
```sql
WITH CategoryAverages AS (
    -- Step 1: Calculate the category average once, inline with the data
    SELECT 
        product_name,
        category,
        price,
        AVG(price) OVER (PARTITION BY category) AS avg_category_price
    FROM products
)
-- Step 2: Filter the pre-calculated results
SELECT 
    product_name,
    category,
    price
FROM CategoryAverages
WHERE price > avg_category_price
ORDER BY category ASC, price DESC;
```

---

## 📝 Explanation
- **The Correlated Subquery Problem**: In Method 1, the inner subquery relies on a value from the outer query (`p1.category = p2.category`). This creates a *correlation*. Because of this, the database engine must execute that subquery individually for **every single row** in the `products` table. If you have 1 million products, that subquery runs 1 million times. It is notoriously slow.
- **The Window Function Solution**: In Method 2, `AVG(price) OVER (PARTITION BY category)` solves this brilliantly. 
  - The `PARTITION BY` clause acts like a `GROUP BY` that doesn't collapse the rows. It calculates the average for 'Apparel' ($50) and appends that `$50` directly alongside the Cotton T-Shirt, the Shorts, and the Jacket.
  - This calculation requires only a **single pass** over the data, making it exponentially faster than the correlated subquery on large datasets.
- **Why the CTE?**: Window functions are evaluated *after* the `WHERE` clause in the SQL order of operations. Therefore, you cannot write `WHERE price > AVG(price) OVER(...)`. You must calculate it inside a CTE first, and then apply the `WHERE` filter in the outer query.
