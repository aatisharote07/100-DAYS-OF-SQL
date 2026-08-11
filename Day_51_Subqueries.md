# Day 51: SQL Challenge - Subqueries (Relational Division / Finding "All" Matches)

## 📌 Business Scenario
A bookstore wants to run a loyalty campaign called "The Completionist". They want to send a special coupon to any customer who has purchased **every single book** in "The Lord of the Rings" series.

This represents a classic SQL problem known as **Relational Division** — finding entities in one table that have a relationship with *all* specified entities in another table.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Books Table
CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(100),
    series_name VARCHAR(50)
);

-- Create Customer Purchases Table
CREATE TABLE customer_purchases (
    purchase_id INT PRIMARY KEY,
    customer_id INT,
    book_id INT
);

-- Insert Sample Data
INSERT INTO books VALUES
(1, 'The Fellowship of the Ring', 'The Lord of the Rings'),
(2, 'The Two Towers', 'The Lord of the Rings'),
(3, 'The Return of the King', 'The Lord of the Rings'),
(4, 'The Hobbit', 'Middle-earth Universe'); -- Different series

INSERT INTO customer_purchases VALUES
(101, 1, 1), -- Customer 1 bought Fellowship
(102, 1, 2), -- Customer 1 bought Two Towers
(103, 2, 1), -- Customer 2 bought Fellowship
(104, 2, 2), -- Customer 2 bought Two Towers
(105, 2, 3), -- Customer 2 bought Return of the King (Completionist!)
(106, 3, 3), -- Customer 3 bought Return of the King
(107, 3, 4); -- Customer 3 bought The Hobbit
```

---

## ❓ The Question
Write an SQL query to find the `customer_id` of all customers who have purchased every book belonging to the series `'The Lord of the Rings'`. 

Use a subquery to dynamically calculate the total number of books in the series, so the query will still work even if a 4th book is added later.

---

## 💡 The Solution

```sql
SELECT 
    cp.customer_id
FROM customer_purchases cp
JOIN books b ON cp.book_id = b.book_id
WHERE b.series_name = 'The Lord of the Rings'
GROUP BY cp.customer_id
HAVING COUNT(DISTINCT cp.book_id) = (
    -- Subquery: Dynamically count how many books are in this series
    SELECT COUNT(*) 
    FROM books 
    WHERE series_name = 'The Lord of the Rings'
);
```

---

## 📝 Explanation
- **The Core Strategy (Aggregation & Counting)**: Since SQL lacks a direct `DIVIDE BY` operator, the standard way to solve relational division is by comparing counts. If a customer bought *N* unique books in a series, and the series contains exactly *N* books, then the customer bought them all.
- **Filtering the Base Set**: The outer query joins purchases to books and filters `WHERE b.series_name = 'The Lord of the Rings'`. This ensures we are only evaluating Lord of the Rings purchases.
- **`COUNT(DISTINCT)`**: We group by `customer_id` and count the *distinct* `book_id`s they purchased. Using `DISTINCT` is vital in case a customer accidentally purchased two copies of "The Two Towers"; they should still only get credit for 1 unique book.
- **The Subquery Comparison**: The `HAVING` clause compares that customer's unique book count against a subquery that simply counts `COUNT(*)` the total rows in the `books` table for that series (which evaluates to 3). Only Customer 2 matches (3 = 3).
