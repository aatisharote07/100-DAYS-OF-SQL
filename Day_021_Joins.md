# Day 21: SQL Challenge - Joins (Simulating Full Outer Join)

## 📌 Business Scenario
A marketing operations team consolidates customer leads across quarters. They have two tables: `leads_q1` and `leads_q2`. Some leads exist only in Q1, some only in Q2, and some in both. 

To run a holistic analysis, they need a full list of all unique leads across both quarters. Because their production database (MySQL) does not natively support the `FULL OUTER JOIN` statement, they need a query that simulates this functionality using portable joins.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Q1 Leads Table
CREATE TABLE leads_q1 (
    lead_id INT PRIMARY KEY,
    lead_name VARCHAR(100),
    email VARCHAR(100)
);

-- Create Q2 Leads Table
CREATE TABLE leads_q2 (
    lead_id INT PRIMARY KEY,
    lead_name VARCHAR(100),
    email VARCHAR(100)
);

-- Insert Sample Data
INSERT INTO leads_q1 (lead_id, lead_name, email) VALUES
(1, 'Alice Smith', 'alice@email.com'),
(2, 'Bob Jones', 'bob@email.com'),
(3, 'Charlie Brown', 'charlie@email.com');

INSERT INTO leads_q2 (lead_id, lead_name, email) VALUES
(2, 'Bob Jones', 'bob@email.com'),     -- Present in both quarters
(4, 'David Green', 'david@email.com'),    -- Present in Q2 only
(5, 'Emma White', 'emma@email.com');       -- Present in Q2 only
```

---

## ❓ The Question
Write an SQL query to perform a full outer join of `leads_q1` and `leads_q2` on the `email` column. For each lead, return their `lead_name` (using the Q1 name if available, otherwise Q2 name), their `email`, and a `lead_status` column indicating if they are in `'Q1 Only'`, `'Q2 Only'`, or `'Both Quarters'`. Do not use native `FULL OUTER JOIN` syntax.

---

## 💡 The Solution

```sql
SELECT 
    COALESCE(q1.lead_name, q2.lead_name) AS lead_name,
    COALESCE(q1.email, q2.email) AS email,
    CASE 
        WHEN q1.email IS NOT NULL AND q2.email IS NOT NULL THEN 'Both Quarters'
        WHEN q1.email IS NOT NULL THEN 'Q1 Only'
        ELSE 'Q2 Only'
    END AS lead_status
FROM leads_q1 q1
LEFT JOIN leads_q2 q2 ON q1.email = q2.email

UNION

SELECT 
    COALESCE(q1.lead_name, q2.lead_name) AS lead_name,
    COALESCE(q1.email, q2.email) AS email,
    CASE 
        WHEN q1.email IS NOT NULL AND q2.email IS NOT NULL THEN 'Both Quarters'
        WHEN q1.email IS NOT NULL THEN 'Q1 Only'
        ELSE 'Q2 Only'
    END AS lead_status
FROM leads_q1 q1
RIGHT JOIN leads_q2 q2 ON q1.email = q2.email;
```

---

## 📝 Explanation
- **Simulating Full Outer Join**: We achieve a full outer join by combining a `LEFT JOIN` (which retains all records from `leads_q1`) and a `RIGHT JOIN` (which retains all records from `leads_q2`) using the `UNION` operator.
- **Deduplication via `UNION`**: The `UNION` operator automatically removes duplicate rows. In this case, it drops the duplicate match records for leads that exist in both tables (like `bob@email.com`), keeping exactly one copy.
- **Handling Nulls via `COALESCE`**: When a record is Q1-only or Q2-only, the corresponding values in the other table will be `NULL`. `COALESCE` selects the first non-null value from the list, resolving the correct name and email.
- **Status Classification (`CASE WHEN`)**: The `CASE` statement inspects whether the emails are present in Q1, Q2, or both, dynamically labelling the quarters they belong to.
