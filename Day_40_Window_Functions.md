# Day 40: SQL Challenge - Window Functions (CUME_DIST / Percentile Rankings)

## 📌 Business Scenario
A gaming platform wants to launch a championship tournament. To keep it competitive, they want to invite only the **top 15% of players** from each game title based on their highest score. 

Rather than choosing an arbitrary cutoff score, we need to calculate the relative percentile rank of each player within their specific game partition. The window function `CUME_DIST` (Cumulative Distribution) is ideal for this type of cohort analysis.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Player Scores Table
CREATE TABLE player_scores (
    player_id INT PRIMARY KEY,
    player_name VARCHAR(100),
    game_title VARCHAR(50),
    high_score INT
);

-- Insert Sample Data
INSERT INTO player_scores (player_id, player_name, game_title, high_score) VALUES
(1, 'Alice', 'Chess', 1800),
(2, 'Bob', 'Chess', 1600),
(3, 'Charlie', 'Chess', 1400),
(4, 'David', 'Chess', 2100),  -- Top score for Chess
(5, 'Emily', 'Chess', 1950),  -- 2nd Chess (Top 40%)
(6, 'Frank', 'Chess', 1200),
(7, 'Grace', 'Chess', 1500),
(8, 'Hannah', 'Speedrun', 320), -- Top score for Speedrun
(9, 'Ian', 'Speedrun', 280),
(10, 'Julia', 'Speedrun', 250),
(11, 'Kevin', 'Speedrun', 190);
```

---

## ❓ The Question
Write an SQL query to calculate the relative percentile rank of each player within their game title using `CUME_DIST`. Invite only players who rank in the top 15% of their respective game titles (i.e. those with a cumulative distribution value less than or equal to `0.15` when ordered by score descending). 

Return `game_title`, `player_name`, `high_score`, and the calculated `percentile_rank` (rounded to 4 decimal places).

---

## 💡 The Solution

```sql
WITH RankedScores AS (
    SELECT 
        game_title,
        player_name,
        high_score,
        -- Calculate the cumulative distribution of scores within each game
        CUME_DIST() OVER (
            PARTITION BY game_title 
            ORDER BY high_score DESC
        ) AS percentile_rank
    FROM player_scores
)
SELECT 
    game_title,
    player_name,
    high_score,
    ROUND(percentile_rank, 4) AS percentile_rank
FROM RankedScores
WHERE percentile_rank <= 0.15
ORDER BY game_title, high_score DESC;
```

---

## 📝 Explanation
- **`CUME_DIST()` Window Function**: `CUME_DIST` computes the cumulative distribution of a value within a partitioned set. The returned values range from `0` to `1` (exclusive of 0).
  - With `ORDER BY high_score DESC`, the player with the highest score in a group is evaluated first.
  - The formula used is: `CUME_DIST() = (number of rows with values >= current row value) / (total number of rows in partition)`.
- **Chess Example**: There are 7 players in the "Chess" partition. 
  - `David` has the highest score (2100). The number of rows with scores >= 2100 is 1. Thus, `CUME_DIST` = `1 / 7` ≈ `0.1429` (14.29%). Since `0.1429 <= 0.15`, David qualifies!
  - `Emily` has the next highest score (1950). The number of rows with scores >= 1950 is 2. Thus, `CUME_DIST` = `2 / 7` ≈ `0.2857` (28.57%). Emily misses the top 15% cutoff.
- **Filtering**: The outer query uses the CTE output to filter where `percentile_rank <= 0.15`, isolating only the players who represent the top 15% of scores for each game title.
