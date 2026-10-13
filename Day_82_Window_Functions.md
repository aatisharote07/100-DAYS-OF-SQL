# Day 82: SQL Challenge - Window Functions (User Sessionization)

## 📌 Business Scenario
A product analytics team at a streaming platform needs to analyze user engagement by tracking distinct "sessions." 

In clickstream and event analytics, a session is typically defined as a series of interactions with an **inactivity timeout**. If a user does not perform any activity for more than **30 minutes**, their next event is considered the start of a brand new session.

Raw event logs only record individual timestamped actions. To group these actions into meaningful sessions, we must detect gaps longer than 30 minutes and generate a distinct `session_id` for each grouping using a two-step window function technique.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create User Events Table
CREATE TABLE user_events (
    event_id INT PRIMARY KEY,
    user_id INT,
    event_time DATETIME,
    event_name VARCHAR(50)
);

-- Insert Sample Data
INSERT INTO user_events VALUES
(1, 101, '2026-10-13 10:00:00', 'login'),       -- Session 1 starts
(2, 101, '2026-10-13 10:15:00', 'view_item'),   -- 15m diff (Session 1)
(3, 101, '2026-10-13 10:25:00', 'add_to_cart'), -- 10m diff (Session 1)
(4, 101, '2026-10-13 11:10:00', 'view_item'),   -- 45m diff (>30m, Session 2 starts)
(5, 101, '2026-10-13 11:20:00', 'checkout'),    -- 10m diff (Session 2)
(6, 102, '2026-10-13 09:00:00', 'login'),       -- Session 1 starts for User 102
(7, 102, '2026-10-13 09:20:00', 'view_item');   -- 20m diff (Session 1)
```

---

## ❓ The Question
Write an SQL query to group the events into user sessions based on a 30-minute inactivity threshold. 

For each user, compute an incremental `session_number` starting at `1` for the first session and increasing by `1` every time an event occurs more than 30 minutes after the previous event.

Return `event_id`, `user_id`, `event_time`, `event_name`, and the calculated `session_number`. Order by `user_id` and `event_time`.

---

## 💡 The Solution

*(Note: Timestamp difference syntax varies by SQL dialect. The solution below uses standard MySQL syntax).*

```sql
WITH FlaggedEvents AS (
    -- Step 1: Compare current event to the prior event using LAG()
    -- Step 2: Flag the row as '1' if it starts a new session (gap > 30 mins or first event)
    SELECT 
        event_id,
        user_id,
        event_time,
        event_name,
        CASE 
            WHEN LAG(event_time) OVER (
                PARTITION BY user_id 
                ORDER BY event_time
            ) IS NULL THEN 1
            WHEN TIMESTAMPDIFF(MINUTE, 
                LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time), 
                event_time
            ) > 30 THEN 1
            ELSE 0 
        END AS is_new_session
    FROM user_events
)
-- Step 3: Run a cumulative SUM() over the flags to produce the session ID
SELECT 
    event_id,
    user_id,
    event_time,
    event_name,
    SUM(is_new_session) OVER (
        PARTITION BY user_id 
        ORDER BY event_time
    ) AS session_number
FROM FlaggedEvents
ORDER BY 
    user_id, 
    event_time;
```

*(For PostgreSQL: Replace `TIMESTAMPDIFF(MINUTE, prev, curr) > 30` with `EXTRACT(EPOCH FROM (event_time - prev_event_time)) / 60 > 30`)*
*(For SQL Server: Replace `TIMESTAMPDIFF(MINUTE, ...)` with `DATEDIFF(minute, prev_event_time, event_time) > 30`)*

---

## 📝 Explanation
Sessionization is a foundational pattern in event data engineering:
- **Step 1 (`LAG` & Identifying Boundaries)**: 
  - Using `LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time)`, we inspect the timestamp of the event right before the current one.
  - If there is no previous event (`IS NULL`), this is the user's very first interaction, so `is_new_session = 1`.
  - If the gap between the current timestamp and the previous timestamp exceeds 30 minutes, the session timed out, so `is_new_session = 1`.
  - If the gap is 30 minutes or less, the user is still active in the current session, so `is_new_session = 0`.
- **Step 2 (The Running Total Trick)**:
  - We compute `SUM(is_new_session) OVER (PARTITION BY user_id ORDER BY event_time)`.
  - Because regular events add `0`, the running total remains unchanged during active browsing.
  - The instant a new session begins, adding `1` bumps the running total from 1 to 2, effectively tagging all subsequent events in that session with `2`.
- **Final Result**:
  - Events 1, 2, and 3 for User 101 are tagged with `session_number = 1`.
  - Event 4 (which occurred 45 minutes after Event 3) bumps the count, tagging Events 4 and 5 with `session_number = 2`.
