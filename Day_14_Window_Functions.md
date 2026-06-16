# Day 14: SQL Challenge - Window Functions (Login Streak / Gaps & Islands)

## 📌 Business Scenario
A product growth team wants to analyze user engagement and reward active usage habits. They need to identify "power users" who have built a habit of using the app by logging in for **3 or more consecutive days**. 

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create User Logins Table
CREATE TABLE user_logins (
    login_id INT PRIMARY KEY,
    user_id INT,
    login_date DATE
);

-- Insert Sample Data
INSERT INTO user_logins (login_id, user_id, login_date) VALUES
(1, 101, '2026-06-01'),
(2, 101, '2026-06-02'),
(3, 101, '2026-06-03'), -- User 101: 3 consecutive days!
(4, 101, '2026-06-05'),
(5, 102, '2026-06-01'),
(6, 102, '2026-06-03'),
(7, 102, '2026-06-04'), -- User 102: Only 2 consecutive days
(8, 103, '2026-06-10'),
(9, 103, '2026-06-11'),
(10, 103, '2026-06-12'),
(11, 103, '2026-06-13'); -- User 103: 4 consecutive days!
```

---

## ❓ The Question
Write an SQL query to identify all users who have logged in on 3 or more consecutive days. For each qualifying streak, return the `user_id`, the streak start date (`streak_start`), the streak end date (`streak_end`), and the number of consecutive days (`streak_length`).

---

## 💡 The Solution

### MySQL Solution
```sql
WITH UniqueLogins AS (
    -- Eliminate duplicate logins on the same day
    SELECT DISTINCT user_id, login_date
    FROM user_logins
),
LoginGroups AS (
    SELECT 
        user_id,
        login_date,
        -- Subtract the row number (in days) from the login_date
        DATE_SUB(login_date, INTERVAL ROW_NUMBER() OVER (
            PARTITION BY user_id 
            ORDER BY login_date
        ) DAY) AS anchor_date
    FROM UniqueLogins
),
Streaks AS (
    SELECT 
        user_id,
        MIN(login_date) AS streak_start,
        MAX(login_date) AS streak_end,
        COUNT(*) AS streak_length
    FROM LoginGroups
    GROUP BY user_id, anchor_date
)
SELECT 
    user_id,
    streak_start,
    streak_end,
    streak_length
FROM Streaks
WHERE streak_length >= 3
ORDER BY user_id, streak_start;
```

### PostgreSQL Solution
```sql
WITH UniqueLogins AS (
    SELECT DISTINCT user_id, login_date
    FROM user_logins
),
LoginGroups AS (
    SELECT 
        user_id,
        login_date,
        -- PostgreSQL allows direct subtraction of integer intervals from dates
        login_date - CAST(ROW_NUMBER() OVER (
            PARTITION BY user_id 
            ORDER BY login_date
        ) AS INT) AS anchor_date
    FROM UniqueLogins
),
Streaks AS (
    SELECT 
        user_id,
        MIN(login_date) AS streak_start,
        MAX(login_date) AS streak_end,
        COUNT(*) AS streak_length
    FROM LoginGroups
    GROUP BY user_id, anchor_date
)
SELECT 
    user_id,
    streak_start,
    streak_end,
    streak_length
FROM Streaks
WHERE streak_length >= 3
ORDER BY user_id, streak_start;
```

---

## 📝 Explanation
- **Gaps and Islands**: This is a classic "Gaps and Islands" SQL problem, where consecutive records form "islands" and breaks in dates represent "gaps".
- **Deduplication**: The first CTE (`UniqueLogins`) filters out users logging in multiple times on a single day.
- **The Date Subtraction Trick**: In the `LoginGroups` CTE, we calculate an `anchor_date` by subtracting the row number from the login date. 
  - For user `101`, consecutive dates are `June 1` (row 1), `June 2` (row 2), and `June 3` (row 3). 
  - `June 1 - 1 day = May 31`, `June 2 - 2 days = May 31`, and `June 3 - 3 days = May 31`. All consecutive rows yield the identical `anchor_date`!
  - When the date jumps to `June 5` (row 4), `June 5 - 4 days = June 1`. This difference forms a new grouping bucket.
- **Grouping & Filtering**: Grouping by `user_id` and the calculated `anchor_date` collects consecutive sessions into single buckets. We then aggregate with `MIN()`, `MAX()`, and `COUNT(*)` to isolate streaks of 3 or more days.
