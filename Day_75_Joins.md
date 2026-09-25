# Day 75: SQL Challenge - Joins & CTEs (Time to Second Purchase)

## 📌 Business Scenario
🎉 **Happy Day 75!** 🎉

An e-commerce company's growth team is analyzing customer loyalty. A key metric they track is the **"Time to Second Purchase"** — exactly how many days, on average, does it take for a new customer to come back and buy something again?

To calculate this, you need to isolate every customer's first purchase, isolate their second purchase, calculate the date difference between the two, and then average that difference across the entire user base.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Purchases Table
CREATE TABLE purchases (
    purchase_id INT PRIMARY KEY,
    customer_id INT,
    purchase_date DATE
);

-- Insert Sample Data
INSERT INTO purchases VALUES
(1, 101, '2026-01-01'), -- Cust 101: 1st Purchase
(2, 101, '2026-01-15'), -- Cust 101: 2nd Purchase (14 days later)
(3, 101, '2026-03-01'), -- Cust 101: 3rd Purchase (Ignore)
(4, 102, '2026-05-10'), -- Cust 102: 1st Purchase (Never made a 2nd, ignore)
(5, 103, '2026-08-01'), -- Cust 103: 1st Purchase
(6, 103, '2026-08-11'); -- Cust 103: 2nd Purchase (10 days later)

-- Average should be (14 + 10) / 2 = 12 Days
```

---

## ❓ The Question
Write an SQL query to calculate the overall average number of days it takes for a customer to make their second purchase. 

Use a CTE and the `ROW_NUMBER()` window function to rank the purchases chronologically. Then, use a **Self-Join** to match a customer's first purchase with their second purchase. Return a single column named `avg_days_to_second_purchase` (rounded to 1 decimal place). 

*Customers who only ever made one purchase should naturally fall out of the calculation.*

---

## 💡 The Solution

*(Note: Date arithmetic syntax varies by dialect. The solution below uses standard MySQL syntax).*

```sql
WITH RankedPurchases AS (
    -- Step 1: Chronologically rank every purchase per customer
    SELECT 
        customer_id,
        purchase_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY purchase_date ASC
        ) AS purchase_num
    FROM purchases
)
-- Step 3: Calculate the average of the differences
SELECT 
    ROUND(AVG(DATEDIFF(p2.purchase_date, p1.purchase_date)), 1) AS avg_days_to_second_purchase
FROM RankedPurchases p1
-- Step 2: Self-Join the 1st purchase to the 2nd purchase
JOIN RankedPurchases p2 
    ON p1.customer_id = p2.customer_id 
    AND p1.purchase_num = 1 
    AND p2.purchase_num = 2;
```

*(For PostgreSQL: Replace `DATEDIFF(p2, p1)` with `(p2.purchase_date - p1.purchase_date)`)*
*(For SQL Server: Replace `DATEDIFF(...)` with `DATEDIFF(day, p1.purchase_date, p2.purchase_date)`)*

---

## 📝 Explanation
- **Step 1 (The CTE)**: We use `ROW_NUMBER()` to assign `1` to the first purchase, `2` to the second, and so on, restarting the count for each `customer_id`.
- **Step 2 (The Self-Join)**: This is the most crucial part of the query. We alias our CTE twice (`p1` and `p2`). We join the table to itself matching on `customer_id`. 
  - To specifically grab the first and second purchases, we hardcode the join conditions: `p1.purchase_num = 1 AND p2.purchase_num = 2`.
  - Because it is an `INNER JOIN`, Customer 102 (who only has a `purchase_num = 1` and no `2`) is safely and automatically excluded from the results.
- **Step 3 (The Math)**: Now that the first and second purchase dates sit side-by-side on the exact same row, we use `DATEDIFF()` to find the gap in days, and wrap that in `AVG()` to find the metric across the entire company.
