# Day 71: SQL Challenge - Window Functions (Finding the Nth Event)

## 📌 Business Scenario
An e-commerce marketing team is launching a "Third Time's the Charm!" loyalty campaign. They want to send a special discount code to customers who have made exactly 3 purchases, and they want to trigger this email based on the date of that specific **3rd purchase**.

To build this trigger, you need to find the exact date and amount of every customer's 3rd purchase. Standard aggregate functions like `MIN()` or `MAX()` can find the 1st or last purchase, but they cannot find the 3rd. This is a perfect use case for `ROW_NUMBER()`.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Purchases Table
CREATE TABLE purchases (
    purchase_id INT PRIMARY KEY,
    customer_id INT,
    purchase_date DATE,
    amount DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO purchases VALUES
(1, 101, '2026-01-10', 50.00),  -- Cust 101: 1st Purchase
(2, 101, '2026-03-15', 75.00),  -- Cust 101: 2nd Purchase
(3, 101, '2026-06-20', 120.00), -- Cust 101: 3rd Purchase (Target!)
(4, 101, '2026-09-05', 40.00),  -- Cust 101: 4th Purchase
(5, 102, '2026-02-14', 15.00),  -- Cust 102: 1st Purchase
(6, 102, '2026-05-10', 30.00),  -- Cust 102: 2nd Purchase (Never made a 3rd)
(7, 103, '2026-08-01', 200.00), -- Cust 103: 1st Purchase
(8, 103, '2026-08-02', 20.00),  -- Cust 103: 2nd Purchase
(9, 103, '2026-08-03', 50.00);  -- Cust 103: 3rd Purchase (Target!)
```

---

## ❓ The Question
Write an SQL query using a Common Table Expression (CTE) and a Window Function to identify the exact date and amount of every customer's 3rd purchase. 

If a customer has made fewer than 3 purchases (like Customer 102), they should simply be excluded from the report. Return the `customer_id`, `third_purchase_date`, and `amount`. Order by `customer_id`.

---

## 💡 The Solution

```sql
WITH RankedPurchases AS (
    -- Step 1: Assign a chronological row number to each purchase per customer
    SELECT 
        customer_id,
        purchase_date,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY purchase_date ASC
        ) AS purchase_num
    FROM purchases
)
-- Step 2: Filter specifically for the 3rd purchase
SELECT 
    customer_id,
    purchase_date AS third_purchase_date,
    amount
FROM RankedPurchases
WHERE purchase_num = 3
ORDER BY customer_id;
```

---

## 📝 Explanation
- **Why `ROW_NUMBER()`?**: While `MIN()` easily finds the 1st purchase and `MAX()` finds the last purchase, there is no aggregate function for "middle" events. `ROW_NUMBER()` is the definitive solution for finding the Nth occurrence of anything in SQL.
- **The Partition (`PARTITION BY customer_id`)**: This tells the database to reset the counter back to `1` for every new customer. Without this, the engine would just number all purchases globally from 1 to 9.
- **The Ordering (`ORDER BY purchase_date ASC`)**: This ensures the counter increments chronologically. The oldest purchase gets `1`, the next gets `2`, and so on.
- **The CTE Filtering (`WHERE purchase_num = 3`)**: Window functions evaluate *after* the `WHERE` clause. Therefore, you cannot write `WHERE ROW_NUMBER() = 3`. You must generate the ranking inside a CTE first, and then apply the `WHERE` filter in the outer query. Customer 102 is naturally excluded because their `purchase_num` never reached 3.
