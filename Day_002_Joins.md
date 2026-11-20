# Day 2: SQL Challenge - Joins (Self Join)

## 📌 Business Scenario
An HR department wants to audit compensation structures. Specifically, they want to identify all employees who earn more than their direct managers to ensure internal equity and review reporting hierarchies.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Employees Table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    salary DECIMAL(10, 2),
    manager_id INT,
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

-- Insert Sample Data
INSERT INTO employees (employee_id, employee_name, salary, manager_id) VALUES
(1, 'Alice Smith', 120000.00, NULL),  -- CEO (No Manager)
(2, 'Bob Jones', 95000.00, 1),       -- Reports to Alice
(3, 'Charlie Brown', 105000.00, 2),   -- Reports to Bob (Charlie earns more than Bob!)
(4, 'David Green', 80000.00, 2),     -- Reports to Bob
(5, 'Emma White', 110000.00, 1),     -- Reports to Alice
(6, 'Frank Black', 115000.00, 5);     -- Reports to Emma (Frank earns more than Emma!)
```

---

## ❓ The Question
Write an SQL query to find the names and salaries of employees who earn more than their direct managers. The output should include the employee's name, employee's salary, manager's name, and manager's salary.

---

## 💡 The Solution

```sql
SELECT 
    e.employee_name AS employee,
    e.salary AS employee_salary,
    m.employee_name AS manager,
    m.salary AS manager_salary
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;
```

---

## 📝 Explanation
- **Self Join**: The query joins the `employees` table to itself using two different aliases (`e` for employee details and `m` for manager details). The join condition `e.manager_id = m.employee_id` links each employee row to their direct supervisor's row.
- **Salary Comparison**: The `WHERE e.salary > m.salary` clause filters the results to only include pairs where the employee's salary is strictly greater than their manager's salary.
- **Result Selection**: We select and rename the relevant columns to provide a clear, readable comparison of the employee and manager information.
