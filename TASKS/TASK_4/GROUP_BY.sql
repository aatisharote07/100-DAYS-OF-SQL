-- Group smartphones by brand and get count, average price, max rating, avg screen size and avg battery capacity 
SELECT brand_name, COUNT(*) AS "num_phones",
AVG(price) AS "avg_price", 
MAX(rating) AS "max_rating",
ROUND(AVG(screen_size),2) AS "Avg_Screen_Size",
AVG(battery_capacity) AS "Avg_Battery"
FROM phones.smartphones
GROUP BY brand_name
ORDER BY avg_price DESC LIMIT 20;

-- Group smartphones by whether they have NFC and get the average price and rating
SELECT has_nfc, ROUND(AVG(price),2) AS "avg_price", 
ROUND(AVG(rating),2) AS "avg_rating"
FROM smartphones
GROUP BY has_nfc
ORDER BY avg_price DESC

-- Group smartphones by the extended memory available and get the average price
SELECT extended_memory_available, AVG(price) AS "avg_price", AVG(rating) AS "avg_rating"
FROM smartphones
GROUP BY extended_memory_available 
ORDER BY avg_price DESC 

-- Group smartphones by the brand and processor brand and get the count of models and the average primary camera resolution (rear) 
SELECT brand_name, processor_brand, COUNT(*) AS "num_ phones", ROUND(AVG(primary_camera_resolution)) AS "avg_rear_cam"
FROM smartphones 
GROUP BY brand_name, processor_brand
ORDER BY brand_name

-- Find top 5 most costly phone brands
SELECT brand_name, ROUND(AVG(price)) AS "avg_price" FROM smartphones
GROUP BY brand_name 
ORDER BY avg_price DESC LIMIT 5

-- Which brand makes the smallest screen smartphones
SELECT brand_name, ROUND(AVG(screen_size)) AS "avg_screen_size" FROM smartphones
GROUP BY brand_name 
ORDER BY avg_screen_size ASC LIMIT 1

-- Group smartphones by the brand and find the brand with the highest number of models that have both nfc and an IR blaster
SELECT brand_name,COUNT(*) AS "num_phones" FROM smartphones
WHERE has_nfc = "TRUE" AND has_ir_blaster = "TRUE"
GROUP BY brand_name
ORDER BY num_phones DESC LIMIT 1

-- Find all samsung 5g enabled and find out the avg price for nfc and non-nfc phones
SELECT has_nfc, ROUND(AVG(price)) AS "avg_price" FROM smartphones
WHERE brand_name = "samsung"
GROUP BY has_nfc










 

