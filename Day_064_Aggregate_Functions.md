# Day 64: SQL Challenge - Aggregate Functions (Calculating the True Median)

## 📌 Business Scenario
A regional real estate brokerage is preparing a market report on home prices across different neighborhoods. 

A junior analyst initially used the standard `AVG()` function to calculate the typical home price. However, in neighborhoods where 99% of homes sell for $300k but one massive mansion sells for $15 Million, the average is heavily skewed upwards, making the neighborhood look falsely unaffordable.

To get a true representation of the "middle" of the market, the lead analyst has asked you to calculate the **Median** (the 50th percentile) home price for each neighborhood.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Home Sales Table
CREATE TABLE home_sales (
    sale_id INT PRIMARY KEY,
    neighborhood VARCHAR(100),
    sale_price DECIMAL(12, 2)
);

-- Insert Sample Data
INSERT INTO home_sales VALUES
(1, 'Downtown', 300000),
(2, 'Downtown', 310000),
(3, 'Downtown', 320000),
(4, 'Downtown', 15000000), -- The Skewing Mansion!
(5, 'Suburbs', 400000),
(6, 'Suburbs', 410000),
(7, 'Suburbs', 420000),
(8, 'Suburbs', 430000);
```

---

## ❓ The Question
Write an SQL query to calculate both the average price and the median price for each neighborhood. 

Use the modern ordered-set aggregate function `PERCENTILE_CONT()` to find the exact 50th percentile. Return the `neighborhood`, the `median_price`, and the `average_price`. 

*Note: This specific syntax is supported in PostgreSQL, SQL Server, Oracle, and most modern cloud data warehouses (Snowflake, BigQuery). It is not supported in MySQL.*

---

## 💡 The Solution

```sql
SELECT 
    neighborhood,
    -- Calculate the Median (50th Percentile)
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sale_price) AS median_price,
    -- Calculate the traditional Mean (Average) for comparison
    ROUND(AVG(sale_price), 2) AS average_price
FROM home_sales
GROUP BY neighborhood;
```

---

## 📝 Explanation
- **The Problem with `AVG()`**: For the 'Downtown' neighborhood, the average is a massive `$3,982,500` due to that single $15M mansion. This is highly misleading for a prospective buyer.
- **`PERCENTILE_CONT(0.5)`**: This is an ordered-set aggregate function. The `0.5` signifies that we want the 50th percentile (the exact middle value).
- **`WITHIN GROUP (ORDER BY...)`**: Unlike standard aggregates, percentiles *require* the data to be sorted first so the engine can find the middle. This clause instructs the engine to sort the `sale_price` from lowest to highest specifically for this percentile calculation.
- **Continuous vs Discrete (`CONT` vs `DISC`)**: 
  - `PERCENTILE_CONT` (Continuous) will interpolate a value if the median falls between two rows. For example, in the 'Suburbs' (4 rows), the middle is between $410k and $420k. `PERCENTILE_CONT` mathematically averages them and returns `$415,000`.
  - `PERCENTILE_DISC` (Discrete) will not interpolate; it forces the engine to pick an exact existing row from the dataset (it would return `$410,000`).
- **The Result**: The median price for 'Downtown' correctly reports as `$315,000`, providing a vastly more accurate picture of the typical home price compared to the skewed $3.9M average!
