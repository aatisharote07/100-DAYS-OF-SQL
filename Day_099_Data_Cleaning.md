# Day 99: SQL Challenge - Data Cleaning (Resolving Overlapping Validity Intervals & SCD Type 2)

## 📌 Business Scenario
A FinTech core banking platform manages customer risk profiles and tier assignments using **Slowly Changing Dimensions (SCD Type 2)**. 

Each customer record has a `valid_from` and `valid_to` date representing the timeframe during which a specific credit tier (`Gold`, `Platinum`, etc.) was active. 

Due to asynchronous event processing and concurrent update retries across microservices, dirty data was introduced into the system: some rows for the same customer contain **overlapping or adjacent date intervals with the exact same tier assignment**.

Before running historical risk assessments, the data engineering team must merge and collapse these contiguous or overlapping duplicate intervals into single, consolidated, unbroken date ranges.

This advanced variant of the **Gaps and Islands** problem is a classic data warehousing interview challenge.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Customer Tier History Table
CREATE TABLE customer_tier_history (
    record_id INT PRIMARY KEY,
    customer_id INT,
    tier VARCHAR(20),
    valid_from DATE,
    valid_to DATE
);

-- Insert Sample Data
-- Customer 101: 
-- Record 1 (Jan 1 to Jan 15) and Record 2 (Jan 10 to Jan 25) OVERLAP with 'Gold' -> Merge into [2026-01-01 to 2026-01-25]
-- Record 3 (Feb 01 to Feb 28) is a separate interval of 'Gold' -> Keep separate!
-- Record 4 (Mar 01 to Mar 31) switches to 'Platinum' -> Keep separate!
INSERT INTO customer_tier_history VALUES
(1, 101, 'Gold',     '2026-01-01', '2026-01-15'),
(2, 101, 'Gold',     '2026-01-10', '2026-01-25'), -- Overlaps with Record 1!
(3, 101, 'Gold',     '2026-02-01', '2026-02-28'), -- Gap between Jan 25 & Feb 01
(4, 101, 'Platinum', '2026-03-01', '2026-03-31'), -- Different tier
(5, 102, 'Silver',   '2026-01-01', '2026-01-20'),
(6, 102, 'Silver',   '2026-01-20', '2026-02-10'); -- Adjacent/touching (Jan 20) -> Merge into [2026-01-01 to 2026-02-10]
```

---

## ❓ The Question
Write an SQL query to consolidate and collapse all overlapping or contiguous validity intervals for each customer and tier.

If two or more records for the same `customer_id` and `tier` overlap (i.e., `next.valid_from <= current.valid_to`), or touch (adjacent), merge them into a single continuous window spanning from the earliest `valid_from` to the latest `valid_to`.

Return `customer_id`, `tier`, `merged_valid_from`, and `merged_valid_to`. Order by `customer_id ASC`, `merged_valid_from ASC`.

---

## 💡 The Solution

```sql
WITH TrackMaxPreviousEnd AS (
    -- Step 1: For each row, find the maximum valid_to seen so far among preceding rows
    SELECT 
        customer_id,
        tier,
        valid_from,
        valid_to,
        MAX(valid_to) OVER (
            PARTITION BY customer_id, tier 
            ORDER BY valid_from, valid_to 
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS max_prev_valid_to
    FROM customer_tier_history
),
IdentifyIslands AS (
    -- Step 2: Flag the start of a new independent island when valid_from is strictly after max_prev_valid_to
    SELECT 
        customer_id,
        tier,
        valid_from,
        valid_to,
        CASE 
            WHEN max_prev_valid_to IS NULL OR valid_from > max_prev_valid_to THEN 1 
            ELSE 0 
        END AS is_new_island
    FROM TrackMaxPreviousEnd
),
GroupIslands AS (
    -- Step 3: Run a cumulative sum over is_new_island to produce an island group ID
    SELECT 
        customer_id,
        tier,
        valid_from,
        valid_to,
        SUM(is_new_island) OVER (
            PARTITION BY customer_id, tier 
            ORDER BY valid_from, valid_to
        ) AS island_id
    FROM IdentifyIslands
)
-- Step 4: Aggregate each island to collapse the boundary
SELECT 
    customer_id,
    tier,
    MIN(valid_from) AS merged_valid_from,
    MAX(valid_to) AS merged_valid_to
FROM GroupIslands
GROUP BY 
    customer_id, 
    tier, 
    island_id
ORDER BY 
    customer_id ASC, 
    merged_valid_from ASC;
```

---

## 📝 Explanation

### The Anatomy of Merging Overlapping Intervals
Standard window comparisons like `LAG(valid_to)` fail when an interval spans across *multiple* subsequent rows. To handle arbitrary overlaps, we use the classic 4-step algorithm:

1. **`MAX() OVER (... ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)`**:
   - Rather than just looking at the single row immediately prior, this tracks the furthest `valid_to` date seen across **all previous intervals**.
   - For Record 2 (Jan 10 - Jan 25), `max_prev_valid_to` is `2026-01-15`.

2. **Flagging Island Starts (`is_new_island`)**:
   - If a row's `valid_from` is earlier than or equal to `max_prev_valid_to`, this row is submerged inside (or contiguous with) the active interval, so `is_new_island = 0`.
   - If `valid_from > max_prev_valid_to`, the previous streak broke, meaning a new interval begins (`is_new_island = 1`).
   - For Customer 101: Record 1 is `1`, Record 2 is `0`, Record 3 is `1` (new island after the gap), Record 4 is `1` (new tier partition).

3. **Cumulative Sum for Island Grouping**:
   - `SUM(is_new_island) OVER (...)` increments only when a new island starts. Records 1 and 2 both get assigned `island_id = 1`. Record 3 gets `island_id = 2`.

4. **Collapsing the Boundary**:
   - A final `GROUP BY customer_id, tier, island_id` extracts `MIN(valid_from)` and `MAX(valid_to)`, fusing the overlapping intervals into one clean range.
