# Day 84: SQL Challenge - Joins (Non-Equi Joins & Tiered Commission)

## 📌 Business Scenario
A B2B enterprise software company pays its sales reps tiered commissions based on deal size. Instead of a single flat rate, the commission percentage scales according to specific bracket thresholds:

- **Bronze**: \$0 to \$10,000 -> 5% commission
- **Silver**: \$10,000.01 to \$50,000 -> 8% commission
- **Gold**: \$50,000.01 to \$100,000 -> 12% commission
- **Platinum**: \$100,000.01 and above -> 15% commission (open-ended upper limit)

Most developers are accustomed to **Equi-Joins** (`ON table_a.id = table_b.id`). However, financial brackets, tax slabs, and pricing rules rarely match on exact IDs. Instead, they require a **Non-Equi Join** using inequality operators (`>=`, `<`, `BETWEEN`) and careful handling of open-ended ranges (`NULL` upper bounds).

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Deals Table
CREATE TABLE deals (
    deal_id INT PRIMARY KEY,
    sales_rep VARCHAR(50),
    deal_amount DECIMAL(10, 2)
);

-- Create Commission Tiers Lookup Table
CREATE TABLE commission_tiers (
    tier_id INT PRIMARY KEY,
    tier_name VARCHAR(50),
    min_amount DECIMAL(10, 2),
    max_amount DECIMAL(10, 2), -- NULL represents no upper limit
    commission_rate DECIMAL(4, 2)
);

-- Insert Sample Data
INSERT INTO deals VALUES
(1, 'Sarah', 8500.00),    -- Falls in Bronze (5%)
(2, 'Sarah', 45000.00),   -- Falls in Silver (8%)
(3, 'Alex', 75000.00),    -- Falls in Gold (12%)
(4, 'Alex', 150000.00);   -- Falls in Platinum (15%, unbounded upper)

INSERT INTO commission_tiers VALUES
(1, 'Bronze',   0.00,      10000.00,  0.05),
(2, 'Silver',   10000.01,  50000.00,  0.08),
(3, 'Gold',     50000.01,  100000.00, 0.12),
(4, 'Platinum', 100000.01, NULL,      0.15);
```

---

## ❓ The Question
Write an SQL query using a **Non-Equi Join** to match each deal to its appropriate commission tier.

Calculate the `commission_earned` (`deal_amount * commission_rate`) rounded to 2 decimal places. Ensure your join logic properly matches deals in the top tier where `max_amount` is `NULL`.

Return `deal_id`, `sales_rep`, `deal_amount`, `tier_name`, and `commission_earned`. Order by `deal_id`.

---

## 💡 The Solution

```sql
SELECT 
    d.deal_id,
    d.sales_rep,
    d.deal_amount,
    t.tier_name,
    ROUND(d.deal_amount * t.commission_rate, 2) AS commission_earned
FROM deals d
-- Non-Equi Join condition matching amount to tier range
JOIN commission_tiers t 
    ON d.deal_amount >= t.min_amount 
    AND (d.deal_amount <= t.max_amount OR t.max_amount IS NULL)
ORDER BY d.deal_id;
```

---

## 📝 Explanation
- **What is a Non-Equi Join?**: Any join that uses operators other than equality (`=`) in its `ON` clause—such as `<`, `>`, `<=`, `>=`, `!=`, or `BETWEEN`—is a Non-Equi Join. They are ubiquitous in finance, billing, logistics, and rating systems.
- **Why not `BETWEEN`?**: 
  - Standard `BETWEEN min AND max` works cleanly for bounded ranges, but fails when the upper bracket is unbounded (`NULL`). 
  - In SQL, `deal_amount <= NULL` evaluates to `UNKNOWN`, which silently discards high-value deals like the \$150,000 Platinum deal!
- **Handling Unbounded Upper Limits**:
  - By writing `(d.deal_amount <= t.max_amount OR t.max_amount IS NULL)`, we explicitly instruct the query optimizer to match the row if it's within the closed bracket OR if that bracket is open-ended.
- **Performance Consideration**: Non-Equi joins typically perform a nested loop or range index scan rather than a hash join. Ensuring an index exists on `(min_amount, max_amount)` ensures high throughput on massive transaction tables.
