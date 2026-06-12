# Day 12: SQL Challenge - Data Cleaning (String Parsing & Standardization)

## 📌 Business Scenario
A marketing team imports sign-up leads from a third-party webinar platform. The input fields are notoriously messy: names and emails contain irregular spaces and mixed casings. To prepare this data for a customer analytics pipeline, we need to clean and standardize the fields, and parse the emails to extract the username and domain.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Raw Leads Table
CREATE TABLE raw_leads (
    lead_id INT PRIMARY KEY,
    raw_name VARCHAR(100),
    raw_email VARCHAR(100)
);

-- Insert Dirty Sample Data
INSERT INTO raw_leads (lead_id, raw_name, raw_email) VALUES
(1, '  alice SMITH  ', 'ALICE@GMAIL.COM'),
(2, 'bob jones', '   bob.j@Company.co.uk '),
(3, '  charlie Brown', 'CHARLIE.B@yahoo.com'),
(4, 'DAVID green   ', 'david.g@outlook.com'),
(5, ' emma WHITE ', 'EMMA@startup.io  ');
```

---

## ❓ The Question
Write an SQL query to clean the `raw_leads` dataset. The query should return:
1. `clean_name`: The `raw_name` trimmed of spaces and converted to lowercase.
2. `clean_email`: The `raw_email` trimmed of spaces and converted to lowercase.
3. `email_username`: The portion of the cleaned email preceding the `@` symbol.
4. `email_domain`: The portion of the cleaned email succeeding the `@` symbol.

---

## 💡 The Solution

```sql
SELECT 
    lead_id,
    TRIM(LOWER(raw_name)) AS clean_name,
    TRIM(LOWER(raw_email)) AS clean_email,
    SUBSTRING(TRIM(LOWER(raw_email)) FROM 1 FOR POSITION('@' IN TRIM(LOWER(raw_email))) - 1) AS email_username,
    SUBSTRING(TRIM(LOWER(raw_email)) FROM POSITION('@' IN TRIM(LOWER(raw_email))) + 1) AS email_domain
FROM raw_leads;
```

---

## 📝 Explanation
- **`TRIM` and `LOWER`**: Trims leading and trailing spaces and converts both fields to lowercase to enforce a consistent casing schema across all leads.
- **`POSITION('@' IN ...)`**: Locates the 1-based index position of the `@` symbol inside the email address string.
- **Username Extraction**: `SUBSTRING(email FROM 1 FOR position - 1)` extracts characters starting from index `1` up to the index right before the `@` symbol.
- **Domain Extraction**: `SUBSTRING(email FROM position + 1)` extracts all characters starting from one index past the `@` symbol through the remainder of the email string.
- **Portability**: The `POSITION()` and `SUBSTRING(... FROM ...)` syntax complies with standard SQL (ANSI SQL), making this query highly portable across PostgreSQL, MySQL, and other database engines.
