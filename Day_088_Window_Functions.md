# Day 88: SQL Challenge - Window Functions (Conditional Running Totals & Balance Ledger)

## 📌 Business Scenario
A fintech startup is building a personal banking dashboard. The core feature is a **transaction ledger** that shows the user's running account balance after every transaction.

Each transaction has a `type` — either `'CREDIT'` (money in) or `'DEBIT'` (money out). The system must chronologically process each transaction: adding credits to the running balance and subtracting debits from it.

This requires combining a `CASE` expression inside a cumulative `SUM()` window function — a pattern that appears in nearly every financial system.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Transactions Table
CREATE TABLE transactions (
    txn_id INT PRIMARY KEY,
    account_id INT,
    txn_date DATE,
    txn_type VARCHAR(10), -- 'CREDIT' or 'DEBIT'
    amount DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO transactions VALUES
(1, 101, '2026-10-01', 'CREDIT', 5000.00), -- Opening deposit
(2, 101, '2026-10-05', 'DEBIT',  1200.00), -- ATM withdrawal
(3, 101, '2026-10-10', 'CREDIT', 800.00),  -- Salary bonus
(4, 101, '2026-10-15', 'DEBIT',  2500.00), -- Rent payment
(5, 101, '2026-10-20', 'DEBIT',  300.00),  -- Grocery
(6, 102, '2026-10-01', 'CREDIT', 10000.00),-- Account 102 opening
(7, 102, '2026-10-12', 'DEBIT',  4500.00); -- Account 102 expense
```

---

## ❓ The Question
Write an SQL query to calculate the `running_balance` for each account after every transaction, processing them chronologically.

Credits should **add** to the balance, and debits should **subtract** from it. Use a single `SUM()` window function with a `CASE` expression to handle both directions in one pass.

Return `txn_id`, `account_id`, `txn_date`, `txn_type`, `amount`, and `running_balance`. Order by `account_id` and `txn_date`.

**Expected results for Account 101:**
| txn_id | txn_type | amount  | running_balance |
|--------|----------|---------|-----------------|
| 1      | CREDIT   | 5000.00 | 5000.00         |
| 2      | DEBIT    | 1200.00 | 3800.00         |
| 3      | CREDIT   | 800.00  | 4600.00         |
| 4      | DEBIT    | 2500.00 | 2100.00         |
| 5      | DEBIT    | 300.00  | 1800.00         |

---

## 💡 The Solution

```sql
SELECT 
    txn_id,
    account_id,
    txn_date,
    txn_type,
    amount,
    -- Conditional Running Total: Add credits, subtract debits
    SUM(
        CASE 
            WHEN txn_type = 'CREDIT' THEN amount
            WHEN txn_type = 'DEBIT'  THEN -amount
        END
    ) OVER (
        PARTITION BY account_id 
        ORDER BY txn_date, txn_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_balance
FROM transactions
ORDER BY account_id, txn_date, txn_id;
```

---

## 📝 Explanation

### The CASE-Inside-SUM Pattern
- The `CASE` expression transforms the raw `amount` into a **signed value** before it ever reaches the `SUM()` function:
  - A `CREDIT` of \$800 becomes `+800`.
  - A `DEBIT` of \$1200 becomes `-1200`.
- Once every amount has a proper sign, the cumulative `SUM()` naturally produces the correct running balance by simply adding up signed numbers.

### The Window Frame
- **`PARTITION BY account_id`**: Resets the running total for each account. Account 101's balance never bleeds into Account 102.
- **`ORDER BY txn_date, txn_id`**: Processes transactions chronologically. We include `txn_id` as a tiebreaker for multiple transactions on the same date, ensuring deterministic ordering.
- **`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`**: This is the explicit default frame for a cumulative sum. It tells the engine: *"Start from the very first row of the partition and accumulate through the current row."* While technically optional (it's the default when `ORDER BY` is specified), explicitly writing it is a best practice for clarity and to avoid subtle behavioral differences across SQL dialects.

### Why Not Two Separate Columns?
An alternative approach uses two separate running totals (`SUM(credits)` and `SUM(debits)`) and subtracts them. While functionally correct, the single-expression approach shown here is:
- **More concise**: One column instead of three.
- **More performant**: One window function scan instead of two or three.
- **Industry standard**: This exact pattern is used in general ledger systems, stock portfolio trackers, and inventory management platforms.
