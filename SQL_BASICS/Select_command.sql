-- CREATE DATABASE My_FirstDB;
-- USE My_FirstDB;
-- CREATE TABLE users (
-- 	id INT AUTO_INCREMENT PRIMARY KEY,
--     name VARCHAR(100) NOT NULL,
--     email VARCHAR(100) UNIQUE NOT NULL,
--     gender ENUM('Male', 'Female', 'Other'),
--     dob DATE,
-- 	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMp
--     );
SELECT * FROM users;
SELECT name,email,gender FROM users;