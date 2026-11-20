# Day 45: SQL Challenge - Joins (Resolving Many-to-Many Relationships)

## 📌 Business Scenario
A university registrar's office is auditing student enrollments for the upcoming semester. In relational databases, when a student can take multiple courses, and a course can have multiple students, this creates a **Many-to-Many relationship**.

To resolve this, the database uses an intermediate junction table (also called an associative entity or mapping table) named `enrollments`. The registrar needs a comprehensive report showing every student's name and the courses they are taking. Crucially, they also need to see students who haven't enrolled in any courses yet.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Students Table
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100)
);

-- Create Courses Table
CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100),
    credits INT
);

-- Create Enrollments Junction Table
CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY,
    student_id INT,
    course_id INT
);

-- Insert Sample Data
INSERT INTO students VALUES
(1, 'Alice Johnson'),
(2, 'Bob Smith'),
(3, 'Charlie Ray'); -- Charlie is not enrolled in any courses yet

INSERT INTO courses VALUES
(101, 'Introduction to Computer Science', 4),
(102, 'Data Structures', 3),
(103, 'Linear Algebra', 3);

INSERT INTO enrollments VALUES
(1, 1, 101), -- Alice takes Intro to CS
(2, 1, 102), -- Alice takes Data Structures
(3, 2, 101), -- Bob takes Intro to CS
(4, 2, 103); -- Bob takes Linear Algebra
```

---

## ❓ The Question
Write an SQL query to retrieve a list of all students and the names and credits of the courses they are enrolled in. If a student is not enrolled in any courses, their name should still appear in the report with `NULL` values for the course details. 

Order the results alphabetically by `student_name`, and then by `course_name`.

---

## 💡 The Solution

```sql
SELECT 
    s.student_name,
    c.course_name,
    c.credits
FROM students s
-- First LEFT JOIN: Link students to their enrollment records (if any)
LEFT JOIN enrollments e 
    ON s.student_id = e.student_id
-- Second LEFT JOIN: Link the enrollment records to the actual course details
LEFT JOIN courses c 
    ON e.course_id = c.course_id
ORDER BY s.student_name, c.course_name;
```

---

## 📝 Explanation
- **Many-to-Many Architecture**: The `students` and `courses` tables never directly reference each other. They are bridged by the `enrollments` table, which holds foreign keys pointing to both.
- **Bridging with Joins**: To get from a student's name to their course name, you must execute two consecutive joins: `students -> enrollments -> courses`.
- **Why LEFT JOIN?**: Using a `LEFT JOIN` at both steps guarantees that every record from the driving table (`students`) is kept. 
  - For Charlie, the first join to `enrollments` finds no matches, producing `NULL`s for the enrollment columns.
  - The second join attempts to match those `NULL` enrollment `course_id`s to the `courses` table, which also yields `NULL`s.
  - If we used an `INNER JOIN`, Charlie would be completely excluded from the final report because he lacks corresponding records in the junction table.
