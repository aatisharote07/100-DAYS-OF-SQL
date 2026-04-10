-- Problem 1
-- Display the names of athletes who won a gold medal in the 2008 Olympics and whose height is greater than the average height of all athletes in the 2008 Olympics.
SELECT * FROM olympics
WHERE Year = 2008 AND 
Medal = "Gold" AND 
Height > (SELECT AVG(Height) FROM olympics WHERE Year = 2008);
-- Problem 2
-- Display the names of athletes who won a medal in the sport of basketball in the 2016 Olympics and whose weight is less than the average weight of all athletes who won a medal in the 2016 Olympics.
SELECT * FROM olympics WHERE 
Medal IS NOT NULL AND 
Sport = "Basketball" AND 
Year = 2016 AND
Weight < (SELECT AVG(Weight) FROM olympics WHERE Year = 2016 AND Medal IS NOT NULL);
 
-- Problem 3
-- Display the names of all athletes who have won a medal in the sport of swimming in both the 2008 and 2016 Olympics.
SELECT * FROM olympics 
WHERE Sport = "Swimming" AND 
Medal IS NOT NULL AND
Year IN (2008,2016);
-- Problem 4
-- Display the names of all countries that have won more than 50 medals in a single year.
SELECT Year , Team, COUNT(*) FROM olympics
WHERE Medal IS NOT NULL AND Team IS NOT NULL
GROUP BY Year , Team  
HAVING COUNT(*)> 50
ORDER BY Year,Team;

-- Problem 5
-- Display the names of all athletes who have won medals in more than one sport in the same year.
SELECT DISTINCT name FROM olympics 
WHERE ID in (SELECT DISTINCT ID FROM olympics 
			 WHERE Medal IS NOT NULL 
             GROUP BY ID,Year,Sport
             HAVING COUNT(Medal) > 1
             ORDER BY COUNT(Medal) DESC);

-- Problem 6
-- What is the average weight difference between male and female athletes in the Olympics who have won a medal in the same event?
WITH result AS (
		SELECT * FROM olympics
        WHERE Medal IS NOT NULL
        )
SELECT AVG(A.Weight - B.Weight) FROM result A
JOIN result B
ON A.Event = B.Event AND
A.Sex != B.Sex


