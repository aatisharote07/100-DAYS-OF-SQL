# Day 55: SQL Challenge - Aggregate Functions (Calculating a Weighted Average)

## 📌 Business Scenario
A university registrar's office is tasked with calculating the final Grade Point Average (GPA) for its students. 

A naive approach would be to use the standard `AVG(grade)` function. However, this is mathematically incorrect because courses have different credit weights (e.g., a 4-credit calculus course impacts the final GPA much more than a 1-credit physical education course). The team must calculate a true **Weighted Average**.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Student Grades Table
CREATE TABLE student_grades (
    grade_id INT PRIMARY KEY,
    student_id INT,
    course_name VARCHAR(100),
    credits INT,
    grade_points DECIMAL(3, 1) -- 4.0 scale
);

-- Insert Sample Data
INSERT INTO student_grades VALUES
(1, 101, 'Calculus I', 4, 3.5),       -- Heavy weight, decent grade
(2, 101, 'Tennis', 1, 4.0),           -- Light weight, perfect grade
(3, 101, 'Physics', 3, 2.5),          -- Medium weight, low grade
(4, 102, 'Data Structures', 4, 4.0),  -- Heavy weight, perfect grade
(5, 102, 'Database Systems', 3, 3.8); -- Medium weight, high grade

-- If we used naive AVG() for Student 101: (3.5 + 4.0 + 2.5) / 3 = 3.33
-- True Weighted GPA for Student 101: ((3.5*4) + (4.0*1) + (2.5*3)) / (4+1+3) = 25.5 / 8 = 3.19
```

---

## ❓ The Question
Write an SQL query to calculate the mathematically correct weighted GPA for each student. 

Return the `student_id` and the calculated `weighted_gpa` rounded to two decimal places. Order the results by the highest `weighted_gpa` first.

---

## 💡 The Solution

```sql
SELECT 
    student_id,
    -- Step 1 & 2: Sum the weighted points, then divide by total weight
    ROUND(SUM(grade_points * credits) / SUM(credits), 2) AS weighted_gpa
FROM student_grades
GROUP BY student_id
ORDER BY weighted_gpa DESC;
```

---

## 📝 Explanation
- **The Mathematical Formula**: A weighted average is calculated by multiplying each value by its weight, summing those results, and then dividing by the total sum of the weights: `Σ(Value * Weight) / Σ(Weight)`.
- **Applying it in SQL**: 
  - `SUM(grade_points * credits)` executes row-by-row multiplication before summing, representing the top half of our equation (the total quality points earned).
  - `SUM(credits)` represents the bottom half of our equation (the total credits attempted).
- **Why `AVG()` Fails Here**: The built-in `AVG(grade_points)` function blindly adds up the raw grades and divides by the *row count* (the number of courses). It is completely unaware of the `credits` column, leading to an artificially inflated GPA for students taking easy 1-credit classes, and heavily penalizing students in difficult 4-credit classes.
- **Rounding**: We wrap the entire mathematical expression in `ROUND(..., 2)` for a clean, report-ready 2-decimal format.
