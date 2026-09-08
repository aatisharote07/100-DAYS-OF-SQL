# Day 66: SQL Challenge - Subqueries (Top N per Group without Window Functions)

## 📌 Business Scenario
You have been hired to audit an older, legacy database system (like MySQL 5.7 or older versions of SQLite) that **does not support Window Functions** (meaning you cannot use `ROW_NUMBER()`, `RANK()`, or `DENSE_RANK()`).

HR needs a report showing the **Top 2 highest-paid employees** in each department. 

Without the luxury of modern window ranking functions, you must rely on a complex Correlated Subquery to manually evaluate and count salaries to simulate a ranking system. This is a notorious and highly tested FAANG interview question!

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Employees Table
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO employees VALUES
(1, 'Alice', 'IT', 90000),
(2, 'Bob', 'IT', 85000),
(3, 'Charlie', 'IT', 80000), -- 3rd place, should be excluded
(4, 'David', 'Sales', 75000),
(5, 'Eve', 'Sales', 70000),
(6, 'Frank', 'Sales', 95000), -- 1st place in Sales
(7, 'Grace', 'Sales', 65000); -- 4th place, should be excluded
```

---

## ❓ The Question
Write an SQL query to find the top 2 highest-paid employees in each department **without using any Window Functions**. 

Return the `department`, `name`, and `salary`. Order the results by `department` alphabetically, and then by `salary` in descending order.

---

## 💡 The Solution

```sql
SELECT 
    e1.department,
    e1.name,
    e1.salary
FROM employees e1
WHERE 2 > (
    -- The Correlated Subquery acts as a manual ranking mechanism
    SELECT COUNT(DISTINCT e2.salary)
    FROM employees e2
    WHERE e2.department = e1.department 
      AND e2.salary > e1.salary
)
ORDER BY 
    e1.department ASC, 
    e1.salary DESC;
```

---

## 📝 Explanation
- **The Core Logic**: If you are the 1st highest-paid person in your department, exactly **0** people make more money than you. If you are the 2nd highest-paid person, exactly **1** person makes more money than you. Therefore, if we count how many people make *more* money than you, and that count is strictly **less than 2** (meaning it's 0 or 1), you are in the Top 2!
- **The Correlated Subquery**: 
  - For every row evaluated in the outer query (`e1`), the inner query executes.
  - It searches the same table (`e2`), filters for the exact same department (`e2.department = e1.department`), and counts how many distinct salaries are strictly greater than the outer row's salary (`e2.salary > e1.salary`).
- **Walking through an example**: 
  - When the outer query looks at **Alice (IT, $90k)**, the inner query counts how many IT people make strictly more than $90k. The answer is **0**. Because `2 > 0` is True, Alice is kept.
  - When it looks at **Charlie (IT, $80k)**, the inner query counts how many IT people make strictly more than $80k (Alice and Bob). The answer is **2**. Because `2 > 2` is False, Charlie is dropped from the result set. 
- **`COUNT(DISTINCT)`**: Using `DISTINCT` ensures that if two employees are tied for 1st place, they don't incorrectly push the 2nd place person out of the rankings.
