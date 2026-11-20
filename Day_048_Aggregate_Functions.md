# Day 48: SQL Challenge - Aggregate Functions (Finding the Mode per Group)

## 📌 Business Scenario
A retail analytics team wants to optimize the checkout experience across their different store locations. To do this, they need to identify the **Mode** — the most frequently used payment method (e.g., Cash, Credit Card, Mobile Wallet) at each specific store.

Unlike `AVG()`, `MAX()`, or `SUM()`, SQL does not have a built-in `MODE()` aggregate function in most standard dialects. Finding the most common string value per group requires a combination of grouping, counting, and window ranking.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Transactions Table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    store_id INT,
    payment_method VARCHAR(50)
);

-- Insert Sample Data
INSERT INTO transactions VALUES
(1, 101, 'Credit Card'),
(2, 101, 'Credit Card'),
(3, 101, 'Cash'),
(4, 101, 'Mobile Wallet'),
(5, 102, 'Cash'),
(6, 102, 'Cash'),
(7, 102, 'Cash'),
(8, 102, 'Credit Card'),
(9, 103, 'Mobile Wallet'),
(10, 103, 'Mobile Wallet'),
(11, 103, 'Credit Card'),
(12, 103, 'Credit Card'); 
-- Note: Store 103 has a tie between Mobile Wallet and Credit Card!
```

---

## ❓ The Question
Write an SQL query to find the most frequently used payment method for each `store_id`. If there is a tie (multiple payment methods have the exact same highest usage count), your query should return all tied payment methods for that store.

Return the `store_id`, `most_popular_method`, and the `usage_count`. Order the results by `store_id`, and then by `most_popular_method` alphabetically.

---

## 💡 The Solution

```sql
WITH PaymentFrequencies AS (
    -- Step 1: Count occurrences of each payment method per store
    -- Step 2: Rank them dynamically within each store partition
    SELECT 
        store_id,
        payment_method,
        COUNT(*) AS usage_count,
        RANK() OVER (
            PARTITION BY store_id 
            ORDER BY COUNT(*) DESC
        ) AS popularity_rank
    FROM transactions
    GROUP BY store_id, payment_method
)
-- Step 3: Filter for only the #1 ranked methods
SELECT 
    store_id,
    payment_method AS most_popular_method,
    usage_count
FROM PaymentFrequencies
WHERE popularity_rank = 1
ORDER BY store_id, most_popular_method;
```

---

## 📝 Explanation
- **Step 1: Grouping and Counting**: Inside the CTE, we first `GROUP BY store_id, payment_method` and apply `COUNT(*)` to find exactly how many times each method was used at each store.
- **Step 2: Window Ranking over Aggregates**: We can apply a window function directly over an aggregate function! `RANK() OVER (PARTITION BY store_id ORDER BY COUNT(*) DESC)` assigns a rank of `1` to the payment method with the highest count in that store.
- **Handling Ties with `RANK()`**: We intentionally use `RANK()` (or `DENSE_RANK()`) instead of `ROW_NUMBER()`. If a store has a tie for the most popular method (like Store 103, where both Mobile Wallet and Credit Card were used twice), `RANK()` assigns `1` to *both* of them. `ROW_NUMBER()` would arbitrarily pick only one.
- **Step 3: Filtering the Mode**: The outer query simply filters the CTE to keep only the rows where `popularity_rank = 1`.
