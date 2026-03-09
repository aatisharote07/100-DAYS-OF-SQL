-- 1. Find the month with most number of flights
SELECT MONTHNAME(date_of_journey),COUNT(*)
FROM flights 
GROUP BY MONTHNAME(date_of_journey)
ORDER BY COUNT(*) DESC LIMIT 1;

-- 2. Which week day has most costly flights
SELECT DAYNAME(date_of_journey),AVG(price) FROM flights
GROUP BY DAYNAME(date_of_journey)
ORDER BY AVG(price) DESC LIMIT 1;

-- 3. Find number of indigo flights every month
SELECT MONTHNAME(date_of_journey),COUNT(*) FROM flights
WHERE airline = "Indigo"
GROUP BY MONTHNAME(date_of_journey),MONTH(date_of_journey)		
ORDER BY MONTH(date_of_journey) ASC;

-- 4. Find list of all flights that depart between 10AM and 2PM from Banglore to
-- Delhi
SELECT * FROM flights 
WHERE source = "Banglore" AND destination = "Delhi"	AND
dep_time BETWEEN "10:00:00" AND "14:00:00";

-- 5. Find the number of flights departing on weekends from Bangalore
SELECT COUNT(*) FROM flights
WHERE source = "Banglore" 
AND DAYNAME(date_of_journey) IN
("Saturday","Sunday","Friday");

-- 6. Calculate the arrival time for all flights by adding the duration to the departure
-- time.
ALTER TABLE flights ADD COLUMN departure DATETIME;
UPDATE flights
SET departure = TIMESTAMP(date_of_journey, dep_time);
ALTER TABLE flights 
ADD COLUMN duration_mins INTEGER,
ADD COLUMN arrival DATETIME;

SELECT Duration,
SUBSTRING_INDEX(duration," ",1),
CASE 
    WHEN SUBSTRING_INDEX(duration," ",-1) = SUBSTRING_INDEX(duration," ",1) THEN 0
	ELSE SUBSTRING_INDEX(duration," ",-1) 
END AS "mins"
FROM flights;

ALTER TABLE flights
DROP COLUMN duration_mins;
UPDATE flights
SET arrival = DATE_ADD(departure,INTERVAL Duration MINUTE);

SELECT TIME(arrival) FROM flights;	
		
-- 7. Calculate the arrival date for all the flights
SELECT DATE(arrival) FROM flights;


-- 8. Find the number of flights which travel on multiple dates.
SELECT COUNT(*) FROm flights
WHERE DATE(departure) != DATE(arrival);

-- 9. Calculate the average duration of flights between all city pairs. The answer
-- should In xh ym format
SELECT source,destination,AVG(Duration) FROM flights
GROUP BY source,destination
