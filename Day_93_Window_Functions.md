# Day 93: SQL Challenge - Window Functions (Top N Records Within Each Group)

## 📌 Business Scenario
A global streaming entertainment platform wants to feature the **Top 2 highest-streamed songs** for each music genre on its homepage browse section.

In production databases containing millions of songs, extracting the top $N$ items per partition or category is an essential, high-frequency SQL task. While a simple `ORDER BY streams DESC LIMIT 2` works across an entire table, extracting the top $N$ items *per distinct category* requires window ranking functions paired with subqueries or CTEs.

Furthermore, engineering teams must carefully decide between `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()` depending on how ties in stream counts should be handled.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Songs Table
CREATE TABLE songs (
    song_id INT PRIMARY KEY,
    title VARCHAR(100),
    genre VARCHAR(50),
    total_streams BIGINT
);

-- Insert Sample Data
INSERT INTO songs VALUES
(1,  'Blinding Nights', 'Pop',   450000000), -- Pop #1
(2,  'Levitating Star', 'Pop',   380000000), -- Pop #2
(3,  'Summer Groove',   'Pop',   310000000), -- Pop #3 (Excluded)
(4,  'Thunderstruck 2', 'Rock',  290000000), -- Rock #1
(5,  'Highway Echoes',  'Rock',  290000000), -- Rock #1 (Tie!)
(6,  'Neon Horizon',    'Rock',  180000000), -- Rock #3 (Excluded)
(7,  'Midnight Jazz',   'Jazz',  95000000),  -- Jazz #1
(8,  'Smooth Sax',      'Jazz',  88000000);  -- Jazz #2
```

---

## ❓ The Question
Write an SQL query to find the **Top 2 highest-streamed songs within each genre**. 

Use the `DENSE_RANK()` window function so that songs tying for the same stream count receive the same rank without skipping subsequent ranks. Break any display ordering ties with `song_id ASC`.

Return `genre`, `rank_in_genre`, `title`, and `total_streams`. Order the final results alphabetically by `genre`, then by `rank_in_genre ASC`, then by `song_id ASC`.

---

## 💡 The Solution

```sql
WITH RankedSongs AS (
    -- Step 1: Assign dense rank per genre based on total streams descending
    SELECT 
        song_id,
        title,
        genre,
        total_streams,
        DENSE_RANK() OVER (
            PARTITION BY genre 
            ORDER BY total_streams DESC
        ) AS rank_in_genre
    FROM songs
)
-- Step 2: Filter for the top 2 ranked songs per genre
SELECT 
    genre,
    rank_in_genre,
    title,
    total_streams
FROM RankedSongs
WHERE rank_in_genre <= 2
ORDER BY 
    genre ASC, 
    rank_in_genre ASC, 
    song_id ASC;
```

---

## 📝 Explanation

### The Anatomy of Partitioned Ranking
- **`PARTITION BY genre`**: Resets the ranking counter independently for each genre (`Pop`, `Rock`, `Jazz`). The highest-streamed song in `Rock` receives rank `1` regardless of stream volumes in `Pop`.
- **`ORDER BY total_streams DESC`**: Orders rows from largest stream volume to smallest within each partition before assigning ranks.
- **Why `DENSE_RANK()`?**:
  - `ROW_NUMBER()` arbitrarily picks a single winner when two songs tie (assigning 1 and 2).
  - `RANK()` assigns tied rows `1, 1` but skips rank 2, numbering the next row `3`. If you filter `WHERE rank <= 2`, it works, but if there's a tie at position 2 (`1, 2, 2`), `RANK()` assigns `1, 2, 2, 4`.
  - `DENSE_RANK()` assigns `1, 1` to ties and ensures the very next distinct stream count receives `2` without gaps, preserving natural leaderboard positions for promotional showcases.

### CTE Filter Requirement
In SQL's logical query processing order, window functions are computed *after* the `WHERE` clause. Therefore, writing `WHERE DENSE_RANK() OVER (...) <= 2` directly in the query is illegal. We must compute the ranking in a Common Table Expression (CTE) first and apply the threshold in the outer `SELECT`.
