# Day 58: SQL Challenge - Subqueries (Exclusive Filtering / "Only X" Analysis)

## 📌 Business Scenario
A telecom provider offers three main services: Mobile, Internet, and TV. The marketing team is launching an upsell campaign. They want a list of customers who are subscribed to **Mobile only**, meaning they strictly do not have an Internet or TV subscription.

This is a classic "Exclusive Filtering" problem. It's not enough to just find customers who have Mobile; you must explicitly verify that they *lack* all other services.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Customer Services Table
CREATE TABLE customer_services (
    subscription_id INT PRIMARY KEY,
    customer_id INT,
    service_type VARCHAR(50)
);

-- Insert Sample Data
INSERT INTO customer_services VALUES
(1, 101, 'Mobile'),
(2, 101, 'Internet'), -- Customer 101 has Mobile + Internet
(3, 102, 'Mobile'),   -- Customer 102 is Mobile ONLY
(4, 103, 'TV'),
(5, 103, 'Internet'), -- Customer 103 has no Mobile
(6, 104, 'Mobile');   -- Customer 104 is Mobile ONLY
```

---

## ❓ The Question
Write an SQL query to find the `customer_id`s of users who are exclusively subscribed to `'Mobile'` services. 

Return the `customer_id` and order the results in ascending order. Provide two different solutions: one using a Subquery (`NOT IN`), and another using Conditional Aggregation (`HAVING`).

---

## 💡 The Solution

### Method 1: Subquery (Anti-Join Pattern)
```sql
SELECT DISTINCT 
    customer_id
FROM customer_services
WHERE service_type = 'Mobile'
  AND customer_id NOT IN (
      -- Identify all customers who have a non-Mobile service
      SELECT customer_id 
      FROM customer_services 
      WHERE service_type != 'Mobile'
  )
ORDER BY customer_id;
```

### Method 2: Conditional Aggregation (No Subqueries)
```sql
SELECT 
    customer_id
FROM customer_services
GROUP BY customer_id
HAVING 
    -- Must have at least one Mobile service
    SUM(CASE WHEN service_type = 'Mobile' THEN 1 ELSE 0 END) > 0
    -- Must have exactly zero non-Mobile services
    AND SUM(CASE WHEN service_type != 'Mobile' THEN 1 ELSE 0 END) = 0
ORDER BY customer_id;
```

---

## 📝 Explanation
- **The Pitfall**: A simple `WHERE service_type = 'Mobile'` would mistakenly include Customer 101, because they *do* have a Mobile row. We must actively exclude them because of their second row (Internet).
- **Method 1 (NOT IN)**: This is the most readable approach. The inner query builds a "blacklist" of any customer who possesses an Internet or TV plan. The outer query finds customers with a Mobile plan, and then drops anyone found on the blacklist.
- **Method 2 (HAVING)**: This approach performs a single pass over the table. By grouping by `customer_id`, we compress all of a user's subscriptions into a single evaluation. The `SUM(CASE WHEN...)` statements act as conditional counters. A customer qualifies only if their Mobile counter is greater than `0` and their Other Services counter is exactly `0`. This is often more performant on large datasets as it avoids a subquery lookup.
