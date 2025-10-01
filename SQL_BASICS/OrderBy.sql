USE my_firstdb;
-- SELECT * FROM users WHERE gender = "Female" AND dob > "1990-01-01"; 
-- SELECT * FROM users WHERE gender = "Male" OR gender = "Other";
SELECT * FROM users ORDER BY dob ASC;
SELECT * FROM users ORDER BY name DESC;