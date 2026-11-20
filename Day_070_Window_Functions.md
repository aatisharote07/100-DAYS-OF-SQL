# Day 70: SQL Challenge - Window Functions (Inventory Allocation & FIFO)

## 📌 Business Scenario
🎉 **Happy Day 70!** 🎉

An e-commerce warehouse uses a First-In-First-Out (FIFO) allocation method. They currently have exactly **100 units** of a highly anticipated new gadget in stock. 

Several customer orders have arrived over the course of the day. The fulfillment team needs a report that evaluates the incoming orders chronologically, calculates the running total of requested units, and explicitly flags which orders can be fully fulfilled, which order drains the last of the inventory (partial fulfillment), and which orders will be placed on backorder.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Orders Table
CREATE TABLE customer_orders (
    order_id INT PRIMARY KEY,
    order_time DATETIME,
    requested_qty INT
);

-- Insert Sample Data
-- Total Inventory Available: 100 units
INSERT INTO customer_orders VALUES
(1, '2026-09-11 09:00:00', 40), -- Running total: 40 (Fulfilled)
(2, '2026-09-11 09:30:00', 50), -- Running total: 90 (Fulfilled)
(3, '2026-09-11 10:15:00', 30), -- Running total: 120 (Only 10 left -> Partially Fulfilled!)
(4, '2026-09-11 11:00:00', 20); -- Running total: 140 (0 left -> Out of Stock)
```

---

## ❓ The Question
Write an SQL query using a Window Function to calculate the cumulative running total of requested units. 

Then, assuming a starting inventory of `100`, use a `CASE` statement to assign a `fulfillment_status` to each order based on the FIFO rules:
- `'Fulfilled'`: Inventory can cover the entire order.
- `'Partially Fulfilled'`: Inventory can cover *some* of the order, but hits exactly 0 during this order.
- `'Out of Stock'`: Inventory was already at 0 before this order even arrived.

Return `order_id`, `requested_qty`, `cumulative_qty`, and `fulfillment_status`. Order chronologically.

---

## 💡 The Solution

```sql
WITH RunningTotals AS (
    -- Step 1: Calculate the cumulative sum of requested quantities chronologically
    SELECT 
        order_id,
        order_time,
        requested_qty,
        SUM(requested_qty) OVER (
            ORDER BY order_time
        ) AS cumulative_qty
    FROM customer_orders
)
-- Step 2: Evaluate the cumulative sum against the hardcoded inventory limit of 100
SELECT 
    order_id,
    requested_qty,
    cumulative_qty,
    CASE 
        -- If the running total is under the limit, we have plenty of stock.
        WHEN cumulative_qty <= 100 THEN 'Fulfilled'
        
        -- If the running total exceeded the limit, BUT the running total 
        -- BEFORE this order was under the limit, this is the breaking point.
        WHEN (cumulative_qty - requested_qty) < 100 THEN 'Partially Fulfilled'
        
        -- Otherwise, the limit was breached by a previous order.
        ELSE 'Out of Stock'
    END AS fulfillment_status
FROM RunningTotals
ORDER BY order_time;
```

---

## 📝 Explanation
- **`SUM() OVER(ORDER BY...)`**: This is the classic syntax for a cumulative running total. By ordering by `order_time`, row 1 evaluates to 40. Row 2 evaluates to 40 + 50 (90). Row 3 evaluates to 90 + 30 (120).
- **The CTE Necessity**: Window functions cannot be directly referenced inside a `CASE` statement in the same `SELECT` block because of SQL's execution order. We must calculate the `cumulative_qty` in a CTE first.
- **The `CASE` Logic**:
  - Order 1 (Total 40) and Order 2 (Total 90) easily pass the first condition (`<= 100`).
  - Order 3 (Total 120) fails the first condition. It moves to the second condition: `(120 - 30) < 100`. Because 90 is less than 100, we know the warehouse *did* have some stock when this order arrived, but this specific order emptied the warehouse. It is marked as `Partially Fulfilled`.
  - Order 4 (Total 140) fails the first condition. It moves to the second condition: `(140 - 20) < 100`. Because 120 is *not* less than 100, we know the warehouse was entirely empty before Order 4 even began processing. It is marked `Out of Stock`.
