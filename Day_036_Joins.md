# Day 36: SQL Challenge - Joins (Last-Touch Attribution in Lookback Window)

## 📌 Business Scenario
A marketing analytics team wants to attribute customer purchases (conversions) to ad clicks using a **last-touch attribution model** with a **7-day lookback window**. 

A conversion is attributed to a specific ad campaign if:
1. The user clicked the ad on or before the conversion date.
2. The ad click happened within a maximum of 7 days prior to the conversion.
3. If the user clicked multiple ads within this 7-day window, the conversion is attributed to the **most recent click** (last-touch).

If no ad clicks occurred within the 7-day window, the purchase is labeled as `'No Ad Attribution'`.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Ad Clicks Table
CREATE TABLE ad_clicks (
    click_id INT PRIMARY KEY,
    user_id INT,
    ad_campaign VARCHAR(50),
    click_date DATE
);

-- Create Conversions Table
CREATE TABLE conversions (
    conversion_id INT PRIMARY KEY,
    user_id INT,
    amount DECIMAL(10, 2),
    conversion_date DATE
);

-- Insert Sample Data
INSERT INTO ad_clicks (click_id, user_id, ad_campaign, click_date) VALUES
(1, 101, 'Google Search', '2026-07-01'),
(2, 101, 'Facebook Ads', '2026-07-05'),  -- Attributed (Most recent click within 7 days of conversion)
(3, 102, 'Google Search', '2026-07-01'), -- Outside lookback window (11 days prior)
(4, 103, 'Instagram Promo', '2026-07-10'); -- Exact same day as conversion

INSERT INTO conversions (conversion_id, user_id, amount, conversion_date) VALUES
(501, 101, 150.00, '2026-07-07'), -- User 101: Conversion on Jul 7. Ad clicks on Jul 1 and Jul 5.
(502, 102, 300.00, '2026-07-12'), -- User 102: Conversion on Jul 12. Ad click on Jul 1.
(503, 103, 80.00, '2026-07-10'),  -- User 103: Conversion on Jul 10. Ad click on Jul 10.
(504, 104, 50.00, '2026-07-15');   -- User 104: Conversion on Jul 15. No ad clicks.
```

---

## ❓ The Question
Write an SQL query to retrieve all conversions and attribute each to the qualifying last-touch ad campaign. Return the `conversion_id`, `user_id`, `amount`, `conversion_date`, and the `attributed_campaign` (display `'No Ad Attribution'` if no qualifying click exists).

---

## 💡 The Solution

### MySQL Solution
```sql
WITH ClickAttribution AS (
    SELECT 
        c.conversion_id,
        c.user_id,
        c.amount,
        c.conversion_date,
        a.ad_campaign,
        -- Rank matched clicks by date descending to find the last-touch click
        ROW_NUMBER() OVER (
            PARTITION BY c.conversion_id 
            ORDER BY a.click_date DESC, a.click_id DESC
        ) AS rn
    FROM conversions c
    LEFT JOIN ad_clicks a ON c.user_id = a.user_id
                         AND a.click_date BETWEEN DATE_SUB(c.conversion_date, INTERVAL 7 DAY) 
                                              AND c.conversion_date
)
SELECT 
    conversion_id,
    user_id,
    amount,
    conversion_date,
    COALESCE(ad_campaign, 'No Ad Attribution') AS attributed_campaign
FROM ClickAttribution
WHERE rn = 1
ORDER BY conversion_id;
```

### PostgreSQL Solution
```sql
WITH ClickAttribution AS (
    SELECT 
        c.conversion_id,
        c.user_id,
        c.amount,
        c.conversion_date,
        a.ad_campaign,
        ROW_NUMBER() OVER (
            PARTITION BY c.conversion_id 
            ORDER BY a.click_date DESC, a.click_id DESC
        ) AS rn
    FROM conversions c
    LEFT JOIN ad_clicks a ON c.user_id = a.user_id
                         AND a.click_date BETWEEN (c.conversion_date - INTERVAL '7 days') 
                                              AND c.conversion_date
)
SELECT 
    conversion_id,
    user_id,
    amount,
    conversion_date,
    COALESCE(ad_campaign, 'No Ad Attribution') AS attributed_campaign
FROM ClickAttribution
WHERE rn = 1
ORDER BY conversion_id;
```

---

## 📝 Explanation
- **Date Range Left Join**: We use a `LEFT JOIN` starting from `conversions` to make sure we keep all purchases. We join on the conditions that the ad click belongs to the same user and occurs within the 7-day lookback window (`BETWEEN c.conversion_date - 7 days AND c.conversion_date`).
- **Last-Touch Deduplication**: If a user clicked multiple ads inside the window, the join yields duplicate rows for that conversion. The `ROW_NUMBER() OVER (PARTITION BY c.conversion_id ORDER BY a.click_date DESC)` assigns a rank of `1` to the most recent ad click.
- **Filtering & Coalescing**: Filtering `WHERE rn = 1` retains exactly one ad click per purchase. Any purchase that fails to join to any active clicks yields a campaign value of `NULL`. `COALESCE` replaces these nulls with `'No Ad Attribution'`.
