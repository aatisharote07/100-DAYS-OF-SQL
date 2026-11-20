# Day 10: SQL Challenge - CTEs (Multi-Stage Funnel Analysis)

## 📌 Business Scenario
A marketing team wants to analyze the conversion funnel for the website. The conversion funnel contains three distinct steps:
1. User visited the website (`session_created`)
2. User added an item to their shopping cart (`added_to_cart`)
3. User successfully completed the purchase (`purchase_completed`)

To optimize product flows, we must calculate the absolute number of unique users at each stage and the relative conversion drop-off rates between stages.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create User Events Table
CREATE TABLE user_events (
    event_id INT PRIMARY KEY,
    user_id INT,
    event_name VARCHAR(50), -- 'session_created', 'added_to_cart', 'purchase_completed'
    event_timestamp TIMESTAMP
);

-- Insert Sample Data
INSERT INTO user_events (event_id, user_id, event_name, event_timestamp) VALUES
(1, 101, 'session_created', '2026-05-01 10:00:00'),
(2, 101, 'added_to_cart', '2026-05-01 10:05:00'),
(3, 101, 'purchase_completed', '2026-05-01 10:15:00'),
(4, 102, 'session_created', '2026-05-01 11:00:00'),
(5, 102, 'added_to_cart', '2026-05-01 11:10:00'),
(6, 103, 'session_created', '2026-05-02 09:00:00'),
(7, 104, 'session_created', '2026-05-02 12:00:00'),
(8, 104, 'added_to_cart', '2026-05-02 12:30:00'),
(9, 104, 'purchase_completed', '2026-05-02 12:45:00'),
(10, 105, 'session_created', '2026-05-03 14:00:00');
```

---

## ❓ The Question
Write an SQL query using a Common Table Expression (CTE) to calculate:
1. The number of unique users at each funnel stage (`visits`, `carts`, `purchases`).
2. The percentage of users who progressed from a visit to a cart (`visit_to_cart_pct`).
3. The percentage of users who progressed from a cart to a purchase (`cart_to_purchase_pct`).

---

## 💡 The Solution

```sql
WITH FunnelStages AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_name = 'session_created' THEN user_id END) AS visits,
        COUNT(DISTINCT CASE WHEN event_name = 'added_to_cart' THEN user_id END) AS carts,
        COUNT(DISTINCT CASE WHEN event_name = 'purchase_completed' THEN user_id END) AS purchases
    FROM user_events
)
SELECT 
    visits,
    carts,
    purchases,
    ROUND(carts * 100.0 / NULLIF(visits, 0), 2) AS visit_to_cart_pct,
    ROUND(purchases * 100.0 / NULLIF(carts, 0), 2) AS cart_to_purchase_pct
FROM FunnelStages;
```

---

## 📝 Explanation
- **`FunnelStages` CTE**: This CTE isolates and counts the unique users at each point in the funnel. Using `COUNT(DISTINCT CASE WHEN event_name = '...' THEN user_id END)` ensures that duplicate user actions within the same step are only counted once, reflecting true unique customer progressions.
- **Conversion Calculations**: The main query computes the percentages. The transition conversion from visit to cart is calculated as `carts / visits * 100`, and the transition from cart to purchase is calculated as `purchases / carts * 100`.
- **Division-by-Zero Safety**: We wrap denominators with `NULLIF(..., 0)`. If a stage has zero users (e.g., `visits` is `0`), `NULLIF` returns `NULL`. Division by `NULL` safely results in `NULL` rather than crashing the database engine with a division-by-zero exception.
