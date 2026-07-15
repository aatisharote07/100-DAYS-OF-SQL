# Day 34: SQL Challenge - Aggregate Functions (Calculating Median Order Value)

## 📌 Business Scenario
A retail finance team wants to analyze customer order sizes. While the average (mean) order value is simple to calculate, it can be heavily skewed by a few extremely large orders (outliers). 

To understand the typical order size, the team needs to calculate the **median order value**. Because SQL does not contain a standard, universal `MEDIAN()` function across all database engines (MySQL and SQL Server lack it, and PostgreSQL uses custom syntax), we must write a portable, arithmetic solution.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_amount DECIMAL(10, 2)
);

-- Insert Sample Data (Odd count of records: 5 rows)
INSERT INTO orders (order_id, order_amount) VALUES
(1, 10.00),
(2, 20.00),
(3, 50.00),  -- The Median Value
(4, 100.00),
(5, 500.00);
```

---

## ❓ The Question
Write a portable SQL query to calculate the median `order_amount` from the `orders` table. Your solution must handle both odd and even counts of records and must not rely on proprietary single-command `MEDIAN()` functions.

---

## 💡 The Solution

```sql
WITH SortedOrders AS (
    SELECT 
        order_amount,
        -- Rank rows by order amount ascending
        ROW_NUMBER() OVER (ORDER BY order_amount) AS row_num,
        -- Fetch the total count of rows across the entire table
        COUNT(*) OVER () AS total_count
    FROM orders
)
SELECT 
    AVG(order_amount) AS median_order_amount
FROM SortedOrders
WHERE row_num IN (
    FLOOR((total_count + 1) / 2), 
    CEIL((total_count + 1) / 2)
);
```

---

## 📝 Explanation
- **`SortedOrders` CTE**: This CTE sorts the dataset by `order_amount` and assigns a sequential index (`row_num`). Simultaneously, it counts the total number of rows in the table (`total_count`) using `COUNT(*) OVER ()`.
- **Finding the Middle Row(s)**: The median is either the single middle value (for odd row counts) or the average of the two middle values (for even row counts).
- **Index Math (`FLOOR` and `CEIL`)**:
  - **Odd Count Case (e.g., `total_count = 5`)**: The calculation `(5 + 1) / 2 = 3`. Both `FLOOR(3)` and `CEIL(3)` return `3`. The query filters `WHERE row_num IN (3, 3)`, selecting the single middle row ($50.00).
  - **Even Count Case (e.g., `total_count = 6`)**: The calculation `(6 + 1) / 2 = 3.5`. `FLOOR(3.5)` returns `3`, and `CEIL(3.5)` returns `4`. The query filters `WHERE row_num IN (3, 4)`, selecting the two middle rows.
- **Calculating the Result (`AVG`)**: The main query runs `AVG(order_amount)` over the filtered rows. For odd counts, the average of a single row is that row itself. For even counts, it calculates the mean of the two middle values, returning the correct median.
