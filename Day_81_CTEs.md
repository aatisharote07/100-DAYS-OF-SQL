# Day 81: SQL Challenge - CTEs & Joins (Finding Missing Numbers in a Sequence)

## 📌 Business Scenario
An external auditing firm is conducting a compliance review on a company's accounts payable. According to tax laws, all sales invoice numbers must be strictly sequential (e.g., 1001, 1002, 1003...) with zero gaps. Gaps in the sequence could indicate fraud, lost revenue, or unauthorized deletions.

The auditor needs a query that automatically scans the `invoices` table between the minimum and maximum invoice numbers and outputs the exact **missing invoice IDs**.

To solve this, we must generate a complete, continuous sequence of numbers using a **Recursive CTE**, and then apply an **Anti-Join** to identify which numbers never made it into the database.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Invoices Table
CREATE TABLE invoices (
    invoice_id INT PRIMARY KEY,
    amount DECIMAL(10, 2),
    invoice_date DATE
);

-- Insert Sample Data (Min: 1001, Max: 1007)
-- Missing Invoices: 1003, 1006
INSERT INTO invoices VALUES
(1001, 250.00, '2026-10-01'),
(1002, 100.00, '2026-10-01'),
-- 1003 is missing!
(1004, 500.00, '2026-10-02'),
(1005, 75.00,  '2026-10-02'),
-- 1006 is missing!
(1007, 300.00, '2026-10-03');
```

---

## ❓ The Question
Write an SQL query using a Recursive CTE and a `LEFT JOIN` (Anti-Join) to find all missing invoice IDs between the minimum and maximum IDs in the table. 

Return a single column named `missing_invoice_id`. Order the results in ascending order.

---

## 💡 The Solution

```sql
-- Note: SQL Server users should omit the word 'RECURSIVE'
WITH RECURSIVE Sequence AS (
    -- Step 1: Anchor Member -> Start at the minimum invoice ID in the table
    SELECT MIN(invoice_id) AS expected_id 
    FROM invoices
    
    UNION ALL
    
    -- Step 2: Recursive Member -> Increment by 1 until reaching the maximum ID
    SELECT expected_id + 1
    FROM Sequence
    WHERE expected_id < (SELECT MAX(invoice_id) FROM invoices)
)
-- Step 3: Anti-Join the generated sequence against the actual table
SELECT 
    s.expected_id AS missing_invoice_id
FROM Sequence s
LEFT JOIN invoices i 
    ON s.expected_id = i.invoice_id
-- Filter for numbers that exist in our sequence, but have no matching invoice
WHERE i.invoice_id IS NULL
ORDER BY s.expected_id ASC;
```

---

## 📝 Explanation
- **The Core Challenge**: SQL cannot query records that don't exist. You cannot simply write a `WHERE` clause on the `invoices` table to find rows that are missing. Therefore, you must first *create* a virtual calendar or sequence containing every single expected number.
- **The Recursive Sequence**:
  - The **Anchor Member** finds the lowest number (`1001`) and seeds the CTE.
  - The **Recursive Member** continuously adds `1` in a loop (`1002`, `1003`, `1004`...), terminating the moment it hits the highest invoice number in the table (`1007`). This gives us a pristine, gapless sequence: `[1001, 1002, 1003, 1004, 1005, 1006, 1007]`.
- **The Anti-Join**:
  - We take that complete sequence (`Sequence s`) and `LEFT JOIN` it back to the real `invoices` table.
  - For rows that exist (like 1001 and 1002), the join succeeds.
  - For the missing numbers (`1003` and `1006`), the right side of the join evaluates to `NULL`.
- **`WHERE i.invoice_id IS NULL`**: This isolates the missing numbers, perfectly flagging the compliance gaps for the auditors.
