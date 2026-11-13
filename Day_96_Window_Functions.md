# Day 96: SQL Challenge - Window Functions (Customer Churn & Inactivity Gaps)

## 📌 Business Scenario
A subscription-based SaaS product team wants to monitor customer retention and detect **dormant or churning accounts**.

An active customer typically logs into the platform frequently. However, if a user experiences an **inactivity gap of 30 or more consecutive days** between logins, or has not logged in for 30+ days since their most recent activity, they are flagged as a churn risk.

To evaluate account health, the customer success team needs a report that analyzes each user's login history, identifies their **maximum recorded gap between consecutive logins**, and determines their **current days of inactivity**.

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

-- Insert Sample Data (Reference Date: '2026-11-13')
INSERT INTO user_logins VALUES
(1, 101, '2026-08-01'),
(2, 101, '2026-08-15'), -- 14 days gap
(3, 101, '2026-09-25'), -- 41 days gap! (Historical Churn Risk)
(4, 101, '2026-11-10'), -- 46 days gap; 3 days inactive as of 2026-11-13
(5, 102, '2026-10-01'),
(6, 102, '2026-10-10'), -- 9 days gap
(7, 102, '2026-10-12'), -- 2 days gap; 32 days inactive as of 2026-11-13 (Currently Churned)
(8, 103, '2026-11-01'),
(9, 103, '2026-11-12'); -- 11 days gap; 1 day inactive as of 2026-11-13 (Healthy)
```

---

## ❓ The Question
Write an SQL query to analyze the login patterns for each user, assuming a snapshot analysis date of `'2026-11-13'`.

For each user, compute:
1. `first_login_date` and `last_login_date`.
2. `max_historical_gap_days`: The largest gap (in days) between any two consecutive logins for that user (use `0` if the user only has 1 login or no gap).
3. `days_since_last_login`: Number of days between their `last_login_date` and the current date (`'2026-11-13'`).
4. `is_currently_at_risk`: Flag as `'YES'` if `days_since_last_login >= 30`, otherwise `'NO'`.

Return `user_id`, `first_login_date`, `last_login_date`, `max_historical_gap_days`, `days_since_last_login`, and `is_currently_at_risk`. Order by `user_id`.

---

## 💡 The Solution

*(Standard ANSI SQL / MySQL syntax)*

```sql
WITH LoginGaps AS (
    -- Step 1: Compute previous login date and calculate gap to current login
    SELECT 
        user_id,
        login_date,
        LAG(login_date) OVER (
            PARTITION BY user_id 
            ORDER BY login_date ASC
        ) AS prev_login_date,
        DATEDIFF(
            login_date, 
            LAG(login_date) OVER (PARTITION BY user_id ORDER BY login_date ASC)
        ) AS gap_days
    FROM user_logins
),
UserSummary AS (
    -- Step 2: Aggregate per user to extract boundary dates and maximum historical gap
    SELECT 
        user_id,
        MIN(login_date) AS first_login_date,
        MAX(login_date) AS last_login_date,
        COALESCE(MAX(gap_days), 0) AS max_historical_gap_days,
        DATEDIFF('2026-11-13', MAX(login_date)) AS days_since_last_login
    FROM LoginGaps
    GROUP BY user_id
)
-- Step 3: Assign risk status based on current inactivity
SELECT 
    user_id,
    first_login_date,
    last_login_date,
    max_historical_gap_days,
    days_since_last_login,
    CASE 
        WHEN days_since_last_login >= 30 THEN 'YES'
        ELSE 'NO'
    END AS is_currently_at_risk
FROM UserSummary
ORDER BY user_id;
```

*(For PostgreSQL: Replace `DATEDIFF(d1, d2)` with `(d1 - d2)` and replace `DATEDIFF('2026-11-13', MAX(login_date))` with `(DATE '2026-11-13' - MAX(login_date))`)*
*(For SQL Server: Replace `DATEDIFF(d1, d2)` with `DATEDIFF(day, d2, d1)`)*

---

## 📝 Explanation

### Step-by-Step Breakdown
- **Step 1 (`LoginGaps` CTE)**:
  - `LAG(login_date) OVER (PARTITION BY user_id ORDER BY login_date ASC)` references the customer's prior session date.
  - `DATEDIFF(login_date, LAG(...))` evaluates the elapsed days between successive visits. The user's very first login has no predecessor, evaluating to `NULL`.
- **Step 2 (`UserSummary` CTE)**:
  - Groups by `user_id` to aggregate metrics across each customer's complete history.
  - `MAX(gap_days)` identifies their single largest historical lapse in engagement. `COALESCE(..., 0)` safely handles single-event users where no gap exists.
  - `DATEDIFF('2026-11-13', MAX(login_date))` checks how long the account has remained silent relative to our current reporting checkpoint.
- **Step 3 (Risk Flagging)**:
  - Evaluates whether the current inactivity streak meets or exceeds the 30-day churn threshold (`'YES'` for dormant users like User 102).
