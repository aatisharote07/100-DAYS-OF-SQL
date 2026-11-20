# Day 72: SQL Challenge - CTEs (Finding Consecutive Available Items)

## 📌 Business Scenario
A cinema chain is upgrading its online ticketing system. They want to introduce a feature that automatically suggests seating blocks for families. To do this, the database must scan a row of seats and identify if there are **3 or more consecutive empty seats**.

This is a famous "Gaps and Islands" variation. Instead of just finding the length of the streak, we must return the exact `seat_id`s that make up those consecutive blocks.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Cinema Seats Table
CREATE TABLE cinema_seats (
    seat_id INT PRIMARY KEY,
    is_empty BOOLEAN
);

-- Insert Sample Data (1 = Empty, 0 = Occupied)
INSERT INTO cinema_seats VALUES
(1, TRUE),
(2, FALSE),
(3, TRUE),
(4, TRUE),
(5, TRUE),   -- Block 1: Seats 3, 4, 5 (3 consecutive)
(6, FALSE),
(7, TRUE),
(8, TRUE),
(9, TRUE),
(10, TRUE);  -- Block 2: Seats 7, 8, 9, 10 (4 consecutive)
```

---

## ❓ The Question
Write an SQL query using Common Table Expressions (CTEs) and Window Functions to find all `seat_id`s that are part of a block of 3 or more consecutive empty seats. 

Return the `seat_id` and order the results in ascending order. (Your result should include seats 3, 4, 5, 7, 8, 9, and 10).

---

## 💡 The Solution

```sql
WITH AvailableSeats AS (
    -- Step 1: Filter to only look at empty seats
    SELECT seat_id
    FROM cinema_seats
    WHERE is_empty = TRUE
),
GroupedSeats AS (
    -- Step 2: Gaps and Islands Math! 
    -- Subtract chronological rank from seat_id to form unique groups
    SELECT 
        seat_id,
        seat_id - ROW_NUMBER() OVER (ORDER BY seat_id) AS island_group
    FROM AvailableSeats
),
CountedGroups AS (
    -- Step 3: Count how many seats belong to each island group
    SELECT 
        seat_id,
        COUNT(*) OVER (PARTITION BY island_group) AS consecutive_count
    FROM GroupedSeats
)
-- Step 4: Filter for groups that have 3 or more seats
SELECT seat_id
FROM CountedGroups
WHERE consecutive_count >= 3
ORDER BY seat_id;
```

---

## 📝 Explanation
- **Step 1 (`AvailableSeats`)**: We aggressively filter out occupied seats. We only want to run our window math on the empty ones.
- **Step 2 (The Gaps & Islands Math)**: This is the core trick. We assign a `ROW_NUMBER()` to the available seats (1, 2, 3, 4...). We then subtract that row number from the actual `seat_id`. 
  - Seat 3 is the 2nd empty seat overall. `3 - 2 = 1`.
  - Seat 4 is the 3rd empty seat overall. `4 - 3 = 1`.
  - Seat 5 is the 4th empty seat overall. `5 - 4 = 1`.
  - Because the consecutive `seat_id`s and the `ROW_NUMBER`s increase at the exact same pace, subtracting them yields a constant number (`1`) for that entire consecutive block! If there is a gap (like occupied Seat 6), the math resets to a new constant number.
- **Step 3 (`COUNT(*) OVER`)**: We use a window function to count how many seats belong to each `island_group`. Unlike a traditional `GROUP BY` (which would compress the rows), the window function appends that count directly to every single seat row.
- **Step 4**: We finally filter the results to only keep the `seat_id`s where their calculated block count is `>= 3`.
