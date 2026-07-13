# Day 32: SQL Challenge - Data Cleaning (Rule-Based Text Categorization)

## 📌 Business Scenario
A personal finance application imports transaction descriptions from credit card statement logs. The raw descriptions are messy and inconsistent (e.g., containing store numbers, cities, and special characters). 

To power a financial dashboard, we need to clean and classify these transactions into standard spending categories like `'Groceries'`, `'Dining'`, `'Travel'`, `'Entertainment'`, or `'Other'` based on keyword rules.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Raw Transactions Table
CREATE TABLE raw_transactions (
    transaction_id INT PRIMARY KEY,
    raw_description VARCHAR(255),
    amount DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO raw_transactions (transaction_id, raw_description, amount) VALUES
(1, 'WHOLEFDS MARKET #9987', 124.50),
(2, 'MCDONALDS #4521 CHICAGO', 12.80),
(3, 'UBER TRIP *HELP.UBER.COM', 24.50),
(4, 'NETFLIX.COM DIGITAL SUBSCRIPTION', 15.49),
(5, 'SHELL OIL 4452 DETROIT', 45.00),
(6, 'STARBUCKS COFFEE NY', 6.75),
(7, 'TARGET STORE #1245', 89.20);
```

---

## ❓ The Question
Write an SQL query to categorize each transaction based on the following rules:
- **`Groceries`**: If the description contains `'WHOLEFDS'` or `'TARGET'`.
- **`Dining`**: If it contains `'MCDONALDS'` or `'STARBUCKS'`.
- **`Travel`**: If it contains `'UBER'` or `'SHELL'`.
- **`Entertainment`**: If it contains `'NETFLIX'`.
- **`Other`**: For all other descriptions.

The query must be case-insensitive to ensure matching succeeds even if raw casing varies. Output the `transaction_id`, `raw_description`, `amount`, and the new `spending_category`. Order the output by `spending_category` alphabetically, and then by `amount` in descending order.

---

## 💡 The Solution

```sql
SELECT 
    transaction_id,
    raw_description,
    amount,
    CASE 
        WHEN UPPER(raw_description) LIKE '%WHOLEFDS%' 
          OR UPPER(raw_description) LIKE '%TARGET%' THEN 'Groceries'
        WHEN UPPER(raw_description) LIKE '%MCDONALDS%' 
          OR UPPER(raw_description) LIKE '%STARBUCKS%' THEN 'Dining'
        WHEN UPPER(raw_description) LIKE '%UBER%' 
          OR UPPER(raw_description) LIKE '%SHELL%' THEN 'Travel'
        WHEN UPPER(raw_description) LIKE '%NETFLIX%' THEN 'Entertainment'
        ELSE 'Other'
    END AS spending_category
FROM raw_transactions
ORDER BY spending_category, amount DESC;
```

---

## 📝 Explanation
- **Case Standardization**: Wrapping the target column in `UPPER(raw_description)` standardizes the text casing before comparison. This handles variations like `'Starbucks'` or `'starbucks'` without requiring separate search rules.
- **Substring Matching via `LIKE`**: We use the percentage wildcard (`%`) on both ends of our search terms (e.g. `'%UBER%'`). This matches the substring regardless of where it appears in the raw text.
- **Logical Routing (`CASE WHEN`)**: The `CASE` statement acts as a sequential logical switch. The engine evaluates each condition top-to-bottom, returning the corresponding string for the first match it hits. If none of the keyword conditions evaluate to true, the `ELSE` branch provides the fallback category `'Other'`.
- **Ordering**: The results are grouped by the newly generated category and sorted within each category by the cash amount in descending order.
