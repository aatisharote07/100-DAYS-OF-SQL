# Day 94: SQL Challenge - Data Cleaning (Masking PII & Sensitive Strings)

## 📌 Business Scenario
A healthcare compliance team is preparing a patient dataset for release to an external clinical research partner. In accordance with strict **HIPAA** and **GDPR** privacy regulations, all Personally Identifiable Information (PII) must be thoroughly masked or anonymized before data export.

Specifically, the export pipeline must sanitize two high-risk PII fields:
1. **Email Addresses**: Preserve the first character of the username, mask all remaining characters before the `@` symbol with asterisks (`****`), and retain the legitimate domain name (e.g., `johndoe@gmail.com` -> `j****@gmail.com`).
2. **Social Security Numbers (SSN)** / Government IDs: Mask the first 5 digits, displaying only the last 4 visible digits (e.g., `123-45-6789` -> `***-**-6789`).

Handling dynamic string lengths, delimiter parsing, and string manipulation using standard SQL functions is a staple requirement in data privacy engineering.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Patient Records Table
CREATE TABLE patient_records (
    patient_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    ssn VARCHAR(11) -- Format: XXX-XX-XXXX
);

-- Insert Sample Data
INSERT INTO patient_records VALUES
(1, 'Johnathan Doe', 'johndoe@gmail.com',    '123-45-6789'),
(2, 'Sarah Connor',  'sconnor@cyberdyne.org', '987-65-4321'),
(3, 'Alex Mercer',   'am@biotech.io',         '555-00-1122');
```

---

## ❓ The Question
Write an SQL query to sanitize the `patient_records` dataset for external compliance sharing.

Your query must:
1. Mask the `email` column so that only the first letter is preserved, followed by 4 asterisks (`'****'`), followed by the `@` symbol and the original domain name.
2. Mask the `ssn` column so that the leading 5 digits are replaced with `'***-**-'`, retaining only the final 4 digits.

Return `patient_id`, `full_name`, `masked_email`, and `masked_ssn`. Order by `patient_id`.

---

## 💡 The Solution

```sql
SELECT 
    patient_id,
    full_name,
    -- Email Masking: 1st char + '****@' + domain
    CONCAT(
        SUBSTRING(email, 1, 1),
        '****@',
        SUBSTRING(email, INSTR(email, '@') + 1)
    ) AS masked_email,
    -- SSN Masking: '***-**-' + last 4 characters
    CONCAT(
        '***-**-',
        RIGHT(ssn, 4)
    ) AS masked_ssn
FROM patient_records
ORDER BY patient_id;
```

*(Note for PostgreSQL / SQLite users: Replace `INSTR(email, '@')` with `POSITION('@' IN email)`, and `CONCAT(a, b)` can also be written using standard pipe concatenation `a || b`).*
*(Note for SQL Server users: Replace `INSTR(email, '@')` with `CHARINDEX('@', email)`).*

---

## 📝 Explanation

### String Parsing Mechanics for Privacy
- **Locating the Domain Boundary (`INSTR` / `POSITION` / `CHARINDEX`)**:
  - The `@` character denotes the boundary between the username and the domain. 
  - `INSTR(email, '@')` finds the 1-based index position of `@`.
  - Adding `+ 1` points to the start of the domain name.
- **Extracting Parts (`SUBSTRING`)**:
  - `SUBSTRING(email, 1, 1)` pulls only the initial letter of the email address.
  - `SUBSTRING(email, INSTR(email, '@') + 1)` slices from the character immediately after `@` to the end of the string, keeping the domain intact (`gmail.com`, `cyberdyne.org`, `biotech.io`).
- **SSN Slicing (`RIGHT`)**:
  - Because SSNs follow a standardized 11-character structure (`XXX-XX-XXXX`), using `RIGHT(ssn, 4)` reliably grabs the final 4 digits without needing variable-length searches.
- **Reconstruction (`CONCAT`)**:
  - Combines the masked components and prefixes into a single clean string, ensuring sensitive credentials cannot be reconstructed or leaked via research exports.
