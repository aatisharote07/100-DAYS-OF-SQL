# Day 95: SQL Challenge - CTEs & Joins (Cross-Selling & Frequent Itemset Co-occurrence)

## 📌 Business Scenario
🎉 **Happy Day 95! Only 5 days remain!** 🎉

The recommendation engineering team at an e-commerce platform is designing a "Frequently Bought Together" widget. When a shopper views an item, the platform wants to recommend the product most often purchased within the same shopping basket.

To calculate item pair co-occurrences, data analysts construct a **co-occurrence matrix**. This involves:
1. Joining an orders table to itself on `order_id` to generate all unique two-item pairs within each checkout.
2. Avoiding symmetric duplicates (e.g., counting `(Item A, Item B)` and `(Item B, Item A)` as separate pairs).
3. Aggregating the pair frequency across all customer baskets to find the strongest product affinities.

This Self-Join pattern is the foundational step behind Market Basket Analysis and Collaborative Filtering algorithms.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Order Items Table
CREATE TABLE order_items (
    order_id INT,
    product_name VARCHAR(50),
    PRIMARY KEY (order_id, product_name)
);

-- Insert Sample Data
INSERT INTO order_items VALUES
(101, 'Espresso Roast'),
(101, 'Oat Milk'),
(101, 'Vanilla Syrup'),
(102, 'Espresso Roast'),
(102, 'Oat Milk'),
(103, 'Espresso Roast'),
(103, 'Vanilla Syrup'),
(104, 'Matcha Powder'),
(104, 'Oat Milk'),
(105, 'Espresso Roast'),
(105, 'Oat Milk');
```

---

## ❓ The Question
Write an SQL query to identify all unique pairs of products purchased together in the same order, and count how many times each pair co-occurred.

To ensure each pair is only represented once regardless of ordering, enforce `product_a < product_b`. 

Return `product_a`, `product_b`, and `times_bought_together`. Order the results by `times_bought_together DESC`, then alphabetically by `product_a ASC`, then `product_b ASC`.

---

## 💡 The Solution

```sql
SELECT 
    oi1.product_name AS product_a,
    oi2.product_name AS product_b,
    COUNT(*) AS times_bought_together
FROM order_items oi1
-- Self-Join on order_id to pair items from the same basket
JOIN order_items oi2 
    ON oi1.order_id = oi2.order_id 
    -- Enforce strict inequality to prevent self-pairing and mirror duplicates
    AND oi1.product_name < oi2.product_name
GROUP BY 
    oi1.product_name, 
    oi2.product_name
ORDER BY 
    times_bought_together DESC, 
    product_a ASC, 
    product_b ASC;
```

---

## 📝 Explanation

### Breaking Down the Self-Join Mechanics
- **Matching on `order_id`**: 
  - `oi1.order_id = oi2.order_id` creates all permutations of items within each shopping cart.
  - For Order 101, this pairs Espresso Roast with Oat Milk, Vanilla Syrup with Oat Milk, etc.
- **The Crucial Inequality Filter (`oi1.product_name < oi2.product_name`)**:
  - **Eliminates Self-Pairs**: If we wrote `oi1.order_id = oi2.order_id`, an item would pair with itself (`'Oat Milk' paired with 'Oat Milk'`). 
  - **Eliminates Commutative Duplicates**: If we only wrote `oi1.product_name != oi2.product_name`, we would get both `('Espresso Roast', 'Oat Milk')` and `('Oat Milk', 'Espresso Roast')` as two distinct rows.
  - By requiring strict alphabetical ordering (`<`), only one permutation is permitted (`'Espresso Roast'` is strictly less than `'Oat Milk'`). This guarantees that every distinct product combination is counted exactly once per order.
- **Aggregation (`COUNT(*)`)**:
  - `GROUP BY product_a, product_b` sums up how many independent orders included both items. 
  - In our dataset, `('Espresso Roast', 'Oat Milk')` was purchased together in Orders 101, 102, and 105, yielding a top co-occurrence score of `3`.
