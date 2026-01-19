-- Find top 5 batsmen in IPL
SELECT batter, SUM(batsman_run) AS "runs"FROM ipl
GROUP BY batter 
ORDER BY runs DESC LIMIT 5;

-- Find the 2nd highest 6 hitter in ipl
SELECT batter,COUNT(*) AS "num_sixes"
FROM cricket.ipl
WHERE batsman_run = 6
GROUP BY batter 
ORDER BY num_sixes DESC LIMIT 1,1;

-- Top 10 batsmen with centuries in IPL
SELECT batter, ID, SUM(batsman_run) AS "score"
FROM cricket.ipl 
GROUP BY batter, ID 
HAVING score >= 100
ORDER BY score DESC LIMIT 10;

-- Find the top 5 batsman with highest strike rate who have played a min of 1000 balls
SELECT batter, SUM(batsman_run) AS "score", COUNT(batsman_run) AS "balls",
ROUND((score/balls) * 100,2) AS "strike_rate" 
FROM cricket.ipl 
GROUP BY batter
HAVING balls > 1000
ORDER BY strike_rate DESC LIMIT 5;