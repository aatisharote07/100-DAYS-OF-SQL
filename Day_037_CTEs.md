# Day 37: SQL Challenge - CTEs (User Activity Sessionization)

## 📌 Business Scenario
A web analytics platform tracks user interactions (clicks, pageviews) as a stream of events. To analyze user behavior, product managers need to group these individual events into **sessions**. 

A single user session is defined as a series of events with no gap in activity larger than **30 minutes**. If a user is inactive for 30 minutes or more and then performs another action, that action marks the start of a **new session**.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create User Events Table
CREATE TABLE user_activity (
    event_id INT PRIMARY KEY,
    user_id INT,
    event_timestamp TIMESTAMP
);

-- Insert Sample Data
INSERT INTO user_activity (event_id, user_id, event_timestamp) VALUES
(1, 101, '2026-07-20 10:00:00'),
(2, 101, '2026-07-20 10:15:00'), -- 15 min gap (Same Session)
(3, 101, '2026-07-20 10:20:00'), -- 5 min gap (Same Session)
(4, 101, '2026-07-20 11:00:00'), -- 40 min gap (New Session!)
(5, 101, '2026-07-20 11:10:00'), -- 10 min gap (Same Session)
(6, 102, '2026-07-20 10:00:00'), -- User 102 Session 1
(7, 102, '2026-07-20 10:45:00'); -- 45 min gap (New Session!)
```

---

## ❓ The Question
Write an SQL query using Common Table Expressions (CTEs) to segment each user's event stream into distinct sessions. For each event, output the `user_id`, `event_timestamp`, and a calculated `session_id` in the format `user_id_session_num` (e.g., `101_1`, `101_2`). 

---

## 💡 The Solution

### MySQL Solution (using TIMESTAMPDIFF)
```sql
WITH LaggedEvents AS (
    -- Step 1: Fetch the previous event timestamp for each user
    SELECT 
        user_id,
        event_timestamp,
        LAG(event_timestamp, 1) OVER (
            PARTITION BY user_id 
            ORDER BY event_timestamp
        ) AS prev_timestamp
    FROM user_activity
),
SessionFlags AS (
    -- Step 2: Flag the start of a new session (1 if gap >= 30 mins or first event, else 0)
    SELECT 
        user_id,
        event_timestamp,
        CASE 
            WHEN prev_timestamp IS NULL THEN 1
            WHEN TIMESTAMPDIFF(MINUTE, prev_timestamp, event_timestamp) >= 30 THEN 1
            ELSE 0
        END AS is_new_session
    FROM LaggedEvents
),
SessionNumbers AS (
    -- Step 3: Compute running sum of flags to determine session numbers
    SELECT 
        user_id,
        event_timestamp,
        SUM(is_new_session) OVER (
            PARTITION BY user_id 
            ORDER BY event_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS session_num
    FROM SessionFlags
)
-- Step 4: Format the final session_id
SELECT 
    user_id,
    event_timestamp,
    CONCAT(user_id, '_', session_num) AS session_id
FROM SessionNumbers
ORDER BY user_id, event_timestamp;
```

### PostgreSQL Solution (using EXTRACT EPOCH)
```sql
WITH LaggedEvents AS (
    SELECT 
        user_id,
        event_timestamp,
        LAG(event_timestamp, 1) OVER (
            PARTITION BY user_id 
            ORDER BY event_timestamp
        ) AS prev_timestamp
    FROM user_activity
),
SessionFlags AS (
    SELECT 
        user_id,
        event_timestamp,
        CASE 
            WHEN prev_timestamp IS NULL THEN 1
            -- Subtract timestamps and check if epoch duration is >= 1800 seconds (30 mins)
            WHEN EXTRACT(EPOCH FROM (event_timestamp - prev_timestamp)) >= 1800 THEN 1
            ELSE 0
        END AS is_new_session
    FROM LaggedEvents
),
SessionNumbers AS (
    SELECT 
        user_id,
        event_timestamp,
        SUM(is_new_session) OVER (
            PARTITION BY user_id 
            ORDER BY event_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS session_num
    FROM SessionFlags
)
SELECT 
    user_id,
    event_timestamp,
    user_id || '_' || session_num AS session_id
FROM SessionNumbers
ORDER BY user_id, event_timestamp;
```

---

## 📝 Explanation
- **`LaggedEvents` CTE**: Uses the `LAG` window function partitioned by `user_id` and ordered by `event_timestamp` to pull the previous event's timestamp.
- **`SessionFlags` CTE**: Measures the inactivity gap. If the gap between the current and previous event is 30 minutes or more, or if there is no previous event (`prev_timestamp IS NULL`), it marks the row as a new session start (`is_new_session = 1`). Otherwise, it flags it as `0`.
- **`SessionNumbers` CTE**: Computes a cumulative running sum of the session start flags. Because `0` values don't increment the sum, the session number stays the same for events in the same session and increments by `1` only when a new session start is encountered.
- **Final Projection**: Combines the `user_id` and the generated session number to form a globally unique, readable `session_id`.
