# Day 56: SQL Challenge - Joins (Multi-Level Hierarchical Self Joins)

## 📌 Business Scenario
An HR department is mapping out the corporate chain of command. The employee data is stored in a single table, with a `manager_id` pointing to the `employee_id` of that person's direct supervisor.

The team needs a report that reveals the management hierarchy **two levels deep**. Specifically, for every employee, the report should show their direct Manager, and that Manager's Manager (the Director). 

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Employees Table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    manager_id INT -- NULL for the CEO
);

-- Insert Sample Data
INSERT INTO employees VALUES
(1, 'Alice (CEO)', NULL),
(2, 'Bob (VP of Sales)', 1),
(3, 'Charlie (VP of Eng)', 1),
(4, 'David (Sales Manager)', 2),
(5, 'Eve (Eng Manager)', 3),
(6, 'Frank (Sales Rep)', 4),
(7, 'Grace (Software Engineer)', 5);
```

---

## ❓ The Question
Write an SQL query using multiple Self Joins to retrieve the chain of command. 

Return the `employee_name`, their direct `manager_name`, and the `director_name` (the manager's manager). If an employee is at the top of the hierarchy and lacks a manager or a director, gracefully display `'N/A'` using `COALESCE`. 

Order the results by the `employee_name` alphabetically.

---

## 💡 The Solution

```sql
SELECT 
    e1.employee_name AS employee,
    COALESCE(e2.employee_name, 'N/A') AS manager_name,
    COALESCE(e3.employee_name, 'N/A') AS director_name
FROM employees e1
-- First Self Join: Connect the employee to their direct manager
LEFT JOIN employees e2 
    ON e1.manager_id = e2.employee_id
-- Second Self Join: Connect the manager to THEIR manager (the director)
LEFT JOIN employees e3 
    ON e2.manager_id = e3.employee_id
ORDER BY e1.employee_name;
```

---

## 📝 Explanation
- **The Core Concept (Self Joins)**: When hierarchical data (like an org chart or a category tree) is flattened into a single table, you must join the table to itself to traverse the levels.
- **`e1`, `e2`, and `e3`**: We alias the `employees` table three times to represent the three levels of the hierarchy:
  - `e1` is the base layer (the employee).
  - `e2` is the second layer (the direct manager). We find this by matching the employee's `manager_id` to the manager's `employee_id`.
  - `e3` is the third layer (the director). We find this by taking `e2` (the manager layer) and matching *their* `manager_id` to the director's `employee_id`.
- **`LEFT JOIN`**: Using a `LEFT JOIN` (instead of an `INNER JOIN`) is crucial. Alice (the CEO) has no manager, and Bob/Charlie have no director above their manager. An `INNER JOIN` would filter them out entirely. `LEFT JOIN` preserves them and produces `NULL`s, which we then clean up into `'N/A'` using `COALESCE`.
