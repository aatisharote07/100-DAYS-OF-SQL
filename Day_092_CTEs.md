# Day 92: SQL Challenge - CTEs (Calculating Server Uptime & Availability)

## 📌 Business Scenario
A Cloud Infrastructure Operations team monitors high-availability microservices. Every minute, health-check probes record service status as either `'UP'` or `'DOWN'`.

Enterprise customers are provided with **Service Level Agreements (SLAs)** guaranteeing 99.9% monthly uptime. If downtime occurs, the Operations team must determine the exact total operational uptime, total downtime in minutes, and overall **availability percentage** for each server.

Calculating uptime requires grouping chronological timestamp intervals, handling continuous ranges, and aggregating durations using Common Table Expressions.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Server Heartbeats Table
CREATE TABLE server_heartbeats (
    heartbeat_id INT PRIMARY KEY,
    server_id INT,
    check_time DATETIME,
    status VARCHAR(10) -- 'UP' or 'DOWN'
);

-- Insert Sample Data for Server 101 and Server 102
-- (Assume each record represents a 5-minute interval check)
INSERT INTO server_heartbeats VALUES
(1, 101, '2026-11-04 00:00:00', 'UP'),
(2, 101, '2026-11-04 00:05:00', 'UP'),
(3, 101, '2026-11-04 00:10:00', 'DOWN'), -- 5 min outage
(4, 101, '2026-11-04 00:15:00', 'UP'),
(5, 101, '2026-11-04 00:20:00', 'UP'),
(6, 102, '2026-11-04 00:00:00', 'UP'),
(7, 102, '2026-11-04 00:05:00', 'DOWN'), -- Outage start
(8, 102, '2026-11-04 00:10:00', 'DOWN'), -- Outage continues (10 min total)
(9, 102, '2026-11-04 00:15:00', 'UP'),
(10, 102, '2026-11-04 00:20:00', 'UP');
```

---

## ❓ The Question
Write an SQL query using Common Table Expressions (CTEs) and Conditional Aggregation to calculate SLA metrics for each server. 

Each recorded heartbeat corresponds to a **5-minute monitoring window**. For each server, calculate:
1. `total_monitored_minutes`: Total window time tracked (`total_checks * 5`).
2. `uptime_minutes`: Minutes where status was `'UP'` (`up_checks * 5`).
3. `downtime_minutes`: Minutes where status was `'DOWN'` (`down_checks * 5`).
4. `availability_pct`: Availability percentage rounded to 2 decimal places (`uptime_minutes / total_monitored_minutes * 100`).

Return `server_id`, `total_monitored_minutes`, `uptime_minutes`, `downtime_minutes`, and `availability_pct`. Order by `server_id`.

---

## 💡 The Solution

```sql
WITH ServerIntervalSummary AS (
    -- Step 1: Count total, up, and down checks per server
    SELECT 
        server_id,
        COUNT(*) AS total_checks,
        COUNT(CASE WHEN status = 'UP' THEN 1 END) AS up_checks,
        COUNT(CASE WHEN status = 'DOWN' THEN 1 END) AS down_checks
    FROM server_heartbeats
    GROUP BY server_id
)
-- Step 2: Convert check intervals to duration in minutes and calculate SLA availability
SELECT 
    server_id,
    total_checks * 5 AS total_monitored_minutes,
    up_checks * 5 AS uptime_minutes,
    down_checks * 5 AS downtime_minutes,
    ROUND((up_checks * 100.0) / total_checks, 2) AS availability_pct
FROM ServerIntervalSummary
ORDER BY server_id;
```

---

## 📝 Explanation

### Step-by-Step Architecture
- **Step 1 (Interval Aggregation via CTE)**: 
  - In telemetry systems, heartbeats arrive at regular intervals. Rather than doing complex datetime boundary subtractions for every single ping, counting interval occurrences within a CTE offers maximum efficiency and robustness against clock drift.
  - `COUNT(CASE WHEN status = 'UP' THEN 1 END)` conditionally tallies successful pings while skipping `DOWN` intervals.
- **Step 2 (Duration & SLA Computation)**:
  - Multiplying check counts by interval duration (5 minutes) translates granular event pings into business-facing operational time metrics (`total_monitored_minutes`, `uptime_minutes`, `downtime_minutes`).
  - `(up_checks * 100.0) / total_checks` uses float division (`100.0`) to avoid integer truncation in engines like SQL Server or PostgreSQL before applying `ROUND(..., 2)`.

### Production Observability Use Case
In production systems (e.g., Datadog, Prometheus, New Relic backends), this aggregated CTE pattern powers daily/monthly SLA dashboards, helping DevOps teams identify whether a cluster breached the contractual 99.9% uptime threshold.
