# Day 25: SQL Challenge - Data Cleaning (Phone Number Standardization via Regex)

## 📌 Business Scenario
A sales department imports contact leads into a CRM database. The phone numbers are input by users in varying formats containing parentheses, hyphens, periods, spaces, and international prefix plus signs. 

To connect the database to a standard SMS outreach system, all phone numbers must be standardized into the E.164 format. This requires stripping away all non-numeric characters and ensuring the US country code (`'1'`) is prepended to all 10-digit numbers.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Messy Contacts Table
CREATE TABLE contacts (
    contact_id INT PRIMARY KEY,
    contact_name VARCHAR(100),
    raw_phone VARCHAR(50)
);

-- Insert Sample Data
INSERT INTO contacts (contact_id, contact_name, raw_phone) VALUES
(1, 'Alice Smith', '+1 (555) 123-4567'),
(2, 'Bob Jones', '555-987-6543'),
(3, 'Charlie Brown', ' 555 321 0987 '),
(4, 'David Green', '15554567890'),
(5, 'Emma White', '555.222.1111');
```

---

## ❓ The Question
Write an SQL query to clean the `raw_phone` column. The query must:
1. Strip all non-numeric characters (hyphens, spaces, brackets, dots, plus signs).
2. Format the numbers such that if the clean digit string is exactly 10 digits, prepend the US country code `'1'`. If it is 11 digits and already starts with `'1'`, keep it. Flag any other length as `'Invalid Phone Format'`.
3. Return the `contact_id`, `contact_name`, `raw_phone`, and `cleaned_phone`.

---

## 💡 The Solution

### MySQL (8.0+) & PostgreSQL Solution
```sql
WITH NumericPhones AS (
    SELECT 
        contact_id,
        contact_name,
        raw_phone,
        -- Replace all non-digit characters with an empty string
        REGEXP_REPLACE(raw_phone, '[^0-9]', '') AS digits_only
    FROM contacts
)
SELECT 
    contact_id,
    contact_name,
    raw_phone,
    CASE 
        -- If it's a standard 10-digit US number, prepend country code '1'
        WHEN LENGTH(digits_only) = 10 THEN CONCAT('1', digits_only)
        -- If it's an 11-digit number starting with '1', it is already correct
        WHEN LENGTH(digits_only) = 11 AND digits_only LIKE '1%' THEN digits_only
        -- Flag any other length/pattern as invalid
        ELSE 'Invalid Phone Format'
    END AS cleaned_phone
FROM NumericPhones;
```

---

## 📝 Explanation
- **Regex Filtering via `REGEXP_REPLACE`**: The regular expression `[^0-9]` matches any character that is **not** a digit from 0 to 9. By replacing these matches with an empty string `''`, we strip away all spaces, dots, hyphens, parentheses, and plus signs.
- **Conditional Formatting (`CASE WHEN`)**: The outer query evaluates the sanitized digit string. 
  - If its length is exactly `10`, we prepend `'1'` using `CONCAT()`.
  - If the length is `11` and begins with `'1'` (checked via `LIKE '1%'`), it is already in E.164 format and we return it unchanged.
  - Any other length indicates missing or extra digits, which we flag as an `'Invalid Phone Format'`.
- **Performance/Index Note**: Regex operations can be CPU-intensive. In large-scale production pipelines, it is best practice to run this cleaning logic during the ETL/ingestion phase rather than executing it dynamically on every query scan.
