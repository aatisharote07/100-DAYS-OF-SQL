# Day 41: SQL Challenge - CTEs (Recursive Bill of Materials / Parts Explosion)

## 📌 Business Scenario
A manufacturing company maintains a **Bill of Materials (BOM)** — a hierarchical list of components that make up a final product. Each component can itself be made up of sub-components, forming a multi-level tree.

The engineering team needs to produce a full "parts explosion" report showing every component and sub-component needed to build the final product, along with its depth level in the assembly hierarchy and the full path from root to the current part.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Bill of Materials Table
CREATE TABLE bom (
    component_id INT PRIMARY KEY,
    component_name VARCHAR(100),
    parent_id INT -- NULL means it's a top-level product
);

-- Insert Sample Data
INSERT INTO bom (component_id, component_name, parent_id) VALUES
(1, 'Bicycle', NULL),         -- Level 0: Root Product
(2, 'Frame', 1),              -- Level 1
(3, 'Wheels', 1),             -- Level 1
(4, 'Drivetrain', 1),         -- Level 1
(5, 'Fork', 2),               -- Level 2 (child of Frame)
(6, 'Seat Tube', 2),          -- Level 2 (child of Frame)
(7, 'Front Wheel', 3),        -- Level 2 (child of Wheels)
(8, 'Rear Wheel', 3),         -- Level 2 (child of Wheels)
(9, 'Chain', 4),              -- Level 2 (child of Drivetrain)
(10, 'Cassette', 4),          -- Level 2 (child of Drivetrain)
(11, 'Spokes', 7),            -- Level 3 (child of Front Wheel)
(12, 'Rim', 7);               -- Level 3 (child of Front Wheel)
```

---

## ❓ The Question
Write a recursive CTE to traverse the entire component hierarchy starting from the top-level product (`parent_id IS NULL`). For each component, return the `component_id`, `component_name`, the `level` in the hierarchy (starting from 0), and a `path` string showing the full ancestry trail (e.g., `Bicycle > Wheels > Front Wheel > Spokes`).

---

## 💡 The Solution

### MySQL / PostgreSQL / SQL Server Solution
```sql
WITH RECURSIVE ComponentHierarchy AS (
    -- Anchor Member: Start with the top-level product
    SELECT 
        component_id,
        component_name,
        parent_id,
        0 AS level,
        CAST(component_name AS CHAR(500)) AS path
    FROM bom
    WHERE parent_id IS NULL

    UNION ALL

    -- Recursive Member: Traverse child components
    SELECT 
        b.component_id,
        b.component_name,
        b.parent_id,
        ch.level + 1 AS level,
        CONCAT(ch.path, ' > ', b.component_name) AS path
    FROM bom b
    JOIN ComponentHierarchy ch ON b.parent_id = ch.component_id
)
SELECT 
    component_id,
    component_name,
    level,
    path
FROM ComponentHierarchy
ORDER BY path;
```

### PostgreSQL Syntax Note
```sql
-- PostgreSQL uses text concatenation with || instead of CONCAT:
-- Replace the CONCAT line with:
ch.path || ' > ' || b.component_name AS path
```

---

## 📝 Explanation
- **Anchor Member**: The first `SELECT` block retrieves the root component (`parent_id IS NULL`). It sets the recursion starting point with `level = 0` and initializes the `path` string with just the root name.
- **Recursive Member**: The second `SELECT` block (after `UNION ALL`) joins the `bom` table with the CTE itself (`ComponentHierarchy`). It matches child rows (`b.parent_id`) to the current level's component ID (`ch.component_id`), incrementing the `level` counter and appending the child component name to the `path` string at each step.
- **Termination**: Recursion automatically terminates when the `JOIN` finds no new child rows to process — meaning every leaf node has been reached.
- **Real-World Use Cases**: This pattern is widely used in organizational charts, category trees, file system traversal, project dependency graphs, and supply chain analysis.
