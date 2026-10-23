# Day 86: SQL Challenge - Aggregate Functions (Multi-Dimensional GROUPING SETS)

## 📌 Business Scenario
An omnichannel retail brand sells products across multiple marketing channels (`Online`, `In-Store`) and geographic regions (`North America`, `Europe`, `Asia`). 

The Head of Growth needs an executive dashboard widget that displays three specific cuts of revenue simultaneously:
1. Total revenue per **Sales Channel**
2. Total revenue per **Region**
3. The overall **Grand Total** across all sales

In legacy workflows, an analyst would write three separate queries and concatenate them using `UNION ALL`. However, this requires scanning the underlying fact table three times. 

Modern SQL provides the `GROUPING SETS` extension to calculate arbitrary multidimensional aggregations in a single, highly-optimized scan, paired with the `GROUPING()` function to identify and label aggregated rows.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Sales Table
CREATE TABLE channel_sales (
    sale_id INT PRIMARY KEY,
    sales_channel VARCHAR(50),
    region VARCHAR(50),
    revenue DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO channel_sales VALUES
(1, 'Online',   'North America', 1200.00),
(2, 'Online',   'Europe',         850.00),
(3, 'Online',   'Asia',           650.00),
(4, 'In-Store', 'North America', 1500.00),
(5, 'In-Store', 'Europe',         950.00),
(6, 'In-Store', 'Asia',           400.00);
```

---

## ❓ The Question
Write a single SQL query using `GROUP BY GROUPING SETS` to aggregate `revenue` across three distinct grouping sets:
1. By `sales_channel`
2. By `region`
3. The overall Grand Total (`()`)

Use the `GROUPING()` function to safely label the aggregated dimensions:
- If `sales_channel` is aggregated out, label it `'ALL CHANNELS'`.
- If `region` is aggregated out, label it `'ALL REGIONS'`.

Return `sales_channel`, `region`, and `total_revenue`. Order the results so that Channel summaries appear first, followed by Region summaries, and the Grand Total appears last.

---

## 💡 The Solution

```sql
SELECT 
    CASE 
        WHEN GROUPING(sales_channel) = 1 THEN 'ALL CHANNELS' 
        ELSE sales_channel 
    END AS sales_channel,
    
    CASE 
        WHEN GROUPING(region) = 1 THEN 'ALL REGIONS' 
        ELSE region 
    END AS region,
    
    SUM(revenue) AS total_revenue
FROM channel_sales
-- Specify only the exact dimensional cuts required
GROUP BY GROUPING SETS (
    (sales_channel),
    (region),
    ()
)
ORDER BY 
    GROUPING(sales_channel),
    GROUPING(region),
    sales_channel,
    region;
```

---

## 📝 Explanation

### Why `GROUPING SETS` Beats `UNION ALL` & `CUBE`
- **Vs `UNION ALL`**: Writing three separate queries with `UNION ALL` scans the `channel_sales` table three times. `GROUPING SETS` allows the database engine to perform a single scan and compute the partial aggregates in memory.
- **Vs `CUBE` and `ROLLUP`**: 
  - `CUBE(sales_channel, region)` would compute all $2^2 = 4$ combinations, including the intersection `(sales_channel, region)`. If the business doesn't need that granular slice, `CUBE` wastes CPU cycles.
  - `ROLLUP` enforces a strict hierarchy (`(A, B) -> (A) -> ()`). It cannot compute `(sales_channel)` and `(region)` independently without also generating the cross-product.
  - `GROUPING SETS` allows you to cherry-pick the exact groupings needed.

### The Power of the `GROUPING()` Function
When an engine aggregates across a dimension, it sets the grouped-out column's value to `NULL`. 

A common pitfall is using `COALESCE(region, 'ALL REGIONS')`. If the underlying data table already contains natural `NULL` values (e.g., an unassigned region), `COALESCE` will mistakenly label a real missing value as `'ALL REGIONS'`.

The ANSI standard `GROUPING(column_name)` function solves this:
- Returns `1` if the column was aggregated out by the grouping set.
- Returns `0` if the value (even a `NULL`) comes from the underlying data row.
- Combining `GROUPING()` with `CASE WHEN` ensures 100% data integrity in reporting dashboards.
