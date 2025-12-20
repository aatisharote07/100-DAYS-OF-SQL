-- Q.7 Find customers that never Ordered
SELECT user_id,name FROM users
EXCEPT
SELECT t1.user_id,name FROM orders t1
JOIN users t2
ON t1.user_id = t2.user_id;

-- Q8. Show order details of a particular customer in a given date range
SELECT t1.order_id,t3.f_name,t4.r_name,t1.date FROM orders t1
JOIN order_details t2
ON t1.order_id = t2.order_id
JOIN food t3 
ON t2.f_id = t3.f_id
JOIN restaurants t4
ON t1.r_id = t4.r_id
WHERE user_id = 1 AND date BETWEEN "2022-05-10" AND "2022-06-10";
 
 
-- Q9. Customer Favourite food
SELECT x.user_id, x.f_name, x.cnt AS fav_food
FROM (
    SELECT u.user_id, f.f_name, COUNT(*) AS cnt
    FROM users u
    JOIN orders o
      ON u.user_id = o.user_id
    JOIN order_details od
      ON o.order_id = od.order_id
    JOIN food f
      ON od.f_id = f.f_id
    GROUP BY u.user_id, f.f_name
) x
JOIN (
    SELECT user_id, MAX(cnt) AS max_cnt
    FROM (
        SELECT u.user_id, f.f_name, COUNT(*) AS cnt
        FROM users u
        JOIN orders o
          ON u.user_id = o.user_id
        JOIN order_details od
          ON o.order_id = od.order_id
        JOIN food f
          ON od.f_id = f.f_id
        GROUP BY u.user_id, f.f_name
    ) y
    GROUP BY user_id
) m
ON x.user_id = m.user_id
AND x.cnt = m.max_cnt;

-- Q10. Find most costly restaurants(Avg price/ Dish)
SELECT t2.r_name,(SUM(price)/COUNT(*)) AS "avg_price" FROM menu t1
JOIN restaurants t2 
ON t1.r_id = t2.r_id
GROUP BY t2.r_name
ORDER BY avg_price DESC LIMIT 1;

-- Q.11 Find the deliverry partner compensation using formula (#deliveries * 100 + 1000* avg_rating)
SELECT t1.partner_name,COUNT(*) * 100 + AVG(delivery_rating) * 1000 AS "salary" FROM delivery_partner t1
JOIN orders t2
ON t1.partner_id = t2.partner_id
GROUP BY t2.partner_id ,t1.partner_name
ORDER BY salary DESC;

-- Q.12 Find all veg resataurants
SELECT t1.r_id FROM menu t1
JOIN food t2
ON t1.f_id = t2.f_id
GROUP BY t1.r_id 
HAVING MIN(type) = "Veg" AND MAX(type) = "Veg";

-- Q.13 Find  Min And Max order value for all the cuustomers
SELECT t2.name,MIN(amount),MAX(amount),AVG(amount) FROM orders t1
JOIN users t2
ON t1.user_id = t2.user_id
GROUP BY t1.user_id,t2.name