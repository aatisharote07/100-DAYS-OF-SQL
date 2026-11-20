# Day 50: SQL Challenge - CTEs (Merging Overlapping Intervals)

## 📌 Business Scenario
🎉 **Happy Day 50! We are halfway through the 100 Days of SQL!** 🎉

For this milestone, we are tackling a classic, notoriously tricky SQL interview problem. 

A streaming platform wants to calculate the exact number of days a user was actively subscribed. However, a user might buy a promotional 1-month subscription while their yearly subscription is still active. 

If we simply sum the durations of all their subscriptions, we will double-count the overlapping days. To solve this, we must first **merge overlapping date intervals** into continuous blocks of time.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Subscriptions Table
CREATE TABLE subscriptions (
    sub_id INT PRIMARY KEY,
    user_id INT,
    start_date DATE,
    end_date DATE
);

-- Insert Sample Data
INSERT INTO subscriptions VALUES
(1, 101, '2026-01-01', '2026-01-31'), -- User 101: Sub 1
(2, 101, '2026-01-15', '2026-02-15'), -- User 101: Sub 2 (Overlaps with Sub 1!)
(3, 101, '2026-03-01', '2026-03-31'), -- User 101: Sub 3 (Distinct interval)
(4, 102, '2026-05-01', '2026-05-15'), -- User 102: Sub 1
(5, 102, '2026-05-16', '2026-05-31'); -- User 102: Sub 2 (Distinct, no overlap)
```

---

## ❓ The Question
Write a query using multiple Common Table Expressions (CTEs) to merge any overlapping subscription intervals for each user. 

For example, User 101's first two subscriptions (`Jan 1 to Jan 31` and `Jan 15 to Feb 15`) should be merged into a single interval (`Jan 1 to Feb 15`). 

Return `user_id`, `merged_start_date`, and `merged_end_date`. Order by `user_id` and `merged_start_date`.

---

## 💡 The Solution

```sql
WITH LaggedSubs AS (
    -- Step 1: Find the maximum end_date seen so far for each user
    SELECT 
        user_id,
        start_date,
        end_date,
        MAX(end_date) OVER (
            PARTITION BY user_id 
            ORDER BY start_date, end_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS max_prev_end
    FROM subscriptions
),
IntervalFlags AS (
    -- Step 2: Flag the row as '1' if it starts a completely new, non-overlapping interval
    SELECT 
        user_id,
        start_date,
        end_date,
        CASE 
            WHEN max_prev_end IS NULL OR start_date > max_prev_end THEN 1 
            ELSE 0 
        END AS is_new_interval
    FROM LaggedSubs
),
IntervalGroups AS (
    -- Step 3: Create a unique ID for each continuous block using a running sum
    SELECT 
        user_id,
        start_date,
        end_date,
        SUM(is_new_interval) OVER (
            PARTITION BY user_id 
            ORDER BY start_date, end_date
        ) AS interval_group_id
    FROM IntervalFlags
)
-- Step 4: Group by the new interval ID to compress the overlaps
SELECT 
    user_id,
    MIN(start_date) AS merged_start_date,
    MAX(end_date) AS merged_end_date
FROM IntervalGroups
GROUP BY user_id, interval_group_id
ORDER BY user_id, merged_start_date;
```

---

## 📝 Explanation
This problem is solved in four logical steps using a technique often called **"Gaps and Islands"**:
1. **`LaggedSubs`**: For every row, we look at all *previous* rows for that user (ordered by start date) and find the absolute maximum `end_date` among them. This tells us how far the previous subscriptions stretched into the future.
2. **`IntervalFlags`**: We compare the current row's `start_date` to that `max_prev_end`. If the current start date is *greater* than the furthest previous end date, it means there is a gap! We flag this row with a `1` as the start of a brand-new island (interval). If it overlaps, it gets a `0`.
3. **`IntervalGroups`**: By taking a running cumulative sum of those `1`s and `0`s, all overlapping rows get grouped into the exact same bucket (e.g., group `1`, group `2`). 
4. **Final Aggregation**: Finally, we just `GROUP BY` that bucket ID and take the `MIN(start_date)` and `MAX(end_date)` to establish the true, merged boundaries of that continuous time block. From here, calculating the total active days is as simple as summing `DATEDIFF(merged_end_date, merged_start_date)`.
