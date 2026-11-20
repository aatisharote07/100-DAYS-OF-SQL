# Day 39: SQL Challenge - Joins (Interval Overlaps / Self Join)

## 📌 Business Scenario
A hotel operations team is auditing booking records. Due to a legacy system glitch, some guests were accidentally double-booked into the same room. 

The operations team needs a query that identifies all **overlapping booking intervals** for the same room. This is a classic data integrity check that requires joining a table to itself and evaluating date range inequalities.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Bookings Table
CREATE TABLE bookings (
    booking_id INT PRIMARY KEY,
    room_number INT,
    guest_name VARCHAR(100),
    start_date DATE,
    end_date DATE
);

-- Insert Sample Data
INSERT INTO bookings (booking_id, room_number, guest_name, start_date, end_date) VALUES
(1, 101, 'Alice Smith', '2026-07-10', '2026-07-15'),
(2, 101, 'Bob Jones', '2026-07-12', '2026-07-18'),    -- Overlaps with Alice!
(3, 101, 'Charlie Brown', '2026-07-20', '2026-07-25'), -- Normal
(4, 102, 'David Green', '2026-07-10', '2026-07-12'),
(5, 102, 'Emma White', '2026-07-12', '2026-07-15'),   -- Consecutive (Starts on same day David leaves - allowed!)
(6, 102, 'Frank Black', '2026-07-13', '2026-07-14');  -- Overlaps with Emma!
```

---

## ❓ The Question
Write an SQL query to identify all pairs of bookings for the same room that overlap in time. Assume checkout time is in the morning and check-in time is in the afternoon, meaning consecutive dates (e.g., booking ends on the 12th and the next starts on the 12th) do **not** overlap. 

For each overlap, return the room number, both booking IDs, both guest names, and the overlapping start/end dates. Avoid returning duplicate pairs (e.g. if A overlaps with B, do not return both (A, B) and (B, A)).

---

## 💡 The Solution

```sql
SELECT 
    b1.room_number,
    b1.booking_id AS booking_id_1,
    b1.guest_name AS guest_1,
    b1.start_date AS start_date_1,
    b1.end_date AS end_date_1,
    b2.booking_id AS booking_id_2,
    b2.guest_name AS guest_2,
    b2.start_date AS start_date_2,
    b2.end_date AS end_date_2
FROM bookings b1
JOIN bookings b2 ON b1.room_number = b2.room_number
                -- Avoid joining a booking to itself
                AND b1.booking_id < b2.booking_id 
                -- Interval overlap condition
                AND b1.start_date < b2.end_date 
                AND b1.end_date > b2.start_date
ORDER BY b1.room_number, b1.start_date;
```

---

## 📝 Explanation
- **Self Join**: The query joins the `bookings` table to itself (`b1` and `b2`) matching on `room_number`.
- **Deduplication (`b1.booking_id < b2.booking_id`)**: Using the strictly less than operator `<` serves a dual purpose: it prevents a booking from joining with itself, and it ensures that if booking `1` and booking `2` overlap, they are returned exactly once as `(1, 2)` and not also as `(2, 1)`.
- **Overlap Logic (`start_1 < end_2 AND end_1 > start_2`)**: Two date ranges overlap if and only if the start date of the first range is strictly before the end date of the second range, AND the end date of the first range is strictly after the start date of the second range. 
  - Consecutive bookings (like `David` ending on the 12th and `Emma` starting on the 12th) do not satisfy `12 < 12`, ensuring they are correctly allowed by the query.
