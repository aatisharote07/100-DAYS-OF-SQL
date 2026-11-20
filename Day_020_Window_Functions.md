# Day 20: SQL Challenge - Window Functions (LEAD / SCD Type 2 Timeline)

## 📌 Business Scenario
A retail business tracks pricing history for its inventory. Every time a product's price is updated, a new record is added to the `price_history` table. 

The analytics team needs to generate a timeline report showing the start date, end date, and active duration (in days) that each price point was in effect for each product. This is a classic example of querying a **Slowly Changing Dimension (SCD Type 2)** structure.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Price History Table
CREATE TABLE price_history (
    history_id INT PRIMARY KEY,
    product_id INT,
    price DECIMAL(10, 2),
    changed_date DATE
);

-- Insert Sample Data
INSERT INTO price_history (history_id, product_id, price, changed_date) VALUES
(1, 101, 19.99, '2026-01-01'), -- Laptop Sleeve Initial Price
(2, 101, 24.99, '2026-01-15'), -- Price increased on Jan 15 (Active for 26 days)
(3, 101, 22.99, '2026-02-10'), -- Price decreased on Feb 10 (Current price)
(4, 102, 99.99, '2026-01-10'), -- Wireless Earbuds Initial Price
(5, 102, 89.99, '2026-03-01'); -- Price decreased on Mar 1 (Current price)
```

---

## ❓ The Question
Write an SQL query to retrieve a complete timeline of price history for each product. For each price interval, display the `product_id`, `price`, `start_date` (which is `changed_date`), `end_date` (the day before the next price change, or the current date `'2026-06-25'` if it is currently active), and the inclusive `active_duration_days` that the price was in effect.

---

## 💡 The Solution

### MySQL Solution
```sql
WITH PriceIntervals AS (
    SELECT 
        product_id,
        price,
        changed_date AS start_date,
        -- Fetch the next change date and subtract 1 day to find the current price's end date
        DATE_SUB(
            LEAD(changed_date, 1) OVER (PARTITION BY product_id ORDER BY changed_date), 
            INTERVAL 1 DAY
        ) AS end_date
    FROM price_history
)
SELECT 
    product_id,
    price,
    start_date,
    COALESCE(end_date, '2026-06-25') AS end_date,
    DATEDIFF(COALESCE(end_date, '2026-06-25'), start_date) + 1 AS active_duration_days
FROM PriceIntervals
ORDER BY product_id, start_date;
```

### PostgreSQL Solution
```sql
WITH PriceIntervals AS (
    SELECT 
        product_id,
        price,
        changed_date AS start_date,
        -- PostgreSQL allows direct subtraction of integer intervals from date types
        LEAD(changed_date, 1) OVER (PARTITION BY product_id ORDER BY changed_date) - 1 AS end_date
    FROM price_history
)
SELECT 
    product_id,
    price,
    start_date,
    COALESCE(end_date, '2026-06-25'::date) AS end_date,
    (COALESCE(end_date, '2026-06-25'::date) - start_date) + 1 AS active_duration_days
FROM PriceIntervals
ORDER BY product_id, start_date;
```

---

## 📝 Explanation
- **`LEAD` Window Function**: The expression `LEAD(changed_date, 1) OVER (PARTITION BY product_id ORDER BY changed_date)` retrieves the `changed_date` from the subsequent chronological row within the partition of the same `product_id`.
- **Calculating `end_date`**: We subtract 1 day from the next price's start date to get the last active date of the current price. For the latest price, `LEAD` returns `NULL`, which represents the price currently in effect.
- **Handling Current Prices**: We use `COALESCE` to default any `NULL` `end_date` to the current reporting date (`'2026-06-25'`).
- **Inclusive Duration**: Subtracting the two dates yields the difference. Adding `1` ensures the count is inclusive of both the start and end dates (e.g. active from Jan 1 to Jan 14 is 14 days inclusive).
