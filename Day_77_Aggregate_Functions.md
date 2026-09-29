# Day 77: SQL Challenge - Aggregate Functions (Anomaly Detection & Z-Scores)

## 📌 Business Scenario
A Quality Control manager at a manufacturing plant is analyzing the weights of a recent batch of mechanical gears. The gears are supposed to weigh exactly 500 grams, but slight manufacturing variances are normal.

To detect true anomalies (defective gears that are dangerously heavy or light), the manager wants to flag any gear whose weight falls more than **2 Standard Deviations** away from the average weight of the batch. This is a classic statistical technique known as calculating a **Z-Score**.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Gear Weights Table
CREATE TABLE gear_weights (
    gear_id INT PRIMARY KEY,
    weight_grams DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO gear_weights VALUES
(1, 501.20),
(2, 499.50),
(3, 500.80),
(4, 502.10),
(5, 498.90),
(6, 450.00), -- Defect! Way too light
(7, 560.00); -- Defect! Way too heavy
```

---

## ❓ The Question
Write an SQL query to calculate the Z-Score for every gear, and filter the results to strictly show the anomalies (gears with a Z-Score greater than `2` or less than `-2`).

The formula for a Z-Score is: `(Value - Mean) / Standard_Deviation`.

Use a Common Table Expression (CTE) and the `STDDEV()` (or `STDEV()`) aggregate function to find the batch's overall mean and standard deviation. Then, `CROSS JOIN` those stats to the main table to calculate the Z-Score. 

Return `gear_id`, `weight_grams`, and `z_score` (rounded to 2 decimal places). Order by the absolute value of the Z-Score descending (most anomalous first).

---

## 💡 The Solution

```sql
WITH BatchStats AS (
    -- Step 1: Calculate the Mean and Standard Deviation for the entire batch
    SELECT 
        AVG(weight_grams) AS mean_weight,
        STDDEV(weight_grams) AS std_weight -- Note: SQL Server uses STDEV()
    FROM gear_weights
)
SELECT 
    g.gear_id,
    g.weight_grams,
    -- Step 3: Apply the Z-Score formula: (Value - Mean) / Standard_Deviation
    ROUND((g.weight_grams - s.mean_weight) / s.std_weight, 2) AS z_score
FROM gear_weights g
-- Step 2: Cross Join the single row of stats back to every individual gear
CROSS JOIN BatchStats s
-- Step 4: Filter for anomalies (> 2 or < -2 standard deviations)
WHERE ABS((g.weight_grams - s.mean_weight) / s.std_weight) > 2
ORDER BY ABS((g.weight_grams - s.mean_weight) / s.std_weight) DESC;
```

---

## 📝 Explanation
- **What is a Z-Score?**: A Z-Score tells you exactly how many standard deviations a data point is from the average. A Z-Score of `0` means the gear is exactly average. A Z-Score of `3` means it is exceptionally heavy. A Z-Score of `-3` means it is exceptionally light. In a normal distribution, 95% of all data falls between `-2` and `2`. Anything outside of that is a statistical anomaly.
- **The CTE (`BatchStats`)**: Because we need the average and standard deviation of the *entire* table to be applied to *individual* rows, we calculate them first in a CTE. This CTE returns exactly 1 row.
- **`CROSS JOIN`**: By crossing joining the main table to that single-row CTE, we effectively append the `mean_weight` and `std_weight` as columns to every single gear row, allowing us to perform row-level mathematical calculations. (You could also use Window Functions to achieve this without a join: `AVG(weight_grams) OVER()`).
- **`ABS()`**: The absolute value function `ABS()` is a convenient way to check for both positive and negative anomalies simultaneously without writing `z_score > 2 OR z_score < -2`.
