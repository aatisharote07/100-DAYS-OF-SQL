-- Find the average rating of smartphone brands which have more than 20 phones
SELECT brand_name,AVG(rating) AS "avg_rating",COUNT(*) AS "num_phones",
AVG(price) AS "avg_price"
FROM phones.smartphones 
GROUP BY brand_name
HAVING num_phones > 20
ORDER BY avg_price DESC LIMIT 10

-- Find the top 3 brands with the highest avg ram that have a refresh rate of atleast 90 hz and fast charging available and dont consider brands which have less than 10 phones.
SELECT brand_name, AVG(ram_capacity) AS "avg_ram", refresh_rate, fast_charging_available = 1,COUNT(*) AS "num_phones"
FROM phones.smartphones
WHERE refresh_rate > 90 AND fast_charging_available = 1
GROUP BY brand_name HAVING
num_phones < 10 
ORDER BY avg_ram DESC LIMIT 3

-- Find the avg price of all the phone brands with avg rating > 70 and num_phones more than 10 among 5g enabled phones
SELECT brand_name, ROUND(AVG(price),2) AS "avg_price"
FROM smartphones
WHERE has_5g = "True"
GROUP BY brand_name
HAVING  
AVG(rating) > 70 AND  COUNT(*) > 10
ORDER BY avg_price DESC 