# Day 78: SQL Challenge - CTEs (Recursive Tree Traversal)

## 📌 Business Scenario
An HR department is mapping out the company's organizational chart. They have a single `employees` table where each employee has a `manager_id` pointing to their direct boss.

The VP of HR wants a report that assigns a "Management Level" to every single employee in the company. 
- The CEO (who has no manager) should be **Level 0**. 
- Direct reports to the CEO (like VPs) are **Level 1**.
- Direct reports to the VPs (like Directors) are **Level 2**, and so on down the chain.

Because the depth of an organizational chart is dynamic and unknown, you cannot hardcode a set of Self-Joins. You must traverse the hierarchy using a **Recursive CTE**.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Employees Table
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    name VARCHAR(100),
    manager_id INT -- NULL for the CEO
);

-- Insert Sample Data
INSERT INTO employees VALUES
(1, 'Alice (CEO)', NULL),
(2, 'Bob (VP of Sales)', 1),
(3, 'Charlie (VP of Eng)', 1),
(4, 'David (Sales Director)', 2),
(5, 'Eve (Eng Director)', 3),
(6, 'Frank (Sales Rep)', 4),
(7, 'Grace (Software Engineer)', 5);
```

---

## ❓ The Question
Write an SQL query using a `WITH RECURSIVE` Common Table Expression to traverse the employee hierarchy. 

Calculate the `management_level` for each employee. Return the `emp_id`, `name`, and `management_level`. Order the results logically by `management_level` first, and then alphabetically by `name`.

---

## 💡 The Solution

```sql
-- Note: SQL Server users should omit the word 'RECURSIVE'
WITH RECURSIVE OrgChart AS (
    -- Step 1: The Anchor Member (Initialize the recursion)
    SELECT 
        emp_id, 
        name, 
        manager_id, 
        0 AS management_level -- CEO is Level 0
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Step 2: The Recursive Member (Looping through the children)
    SELECT 
        e.emp_id, 
        e.name, 
        e.manager_id, 
        oc.management_level + 1 -- Increment the level for each step down
    FROM employees e
    -- Join the standard table back to the CTE itself!
    JOIN OrgChart oc 
        ON e.manager_id = oc.emp_id
)
-- Step 3: Select from the fully built CTE
SELECT 
    emp_id, 
    name, 
    management_level
FROM OrgChart
ORDER BY 
    management_level ASC, 
    name ASC;
```

---

## 📝 Explanation
Recursive CTEs are the definitive way to traverse hierarchical data (trees, graphs, bill-of-materials, or org charts) in SQL. They consist of two parts joined by a `UNION ALL`:
- **The Anchor Member**: This is the starting point. It executes exactly once. We query the `employees` table looking for the CEO (`manager_id IS NULL`) and hardcode their level as `0`. This single row seeds the CTE.
- **The Recursive Member**: This is where the magic happens. It executes repeatedly in a loop.
  - *Loop 1*: It takes the standard `employees` table and joins it to the CTE (which currently only holds the CEO). It finds Bob and Charlie (whose manager is the CEO). It assigns them `Level 0 + 1 = 1`. The CTE now holds Alice, Bob, and Charlie.
  - *Loop 2*: It joins the `employees` table to the CTE *again*. It finds David and Eve (who report to Bob and Charlie). It assigns them `Level 1 + 1 = Level 2`. The CTE expands.
  - *Termination*: The engine continues this loop automatically until a join produces exactly 0 new records (in this case, when it looks for employees reporting to Frank and Grace, finds none, and stops).
