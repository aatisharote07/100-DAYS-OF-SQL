# Day 5: SQL Challenge - Aggregate Functions (Conditional Aggregation)

## 📌 Business Scenario
A SaaS startup needs to build an executive dashboard to monitor subscription performance across different pricing tiers. The finance team requires metrics detailing active memberships, cancellations, Monthly Recurring Revenue (MRR) from active accounts, and plan-level customer churn rates.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Subscriptions Table
CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY,
    customer_id INT,
    plan_type VARCHAR(50),
    monthly_price DECIMAL(10, 2),
    status VARCHAR(20), -- 'active' or 'canceled'
    start_date DATE
);

-- Insert Sample Data
INSERT INTO subscriptions (subscription_id, customer_id, plan_type, monthly_price, status, start_date) VALUES
(1, 101, 'Basic', 9.99, 'active', '2026-01-10'),
(2, 102, 'Pro', 29.99, 'active', '2026-01-15'),
(3, 103, 'Pro', 29.99, 'canceled', '2026-01-20'),
(4, 104, 'Enterprise', 199.99, 'active', '2026-02-01'),
(5, 105, 'Basic', 9.99, 'canceled', '2026-02-10'),
(6, 106, 'Pro', 29.99, 'active', '2026-02-15'),
(7, 107, 'Basic', 9.99, 'active', '2026-03-01'),
(8, 108, 'Enterprise', 199.99, 'canceled', '2026-03-05'),
(9, 109, 'Enterprise', 199.99, 'active', '2026-03-12'),
(10, 110, 'Pro', 29.99, 'active', '2026-03-20');
```

---

## ❓ The Question
Write an SQL query to retrieve the following metrics for each `plan_type`:
1. Total number of subscriptions.
2. Total number of active subscriptions.
3. Total number of canceled subscriptions.
4. Total Monthly Recurring Revenue (MRR) from active subscriptions.
5. Churn rate percentage (calculated as `canceled / total * 100` rounded to 2 decimal places).

---

## 💡 The Solution

```sql
SELECT 
    plan_type,
    COUNT(subscription_id) AS total_subscriptions,
    COUNT(CASE WHEN status = 'active' THEN 1 END) AS active_subscriptions,
    COUNT(CASE WHEN status = 'canceled' THEN 1 END) AS canceled_subscriptions,
    SUM(CASE WHEN status = 'active' THEN monthly_price ELSE 0 END) AS active_mrr,
    ROUND(
        COUNT(CASE WHEN status = 'canceled' THEN 1 END) * 100.0 / COUNT(subscription_id),
        2
    ) AS churn_rate_pct
FROM subscriptions
GROUP BY plan_type;
```

---

## 📝 Explanation
- **Conditional Count**: Using `CASE WHEN status = 'active' THEN 1 END` inside the `COUNT` function evaluates to `1` when the condition is met and `NULL` otherwise. Since SQL aggregate functions like `COUNT` ignore `NULL` values, this yields the correct filtered count for each status.
- **Conditional Sum**: The `SUM(CASE WHEN status = 'active' THEN monthly_price ELSE 0 END)` expression sums the monthly price only when the subscription status is active, giving us the current active MRR.
- **Churn Rate**: The percentage is derived by dividing the count of canceled subscriptions by the total count. Multiplying by `100.0` ensures the database engine performs floating-point division instead of integer division, which is then rounded to two decimal places.
