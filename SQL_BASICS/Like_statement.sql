USE my_firstdb;
SELECT * FROM users WHERE name LIKE	'A%'; -- starts with A
SELECT * FROM users WHERE name LIKE '%a';-- Ends with a
SELECT * FROM users WHERE name LIKE '%li%';-- Contains 'li