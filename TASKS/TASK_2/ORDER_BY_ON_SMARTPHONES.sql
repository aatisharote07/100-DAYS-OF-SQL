-- Top five samsung phones with biggest screen size
SELECT model,screen_size FROM smartphones WHERE brand_name = 'samsung'
ORDER BY screen_size DESC LIMIT 5 

-- Sort all the phone in desending order of number of total cameras;
SELECT model,num_rear_cameras + num_front_cameras AS "total_cameras" FROM smartphones 
ORDER BY total_cameras DESC  

-- Sort data on basis of ppi in decreasing order
SELECT model,
ROUND(SQRT((resolution_width * resolution_width) + (resolution_height * resolution_height))/screen_size)
AS "ppi" 
FROM smartphones
ORDER BY ppi DESC 

-- Find the phone with second highest battery capacity
SELECT model,battery_capacity FROM smartphones
ORDER BY battery_capacity DESC LIMIT 1,1 
 
-- Find the name and the rating of the worst rated apple phone 
SELECT model,rating FROM smartphones
WHERE brand_name = "apple" ORDER BY rating ASC LIMIT 1

-- Sort phones alphabetically and then on the basis of rating in desc order
SELECT brand_name,rating FROM smartphones
ORDER BY brand_name ASC,rating DESC -- Sorting on two column simultaneously 
 
-- Sort phones alphabetically and then on the basis of price in desc order
SELECT brand_name,rating FROM smartphones
ORDER BY brand_name ASC,price ASC