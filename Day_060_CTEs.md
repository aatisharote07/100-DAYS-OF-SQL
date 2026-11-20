# Day 60: SQL Challenge - CTEs (Finding the Longest Consecutive Streak)

## 📌 Business Scenario
🎉 **Happy Day 60!** 🎉

A fitness tracking app wants to gamify their user experience by awarding a badge to users for their dedication. The data science team needs to calculate the **Longest Consecutive Workout Streak** (in days) for every single user on the platform.

Because users might log multiple small workouts on the same day, or skip several days between workouts, finding continuous blocks of time requires an advanced SQL technique known as **"Gaps and Islands"** using Date Math.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Workouts Table
CREATE TABLE workouts (
    workout_id INT PRIMARY KEY,
    user_id INT,
    workout_date DATE
);

-- Insert Sample Data
INSERT INTO workouts VALUES
(1, 101, '2026-08-01'),
(2, 101, '2026-08-02'),
(3, 101, '2026-08-03'), -- User 101 Streak 1: 3 Days (Aug 1-3)
(4, 101, '2026-08-05'),
(5, 101, '2026-08-06'), -- User 101 Streak 2: 2 Days (Aug 5-6)
(6, 102, '2026-08-01'),
(7, 102, '2026-08-01'), -- User 102 worked out twice on Aug 1
(8, 102, '2026-08-02'); -- User 102 Streak 1: 2 Days (Aug 1-2)
```

---

## ❓ The Question
Write a query using multiple Common Table Expressions (CTEs) to find the maximum number of consecutive days each user has worked out. 

Account for the fact that a user might have multiple workout entries on the exact same date. Return `user_id` and `longest_streak`. Order by `longest_streak` in descending order.

---

## 💡 The Solution

```sql
WITH DistinctWorkouts AS (
    -- Step 1: Remove duplicate same-day workouts
    SELECT DISTINCT user_id, workout_date 
    FROM workouts
),
RankedDates AS (
    -- Step 2: Create a unique "Island" identifier using Date Math
    SELECT 
        user_id,
        workout_date,
        -- Subtract the chronological rank (number of days) from the actual date
        DATE_SUB(
            workout_date, 
            INTERVAL DENSE_RANK() OVER(PARTITION BY user_id ORDER BY workout_date) DAY
        ) AS island_group_date
    FROM DistinctWorkouts
),
StreakCounts AS (
    -- Step 3: Group by the Island identifier to count the length of each streak
    SELECT 
        user_id,
        island_group_date,
        COUNT(*) AS streak_length
    FROM RankedDates
    GROUP BY user_id, island_group_date
)
-- Step 4: Find the maximum streak length per user
SELECT 
    user_id,
    MAX(streak_length) AS longest_streak
FROM StreakCounts
GROUP BY user_id
ORDER BY longest_streak DESC;
```
*(Note: PostgreSQL users should replace `DATE_SUB(...)` with `workout_date - (DENSE_RANK() OVER(...) || ' days')::INTERVAL`)*

---

## 📝 Explanation
This is the most elegant way to solve Gaps and Islands for consecutive dates:
1. **`DistinctWorkouts`**: We first `SELECT DISTINCT` because if a user works out twice on Monday, it shouldn't artificially inflate their consecutive day streak to 2. It is still just a 1-day streak.
2. **The Magic Math (`RankedDates`)**: We rank the user's workout dates chronologically (1, 2, 3...). 
   - If they work out on Aug 1st (Rank 1), Aug 1 minus 1 day = **July 31**.
   - If they work out on Aug 2nd (Rank 2), Aug 2 minus 2 days = **July 31**.
   - If they work out on Aug 3rd (Rank 3), Aug 3 minus 3 days = **July 31**.
   - Because the dates and the ranks increment at the exact same pace, subtracting them yields a **constant anchor date** (July 31) for the entire consecutive streak (the "Island").
   - If they skip Aug 4th and work out on Aug 5th (Rank 4), Aug 5 minus 4 days = **Aug 1**. The anchor date changes, proving the streak was broken!
3. **`StreakCounts`**: Now we simply `GROUP BY` that anchor date (`island_group_date`) and count how many rows belong to it.
4. **Final Aggregation**: Finally, we `GROUP BY user_id` and take the `MAX(streak_length)` to find their personal best.
