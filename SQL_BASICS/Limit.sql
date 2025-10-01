USE my_firstdb;
SELECT  * FROM users LIMIT 5; -- Top5 rows
SELECT  * FROM users LIMIT 15 OFFSET 5; --  Skip first 5 rows, then get next 15
SELECT * FROM users LIMIT 5, 10; -- STart from 6th row and get 10 rows
SELECT * FROM users ORDER BY created_at DESC LIMIT 10;