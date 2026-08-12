# Day 52: SQL Challenge - Data Cleaning (String Parsing & Domain Extraction)

## 📌 Business Scenario
A B2B (Business-to-Business) software company has a growing list of users who signed up for their free trial using their work emails. The sales team wants to prioritize outreach by identifying which companies have the most employees using the product.

To do this, they need a report that extracts the **email domain** (the part after the `@` symbol) from each user's email address, and then counts how many users belong to each domain.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Users Table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100)
);

-- Insert Sample Data
INSERT INTO users VALUES
(1, 'Alice Smith', 'alice.smith@acmecorp.com'),
(2, 'Bob Jones', 'bjones@acmecorp.com'),
(3, 'Charlie Ray', 'charlie.ray@techstart.io'),
(4, 'David Green', 'david@global.net'),
(5, 'Emma White', 'emma.w@acmecorp.com'),
(6, 'Frank Black', 'frankb@techstart.io');
```

---

## ❓ The Question
Write an SQL query to extract the domain from the `email` column for every user. Group the results by this extracted domain to count the number of users per company. 

Return the `email_domain` and `user_count`. Order the results by the `user_count` in descending order, and then alphabetically by `email_domain` in case of a tie.

---

## 💡 The Solution

### ANSI SQL Standard (PostgreSQL / MySQL)
```sql
SELECT 
    -- Extract everything starting 1 character after the '@' symbol
    SUBSTRING(email FROM POSITION('@' IN email) + 1) AS email_domain,
    COUNT(*) AS user_count
FROM users
GROUP BY 
    SUBSTRING(email FROM POSITION('@' IN email) + 1)
ORDER BY 
    user_count DESC, 
    email_domain ASC;
```

### SQL Server Alternative (using CHARINDEX)
```sql
SELECT 
    SUBSTRING(email, CHARINDEX('@', email) + 1, LEN(email)) AS email_domain,
    COUNT(*) AS user_count
FROM users
GROUP BY 
    SUBSTRING(email, CHARINDEX('@', email) + 1, LEN(email))
ORDER BY 
    user_count DESC, 
    email_domain ASC;
```

---

## 📝 Explanation
- **`POSITION('@' IN email)`**: This function scans the string and returns the integer index (1-based) where the `@` symbol is located. For `alice.smith@acmecorp.com`, the `@` is at position `12`.
- **`SUBSTRING()`**: We use the substring function to slice the email. By passing `POSITION('@' IN email) + 1` as the starting point, we tell the engine to start extracting exactly one character *after* the `@` symbol (skipping the `@` itself).
  - Since we omit the `FOR [length]` parameter in the ANSI standard version, it automatically extracts all remaining characters until the end of the string.
- **`GROUP BY`**: We group by the dynamically extracted domain string. This allows `COUNT(*)` to tally up the occurrences of each unique company domain, giving the sales team their target list!
