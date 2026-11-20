# Day 57: SQL Challenge - Joins (Point-in-Time Joins for Slowly Changing Dimensions)

## 📌 Business Scenario
In data warehousing, prices change over time. When a database tracks historical changes (creating a new row for each price change rather than overwriting the old price), it is known as a **Slowly Changing Dimension (SCD) Type 2**.

A retail company needs to generate historical sales reports. When calculating the total revenue of a past sale, the query must look up the exact price of the product *at the time the sale occurred*, rather than just fetching the current active price.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Product Prices Table (SCD Type 2)
CREATE TABLE product_prices (
    product_id INT,
    price DECIMAL(10, 2),
    valid_from DATE,
    valid_to DATE -- NULL indicates this is the current active price
);

-- Create Sales Table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    sale_date DATE,
    quantity INT
);

-- Insert Sample Data
INSERT INTO product_prices VALUES
(101, 15.00, '2026-01-01', '2026-06-30'), -- Old Price
(101, 20.00, '2026-07-01', NULL),         -- Current Price
(102, 50.00, '2026-01-01', NULL);         -- Price has never changed

INSERT INTO sales VALUES
(1, 101, '2026-03-15', 2), -- Occurred during the old $15.00 price window
(2, 101, '2026-08-10', 1), -- Occurred during the new $20.00 price window
(3, 102, '2026-05-20', 3); -- Occurred during the $50.00 price window
```

---

## ❓ The Question
Write an SQL query using a Point-in-Time Join to calculate the correct total amount for each sale. 

Join the `sales` table to the `product_prices` table to find the historical price that was active on the `sale_date`. Then, multiply that price by the `quantity`. Return the `sale_id`, `sale_date`, `product_id`, the historical `price`, and the calculated `total_amount`. Order by `sale_id`.

---

## 💡 The Solution

```sql
SELECT 
    s.sale_id,
    s.sale_date,
    s.product_id,
    p.price AS historical_price,
    (s.quantity * p.price) AS total_amount
FROM sales s
JOIN product_prices p 
    ON s.product_id = p.product_id
    -- Point-in-Time logic: The sale must fall between the valid dates
    AND s.sale_date >= p.valid_from 
    AND (s.sale_date <= p.valid_to OR p.valid_to IS NULL)
ORDER BY s.sale_id;
```

---

## 📝 Explanation
- **Point-in-Time Join**: Instead of just joining on `product_id` (which would cause duplicates by joining Sale #1 to both the old and new prices of product 101), we add inequality conditions to the `ON` clause to check the date boundaries.
- **Handling `NULL` End Dates**: For the most recent (current) prices, the `valid_to` column is left as `NULL` because they haven't expired yet. 
  - Standard comparisons (`<= NULL`) yield `UNKNOWN` and fail the join condition. 
  - Therefore, we wrap the end-date check in parenthesis and add `OR p.valid_to IS NULL`. This allows modern sales (like Sale #2) to correctly match with the active, unexpired price row.
- **The Result**: Sale #1 correctly calculates its total using the historical `$15.00` price, while Sale #2 dynamically pulls the newer `$20.00` price.
