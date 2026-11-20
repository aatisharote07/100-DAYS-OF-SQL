# Day 27: SQL Challenge - Window Functions (7-Day Moving Average)

## 📌 Business Scenario
A product analytics team monitors Daily Active Users (DAU) for a web application. Because daily user counts fluctuate heavily (typically spiking on weekends and dropping mid-week), the raw numbers are noisy. 

To visualize the true growth trend, the team wants to calculate a **7-day moving average** of DAU. This moving average for any given date should average the active user counts from the current date and the **6 days preceding it**.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Daily Active Users Table
CREATE TABLE daily_active_users (
    activity_date DATE PRIMARY KEY,
    active_users INT
);

-- Insert Sample Data (10 consecutive days)
INSERT INTO daily_active_users (activity_date, active_users) VALUES
('2026-07-01', 1000),
('2026-07-02', 1050),
('2026-07-03', 1100),
('2026-07-04', 1500), -- Weekend Spike (Saturday)
('2026-07-05', 1450), -- Weekend Spike (Sunday)
('2026-07-06', 950),
('2026-07-07', 1000),
('2026-07-08', 1020),
('2026-07-09', 1050),
('2026-07-10', 1080);
```

---

## ❓ The Question
Write an SQL query to retrieve the Daily Active Users (DAU) timeline. For each date, display the `activity_date`, the daily `active_users` count, and the `moving_avg_7day` (rounded to 2 decimal places). The moving average must be calculated over a sliding window including the current date and the 6 preceding days.

---

## 💡 The Solution

```sql
SELECT 
    activity_date,
    active_users,
    ROUND(
        AVG(active_users) OVER (
            ORDER BY activity_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_7day
FROM daily_active_users
ORDER BY activity_date;
```

---

## 📝 Explanation
- **`AVG()` as a Window Function**: Applying `AVG(active_users) OVER (...)` allows us to calculate moving averages for each row without grouping or collapsing our timeline into a single row.
- **Window Frame Definition**: The clause `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` instructs the database engine to define the window frame. For any given row, it aggregates the current active users count along with the counts of the 6 chronological rows preceding it.
- **Handling the Edge Case (Start of Series)**: During the first 6 days of the dataset, there are not enough preceding rows to fill a 7-day window. In standard SQL, the engine gracefully handles this by averaging whatever records *are* available within the specified window range (e.g., on July 2, it averages July 1 and July 2).
