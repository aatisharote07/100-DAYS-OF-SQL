# Day 90: SQL Challenge - Joins & Window Functions (Funnel Analysis)

## 📌 Business Scenario
🎉 **Happy Day 90! Only 10 days to go!** 🎉

A product growth team at a SaaS company wants to understand where users drop off in their onboarding funnel. The funnel has 4 sequential stages:

1. **Sign Up** → 2. **Email Verified** → 3. **Profile Completed** → 4. **First Purchase**

The team needs a report that shows for each stage: the total number of users who reached it, the **drop-off count** from the previous stage, and the **conversion rate** (percentage of users who advanced from one stage to the next).

This requires combining a reference table of funnel stages with event data, using a `LEFT JOIN` to preserve stages even if zero users reached them, and applying `LAG()` to compare each stage against the one before it.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Funnel Stages Reference Table
CREATE TABLE funnel_stages (
    stage_order INT PRIMARY KEY,
    stage_name VARCHAR(50)
);

-- Create User Events Table
CREATE TABLE user_events (
    event_id INT PRIMARY KEY,
    user_id INT,
    stage_name VARCHAR(50),
    event_date DATE
);

-- Insert Funnel Stages (in order)
INSERT INTO funnel_stages VALUES
(1, 'Sign Up'),
(2, 'Email Verified'),
(3, 'Profile Completed'),
(4, 'First Purchase');

-- Insert Sample Data
-- 100 users signed up, 75 verified email, 40 completed profile, 18 purchased
INSERT INTO user_events VALUES
-- Representing aggregated counts via individual events for realism
(1,  1,  'Sign Up',           '2026-10-01'),
(2,  2,  'Sign Up',           '2026-10-01'),
(3,  3,  'Sign Up',           '2026-10-01'),
(4,  4,  'Sign Up',           '2026-10-02'),
(5,  5,  'Sign Up',           '2026-10-02'),
(6,  1,  'Email Verified',    '2026-10-01'),
(7,  2,  'Email Verified',    '2026-10-02'),
(8,  3,  'Email Verified',    '2026-10-03'),
(9,  4,  'Email Verified',    '2026-10-03'),
(10, 1,  'Profile Completed', '2026-10-02'),
(11, 3,  'Profile Completed', '2026-10-04'),
(12, 4,  'Profile Completed', '2026-10-05'),
(13, 1,  'First Purchase',    '2026-10-03'),
(14, 3,  'First Purchase',    '2026-10-06');
```

---

## ❓ The Question
Write an SQL query to build a complete funnel analysis report. For each stage, calculate:
- `users_at_stage`: The count of distinct users who reached that stage.
- `users_at_prev_stage`: The count from the previous stage (using `LAG()`).
- `drop_off`: How many users were lost between the previous stage and this one.
- `conversion_rate_pct`: The percentage of users from the previous stage who advanced to this one (rounded to 1 decimal place). For the first stage, this should be `100.0`.

Return `stage_order`, `stage_name`, `users_at_stage`, `drop_off`, and `conversion_rate_pct`. Order by `stage_order`.

---

## 💡 The Solution

```sql
WITH StageCounts AS (
    -- Step 1: Count distinct users per funnel stage
    SELECT 
        fs.stage_order,
        fs.stage_name,
        COUNT(DISTINCT ue.user_id) AS users_at_stage
    FROM funnel_stages fs
    LEFT JOIN user_events ue 
        ON fs.stage_name = ue.stage_name
    GROUP BY fs.stage_order, fs.stage_name
),
FunnelMetrics AS (
    -- Step 2: Use LAG() to bring in the previous stage's count
    SELECT 
        stage_order,
        stage_name,
        users_at_stage,
        LAG(users_at_stage) OVER (ORDER BY stage_order) AS users_at_prev_stage
    FROM StageCounts
)
-- Step 3: Calculate drop-off and conversion rate
SELECT 
    stage_order,
    stage_name,
    users_at_stage,
    COALESCE(users_at_prev_stage - users_at_stage, 0) AS drop_off,
    CASE 
        WHEN users_at_prev_stage IS NULL THEN 100.0
        WHEN users_at_prev_stage = 0 THEN 0.0
        ELSE ROUND(users_at_stage * 100.0 / users_at_prev_stage, 1)
    END AS conversion_rate_pct
FROM FunnelMetrics
ORDER BY stage_order;
```

---

## 📝 Explanation

### Building a Funnel Report Step-by-Step

- **Step 1 (Stage Counts with `LEFT JOIN`)**: 
  - We join the `funnel_stages` reference table to `user_events` using a `LEFT JOIN`. This ensures that even if zero users reached a particular stage, it still appears in the output with a count of `0`.
  - `COUNT(DISTINCT ue.user_id)` ensures a user who triggered the same event multiple times is only counted once per stage.

- **Step 2 (LAG for Previous Stage)**:
  - `LAG(users_at_stage) OVER (ORDER BY stage_order)` peeks at the row directly above (the prior funnel stage) and brings its user count into the current row.
  - For the first stage ("Sign Up"), there is no previous stage, so `LAG()` returns `NULL`.

- **Step 3 (Derived Metrics)**:
  - **Drop-off**: Simply `previous_count - current_count`. For Stage 1, `COALESCE` converts the `NULL` difference to `0` (no one dropped off before the funnel began).
  - **Conversion Rate**: `(current / previous) * 100`. The `CASE` statement handles edge cases:
    - Stage 1 gets a hardcoded `100.0%` (entry point).
    - A stage where the previous count is `0` safely returns `0.0%` instead of crashing on division by zero.

### Why Funnel Analysis Matters
Funnel analysis is the most critical report in product-led growth. In our example:
- **Sign Up → Email Verified**: 4/5 = **80%** (healthy)
- **Email Verified → Profile Completed**: 3/4 = **75%** (acceptable)
- **Profile Completed → First Purchase**: 2/3 = **66.7%** (biggest absolute drop — the team should investigate friction in the purchase flow)
