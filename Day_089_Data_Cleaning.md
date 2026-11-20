# Day 89: SQL Challenge - Data Cleaning (Deduplication with Row Selection Strategy)

## 📌 Business Scenario
A healthcare analytics platform ingests patient appointment records from multiple hospital systems via a nightly ETL pipeline. Due to integration issues, duplicate records frequently appear — the same patient with the same doctor on the same date gets inserted multiple times, sometimes with slightly different `notes` or `created_at` timestamps.

Before loading the data into the analytics warehouse, the data engineering team must deduplicate the records. Their business rule is simple: **Keep only the most recently created record** for each unique combination of `patient_id`, `doctor_id`, and `appointment_date`. All other duplicates must be removed from the query result.

This pattern — ranking duplicates and keeping only one — is the most commonly used deduplication technique in production SQL pipelines.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Appointments Table (Contains Duplicates)
CREATE TABLE appointments (
    record_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    appointment_date DATE,
    notes VARCHAR(200),
    created_at DATETIME
);

-- Insert Sample Data
INSERT INTO appointments VALUES
(1, 201, 301, '2026-10-15', 'Initial checkup',       '2026-10-15 08:00:00'),
(2, 201, 301, '2026-10-15', 'Initial checkup (v2)',   '2026-10-15 09:30:00'), -- Duplicate, newer
(3, 201, 301, '2026-10-15', 'Initial checkup (v3)',   '2026-10-15 11:00:00'), -- Duplicate, newest (KEEP)
(4, 201, 302, '2026-10-16', 'Follow-up with Dr. Lee', '2026-10-16 14:00:00'), -- Unique (KEEP)
(5, 202, 301, '2026-10-15', 'Blood work review',      '2026-10-15 10:00:00'), -- Unique (KEEP)
(6, 202, 301, '2026-10-15', 'Blood work review (dup)','2026-10-15 12:00:00'); -- Duplicate, newer (KEEP)
```

---

## ❓ The Question
Write an SQL query to deduplicate the `appointments` table. For each unique combination of `(patient_id, doctor_id, appointment_date)`, keep only the record with the **latest `created_at` timestamp**.

Return all columns: `record_id`, `patient_id`, `doctor_id`, `appointment_date`, `notes`, and `created_at`. Order the results by `record_id`.

---

## 💡 The Solution

```sql
WITH RankedAppointments AS (
    SELECT 
        record_id,
        patient_id,
        doctor_id,
        appointment_date,
        notes,
        created_at,
        ROW_NUMBER() OVER (
            PARTITION BY patient_id, doctor_id, appointment_date
            ORDER BY created_at DESC
        ) AS rn
    FROM appointments
)
SELECT 
    record_id,
    patient_id,
    doctor_id,
    appointment_date,
    notes,
    created_at
FROM RankedAppointments
WHERE rn = 1
ORDER BY record_id;
```

---

## 📝 Explanation

### The Deduplication Pattern (Rank-and-Filter)
This is arguably the single most important pattern in data engineering SQL:

1. **Define the Duplicate Key (`PARTITION BY`)**: We partition by `(patient_id, doctor_id, appointment_date)`. This tells the engine: *"Any rows that share all three of these values are considered duplicates of each other."*

2. **Define the Selection Strategy (`ORDER BY`)**: Within each group of duplicates, we order by `created_at DESC`. This puts the most recently ingested record first, assigning it `ROW_NUMBER() = 1`.

3. **Filter (`WHERE rn = 1`)**: We discard every row except the winner (`rn = 1`) from each group.

### Why `ROW_NUMBER()` and Not `RANK()` or `DENSE_RANK()`?
- **`ROW_NUMBER()`**: Always assigns strictly unique sequential numbers (1, 2, 3...). Even if two duplicates have the exact same `created_at` timestamp, one gets `1` and the other gets `2`. This **guarantees exactly one survivor per group** — critical for deduplication.
- **`RANK()` / `DENSE_RANK()`**: If two rows tie on `created_at`, both receive rank `1`. Filtering `WHERE rn = 1` would keep *both* ties, defeating the purpose of deduplication.

### Production Considerations
- **DELETE variant**: In production ETL, this pattern is often used with a `DELETE` statement instead of a `SELECT` to physically remove duplicates:
  ```sql
  DELETE FROM appointments 
  WHERE record_id NOT IN (
      SELECT record_id FROM RankedAppointments WHERE rn = 1
  );
  ```
- **Idempotency**: Running this deduplication query multiple times produces the same result — a critical property for reliable data pipelines.
