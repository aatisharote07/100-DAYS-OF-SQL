# Day 19: SQL Challenge - Data Cleaning (Standardizing Messy Date Inputs)

## 📌 Business Scenario
A data engineer is integrating customer sign-up data from two different marketing platforms. In the raw consolidated database, the sign-up date was imported as a text string (`signup_date_str`) and contains two distinct formats depending on which platform the lead originated from:
1. `'YYYY/MM/DD'` (e.g., `'2026/05/15'`)
2. `'DD-MM-YYYY'` (e.g., `'20-06-2026'`)

We need to parse this string column and standardize it into a true SQL `DATE` data type so it can be sorted, filtered, and used in downstream analytics.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Raw Signups Table
CREATE TABLE raw_signups (
    user_id INT PRIMARY KEY,
    signup_date_str VARCHAR(20)
);

-- Insert Sample Data (mixed date string formats)
INSERT INTO raw_signups (user_id, signup_date_str) VALUES
(1, '2026/05/15'), -- YYYY/MM/DD
(2, '20-06-2026'), -- DD-MM-YYYY
(3, '2026/05/18'), -- YYYY/MM/DD
(4, '01-07-2026'), -- DD-MM-YYYY
(5, '2026/04/30'); -- YYYY/MM/DD
```

---

## ❓ The Question
Write an SQL query to parse the `signup_date_str` column and output it as a standardized `DATE` type column named `clean_signup_date`. Use conditional logic (`CASE WHEN`) and date parsing functions to handle both formats.

---

## 💡 The Solution

### MySQL Solution
```sql
SELECT 
    user_id,
    signup_date_str,
    CASE 
        -- Matches 'YYYY/MM/DD' pattern (4 digits, slash, 2 digits, slash, 2 digits)
        WHEN signup_date_str LIKE '____/__/__' THEN STR_TO_DATE(signup_date_str, '%Y/%m/%d')
        -- Matches 'DD-MM-YYYY' pattern (2 digits, dash, 2 digits, dash, 4 digits)
        WHEN signup_date_str LIKE '__-__-____' THEN STR_TO_DATE(signup_date_str, '%d-%m-%Y')
        ELSE NULL
    END AS clean_signup_date
FROM raw_signups;
```

### PostgreSQL Solution
```sql
SELECT 
    user_id,
    signup_date_str,
    CASE 
        -- Matches 'YYYY/MM/DD' pattern
        WHEN signup_date_str LIKE '____/__/__' THEN TO_DATE(signup_date_str, 'YYYY/MM/DD')
        -- Matches 'DD-MM-YYYY' pattern
        WHEN signup_date_str LIKE '__-__-____' THEN TO_DATE(signup_date_str, 'DD-MM-YYYY')
        ELSE NULL
    END AS clean_signup_date
FROM raw_signups;
```

---

## 📝 Explanation
- **`LIKE` Pattern Matching**: The query uses the underscore wildcard (`_`) in the `LIKE` expression, which represents exactly one character. `'____/__/__'` matches any string consisting of 4 characters, a slash, 2 characters, another slash, and 2 characters.
- **Conditional Routing (`CASE WHEN`)**: The `CASE` statement evaluates the string format for each row and routes it to the appropriate date-parsing function.
- **Date Casting (`STR_TO_DATE` / `TO_DATE`)**: These functions convert string inputs into true database `DATE` objects based on the layout formats provided (e.g., `%Y/%m/%d` or `YYYY/MM/DD`). Correctly casting text into native dates is essential to perform date-range queries or date math.
