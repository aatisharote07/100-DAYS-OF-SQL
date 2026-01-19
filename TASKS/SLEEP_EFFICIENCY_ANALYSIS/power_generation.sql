-- Display those power stations which have average 'Monitored Cap.(MW)' (display the values) between 1000 and 2000 
-- and the number of occurance of the power stations (also display these values) are greater than 200.
-- Also sort the result in ascending order.

SELECT AVG(`Monitored Cap.(MW)`) AS "avg_mw", `Power Station`, COUNT(*) AS "Occurence"
FROM powergeneration
GROUP BY `Power Station`
HAVING avg_mw BETWEEN 1000 AND 2000 AND  Occurence > 200
ORDER BY avg_mw 