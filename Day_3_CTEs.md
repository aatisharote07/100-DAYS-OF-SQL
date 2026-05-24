# Day 3: SQL Challenge - CTEs (Recursive CTEs)

## 📌 Business Scenario
An enterprise company wants to audit their organizational structure. They need to map out the reporting hierarchy to understand the reporting depth (how many management layers exist) and trace the direct path from the CEO to each employee.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Employees Table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    manager_id INT,
    role VARCHAR(50)
);

-- Insert Sample Data
INSERT INTO employees (employee_id, employee_name, manager_id, role) VALUES
(1, 'Alice', NULL, 'CEO'),
(2, 'Bob', 1, 'VP of Engineering'),
(3, 'Charlie', 2, 'Engineering Manager'),
(4, 'David', 3, 'Senior Engineer'),
(5, 'Emily', 3, 'Software Engineer'),
(6, 'Fiona', 1, 'VP of Product'),
(7, 'George', 6, 'Product Manager');
```

---

## ❓ The Question
Write an SQL query using a recursive CTE to find the reporting hierarchy of the organization. For each employee, display their `employee_id`, `employee_name`, their `role`, their reporting `level` (where CEO is Level 1, VPs are Level 2, etc.), and their full `reporting_path` from the CEO (e.g., `Alice -> Bob -> Charlie`).

---

## 💡 The Solution

```sql
WITH RECURSIVE OrgHierarchy AS (
    -- Anchor Member: Start with the CEO (no manager)
    SELECT 
        employee_id,
        employee_name,
        manager_id,
        role,
        1 AS level,
        CAST(employee_name AS CHAR(255)) AS reporting_path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive Member: Join remaining employees with the hierarchy built so far
    SELECT 
        e.employee_id,
        e.employee_name,
        e.manager_id,
        e.role,
        h.level + 1 AS level,
        CONCAT(h.reporting_path, ' -> ', e.employee_name) AS reporting_path
    FROM employees e
    INNER JOIN OrgHierarchy h ON e.manager_id = h.employee_id
)
SELECT 
    employee_id,
    employee_name,
    role,
    level,
    reporting_path
FROM OrgHierarchy
ORDER BY level, employee_id;
```

---

## 📝 Explanation
- **Anchor Member**: The top query in the CTE sets the base case. It selects the employee with no manager (the CEO, `Alice`), starting the hierarchy at `level = 1` and initializing the `reporting_path` with just her name.
- **Recursive Member**: The bottom query joins the `employees` table with the CTE itself. By matching `e.manager_id = h.employee_id`, it recursively finds who reports to whom, incrementing the level by `1` and appending the employee's name to the `reporting_path` at each step.
- **Termination & Output**: The recursion runs until no more reporting relationships can be resolved. The outer query selects all columns from the CTE, ordering by level to show the hierarchy from top to bottom.
