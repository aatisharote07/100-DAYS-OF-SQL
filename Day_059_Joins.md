# Day 59: SQL Challenge - Joins (CROSS JOIN for Matrix Generation)

## 📌 Business Scenario
A clothing brand is launching a new line of t-shirts. The design will be available in 3 colors and 4 sizes. Before manufacturing, the operations team needs to generate a complete inventory matrix (a list of every possible color and size combination) to insert into their warehouse system as unique SKUs.

However, due to a fabric shortage, they will **not** be producing the "Red" shirt in "Small". 

Generating all possible combinations between two independent lists is the textbook use case for a **CROSS JOIN**.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Colors Table
CREATE TABLE colors (
    color_id INT PRIMARY KEY,
    color_name VARCHAR(50)
);

-- Create Sizes Table
CREATE TABLE sizes (
    size_id INT PRIMARY KEY,
    size_name VARCHAR(50)
);

-- Insert Sample Data
INSERT INTO colors VALUES
(1, 'Red'),
(2, 'Blue'),
(3, 'Black');

INSERT INTO sizes VALUES
(1, 'Small'),
(2, 'Medium'),
(3, 'Large'),
(4, 'Extra Large');
```

---

## ❓ The Question
Write an SQL query to generate a complete list of all possible combinations of `color_name` and `size_name`. 

Exclude the specific combination of `'Red'` and `'Small'` from the final output. Return the `color_name` and `size_name`, ordered first by color alphabetically, and then by size alphabetically.

---

## 💡 The Solution

```sql
SELECT 
    c.color_name,
    s.size_name
FROM colors c
-- CROSS JOIN creates a Cartesian product (every row in C matches every row in S)
CROSS JOIN sizes s
WHERE NOT (c.color_name = 'Red' AND s.size_name = 'Small')
ORDER BY 
    c.color_name ASC, 
    s.size_name ASC;
```

---

## 📝 Explanation
- **What is a `CROSS JOIN`?**: Unlike `INNER` or `LEFT` joins, a `CROSS JOIN` does not require an `ON` clause to match rows based on a condition. Instead, it creates a **Cartesian Product**. It takes every single row from the first table and pairs it with every single row from the second table.
  - 3 Colors × 4 Sizes = **12 Total Combinations**.
- **When to use it**: It is incredibly useful for generating grids, calendar date-time matrices, mock test data, or ensuring a report has a placeholder row for every possible category even if no sales occurred.
- **The Exclusion (`WHERE NOT`)**: After generating the 12 combinations, the `WHERE` clause filters the results. Wrapping the specific conditions `c.color_name = 'Red' AND s.size_name = 'Small'` inside a `NOT()` statement neatly removes that single SKU from the 12 generated rows, leaving 11 active combinations for the inventory system.
