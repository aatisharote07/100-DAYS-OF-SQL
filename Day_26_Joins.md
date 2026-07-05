# Day 26: SQL Challenge - Joins (Non-Equi Join on Date Ranges)

## 📌 Business Scenario
A marketing attribution team wants to measure the direct impact of running promotional campaigns. They want to attribute product transactions to specific marketing campaigns. 

A purchase is classified as "attributed" to a campaign if:
1. The transaction occurred during the campaign's running window (between the campaign's `start_date` and `end_date`, inclusive).
2. The product category of the purchase matches the category focus of the campaign.

If a transaction cannot be linked to any active campaign, it is labeled as an `"Organic"` sale.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Campaigns Table
CREATE TABLE campaigns (
    campaign_id INT PRIMARY KEY,
    campaign_name VARCHAR(100),
    category VARCHAR(50),
    start_date DATE,
    end_date DATE
);

-- Create Transactions Table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    product_category VARCHAR(50),
    amount DECIMAL(10, 2),
    transaction_date DATE
);

-- Insert Sample Data
INSERT INTO campaigns (campaign_id, campaign_name, category, start_date, end_date) VALUES
(1, 'Spring Tech Festival', 'Electronics', '2026-04-01', '2026-04-15'),
(2, 'Home Upgrade Sale', 'Furniture', '2026-05-01', '2026-05-31'),
(3, 'Summer Apparel Promo', 'Apparel', '2026-06-01', '2026-06-15');

INSERT INTO transactions (transaction_id, customer_id, product_category, amount, transaction_date) VALUES
(101, 1001, 'Electronics', 1200.00, '2026-04-05'), -- Attributed (Spring Tech Festival)
(102, 1002, 'Electronics', 400.00, '2026-04-20'),  -- Organic (Outside campaign date range)
(103, 1003, 'Furniture', 750.00, '2026-05-15'),    -- Attributed (Home Upgrade Sale)
(104, 1004, 'Apparel', 80.00, '2026-06-10'),       -- Attributed (Summer Apparel Promo)
(105, 1001, 'Apparel', 120.00, '2026-06-20');      -- Organic (Outside campaign date range)
```

---

## ❓ The Question
Write an SQL query to retrieve all transactions, attributing each transaction to a campaign if it fits the rules. For each transaction, return the `transaction_id`, `product_category`, `amount`, `transaction_date`, and the `campaign_attribution` (display the campaign name, or `'Organic'` if the purchase did not fall within any campaign window).

---

## 💡 The Solution

```sql
SELECT 
    t.transaction_id,
    t.product_category,
    t.amount,
    t.transaction_date,
    COALESCE(c.campaign_name, 'Organic') AS campaign_attribution
FROM transactions t
LEFT JOIN campaigns c ON t.product_category = c.category
                     AND t.transaction_date BETWEEN c.start_date AND c.end_date
ORDER BY t.transaction_id;
```

---

## 📝 Explanation
- **Non-Equi Join**: Unlike a standard join that links rows using strict equality (`ON tableA.id = tableB.id`), a non-equi join links rows using range and inequality operators. In this query, we link transactions to campaigns using the criteria `t.transaction_date BETWEEN c.start_date AND c.end_date`.
- **`LEFT JOIN`**: We perform a `LEFT JOIN` starting from the `transactions` table to ensure that every single sale is represented in the final output, regardless of whether it is successfully linked to a campaign.
- **Handling NULLs via `COALESCE`**: Any transaction that occurs outside of a campaign period will fail the join condition, resulting in a campaign name of `NULL`. Wrapping the campaign name in `COALESCE(c.campaign_name, 'Organic')` replaces these nulls with the string `'Organic'`.
