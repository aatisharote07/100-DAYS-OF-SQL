# Day 85: SQL Challenge - Subqueries (The NOT IN vs NOT EXISTS NULL Trap)

## 📌 Business Scenario
A retail marketing team runs an automated VIP campaign targeting customers who have **never returned an item**. 

A developer wrote what looked like a straightforward subquery:
```sql
SELECT customer_id, customer_name 
FROM customers 
WHERE customer_id NOT IN (
    SELECT customer_id FROM returned_orders
);
```
Everything worked fine in staging. But in production, the marketing system suddenly sent zero emails. The query returned **0 rows**, even though thousands of customers had never made a return!

The culprit was a single row in `returned_orders` created by a guest checkout where `customer_id` was `NULL`. That single `NULL` triggered SQL's **Three-Valued Logic**, completely breaking the `NOT IN` clause.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100)
);

-- Create Returned Orders Table
CREATE TABLE returned_orders (
    return_id INT PRIMARY KEY,
    customer_id INT, -- Can contain NULL for guest returns
    return_reason VARCHAR(100)
);

-- Insert Sample Data
INSERT INTO customers VALUES
(1, 'Alice',   'alice@example.com'),
(2, 'Bob',     'bob@example.com'),
(3, 'Charlie', 'charlie@example.com');

-- Alice returned an item. Bob and Charlie did NOT.
-- But note the guest checkout return with customer_id = NULL!
INSERT INTO returned_orders VALUES
(101, 1,    'Defective item'),
(102, NULL, 'Guest checkout return');
```

---

## ❓ The Question
Write a production-grade SQL query using a correlated subquery with the `NOT EXISTS` operator to retrieve all customers who have never made a return. 

Your query must safely return **Bob** and **Charlie**, remaining completely unaffected by any `NULL` values present in the `returned_orders` table. Return `customer_id`, `customer_name`, and `email`, ordered by `customer_id`.

---

## 💡 The Solution

```sql
SELECT 
    c.customer_id,
    c.customer_name,
    c.email
FROM customers c
-- Correlated Subquery with NOT EXISTS (Safe against NULLs)
WHERE NOT EXISTS (
    SELECT 1
    FROM returned_orders r
    WHERE r.customer_id = c.customer_id
)
ORDER BY c.customer_id;
```

*(Alternative Fix using `NOT IN` with an explicit filter):*
```sql
SELECT customer_id, customer_name, email
FROM customers
WHERE customer_id NOT IN (
    SELECT customer_id 
    FROM returned_orders 
    WHERE customer_id IS NOT NULL -- Mandatory to avoid the NULL trap!
)
ORDER BY customer_id;
```

---

## 📝 Explanation

### The Anatomy of the Bug: Three-Valued Logic
SQL uses three-valued logic: `TRUE`, `FALSE`, and `UNKNOWN` (represented by `NULL`).

When you write:
```sql
WHERE customer_id NOT IN (1, NULL)
```
SQL internally translates this into a chain of inequality checks joined by `AND`:
```sql
WHERE (customer_id != 1) AND (customer_id != NULL)
```
For Bob (`customer_id = 2`):
1. `(2 != 1)` evaluates to `TRUE`.
2. `(2 != NULL)` evaluates to `UNKNOWN` (in SQL, comparing anything to `NULL` yields `UNKNOWN`).
3. `TRUE AND UNKNOWN` evaluates to `UNKNOWN`.

Because the `WHERE` clause only keeps rows where the condition evaluates to strictly `TRUE`, **every single row is discarded**, producing an empty result set!

### Why `NOT EXISTS` is Bulletproof
`NOT EXISTS` does not perform value equality chains across a list. Instead, it tests whether the inner subquery returns **at least one row**:
- For Bob (`customer_id = 2`), the engine checks `WHERE r.customer_id = 2`. 
- No matching rows exist in `returned_orders`, so the subquery returns an empty set (`0 rows`).
- `NOT EXISTS (empty set)` evaluates strictly to `TRUE`.
- Any rows in `returned_orders` where `customer_id IS NULL` simply fail the join predicate `r.customer_id = 2` and are harmlessly ignored.

> **Key Rule of Thumb**: Never use `NOT IN` against a subquery unless you are 100% certain the target column has a `NOT NULL` constraint. Otherwise, always default to `NOT EXISTS`!
