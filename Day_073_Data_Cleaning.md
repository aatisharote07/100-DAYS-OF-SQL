# Day 73: SQL Challenge - Data Cleaning (Preventing Divide-by-Zero Errors)

## 📌 Business Scenario
A data engineering team has set up an automated nightly pipeline that calculates the **Average Revenue Per Unit (ARPU)** for a retail company's daily sales. The formula is simply `revenue / units_sold`.

However, last night, the pipeline completely crashed. A transaction was recorded where `units_sold` was accidentally entered as `0`. This triggered a fatal **Divide-by-Zero** error in the SQL engine. 

The team needs a robust query that performs this division but safely handles any `0` values without crashing the entire report.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Sales Table
CREATE TABLE daily_sales (
    sale_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    revenue DECIMAL(10, 2),
    units_sold INT
);

-- Insert Sample Data
INSERT INTO daily_sales VALUES
(1, 'Laptop', 2000.00, 2),    -- ARPU: $1000
(2, 'Mouse', 50.00, 1),       -- ARPU: $50
(3, 'Monitor', 300.00, 0),    -- The Problem Row! (Divide by zero)
(4, 'Keyboard', 150.00, 3);   -- ARPU: $50
```

---

## ❓ The Question
Write an SQL query to calculate the `revenue_per_unit` for each sale. 

Use a built-in SQL function to safely convert any `0` values in the `units_sold` column into `NULL`s before the division takes place. This will allow the division to safely evaluate to `NULL` instead of crashing. 

Return the `sale_id`, `product_name`, `revenue`, `units_sold`, and the calculated `revenue_per_unit`. Order by `sale_id`.

---

## 💡 The Solution

```sql
SELECT 
    sale_id,
    product_name,
    revenue,
    units_sold,
    -- NULLIF prevents the fatal Divide-by-Zero error
    ROUND(revenue / NULLIF(units_sold, 0), 2) AS revenue_per_unit
FROM daily_sales
ORDER BY sale_id;
```

---

## 📝 Explanation
- **The Fatal Error**: In almost every SQL dialect, attempting to divide a number by `0` throws a hard error (e.g., `Division by zero`) and stops the entire query from executing. 
- **How `NULLIF(expression1, expression2)` works**: This incredibly useful function compares two expressions. 
  - If they are equal, it returns `NULL`. 
  - If they are different, it returns `expression1`.
- **Applying it to Division**: By wrapping the denominator in `NULLIF(units_sold, 0)`, we are telling the engine: *"If units_sold is exactly 0, replace it with a NULL. Otherwise, just leave it as units_sold."*
- **Why this saves the query**: SQL engines have special rules for mathematically interacting with `NULL`s. Unlike dividing by zero, dividing a number by `NULL` does not throw an error; it simply evaluates to `NULL`. The query will successfully process rows 1, 2, and 4, while safely outputting `NULL` for the problematic row 3.
