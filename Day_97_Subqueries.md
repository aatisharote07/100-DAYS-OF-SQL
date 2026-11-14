# Day 97: SQL Challenge - Subqueries (Correlated Subquery vs JOIN for Median)

## 📌 Business Scenario
A compensation committee at a mid-sized tech firm is evaluating salary distributions across departments. In skewed distributions (such as when executive salaries pull the arithmetic mean upward), leadership relies on the **median salary** rather than the average to establish equitable pay bands.

While modern cloud data warehouses offer built-in analytic functions like `PERCENTILE_CONT(0.5)`, many relational engines or legacy environments do not support native median functions. 

A quintessential SQL interview problem tests candidates on deriving the **true mathematical median using correlated subqueries or ranking self-joins**, requiring an exact balance where the count of values above the median equals the count of values below it.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Employees Table
CREATE TABLE department_salaries (
    emp_id INT PRIMARY KEY,
    department VARCHAR(50),
    salary DECIMAL(10, 2)
);

-- Insert Sample Data
-- Engineering (Odd count: 5 records -> Median is 3rd: 110,000.00)
-- Marketing (Even count: 4 records -> Median is avg of 2nd & 3rd: (65,000 + 75,000)/2 = 70,000.00)
INSERT INTO department_salaries VALUES
(1, 'Engineering', 90000.00),
(2, 'Engineering', 105000.00),
(3, 'Engineering', 110000.00), -- Middle
(4, 'Engineering', 130000.00),
(5, 'Engineering', 180000.00),
(6, 'Marketing',   55000.00),
(7, 'Marketing',   65000.00),  -- Middle 1
(8, 'Marketing',   75000.00),  -- Middle 2
(9, 'Marketing',   95000.00);
```

---

## ❓ The Question
Write an SQL query to calculate the **median salary for each department** without using proprietary median functions like `PERCENTILE_CONT` or `MEDIAN`.

Handle both odd and even numbers of department employees:
- For an odd count of $N$ rows, the median is the single middle value at position $(N + 1) / 2$.
- For an even count of $N$ rows, the median is the average of the two middle values at positions $N / 2$ and $(N / 2) + 1$.

Return `department` and `median_salary` (rounded to 2 decimal places). Order by `department`.

---

## 💡 The Solution

```sql
WITH RankedSalaries AS (
    -- Step 1: Assign ascending row numbers and compute total count per department
    SELECT 
        department,
        salary,
        ROW_NUMBER() OVER (
            PARTITION BY department 
            ORDER BY salary ASC, emp_id ASC
        ) AS row_num,
        COUNT(*) OVER (
            PARTITION BY department
        ) AS total_count
    FROM department_salaries
)
-- Step 2: Filter strictly for the middle position(s) and compute average
SELECT 
    department,
    ROUND(AVG(salary), 2) AS median_salary
FROM RankedSalaries
WHERE row_num IN (
    FLOOR((total_count + 1) / 2.0), 
    CEIL((total_count + 1) / 2.0)
)
GROUP BY department
ORDER BY department;
```

---

## 📝 Explanation

### The Mathematical Elegance of `FLOOR` and `CEIL`
Handling both odd and even dataset sizes in SQL often leads to bloated `CASE` statements. The `FLOOR` / `CEIL` formula resolves both cases simultaneously:

1. **When Count is Odd (e.g., Engineering with 5 employees)**:
   - `total_count = 5`
   - `(5 + 1) / 2.0 = 3.0`
   - `FLOOR(3.0) = 3` and `CEIL(3.0) = 3`
   - `WHERE row_num IN (3, 3)` isolates only the exact middle row ($110,000.00$).
   - `AVG($110,000.00)` yields **\$110,000.00**.

2. **When Count is Even (e.g., Marketing with 4 employees)**:
   - `total_count = 4`
   - `(4 + 1) / 2.0 = 2.5`
   - `FLOOR(2.5) = 2` and `CEIL(2.5) = 3`
   - `WHERE row_num IN (2, 3)` extracts both middle rows ($65,000.00$ and $75,000.00$).
   - `AVG(65000, 75000)` produces **\$70,000.00**.

### Portability and Efficiency
- Works identically across MySQL 8.0+, PostgreSQL, SQLite 3.25+, SQL Server, and Oracle.
- Avoids expensive $O(N^2)$ cross-join self-comparisons by using a single $O(N \log N)$ windowed sort pass inside the CTE.
