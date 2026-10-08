# Day 80: SQL Challenge - Aggregate Functions (Cohort Retention Rates)

## 📌 Business Scenario
🎉 **Happy Day 80!** 🎉

The Product team at a mobile app company is analyzing user engagement. They want to calculate the **Month 1 Retention Rate** for their January 2026 cohort. 

Specifically, they want to know: Out of all the users who signed up in January 2026, what percentage of them returned to make at least one purchase in February 2026?

Cohort analysis is the absolute cornerstone of product analytics. This challenge requires combining a precisely filtered `LEFT JOIN` with Conditional Aggregation.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Users Table (Signups)
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    signup_date DATE
);

-- Create Purchases Table
CREATE TABLE purchases (
    purchase_id INT PRIMARY KEY,
    user_id INT,
    purchase_date DATE
);

-- Insert Sample Data
INSERT INTO users VALUES
(1, '2026-01-05'), -- Jan Cohort
(2, '2026-01-15'), -- Jan Cohort
(3, '2026-01-20'), -- Jan Cohort
(4, '2026-01-25'), -- Jan Cohort
(5, '2026-02-02'); -- Feb Cohort (Should be ignored entirely)

INSERT INTO purchases VALUES
(101, 1, '2026-01-10'), -- Purchase in Jan (Ignore for Month 1 retention)
(102, 1, '2026-02-15'), -- Retained! (User 1 bought in Feb)
(103, 1, '2026-02-20'), -- Retained! (User 1 bought twice, count only once)
(104, 2, '2026-02-05'), -- Retained! (User 2 bought in Feb)
(105, 5, '2026-02-10'); -- Bought in Feb, but not in the Jan Cohort!

-- Expected Math: 4 Jan Signups. 2 of them bought in Feb. Retention = 50.00%
```

---

## ❓ The Question
Write a single SQL query to calculate the Month 1 Retention Rate for the January 2026 cohort. 

Return the `total_jan_signups`, the number of users `retained_in_feb`, and the `retention_rate_pct` (rounded to 2 decimal places). 

*Hint: If you join the purchases table, make sure you only join the February purchases, otherwise your base signup count might inflate!*

---

## 💡 The Solution

```sql
SELECT 
    -- Step 1: Count the total base of the cohort
    COUNT(DISTINCT u.user_id) AS total_jan_signups,
    
    -- Step 3: Count how many unique users successfully joined to a Feb purchase
    COUNT(DISTINCT p.user_id) AS retained_in_feb,
    
    -- Step 4: Calculate the percentage (Retained / Total) * 100
    ROUND(
        COUNT(DISTINCT p.user_id) * 100.0 / COUNT(DISTINCT u.user_id), 
    2) AS retention_rate_pct
FROM users u
-- Step 2: LEFT JOIN ONLY the February purchases
LEFT JOIN purchases p 
    ON u.user_id = p.user_id 
    -- Applying the date filter IN THE JOIN CLAUSE prevents row inflation for other months
    AND p.purchase_date >= '2026-02-01' 
    AND p.purchase_date < '2026-03-01'
-- Filter the base table to strictly the January Cohort
WHERE u.signup_date >= '2026-01-01' 
  AND u.signup_date < '2026-02-01';
```

---

## 📝 Explanation
- **The Base Cohort (`WHERE`)**: The `WHERE` clause filters the `users` table so we are strictly dealing with the 4 users who signed up in January. User 5 is completely ignored.
- **The Strategic `LEFT JOIN`**: We must use a `LEFT JOIN` because we need to keep *all* 4 January users in the result set to act as our denominator, even if they didn't buy anything in February. 
- **Filtering inside the `ON` clause**: We place the February date filter directly inside the `ON` clause (`p.purchase_date >= '2026-02-01'`). 
  - If we placed this in the `WHERE` clause, the query would transform into an `INNER JOIN`, instantly dropping Users 3 and 4 (who bought nothing) and ruining our denominator.
  - By keeping it in the `ON` clause, User 1 successfully matches their Feb purchases, while Users 3 and 4 simply receive `NULL`s for the purchase columns but remain in the table!
- **`COUNT(DISTINCT)`**: Because User 1 made *two* purchases in February, the `LEFT JOIN` duplicates User 1's row. Using `COUNT(DISTINCT user_id)` ensures User 1 is only counted exactly once as a signup, and exactly once as a retained user, giving us our perfect `2 / 4 = 50%` metric.
