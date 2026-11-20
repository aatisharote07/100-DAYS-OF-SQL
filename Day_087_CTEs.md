# Day 87: SQL Challenge - CTEs (Recursive Graph Traversal & Route Finding)

## 📌 Business Scenario
A flight aggregator platform needs to power its itinerary search engine. When a passenger searches for flights from **New York (`NYC`)** to **London (`LON`)**, the engine must find not only direct flights, but also multi-city connecting routes with up to **2 stops** (max 3 flight legs).

Graph traversal in SQL requires traversing directed edges (flight paths) while accumulating the total cost, tracking the journey breadcrumb trail, and preventing infinite loops (cycles) when flights run bidirectionally.

A **Recursive CTE with Cycle Prevention** is the industry-standard way to solve graph pathfinding directly inside the relational database.

---

## 🗄️ The Schema

### Table Structure & Sample Data

```sql
-- Create Flights Table
CREATE TABLE flights (
    flight_id INT PRIMARY KEY,
    origin VARCHAR(10),
    destination VARCHAR(10),
    price DECIMAL(10, 2)
);

-- Insert Sample Data
INSERT INTO flights VALUES
(1, 'NYC', 'LON', 800.00), -- Direct (0 stops)
(2, 'NYC', 'BOS', 100.00),
(3, 'BOS', 'LON', 500.00), -- NYC -> BOS -> LON: 1 stop ($600)
(4, 'NYC', 'DUB', 450.00),
(5, 'DUB', 'LON', 150.00), -- NYC -> DUB -> LON: 1 stop ($600)
(6, 'LON', 'NYC', 750.00), -- Return flight (potential cycle!)
(7, 'BOS', 'NYC', 90.00),  -- Return flight (potential cycle!)
(8, 'NYC', 'MIA', 200.00); -- Unrelated route
```

---

## ❓ The Question
Write an SQL query using a `WITH RECURSIVE` Common Table Expression to find all valid itineraries from `'NYC'` to `'LON'` with a maximum of **2 stops** (at most 3 flights).

Your query must:
1. Prevent infinite cycles (ensure a city is not revisited on the same itinerary).
2. Calculate the number of `stops` (`total_flights - 1`).
3. Calculate the `total_cost`.
4. Construct the full travel route as a string (e.g., `'NYC -> BOS -> LON'`).

Return `route`, `stops`, and `total_cost`. Order the results by `total_cost ASC`, then `stops ASC`.

---

## 💡 The Solution

*(Standard ANSI SQL / MySQL 8.0+ / PostgreSQL syntax)*

```sql
WITH RECURSIVE Itineraries AS (
    -- Step 1: Anchor Member -> Departures from NYC
    SELECT 
        origin,
        destination,
        price AS total_cost,
        0 AS stops,
        CAST(CONCAT(origin, ' -> ', destination) AS CHAR(200)) AS route,
        -- Track visited nodes to prevent cycles
        CAST(CONCAT(',', origin, ',', destination, ',') AS CHAR(200)) AS visited_cities
    FROM flights
    WHERE origin = 'NYC'
    
    UNION ALL
    
    -- Step 2: Recursive Member -> Expand connecting flights
    SELECT 
        f.origin,
        f.destination,
        i.total_cost + f.price,
        i.stops + 1,
        CAST(CONCAT(i.route, ' -> ', f.destination) AS CHAR(200)),
        CAST(CONCAT(i.visited_cities, f.destination, ',') AS CHAR(200))
    FROM flights f
    JOIN Itineraries i 
        ON f.origin = i.destination
    WHERE 
        -- Cycle Prevention: Ensure destination has not already been visited
        LOCATE(CONCAT(',', f.destination, ','), i.visited_cities) = 0
        -- Constraint: Max 2 stops (i.stops < 2 allows expanding to a 2nd stop)
        AND i.stops < 2
        -- Stop expanding once the target destination is reached
        AND i.destination != 'LON'
)
-- Step 3: Filter for itineraries that reached the final destination
SELECT 
    route,
    stops,
    total_cost
FROM Itineraries
WHERE destination = 'LON'
ORDER BY 
    total_cost ASC, 
    stops ASC;
```

*(For PostgreSQL: Replace `CONCAT(...)` with `||`, `LOCATE(sub, str) = 0` with `POSITION(sub IN str) = 0`, and `CHAR(200)` with `VARCHAR(200)`).*

---

## 📝 Explanation

### Graph Traversal Mechanics
- **The Graph Representation**: In relational modeling, the `flights` table acts as a collection of directed edges connecting city nodes. 
- **The Anchor**: Initiates all paths starting at `'NYC'`. It seeds each path with 0 stops, the initial flight cost, the route string `'NYC -> destination'`, and a comma-delimited `visited_cities` tracker (e.g., `',NYC,BOS,'`).
- **The Recursive Join**: Joins `flights f` on `f.origin = i.destination`. For each path currently ending at `'BOS'`, it inspects outbound flights from Boston and creates new extended path rows.

### Guarding Against Infinite Loops (Cycle Detection)
Because flights travel bidirectionally (NYC to BOS and BOS to NYC), naive recursion will loop infinitely between NYC and BOS until the database crashes with a recursion limit error.
- We maintain a delimiter-guarded trail: `visited_cities` (e.g., `',NYC,BOS,'`).
- In the recursive step, we verify `LOCATE(',LON,', visited_cities) = 0`. If Boston tries to route back to NYC, the check detects `,NYC,` is already in the string and kills that branch immediately.
- We also add `AND i.destination != 'LON'` so that once a path successfully lands in London, it doesn't continue taking passengers to other cities.
