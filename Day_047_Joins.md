# Day 47: SQL Challenge - Joins (Market Basket Analysis / Product Combinations)

## 📌 Business Scenario
A retail data science team is building a product recommendation engine (e.g., "Customers who bought this also bought..."). To train the model, they need to perform a **Market Basket Analysis** to identify which pairs of products are most frequently purchased together in the exact same transaction.

This requires generating combinations of items within the same order by self-joining the order details table, and then aggregating those pairs to find the most common combinations.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Order Items Table
CREATE TABLE order_items (
    order_id INT,
    product_name VARCHAR(100),
    PRIMARY KEY (order_id, product_name)
);

-- Insert Sample Data
INSERT INTO order_items VALUES
(101, 'Coffee'),
(101, 'Milk'),
(101, 'Sugar'),
(102, 'Coffee'),
(102, 'Sugar'),
(103, 'Milk'),
(103, 'Bread'),
(104, 'Coffee'),
(104, 'Milk'),
(104, 'Bread'),
(105, 'Coffee'),
(105, 'Milk');
-- Coffee + Milk occurs in orders 101, 104, 105 (3 times)
-- Coffee + Sugar occurs in orders 101, 102 (2 times)
```

---

## ❓ The Question
Write an SQL query to find every unique pair of products bought together in the same order and count how many times they were purchased together. 

Return `product_1`, `product_2`, and `times_bought_together`. Order the results by the frequency in descending order. Ensure that the same pair isn't listed twice (e.g., if you list `Coffee & Milk`, do not also list `Milk & Coffee`) and that a product isn't paired with itself.

---

## 💡 The Solution

```sql
SELECT 
    a.product_name AS product_1,
    b.product_name AS product_2,
    COUNT(*) AS times_bought_together
FROM order_items a
JOIN order_items b 
    ON a.order_id = b.order_id
    -- Crucial: strictly less than comparison to avoid dupes and self-pairing
    AND a.product_name < b.product_name
GROUP BY 
    a.product_name, 
    b.product_name
ORDER BY 
    times_bought_together DESC,
    product_1 ASC;
```

---

## 📝 Explanation
- **The Self Join**: By joining `order_items` to itself (`a` and `b`) on `order_id`, we effectively create a matrix of every possible item combination within every single order.
- **Handling Combinations (`a.product_name < b.product_name`)**: This single line of inequality logic achieves two critical things:
  1. **Prevents Self-Pairing**: It stops 'Coffee' from pairing with 'Coffee' (since 'Coffee' is not less than 'Coffee').
  2. **Prevents Duplicates (A,B vs B,A)**: Because 'Coffee' comes before 'Milk' alphabetically, the join only matches 'Coffee' on the left and 'Milk' on the right. It will ignore the reverse match ('Milk' on left, 'Coffee' on right), guaranteeing that each unique pair only appears once per order.
- **Aggregation**: Finally, we `GROUP BY` both product columns and use `COUNT(*)` to tally how many orders contained that specific pair.
