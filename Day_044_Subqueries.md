# Day 44: SQL Challenge - Subqueries (Finding the Closest Previous Event / "As-Of" Join)

## 📌 Business Scenario
A multinational e-commerce company records its daily transactions in various currencies. To calculate accurate revenue in USD, the finance team needs to convert each transaction amount using the exchange rate active *on the day of the transaction*. 

However, exchange rates are only published on weekdays or when significant shifts occur, meaning there isn't always an exchange rate record for every single date. For any given transaction, the system must find the **most recently published exchange rate** prior to or exactly on the transaction date.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Exchange Rates Table
CREATE TABLE exchange_rates (
    currency_code VARCHAR(3),
    rate_date DATE,
    to_usd_rate DECIMAL(10, 4),
    PRIMARY KEY (currency_code, rate_date)
);

-- Create Transactions Table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    transaction_date DATE,
    currency_code VARCHAR(3),
    local_amount DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO exchange_rates VALUES
('EUR', '2026-08-01', 1.1000),
('EUR', '2026-08-04', 1.0950), -- No rates published on Aug 2 or Aug 3
('GBP', '2026-08-01', 1.2500),
('GBP', '2026-08-05', 1.2600);

INSERT INTO transactions VALUES
(101, '2026-08-01', 'EUR', 100.00), -- Exact match (Aug 1 rate: 1.1000)
(102, '2026-08-02', 'EUR', 150.00), -- Should use Aug 1 rate (1.1000)
(103, '2026-08-03', 'EUR', 200.00), -- Should use Aug 1 rate (1.1000)
(104, '2026-08-04', 'EUR', 50.00),  -- Exact match (Aug 4 rate: 1.0950)
(105, '2026-08-04', 'GBP', 200.00); -- Should use Aug 1 rate (1.2500)
```

---

## ❓ The Question
Write an SQL query to calculate the `usd_amount` for each transaction. To do this, you must fetch the most recent `to_usd_rate` for the transaction's currency where the `rate_date` is less than or equal to the `transaction_date`. 

Return the `transaction_id`, `transaction_date`, `currency_code`, `local_amount`, the applied `to_usd_rate`, and the calculated `usd_amount`. Order by `transaction_id`.

---

## 💡 The Solution

```sql
SELECT 
    t.transaction_id,
    t.transaction_date,
    t.currency_code,
    t.local_amount,
    e.to_usd_rate,
    ROUND(t.local_amount * e.to_usd_rate, 2) AS usd_amount
FROM transactions t
LEFT JOIN exchange_rates e 
    ON t.currency_code = e.currency_code
    AND e.rate_date = (
        -- Correlated subquery to find the closest previous date
        SELECT MAX(rate_date)
        FROM exchange_rates er
        WHERE er.currency_code = t.currency_code
          AND er.rate_date <= t.transaction_date
    )
ORDER BY t.transaction_id;
```

---

## 📝 Explanation
- **The "As-Of" Join Problem**: Standard equi-joins (`t.date = e.date`) fail here because transactions occurring on weekends (Aug 2, Aug 3) have no corresponding row in the `exchange_rates` table.
- **Correlated Subquery**: The subquery executes for every row in the `transactions` table. It looks into the `exchange_rates` table for the same currency (`er.currency_code = t.currency_code`) and filters for dates on or before the transaction (`er.rate_date <= t.transaction_date`). 
- **`MAX(rate_date)`**: By taking the maximum date from the filtered results, the subquery perfectly isolates the *most recent* exchange rate published prior to the transaction.
- **The Join Condition**: The outer `LEFT JOIN` then uses this dynamically calculated date to fetch the actual `to_usd_rate` from the `exchange_rates` table. 
- **Note on Performance**: While this approach works beautifully across all SQL dialects, it can be computationally expensive on massive datasets. Some modern engines offer native "AS OF" joins (e.g., Snowflake) or allow `LAST_VALUE()` with `IGNORE NULLS` for more optimized execution.
