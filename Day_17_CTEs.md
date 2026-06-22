# Day 17: SQL Challenge - CTEs (Cohort Retention Analytics)

## 📌 Business Scenario
A product growth team wants to measure user retention. Specifically, they want to track the **Month-1 Retention Rate** for all users. A user is defined as "retained in Month 1" if they perform at least one activity between **30 and 60 days (inclusive)** after their sign-up date. 

To report this to the executive team, we need to build a clean multi-stage aggregation using CTEs.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Users Table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(100),
    signup_date DATE
);

-- Create Activity Log Table
CREATE TABLE activity_log (
    activity_id INT PRIMARY KEY,
    user_id INT,
    activity_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Insert Sample Data
INSERT INTO users (user_id, user_name, signup_date) VALUES
(1, 'Alice', '2026-01-05'),
(2, 'Bob', '2026-01-10'),
(3, 'Charlie', '2026-02-15'),
(4, 'David', '2026-02-20'),
(5, 'Emily', '2026-03-01');

INSERT INTO activity_log (activity_id, user_id, activity_date) VALUES
(101, 1, '2026-01-06'), -- Alice: Day 1 activity
(102, 1, '2026-02-10'), -- Alice: Day 36 activity (Retained!)
(103, 2, '2026-01-12'), -- Bob: Day 2 activity
-- Bob has no Month 1 activity
(104, 3, '2026-03-20'), -- Charlie: Day 33 activity (Retained!)
(105, 4, '2026-02-25'), -- David: Day 5 activity
(106, 4, '2026-04-10'), -- David: Day 49 activity (Retained!)
(107, 5, '2026-03-15'); -- Emily: Day 14 activity
```

---

## ❓ The Question
Write an SQL query using multiple Common Table Expressions (CTEs) to find:
1. The total number of unique users who signed up (`total_signups`).
2. The total number of unique users who returned and performed an activity in their Month 1 window (30 to 60 days inclusive after their `signup_date`).
3. The resulting Month 1 retention rate percentage (`month_1_retention_pct`), rounded to 2 decimal places.

---

## 💡 The Solution

```sql
WITH SignupCohort AS (
    -- Step 1: Isolate the signup cohort
    SELECT user_id, signup_date
    FROM users
),
Month1ActiveUsers AS (
    -- Step 2: Identify users active in the Month 1 window (30-60 days)
    SELECT DISTINCT c.user_id
    FROM SignupCohort c
    JOIN activity_log a ON c.user_id = a.user_id
    WHERE DATEDIFF(a.activity_date, c.signup_date) BETWEEN 30 AND 60
),
CohortMetrics AS (
    -- Step 3: Count the sizes of both cohorts
    SELECT 
        (SELECT COUNT(*) FROM SignupCohort) AS total_signups,
        (SELECT COUNT(*) FROM Month1ActiveUsers) AS retained_users
)
SELECT 
    total_signups,
    retained_users,
    ROUND(retained_users * 100.0 / NULLIF(total_signups, 0), 2) AS month_1_retention_pct
FROM CohortMetrics;
```

---

## 📝 Explanation
- **`SignupCohort` CTE**: Sets up the base list of users in our study.
- **`Month1ActiveUsers` CTE**: Joins the signup cohort to the activity log. The `DATEDIFF` function computes the elapsed days between sign-up and activity. Filtering for `BETWEEN 30 AND 60` isolates Month 1 interactions. We use `DISTINCT c.user_id` so that users active multiple times in this window are counted only once.
- **`CohortMetrics` CTE**: Selects scalar count subqueries to bundle both metric points together on a single row.
- **Final Query**: Divides the number of retained users by total signups and multiplies by `100.0` to calculate the percentage. `NULLIF(total_signups, 0)` is used to safeguard the mathematical division against zero-division errors.
