USE insurance;
-- Show records of 'male' patient from 'southwest' region.
SELECT * FROM insurance
WHERE gender = "male" AND region = "southeast"

-- Show all records having bmi in range 30 to 45 both inclusive.
SELECT * FROM insurance
WHERE bmi BETWEEN 30 AND 45;

-- Show minimum and maximum bloodpressure of diabetic patient who smokes. Make column names as MinBP and MaxBP respectively.
SELECT MIN(bloodpressure) AS "MinBP",MAX(bloodpressure) AS "MaxBP"  FROM insurance WHERE smoker = "Yes" AND diabetic = "Yes";

-- Find no of unique patients who are not from southwest region.
SELECT COUNT(DISTINCT(PatientID)) FROM insurance 
WHERE region != "southwest";
 
-- Total claim amount from male smoker.
SELECT SUM(claim) FROM insurance WHERE gender = "male";

-- Select all records of south region.

SELECT * FROM insurance WHERE region = "southeast" OR region = "southwest";
SELECT * FROM insurance WHERE region LIKE "south%";

-- No of patient having normal blood pressure. Normal range[90-120]

SELECT COUNT(*) FROM insurance WHERE bloodpressure BETWEEN 90 AND 120;

-- No of pateint below 17 years of age having normal blood pressure as per below formula -
-- BP normal range = 80+(age in years × 2) to 100 + (age in years × 2)
-- Note: Formula taken just for practice, don't take in real sense. 

SELECT COUNT(*) AS normalbp FROM insurance 
WHERE age < 17 AND 
bloodpressure BETWEEN (80 + (age * 2)) AND (100 + (age * 2));

-- What is the average claim amount for non-smoking female patients who are diabetic?insurance 

SELECT AVG(claim) FROM insurance 
WHERE gender = "female" AND smoker = "No" AND
diabetic = "Yes";

-- Write a SQL query to update the claim amount for the patient with PatientID = 1234 to 5000.

UPDATE insurance
SET claim  = 5000 
WHERE PatientID = 1234;	

-- Write a SQL query to delete all records for patients who are smokers and have no children.

DELETE FROM insurance
WHERE smoker = "Yes" AND children = 0;