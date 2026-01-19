-- 1. What are the top 5 patients who claimed the highest insurance amounts?
SELECT *, DENSE_RANK() OVER(ORDER BY claim DESC) FROM insurance LIMIT 5;

-- 2. What is the average insurance claimed by patients based on the number of children they have?
SELECT children,avg_claim,row_num FROM (SELECT *,
AVG(claim) OVER(PARTITION BY children) AS avg_claim,
ROW_NUMBER() OVER(PARTITION BY children) AS row_num
FROM insurance) t
WHERE t.row_num = 1;	

-- 3. What is the highest and lowest claimed amount by patients in each region?
SELECT region,min_claim,max_claim FROM (SELECT *,
MIN(claim) OVER (PARTITION BY region) AS min_claim,
MAX(claim) OVER (PARTITION BY region) AS max_claim,
ROW_NUMBER() OVER (PARTITION BY region) AS row_num
FROM insurance) t
WHERE t.row_num = 1;

-- 4. What is the difference between the claimed amount of each patient 
-- and the claimed amount of first patient
SELECt *,
claim - FIRST_VALUE(claim) OVER() AS diff
FROM insurance
