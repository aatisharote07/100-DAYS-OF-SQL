# Day 69: SQL Challenge - Window Functions (Calculating Time Between Events)

## 📌 Business Scenario
A cybersecurity team is monitoring application logs for potential brute-force attacks. A brute-force attack often involves rapid, consecutive failed login attempts on the same account. 

To build an alert system, the team needs a query that calculates the exact **time elapsed (in minutes) between consecutive failed login attempts** for each user. This requires looking backward in time to compare the current row's timestamp against the previous row's timestamp.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Login Attempts Table
CREATE TABLE login_attempts (
    attempt_id INT PRIMARY KEY,
    user_id INT,
    attempt_timestamp DATETIME,
    status VARCHAR(20)
);

-- Insert Sample Data
INSERT INTO login_attempts VALUES
(1, 101, '2026-09-10 08:00:00', 'FAILED'),
(2, 101, '2026-09-10 08:02:00', 'FAILED'), -- 2 mins since last fail
(3, 101, '2026-09-10 08:15:00', 'SUCCESS'),
(4, 101, '2026-09-10 09:00:00', 'FAILED'), -- 58 mins since last fail
(5, 102, '2026-09-10 10:00:00', 'FAILED');
```

---

## ❓ The Question
Write an SQL query to calculate the minutes elapsed between a user's failed login attempt and their strictly preceding failed login attempt. Ignore 'SUCCESS' attempts entirely.

Return the `user_id`, the current `attempt_timestamp`, the `previous_attempt_time`, and the `minutes_since_last_fail`. If it's a user's first failed attempt, the previous time and minutes elapsed should be `NULL`. Order by `user_id` and `attempt_timestamp`.

---

## 💡 The Solution

*(Note: Date/Time arithmetic functions vary by dialect. Below uses standard MySQL syntax).*

```sql
WITH FailedLogins AS (
    -- Step 1: Filter out successes and grab the previous failure's timestamp
    SELECT 
        user_id,
        attempt_timestamp,
        LAG(attempt_timestamp) OVER (
            PARTITION BY user_id 
            ORDER BY attempt_timestamp
        ) AS previous_attempt_time
    FROM login_attempts
    WHERE status = 'FAILED'
)
-- Step 2: Calculate the difference between the two timestamps
SELECT 
    user_id,
    attempt_timestamp,
    previous_attempt_time,
    TIMESTAMPDIFF(MINUTE, previous_attempt_time, attempt_timestamp) AS minutes_since_last_fail
FROM FailedLogins
ORDER BY user_id, attempt_timestamp;
```

*(For PostgreSQL: Replace `TIMESTAMPDIFF(...)` with `EXTRACT(EPOCH FROM (attempt_timestamp - previous_attempt_time))/60`)*
*(For SQL Server: Replace `TIMESTAMPDIFF(...)` with `DATEDIFF(minute, previous_attempt_time, attempt_timestamp)`)*

---

## 📝 Explanation
- **Filtering First**: The CTE filters `WHERE status = 'FAILED'` *before* applying the window function. This is critical. If we applied `LAG()` without filtering, the previous row might be a successful login, which breaks the business logic of finding time between *failures*.
- **`LAG()`**: We partition by `user_id` so we don't accidentally compare Alice's login against Bob's login. We order chronologically to fetch the most recent timestamp exactly 1 row prior.
- **Time Arithmetic**: Because timestamps are not simple integers, you cannot just use a minus sign `-` in most SQL dialects (Postgres is an exception). You must use dedicated functions like `TIMESTAMPDIFF()` (MySQL) or `DATEDIFF()` (SQL Server) to accurately calculate the boundary crossing of minutes, hours, or days between two datetime objects.
