-- Q1. Find The number of order placed by each customers
SELECT 
    t1.name,
    COUNT(t2.order_id) AS num_orders
FROM users t1
JOIN orders t2
    ON t1.user_id = t2.user_id
GROUP BY t1.user_id, t1.name
ORDER BY num_orders DESC;

-- Q2. Find restaurant with most number of menu items
SELECT r_name,COUNT(cuisine) AS "num_items" FROM restaurants t1
JOIN menu t2 
ON t1.r_id = t2.r_id
GROUP BY t1.r_id , r_name
ORDER BY num_items DESC LIMIT 1;

-- Q3. Find the Number of votes and avg rating for all the restaurants
SELECT 
	t2.r_name,
    COUNT(*) AS "num_votes",
	ROUND(AVG(t1.restaurant_rating),2) AS "rating"
FROM orders t1
JOIN restaurants t2
	ON t1.r_id = t2.r_id
WHERE t1.restaurant_rating IS NOT NULL
GROUP BY t1.r_id, t2.r_name;

-- Q4. Find the food which is being sold at most number of restaurants
SELECT t2.f_name,COUNT(*) FROM menu t1
JOIN food t2 
ON t1.f_id = t2.f_id
GROUP BY t2.f_id,t2.f_name
ORDER BY COUNT(*) DESC; 

-- Q5. Find a restaurant with max revenue in a given month
-- -> MAY
-- SELECT MONTHNAME(DATE(date)) from orders
SELECT t1.r_name,SUM(amount) AS "revenue" FROM restaurants t1 
JOIN orders t2 
ON t1.r_id = t2.r_id
WHERE MONTHNAME(DATE(date)) = "May"
GROUP BY t1.r_id,t1.r_name
ORDER BY revenue DESC;

-- Month by Month revenue for a  particular Restaurant 
SELECT MONTHNAME(DATE(date)) AS "Month",SUM(amount) AS "revenue" FROM restaurants t1 
JOIN orders t2 
ON t1.r_id = t2.r_id
WHERE r_name = "dominos"
GROUP BY MONTHNAME(DATE(date)) 
ORDER BY revenue; 

-- Q6. Find restaurant with sales > x
SELECT t2.r_name,SUM(amount) AS "revenue" FROM orders t1
JOIN restaurants t2
ON t1.r_id = t2.r_id
GROUP BY t1.r_id,t2.r_name
HAVING revenue > 100000
