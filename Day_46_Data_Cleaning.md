# Day 46: SQL Challenge - Data Cleaning (Extracting JSON Data)

## 📌 Business Scenario
A modern SaaS platform uses a relational database to store user accounts but utilizes a single JSON column named `preferences` to store flexible, evolving user settings (such as UI themes, notification toggles, and language). 

The data science team needs to build a structured dashboard analyzing these preferences. To do this, they need a query that unpacks the nested JSON keys into standard, relational SQL columns.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create User Profiles Table
CREATE TABLE user_profiles (
    user_id INT PRIMARY KEY,
    username VARCHAR(50),
    preferences JSON
);

-- Insert Sample Data
INSERT INTO user_profiles VALUES
(1, 'alice_99', '{"theme": "dark", "language": "en", "email_alerts": true}'),
(2, 'bob_builder', '{"theme": "light", "language": "fr", "email_alerts": false}'),
(3, 'charlie_x', '{"theme": "dark", "language": "es", "email_alerts": true}'),
-- David hasn't set a language or email_alerts preference yet
(4, 'david_data', '{"theme": "system"}'); 
```

---

## ❓ The Question
Write an SQL query to extract the `theme`, `language`, and `email_alerts` settings from the JSON column into their own dedicated columns. If a key does not exist in a user's JSON object, it should gracefully return `NULL`. 

Return the `user_id`, `username`, `theme`, `language`, and `email_alerts`.

---

## 💡 The Solution

### MySQL Solution (Using the `->>` Operator)
```sql
SELECT 
    user_id,
    username,
    -- Extract JSON values as unquoted text
    preferences->>'$.theme' AS theme,
    preferences->>'$.language' AS language,
    -- Extract and cast boolean/numeric types
    preferences->>'$.email_alerts' = 'true' AS email_alerts
FROM user_profiles;

/* Note: You can also use the verbose function: 
   JSON_UNQUOTE(JSON_EXTRACT(preferences, '$.theme')) 
*/
```

### PostgreSQL Solution (Using the `->>` Operator)
```sql
SELECT 
    user_id,
    username,
    -- Postgres JSON path doesn't require the '$.' prefix for root keys
    preferences->>'theme' AS theme,
    preferences->>'language' AS language,
    -- Cast extracted string to boolean
    CAST(preferences->>'email_alerts' AS BOOLEAN) AS email_alerts
FROM user_profiles;
```

---

## 📝 Explanation
- **JSON Operators (`->` vs `->>`)**: 
  - The `->` operator extracts a JSON object or array. It keeps the data in a JSON format (strings will still be wrapped in double quotes like `"dark"`).
  - The `->>` operator extracts the JSON value as raw, unquoted text (`dark`). This is almost always what you want when flattening JSON into standard SQL columns.
- **Handling Missing Keys**: One of the benefits of JSON extraction functions in SQL is that they are null-safe. When we query `david_data` for his `language`, the engine simply returns `NULL` rather than throwing an error for a missing key.
- **Type Casting**: Because `->>` returns text, Boolean values like `true` or numbers are extracted as strings (e.g., `'true'`). In MySQL, comparing the string to `'true'` parses it to a `1/0` tinyint. In PostgreSQL, casting the extracted text to `BOOLEAN` parses it natively.
